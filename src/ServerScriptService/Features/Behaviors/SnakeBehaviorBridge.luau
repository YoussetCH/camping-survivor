--!strict
-- SnakeBehaviorBridge
-- Reference-style snake movement using BodyVelocity + physics (closer to original asset feel),
-- while keeping game-integrated damage/status through SurvivalService.

export type SnakeBehaviorBridgeModule = {
	init: () -> (),
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SurvivalService = require(ServerScriptService.Services.SurvivalService)
local FaunaConstants = require(ReplicatedStorage.Shared.Constants.FaunaConstants)
local SnakeDefinition = require(ReplicatedStorage.Shared.Features.Snake.SnakeDefinition)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)

-- Tuning aligned with gameplay request (dodge + punish windows)
local SPEED = SnakeDefinition.moveSpeedStuds
local DETECT_RANGE = SnakeDefinition.detectRangeStuds
local ATTACK_RANGE = 7
local LUNGE_HIT_RANGE = 6
local DAMAGE = SnakeDefinition.damage
local POISON_CHANCE = 1.0
local ALERT_DURATION = 0.35
local WINDUP_DURATION = 0.5
local LUNGE_DURATION = 0.32
local RECOVER_DURATION = 1.55
local WANDER_DISTANCE = 5
local WANDER_PAUSE_MIN = 1.8
local WANDER_PAUSE_MAX = 2.8
local AI_TICK = 0.1

type SnakeState = "wander" | "alert" | "windup" | "lunge" | "recover"

local initialized = false
local activeSnakes: { [Model]: boolean } = {}

local function getHead(model: Model): BasePart?
	local head = model:FindFirstChild("Head", true)
	if head ~= nil and head:IsA("BasePart") then
		return head
	end
	return nil
end

local function getRoot(model: Model): BasePart?
	local root = model:FindFirstChild("HumanoidRootPart", true)
	if root ~= nil and root:IsA("BasePart") then
		return root
	end

	local torso = model:FindFirstChild("Torso1", true)
	if torso ~= nil and torso:IsA("BasePart") then
		return torso
	end

	return getHead(model)
end

local function getOrCreateBodyVelocity(part: BasePart): BodyVelocity
	local existing = part:FindFirstChildOfClass("BodyVelocity")
	if existing ~= nil then
		return existing
	end

	local velocity = Instance.new("BodyVelocity")
	velocity.Name = "BridgeVelocity"
	velocity.MaxForce = Vector3.new(4000, 0, 4000)
	velocity.Velocity = Vector3.new(0, 0, 0)
	velocity.Parent = part
	return velocity
end

local function setVelocity(bodyVelocity: BodyVelocity, direction: Vector3, speed: number, verticalForce: boolean?)
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude <= 0.001 then
		bodyVelocity.Velocity = Vector3.zero
		return
	end

	local dir = flat.Unit
	bodyVelocity.MaxForce = if verticalForce then Vector3.new(8000, 8000, 8000) else Vector3.new(4000, 0, 4000)
	bodyVelocity.Velocity = dir * speed
end

local function stopVelocity(bodyVelocity: BodyVelocity)
	bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
	bodyVelocity.Velocity = Vector3.zero
end

local function playSound(head: BasePart, keywords: { string })
	for _, descendant in head:GetDescendants() do
		if descendant:IsA("Sound") then
			local lowered = string.lower(descendant.Name)
			for _, keyword in keywords do
				if string.find(lowered, keyword, 1, true) ~= nil then
					descendant:Play()
					return
				end
			end
		end
	end
end

local function getPlayerRoot(player: Player): BasePart?
	local character = player.Character
	if character == nil then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root ~= nil and root:IsA("BasePart") then
		return root
	end

	return nil
end

local function getNearestPlayer(position: Vector3): (Player?, BasePart?, number)
	local nearestPlayer: Player? = nil
	local nearestRoot: BasePart? = nil
	local nearestDistance = math.huge

	for _, player in Players:GetPlayers() do
		local root = getPlayerRoot(player)
		if root ~= nil then
			local distance = (position - root.Position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestPlayer = player
				nearestRoot = root
			end
		end
	end

	return nearestPlayer, nearestRoot, nearestDistance
end

local function clearAttackTelegraph(model: Model)
	model:SetAttribute(FaunaConstants.SNAKE_ATTACK_STARTED_AT_ATTRIBUTE, nil)
	model:SetAttribute(FaunaConstants.SNAKE_ATTACK_DURATION_ATTRIBUTE, nil)
end

local function runSnakeAi(model: Model)
	if activeSnakes[model] then
		return
	end
	activeSnakes[model] = true
	clearAttackTelegraph(model)

	local head = getHead(model)
	local root = getRoot(model)
	if head == nil or root == nil then
		activeSnakes[model] = nil
		return
	end

	local bodyVelocity = getOrCreateBodyVelocity(head)

	local gravityForce = head:FindFirstChildOfClass("VectorForce")
	if gravityForce ~= nil then
		gravityForce.Enabled = true
	end

	local state: SnakeState = "wander"
	local stateTimer = 0
	local wanderTarget: Vector3? = nil
	local accumulator = 0
	local lungeDirection = Vector3.new(1, 0, 0)
	local recoverDirection = Vector3.new(-1, 0, 0)

	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		if model.Parent == nil then
			connection:Disconnect()
			activeSnakes[model] = nil
			return
		end

		local liveHead = getHead(model)
		if liveHead == nil then
			connection:Disconnect()
			activeSnakes[model] = nil
			return
		end

		accumulator += deltaTime
		if accumulator < AI_TICK then
			return
		end

		stateTimer -= accumulator
		local tick = accumulator
		accumulator = 0

		local player, playerRoot, distance = getNearestPlayer(liveHead.Position)

		if state == "wander" then
			if player ~= nil and playerRoot ~= nil and distance <= DETECT_RANGE then
				if distance <= ATTACK_RANGE + 1 then
					state = "alert"
					stateTimer = ALERT_DURATION
					stopVelocity(bodyVelocity)
					playSound(liveHead, { "growl" })
					return
				end

				setVelocity(bodyVelocity, playerRoot.Position - liveHead.Position, SPEED, false)
				return
			end

			if wanderTarget == nil or (wanderTarget - liveHead.Position).Magnitude < 2 then
				local angle = math.random() * math.pi * 2
				wanderTarget = liveHead.Position + Vector3.new(math.cos(angle) * WANDER_DISTANCE, 0, math.sin(angle) * WANDER_DISTANCE)
				stateTimer = math.random() * (WANDER_PAUSE_MAX - WANDER_PAUSE_MIN) + WANDER_PAUSE_MIN
				if math.random() < 0.35 then
					playSound(liveHead, { "hiss" })
				end
			end

			if stateTimer <= 0 and wanderTarget ~= nil then
				setVelocity(bodyVelocity, wanderTarget - liveHead.Position, SPEED * 0.55, false)
			else
				stopVelocity(bodyVelocity)
			end
		elseif state == "alert" then
			stopVelocity(bodyVelocity)
			if stateTimer <= 0 then
				if playerRoot ~= nil and distance <= ATTACK_RANGE then
					state = "windup"
					stateTimer = WINDUP_DURATION
					model:SetAttribute(FaunaConstants.SNAKE_ATTACK_STARTED_AT_ATTRIBUTE, workspace:GetServerTimeNow())
					model:SetAttribute(FaunaConstants.SNAKE_ATTACK_DURATION_ATTRIBUTE, WINDUP_DURATION + LUNGE_DURATION)
				else
					state = "wander"
					wanderTarget = nil
				end
			end
		elseif state == "windup" then
			stopVelocity(bodyVelocity)
			if playerRoot ~= nil then
				local dir = playerRoot.Position - liveHead.Position
				if dir.Magnitude > 0.01 then
					lungeDirection = dir.Unit
					recoverDirection = -lungeDirection
				end
			end

			if stateTimer <= 0 then
				state = "lunge"
				stateTimer = LUNGE_DURATION
				playSound(liveHead, { "growl", "hiss" })
			end
		elseif state == "lunge" then
			setVelocity(bodyVelocity, lungeDirection, SPEED * 2.1, true)
			if stateTimer <= 0 then
				local hit = false
				if player ~= nil and playerRoot ~= nil then
					local hitRange = LUNGE_HIT_RANGE or 6
					if (liveHead.Position - playerRoot.Position).Magnitude <= hitRange then
						hit = true
						local effects: { string } = {}
						if math.random() <= POISON_CHANCE then
							table.insert(effects, "poison")
						end
						SurvivalService.applyDamage(player, DAMAGE, effects)
						playSound(liveHead, { "bite" })
						Logger.info("SnakeBehaviorBridge", `Snake hit {player.Name} — {DAMAGE}dmg poison={#effects > 0}`)
					end
				end

				clearAttackTelegraph(model)
				if not hit then
					playSound(liveHead, { "hiss" })
				end

				state = "recover"
				stateTimer = RECOVER_DURATION
			end
		elseif state == "recover" then
			setVelocity(bodyVelocity, recoverDirection, RECOVER_DURATION > 0 and (RECOVER_SPEED) or 0, false)
			if stateTimer <= 0 then
				state = "wander"
				wanderTarget = nil
			end
		end

		-- keep root generally aligned with head so chained parts don't drift far
		if root ~= nil and liveHead ~= nil and (root.Position - liveHead.Position).Magnitude > 8 then
			model:PivotTo(CFrame.new(liveHead.Position))
		end

		-- small safety cap on very large dt spikes
		if tick > 1.5 then
			stopVelocity(bodyVelocity)
		end
	end)
end

local function tryRegisterSnake(instance: Instance)
	if not instance:IsA("Model") then
		return
	end
	if instance:GetAttribute("UsesEmbeddedAi") ~= true then
		return
	end
	if getHead(instance) == nil then
		return
	end

	runSnakeAi(instance)
end

local SnakeBehaviorBridge: SnakeBehaviorBridgeModule = {
	init = function()
		if initialized then
			return
		end

		initialized = true

		for _, descendant in workspace:GetDescendants() do
			tryRegisterSnake(descendant)
		end

		workspace.DescendantAdded:Connect(function(descendant: Instance)
			task.defer(tryRegisterSnake, descendant)
		end)

		-- Safety net: periodic reconcile in case events miss any spawned model.
		task.spawn(function()
			while true do
				task.wait(2)
				for _, descendant in workspace:GetDescendants() do
					tryRegisterSnake(descendant)
				end
			end
		end)
	end,
}

return SnakeBehaviorBridge
