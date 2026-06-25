--!strict

local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BaseController = require(script.Parent.Parent.Kernel.BaseController)
local ClientKernel = require(script.Parent.Parent.Kernel.ClientKernel)
local FaunaConstants = require(ReplicatedStorage.Shared.Constants.FaunaConstants)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local FaunaWalkAnimation = require(ReplicatedStorage.Shared.World.FaunaWalkAnimation)
local SnakeAnimation = require(ReplicatedStorage.Shared.World.SnakeAnimation)
local WolfAttackAnimation = require(ReplicatedStorage.Shared.World.WolfAttackAnimation)
local FaunaTypes = require(ReplicatedStorage.Shared.Types.Fauna)
local Localization = require(ReplicatedStorage.Shared.Localization.Localization)
local ResourceNodesConstants = require(ReplicatedStorage.Shared.Constants.ResourceNodesConstants)
local ToolSwingAnimation = require(ReplicatedStorage.Shared.Tools.ToolSwingAnimation)

local FaunaController = BaseController.new("FaunaController")

local ATTACK_ACTION_NAME = "AttackFauna"
local DODGE_ACTION_NAME = "DodgeFauna"
local ATTACK_KEY = Enum.KeyCode.F
local DODGE_KEY = Enum.KeyCode.Q
local FRONT_ATTACK_DOT_THRESHOLD = 0.25

local healthBars: { [string]: BillboardGui } = {}
local walkStates: { [Model]: { lastPosition: Vector3, walkPhase: number } } = {}
local toastLabel: TextLabel? = nil
local attackButton: TextButton? = nil
local dodgeButton: TextButton? = nil
local toastToken = 0
local holdAttackActive = false
local holdAttackToken = 0
local dodgeCooldown = false

local function findFaunaModel(faunaId: string): Model?
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("Model") and descendant:GetAttribute(FaunaConstants.FAUNA_ID_ATTRIBUTE) == faunaId then
			return descendant
		end
	end

	return nil
end

local function getFaunaIdFromInstance(instance: Instance): string?
	local current: Instance? = instance

	while current ~= nil do
		if current:IsA("Model") then
			local faunaId = current:GetAttribute(FaunaConstants.FAUNA_ID_ATTRIBUTE)
			if type(faunaId) == "string" then
				return faunaId
			end
		end

		current = current.Parent
	end

	return nil
end

local function removeHealthBar(faunaId: string)
	local billboard = healthBars[faunaId]
	if billboard ~= nil then
		billboard:Destroy()
		healthBars[faunaId] = nil
	end
end

local function updateHealthBar(snapshot: FaunaTypes.FaunaSnapshot)
	if snapshot.removed == true then
		removeHealthBar(snapshot.faunaId)
		return
	end

	local model = findFaunaModel(snapshot.faunaId)
	if model == nil or model.PrimaryPart == nil then
		return
	end

	local billboard = healthBars[snapshot.faunaId]
	if billboard == nil then
		billboard = Instance.new("BillboardGui")
		billboard.Name = "FaunaHealthBar"
		billboard.AlwaysOnTop = true
		billboard.Size = UDim2.fromOffset(80, 10)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.Parent = model.PrimaryPart

		local background = Instance.new("Frame")
		background.Name = "Background"
		background.Size = UDim2.fromScale(1, 1)
		background.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		background.BorderSizePixel = 0
		background.Parent = billboard

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
		fill.BorderSizePixel = 0
		fill.Parent = background

		healthBars[snapshot.faunaId] = billboard
	end

	local background = billboard:FindFirstChild("Background")
	local fill = if background ~= nil then background:FindFirstChild("Fill") else nil
	if fill ~= nil and fill:IsA("Frame") then
		local ratio = if snapshot.maxHp > 0 then snapshot.hp / snapshot.maxHp else 0
		fill.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
	end
end

local function showToast(messageKey: string)
	if toastLabel == nil then
		return
	end

	toastToken += 1
	local currentToken = toastToken
	toastLabel.Text = Localization.get(messageKey)
	toastLabel.Visible = true

	task.delay(2.5, function()
		if toastToken == currentToken and toastLabel ~= nil then
			toastLabel.Visible = false
		end
	end)
end

local function getEquippedToolId(): string?
	local syncController = ClientKernel.getController("ClientSyncController")
	if syncController == nil then
		return nil
	end

	local inventory = syncController:GetInventory()
	if inventory == nil then
		return nil
	end

	return inventory.equipped.toolItemId
end

local function getFaunaIdFromScreenPoint(player: Player, screenX: number, screenY: number): string?
	local character = player.Character
	local camera = workspace.CurrentCamera

	if camera == nil then
		return nil
	end

	local unitRay = camera:ScreenPointToRay(screenX, screenY)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	if character ~= nil then
		raycastParams.FilterDescendantsInstances = { character }
	end

	local rayResult = workspace:Raycast(
		unitRay.Origin,
		unitRay.Direction * (FaunaConstants.PLAYER_ATTACK_RANGE_STUDS + 12),
		raycastParams
	)

	if rayResult ~= nil then
		return getFaunaIdFromInstance(rayResult.Instance)
	end

	return nil
end

local function findNearestFaunaInFront(player: Player): string?
	local character = player.Character

	if character == nil then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")

	if root == nil or not root:IsA("BasePart") then
		return nil
	end

	local lookVector = root.CFrame.LookVector
	local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)

	if flatLook.Magnitude <= 0.01 then
		return nil
	end

	flatLook = flatLook.Unit

	local bestFaunaId: string? = nil
	local bestDistance = FaunaConstants.PLAYER_ATTACK_RANGE_STUDS + 1

	for _, descendant in workspace:GetDescendants() do
		if not descendant:IsA("Model") then
			continue
		end

		local faunaId = descendant:GetAttribute(FaunaConstants.FAUNA_ID_ATTRIBUTE)

		if type(faunaId) ~= "string" then
			continue
		end

		local primaryPart = descendant.PrimaryPart

		if primaryPart == nil then
			continue
		end

		local offset = primaryPart.Position - root.Position
		local flatOffset = Vector3.new(offset.X, 0, offset.Z)
		local distance = flatOffset.Magnitude

		if distance > FaunaConstants.PLAYER_ATTACK_RANGE_STUDS or distance <= 0.05 then
			continue
		end

		if flatLook:Dot(flatOffset.Unit) < FRONT_ATTACK_DOT_THRESHOLD then
			continue
		end

		if distance < bestDistance then
			bestDistance = distance
			bestFaunaId = faunaId
		end
	end

	return bestFaunaId
end

local function canSwingWithEquippedTool(): (boolean, string?)
	local equippedTool = getEquippedToolId()

	if equippedTool == nil then
		return false, "combat.error.no_tool"
	end

	if not ResourceNodesConstants.matchesAxeTool(equippedTool) then
		return false, "combat.error.wrong_tool"
	end

	return true, nil
end

local function performSwing(faunaId: string?, silent: boolean?): boolean
	local player = Players.LocalPlayer
	local canSwing, errorKey = canSwingWithEquippedTool()

	if not canSwing then
		if not silent and errorKey ~= nil then
			showToast(errorKey)
		end

		return false
	end

	local character = player.Character

	if character ~= nil then
		ToolSwingAnimation.play(character)
	end

	if faunaId == nil then
		faunaId = findNearestFaunaInFront(player)
	end

	if faunaId ~= nil then
		Networking.getEvent("AttackFaunaEvent"):FireServer(faunaId)
	end

	return true
end

local function stopHeldAttack()
	holdAttackActive = false
	holdAttackToken += 1
end

local function startHeldAttack()
	if holdAttackActive then
		return
	end

	local canSwing, errorKey = canSwingWithEquippedTool()

	if not canSwing then
		if errorKey ~= nil then
			showToast(errorKey)
		end

		return
	end

	holdAttackActive = true
	holdAttackToken += 1
	local currentToken = holdAttackToken

	performSwing(nil, true)

	task.spawn(function()
		while holdAttackActive and currentToken == holdAttackToken do
			local elapsed = 0

			while elapsed < FaunaConstants.PLAYER_ATTACK_COOLDOWN_SECONDS and holdAttackActive and currentToken == holdAttackToken do
				task.wait(0.05)
				elapsed += 0.05
			end

			if not holdAttackActive or currentToken ~= holdAttackToken then
				break
			end

			performSwing(nil, true)
		end
	end)
end

local function tryAttackFromScreenPoint(screenX: number, screenY: number)
	local player = Players.LocalPlayer
	local faunaId = getFaunaIdFromScreenPoint(player, screenX, screenY)

	performSwing(faunaId)
end

local function refreshAttackButtonLabel()
	if attackButton ~= nil then
		attackButton.Text = Localization.get("ui.combat.attack")
	end
end

local function refreshDodgeButtonLabel()
	if dodgeButton ~= nil then
		dodgeButton.Text = Localization.get("ui.combat.dodge")
	end
end

local function performClientDash()
	local player = Players.LocalPlayer
	local character = player.Character
	if character == nil then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if rootPart == nil or not rootPart:IsA("BasePart") or humanoid == nil then
		return
	end

	-- Dash sideways (right) relative to character facing
	local rightVector = rootPart.CFrame.RightVector
	local dashTarget = rootPart.Position + rightVector * FaunaConstants.DODGE_MOVE_STUDS

	-- Briefly boost walkspeed for snappy feel, then restore
	local originalSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = originalSpeed * 3.5
	humanoid:MoveTo(dashTarget)

	task.delay(0.18, function()
		if humanoid.Parent ~= nil then
			humanoid.WalkSpeed = originalSpeed
		end
	end)
end

local function performDodge()
	if dodgeCooldown then
		showToast("combat.dodge.cooldown")
		return
	end

	dodgeCooldown = true
	performClientDash()
	Networking.getEvent("DodgeEvent"):FireServer()

	-- Visual cooldown indicator on button
	if dodgeButton ~= nil then
		dodgeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	end

	task.delay(FaunaConstants.DODGE_COOLDOWN_SECONDS, function()
		dodgeCooldown = false
		if dodgeButton ~= nil then
			dodgeButton.BackgroundColor3 = Color3.fromRGB(55, 120, 180)
		end
	end)
end

function FaunaController:Init()
	local trove = self:GetTrove()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FaunaHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 96
	screenGui.Parent = playerGui
	trove:Add(screenGui)

	toastLabel = Instance.new("TextLabel")
	toastLabel.AnchorPoint = Vector2.new(0.5, 1)
	toastLabel.Position = UDim2.new(0.5, 0, 1, -160)
	toastLabel.Size = UDim2.fromOffset(320, 32)
	toastLabel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	toastLabel.BackgroundTransparency = 0.15
	toastLabel.BorderSizePixel = 0
	toastLabel.Font = Enum.Font.Gotham
	toastLabel.TextSize = 13
	toastLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	toastLabel.Visible = false
	toastLabel.Parent = screenGui

	local toastCorner = Instance.new("UICorner")
	toastCorner.CornerRadius = UDim.new(0, 8)
	toastCorner.Parent = toastLabel

	attackButton = Instance.new("TextButton")
	attackButton.Name = "AttackButton"
	attackButton.AnchorPoint = Vector2.new(1, 1)
	attackButton.Position = UDim2.new(1, -16, 1, -88)
	attackButton.Size = if UserInputService.TouchEnabled then UDim2.fromOffset(72, 72) else UDim2.fromOffset(64, 64)
	attackButton.BackgroundColor3 = Color3.fromRGB(180, 55, 55)
	attackButton.BorderSizePixel = 0
	attackButton.Font = Enum.Font.GothamBold
	attackButton.TextSize = if UserInputService.TouchEnabled then 14 else 13
	attackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	attackButton.Text = Localization.get("ui.combat.attack")
	attackButton.Parent = screenGui

	local attackCorner = Instance.new("UICorner")
	attackCorner.CornerRadius = UDim.new(1, 0)
	attackCorner.Parent = attackButton

	-- Dodge button (positioned to the left of attack button)
	dodgeButton = Instance.new("TextButton")
	dodgeButton.Name = "DodgeButton"
	dodgeButton.AnchorPoint = Vector2.new(1, 1)
	dodgeButton.Position = UDim2.new(1, -100, 1, -88)
	dodgeButton.Size = if UserInputService.TouchEnabled then UDim2.fromOffset(72, 72) else UDim2.fromOffset(64, 64)
	dodgeButton.BackgroundColor3 = Color3.fromRGB(55, 120, 180)
	dodgeButton.BorderSizePixel = 0
	dodgeButton.Font = Enum.Font.GothamBold
	dodgeButton.TextSize = if UserInputService.TouchEnabled then 14 else 13
	dodgeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	dodgeButton.Text = Localization.get("ui.combat.dodge")
	dodgeButton.Parent = screenGui

	local dodgeCorner = Instance.new("UICorner")
	dodgeCorner.CornerRadius = UDim.new(1, 0)
	dodgeCorner.Parent = dodgeButton

	trove:Connect(dodgeButton.MouseButton1Down, function()
		performDodge()
	end)

	trove:Connect(dodgeButton.TouchTap, function()
		performDodge()
	end)

	trove:Connect(attackButton.MouseButton1Down, function()
		startHeldAttack()
	end)

	trove:Connect(attackButton.MouseButton1Up, function()
		stopHeldAttack()
	end)

	trove:Connect(attackButton.MouseLeave, function()
		stopHeldAttack()
	end)

	ContextActionService:BindAction(
		ATTACK_ACTION_NAME,
		function(_actionName, inputState)
			if UserInputService:GetFocusedTextBox() ~= nil then
				return Enum.ContextActionResult.Pass
			end

			if inputState == Enum.UserInputState.Begin then
				startHeldAttack()
				return Enum.ContextActionResult.Sink
			end

			if inputState == Enum.UserInputState.End then
				stopHeldAttack()
				return Enum.ContextActionResult.Sink
			end

			return Enum.ContextActionResult.Pass
		end,
		false,
		ATTACK_KEY
	)

	ContextActionService:BindAction(
		DODGE_ACTION_NAME,
		function(_actionName, inputState)
			if UserInputService:GetFocusedTextBox() ~= nil then
				return Enum.ContextActionResult.Pass
			end

			if inputState == Enum.UserInputState.Begin then
				performDodge()
				return Enum.ContextActionResult.Sink
			end

			return Enum.ContextActionResult.Pass
		end,
		false,
		DODGE_KEY
	)

	trove:Add(function()
		ContextActionService:UnbindAction(ATTACK_ACTION_NAME)
		ContextActionService:UnbindAction(DODGE_ACTION_NAME)
		stopHeldAttack()
	end)

	trove:Connect(Networking.getEvent("FaunaUpdatedEvent").OnClientEvent, function(snapshot: FaunaTypes.FaunaSnapshot)
		updateHealthBar(snapshot)
	end)

	trove:Connect(Networking.getEvent("DodgeResultEvent").OnClientEvent, function(result: { success: boolean?, failed: boolean?, cooldown: boolean? })
		if result.cooldown then
			showToast("combat.dodge.cooldown")
		elseif result.success then
			showToast("combat.dodge.success")
		elseif result.failed then
			showToast("combat.dodge.failed")
		end
	end)

	trove:Connect(UserInputService.InputBegan, function(input, gameProcessed)
		if UserInputService:GetFocusedTextBox() ~= nil then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		if gameProcessed and getEquippedToolId() == nil then
			return
		end

		tryAttackFromScreenPoint(input.Position.X, input.Position.Y)
	end)

	trove:Connect(Localization.LocaleChanged, refreshAttackButtonLabel)
	trove:Connect(Localization.LocaleChanged, refreshDodgeButtonLabel)
end

function FaunaController:Start()
	local trove = self:GetTrove()

	trove:Connect(RunService.Heartbeat, function(deltaTime: number)
		for _, descendant in workspace:GetDescendants() do
			if not descendant:IsA("Model") or descendant:GetAttribute("WalkAnimated") ~= true then
				continue
			end

			local model = descendant
			local root = model.PrimaryPart
			if root == nil then
				continue
			end

			if model.Parent == nil then
				walkStates[model] = nil
				continue
			end

			local state = walkStates[model]
			if state == nil then
				walkStates[model] = {
					lastPosition = root.Position,
					walkPhase = 0,
				}
				continue
			end

			local moved = (root.Position - state.lastPosition).Magnitude
			local isMoving = moved > 0.05
			local speciesId = model:GetAttribute(FaunaConstants.FAUNA_SPECIES_ATTRIBUTE)

			if speciesId == "snake" and SnakeAnimation.isSnakeCapable(model) then
				local attackAlpha = 0
				local attackStartedAt = model:GetAttribute(FaunaConstants.SNAKE_ATTACK_STARTED_AT_ATTRIBUTE)
				local attackDuration = model:GetAttribute(FaunaConstants.SNAKE_ATTACK_DURATION_ATTRIBUTE)

				if type(attackStartedAt) == "number" and type(attackDuration) == "number" and attackDuration > 0 then
					attackAlpha = math.clamp((workspace:GetServerTimeNow() - attackStartedAt) / attackDuration, 0, 1)
				end

				state.walkPhase = SnakeAnimation.advancePhase(state.walkPhase, deltaTime, isMoving)
				SnakeAnimation.update(model, state.walkPhase, isMoving, attackAlpha)
			elseif speciesId == "wolf" and WolfAttackAnimation.isAttackCapable(model) then
				local attackAlpha = 0
				local attackStartedAt = model:GetAttribute(FaunaConstants.WOLF_ATTACK_STARTED_AT_ATTRIBUTE)
				local attackDuration = model:GetAttribute(FaunaConstants.WOLF_ATTACK_DURATION_ATTRIBUTE)

				if type(attackStartedAt) == "number" and type(attackDuration) == "number" and attackDuration > 0 then
					attackAlpha = math.clamp((workspace:GetServerTimeNow() - attackStartedAt) / attackDuration, 0, 1)
				end

				state.walkPhase = FaunaWalkAnimation.advancePhase(state.walkPhase, deltaTime, isMoving)
				if attackAlpha > 0 then
					WolfAttackAnimation.update(model, attackAlpha)
				else
					FaunaWalkAnimation.update(model, state.walkPhase, isMoving)
				end
			else
				state.walkPhase = FaunaWalkAnimation.advancePhase(state.walkPhase, deltaTime, isMoving)
				FaunaWalkAnimation.update(model, state.walkPhase, isMoving)
			end
			state.lastPosition = root.Position
		end
	end)
end

return FaunaController
