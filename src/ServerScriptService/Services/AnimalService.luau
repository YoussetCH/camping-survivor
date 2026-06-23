--!strict

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseService = require(ServerScriptService.Kernel.BaseService)
local DayNightService = require(ServerScriptService.Services.DayNightService)
local FaunaConstants = require(ReplicatedStorage.Shared.Constants.FaunaConstants)
local FaunaRegistry = require(ServerScriptService.Features.FaunaRegistry)
local InventoryService = require(ServerScriptService.Services.InventoryService)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local ResourceNodesConstants = require(ReplicatedStorage.Shared.Constants.ResourceNodesConstants)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local SurvivalService = require(ServerScriptService.Services.SurvivalService)
local FaunaModelUtils = require(ReplicatedStorage.Shared.World.FaunaModelUtils)
local FaunaTypes = require(ReplicatedStorage.Shared.Types.Fauna)

local AnimalService = BaseService.new("AnimalService")

type FaunaInstance = {
	faunaId: string,
	speciesId: string,
	model: Model,
	humanoid: Humanoid,
	hp: number,
	maxHp: number,
	state: FaunaTypes.FaunaAiState,
	targetPlayer: Player?,
	lastAttackAt: number,
	spawnPosition: Vector3,
	patrolTarget: Vector3?,
	revealed: boolean,
	lastAttacker: Player?,
}

local faunaInstances: { [string]: FaunaInstance } = {}
local playerAttackCooldowns: { [number]: number } = {}
local faunaCounter = 0
local aiAccumulator = 0

local function getCharacterRoot(player: Player): BasePart?
	local character = player.Character
	if character == nil then
		return nil
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart ~= nil and rootPart:IsA("BasePart") then
		return rootPart
	end
	return nil
end

local function getFaunaRoot(fauna: FaunaInstance): BasePart?
	return fauna.model.PrimaryPart
end

local function countFaunaInstances(): number
	local count = 0
	for _ in faunaInstances do
		count += 1
	end
	return count
end

local function buildSnapshot(fauna: FaunaInstance, removed: boolean?): FaunaTypes.FaunaSnapshot
	return {
		faunaId = fauna.faunaId,
		speciesId = fauna.speciesId,
		hp = fauna.hp,
		maxHp = fauna.maxHp,
		state = fauna.state,
		removed = removed,
	}
end

local function broadcastSnapshot(fauna: FaunaInstance, removed: boolean?)
	local snapshot = buildSnapshot(fauna, removed)
	local event = Networking.getEvent("FaunaUpdatedEvent")
	local root = getFaunaRoot(fauna)
	if root == nil then
		return
	end

	for _, player in Players:GetPlayers() do
		local playerRoot = getCharacterRoot(player)
		if playerRoot ~= nil and (playerRoot.Position - root.Position).Magnitude <= FaunaConstants.FAUNA_SYNC_RADIUS_STUDS then
			event:FireClient(player, snapshot)
		end
	end
end

local function syncNearbyFaunaToPlayer(player: Player)
	local playerRoot = getCharacterRoot(player)
	if playerRoot == nil then
		return
	end

	local event = Networking.getEvent("FaunaUpdatedEvent")

	for _, fauna in faunaInstances do
		local root = getFaunaRoot(fauna)
		if root ~= nil and (playerRoot.Position - root.Position).Magnitude <= FaunaConstants.FAUNA_SYNC_RADIUS_STUDS then
			event:FireClient(player, buildSnapshot(fauna))
		end
	end
end

local function countFaunaNearPosition(position: Vector3): number
	local count = 0

	for _, fauna in faunaInstances do
		local root = getFaunaRoot(fauna)
		if root ~= nil and (root.Position - position).Magnitude <= FaunaConstants.PLAYER_FAUNA_RADIUS_STUDS then
			count += 1
		end
	end

	return count
end

local function rollStatusEffects(definition: FaunaTypes.FaunaSpeciesDefinition): { string }
	local applied: { string } = {}

	for _, status in definition.statusOnHit do
		if math.random() <= status.chance then
			table.insert(applied, status.id)
		end
	end

	return applied
end

local function grantDrops(player: Player, definition: FaunaTypes.FaunaSpeciesDefinition)
	for _, drop in definition.drops do
		if math.random() <= drop.chance then
			InventoryService.grantItem(player, drop.itemId, drop.quantity)
		end
	end
end

local function destroyFauna(faunaId: string, killer: Player?)
	local fauna = faunaInstances[faunaId]
	if fauna == nil then
		return
	end

	local behavior = FaunaRegistry.get(fauna.speciesId)
	if killer ~= nil and behavior ~= nil then
		grantDrops(killer, behavior.definition)
	end

	broadcastSnapshot(fauna, true)
	fauna.model:Destroy()
	faunaInstances[faunaId] = nil
end

local function canSpeciesAggress(definition: FaunaTypes.FaunaSpeciesDefinition): boolean
	if definition.aggressiveByDay then
		return true
	end

	local phase = DayNightService.getPhase()
	return phase == "night" or phase == "dusk"
end

local function findNearestPlayer(fauna: FaunaInstance, maxRange: number): (Player?, number)
	local root = getFaunaRoot(fauna)
	if root == nil then
		return nil, math.huge
	end

	local nearestPlayer: Player? = nil
	local nearestDistance = math.huge

	for _, player in Players:GetPlayers() do
		local playerRoot = getCharacterRoot(player)
		if playerRoot ~= nil then
			local distance = (playerRoot.Position - root.Position).Magnitude
			if distance <= maxRange and distance < nearestDistance then
				nearestPlayer = player
				nearestDistance = distance
			end
		end
	end

	return nearestPlayer, nearestDistance
end

local function ensurePatrolTarget(fauna: FaunaInstance)
	local root = getFaunaRoot(fauna)
	if root == nil then
		return
	end

	if fauna.patrolTarget == nil then
		local angle = math.random() * math.pi * 2
		local radius = math.random(8, FaunaConstants.PATROL_RADIUS_STUDS)
		fauna.patrolTarget = fauna.spawnPosition + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		return
	end

	local flatDistance = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(fauna.patrolTarget.X, 0, fauna.patrolTarget.Z)).Magnitude
	if flatDistance < 3 then
		fauna.patrolTarget = nil
	end
end

local function moveFaunaToward(fauna: FaunaInstance, targetPosition: Vector3, speed: number)
	local root = getFaunaRoot(fauna)
	if root == nil then
		return
	end

	local flatOffset = Vector3.new(targetPosition.X - root.Position.X, 0, targetPosition.Z - root.Position.Z)
	if flatOffset.Magnitude <= 1 then
		return
	end

	fauna.humanoid.WalkSpeed = speed
	fauna.humanoid:MoveTo(Vector3.new(targetPosition.X, root.Position.Y, targetPosition.Z))
end

local function tryAttackPlayer(fauna: FaunaInstance, player: Player, definition: FaunaTypes.FaunaSpeciesDefinition)
	local now = os.clock()
	if now - fauna.lastAttackAt < definition.attackCooldownSeconds then
		return
	end

	local faunaRoot = getFaunaRoot(fauna)
	local playerRoot = getCharacterRoot(player)
	if faunaRoot == nil or playerRoot == nil then
		return
	end

	if (faunaRoot.Position - playerRoot.Position).Magnitude > definition.meleeRangeStuds then
		return
	end

	fauna.lastAttackAt = now
	fauna.state = "attack"
	SurvivalService.applyDamage(player, definition.damage, rollStatusEffects(definition))
end

local function processFauna(fauna: FaunaInstance)
	local behavior = FaunaRegistry.get(fauna.speciesId)
	if behavior == nil then
		return
	end

	local definition = behavior.definition
	local nearestPlayer, nearestDistance = findNearestPlayer(fauna, definition.detectRangeStuds)

	if nearestPlayer == nil then
		fauna.state = "patrol"
		fauna.targetPlayer = nil
		ensurePatrolTarget(fauna)

		if fauna.patrolTarget ~= nil then
			moveFaunaToward(fauna, fauna.patrolTarget, definition.moveSpeedStuds * 0.6)
		end

		return
	end

	fauna.state = "alert"
	fauna.targetPlayer = nearestPlayer

	if definition.ambush and not fauna.revealed then
		fauna.revealed = true
		if behavior.onReveal ~= nil then
			behavior.onReveal(fauna.model)
		end
	end

	if not canSpeciesAggress(definition) then
		ensurePatrolTarget(fauna)
		if fauna.patrolTarget ~= nil then
			moveFaunaToward(fauna, fauna.patrolTarget, definition.moveSpeedStuds * 0.35)
		end
		return
	end

	if nearestDistance <= definition.meleeRangeStuds then
		tryAttackPlayer(fauna, nearestPlayer, definition)
		return
	end

	fauna.state = "chase"
	local playerRoot = getCharacterRoot(nearestPlayer)
	if playerRoot ~= nil then
		moveFaunaToward(fauna, playerRoot.Position, definition.moveSpeedStuds)
	end
end

local function processAiTick()
	for _, fauna in faunaInstances do
		processFauna(fauna)
	end
end

local function spawnFauna(speciesId: string, position: Vector3): FaunaInstance?
	local behavior = FaunaRegistry.get(speciesId)
	if behavior == nil then
		return nil
	end

	if countFaunaNearPosition(position) >= FaunaConstants.MAX_FAUNA_PER_PLAYER_RADIUS then
		return nil
	end

	faunaCounter += 1
	local faunaId = `{speciesId}_{faunaCounter}`
	local model = behavior.buildModel(position)
	model:SetAttribute(FaunaConstants.FAUNA_ID_ATTRIBUTE, faunaId)
	model:SetAttribute(FaunaConstants.FAUNA_SPECIES_ATTRIBUTE, speciesId)

	local worldFolder = workspace:FindFirstChild("World")
	local faunaFolder = worldFolder and worldFolder:FindFirstChild("Fauna")
	if faunaFolder ~= nil and faunaFolder:IsA("Folder") then
		model.Parent = faunaFolder
	else
		model.Parent = workspace
	end

	local humanoid = FaunaModelUtils.setupMotor(model, behavior.definition.moveSpeedStuds)
	if humanoid == nil then
		model:Destroy()
		Logger.warn("AnimalService", `Failed to setup motor for {faunaId}`)
		return nil
	end

	local instance: FaunaInstance = {
		faunaId = faunaId,
		speciesId = speciesId,
		model = model,
		humanoid = humanoid,
		hp = behavior.definition.maxHp,
		maxHp = behavior.definition.maxHp,
		state = "idle",
		targetPlayer = nil,
		lastAttackAt = 0,
		spawnPosition = position,
		patrolTarget = nil,
		revealed = not behavior.definition.ambush,
		lastAttacker = nil,
	}

	faunaInstances[faunaId] = instance
	broadcastSnapshot(instance)
	Logger.info("AnimalService", `Spawned {speciesId} at {position} (total fauna: {countFaunaInstances()})`)
	return instance
end

local function registerSpawnPoints()
	local spawnedCount = 0

	for _, spawnPart in CollectionService:GetTagged(FaunaConstants.FAUNA_SPAWN_TAG) do
		if not spawnPart:IsA("BasePart") then
			continue
		end

		local speciesId = spawnPart:GetAttribute(FaunaConstants.SPAWN_SPECIES_ATTRIBUTE)
		if type(speciesId) ~= "string" then
			continue
		end

		if spawnFauna(speciesId, spawnPart.Position) ~= nil then
			spawnedCount += 1
		end
	end

	Logger.info("AnimalService", `Registered {spawnedCount} fauna from {#CollectionService:GetTagged(FaunaConstants.FAUNA_SPAWN_TAG)} spawn markers`)
end

local function onAttackFauna(player: Player, faunaId: unknown)
	if type(faunaId) ~= "string" then
		return
	end

	local fauna = faunaInstances[faunaId]
	if fauna == nil or fauna.hp <= 0 then
		return
	end

	local now = os.clock()
	local lastAttack = playerAttackCooldowns[player.UserId]
	if lastAttack ~= nil and now - lastAttack < FaunaConstants.PLAYER_ATTACK_COOLDOWN_SECONDS then
		return
	end

	local playerRoot = getCharacterRoot(player)
	local faunaRoot = getFaunaRoot(fauna)
	if playerRoot == nil or faunaRoot == nil then
		return
	end

	if (playerRoot.Position - faunaRoot.Position).Magnitude > FaunaConstants.PLAYER_ATTACK_RANGE_STUDS then
		return
	end

	local playerData = PlayerDataService:GetData(player)
	if playerData == nil then
		return
	end

	local equippedTool = playerData.equipped.toolItemId

	if not ResourceNodesConstants.matchesAxeTool(equippedTool) then
		return
	end

	playerAttackCooldowns[player.UserId] = now
	fauna.hp -= FaunaConstants.PLAYER_ATTACK_DAMAGE
	fauna.lastAttacker = player
	broadcastSnapshot(fauna)

	if fauna.hp <= 0 then
		destroyFauna(faunaId, player)
	end
end

function AnimalService:Init()
	local trove = self:GetTrove()
	trove:Connect(Networking.getEvent("AttackFaunaEvent").OnServerEvent, onAttackFauna)
end

function AnimalService:Start()
	registerSpawnPoints()

	local trove = self:GetTrove()
	trove:Connect(Players.PlayerAdded, function(player: Player)
		task.defer(syncNearbyFaunaToPlayer, player)
	end)

	for _, player in Players:GetPlayers() do
		task.defer(syncNearbyFaunaToPlayer, player)
	end

	trove:Connect(RunService.Heartbeat, function(deltaTime: number)
		aiAccumulator += deltaTime

		if aiAccumulator < FaunaConstants.AI_TICK_SECONDS then
			return
		end

		aiAccumulator = 0
		processAiTick()
	end)
end

function AnimalService:Destroy()
	for faunaId in faunaInstances do
		local fauna = faunaInstances[faunaId]
		if fauna.model.Parent ~= nil then
			fauna.model:Destroy()
		end
	end

	table.clear(faunaInstances)
	BaseService.Destroy(self)
end

return AnimalService
