--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local BaseService = require(ServerScriptService.Kernel.BaseService)
local CampConstants = require(ReplicatedStorage.Shared.Constants.CampConstants)
local HelperBehaviorRegistry = require(ServerScriptService.Features.HelperBehaviorRegistry)
local HelperConstants = require(ReplicatedStorage.Shared.Constants.HelperConstants)
local Helpers = require(ReplicatedStorage.Shared.Constants.Helpers)
local Items = require(ReplicatedStorage.Shared.Constants.Items)
local GameEvents = require(ServerScriptService.Features.GameEvents)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local CampService = require(ServerScriptService.Services.CampService)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local PlayerSyncService = require(ServerScriptService.Services.PlayerSyncService)
local HelperTypes = require(ReplicatedStorage.Shared.Types.Helper)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)
local SurvivalTypes = require(ReplicatedStorage.Shared.Types.Survival)

local HelperService = BaseService.new("HelperService")

type HelperRuntime = {
	lastWorkAt: number,
	model: Model?,
	patrolIndex: number?,
}

type EscortRuntime = {
	model: Model,
	helperTypeId: string,
}

local helperRuntime: { [string]: HelperRuntime } = {}
local escorts: { [number]: EscortRuntime } = {}
local lastRemovedInstanceId: { [number]: string? } = {}
local tickThread: thread? = nil
local escortTickThread: thread? = nil

local PLOT_HELPER_OFFSETS = {
	Vector3.new(-6, 0, 4),
	Vector3.new(6, 0, 4),
}

local PLOT_PATROL_OFFSETS = {
	Vector3.new(-10, 0, 12),
	Vector3.new(10, 0, 12),
	Vector3.new(0, 0, 14),
}

local PLOT_STAND_Y_OFFSET = 3

local function hasStatusEffect(statusEffects: { SurvivalTypes.StatusEffect }, effectId: string): boolean
	for _, effect in statusEffects do
		if effect.id == effectId then
			return true
		end
	end

	return false
end

local function removeStatusEffectById(statusEffects: { SurvivalTypes.StatusEffect }, effectId: string): boolean
	for index, effect in statusEffects do
		if effect.id == effectId then
			table.remove(statusEffects, index)
			return true
		end
	end

	return false
end

local function countHelpers(data: PlayerProfileTypes.PlayerProfile): number
	local count = 0

	for _ in data.helpers do
		count += 1
	end

	return count
end

local function hasLostHelperType(data: PlayerProfileTypes.PlayerProfile, helperTypeId: string): boolean
	for _, lostType in data.lostHelpers do
		if lostType == helperTypeId then
			return true
		end
	end

	return false
end

local function isPositionInPlot(plotPart: BasePart, position: Vector3): boolean
	local half = CampConstants.PLOT_SIZE_STUDS / 2

	return math.abs(position.X - plotPart.Position.X) <= half
		and math.abs(position.Z - plotPart.Position.Z) <= half
end

local function getHelpersFolder(): Folder
	local worldFolder = Workspace:FindFirstChild("World")

	if worldFolder == nil or not worldFolder:IsA("Folder") then
		worldFolder = Instance.new("Folder")
		worldFolder.Name = "World"
		worldFolder.Parent = Workspace
	end

	local helpersFolder = worldFolder:FindFirstChild("Helpers")

	if helpersFolder == nil or not helpersFolder:IsA("Folder") then
		helpersFolder = Instance.new("Folder")
		helpersFolder.Name = "Helpers"
		helpersFolder.Parent = worldFolder
	end

	return helpersFolder
end

local function flatDistanceBetween(left: Vector3, right: Vector3): number
	return (Vector3.new(left.X, 0, left.Z) - Vector3.new(right.X, 0, right.Z)).Magnitude
end

local function helperHasWeakStatus(helperState: HelperTypes.HelperState): boolean
	for _, effect in helperState.statusEffects do
		if effect.id == "weak" then
			return true
		end
	end

	return false
end

local function canPlotHelperPatrol(helperState: HelperTypes.HelperState): boolean
	return helperState.mode == "work"
		and helperState.health > 0
		and helperState.hunger > 0
		and not helperHasWeakStatus(helperState)
end

local function findPlotHelperModel(instanceId: string): Model?
	for _, child in getHelpersFolder():GetChildren() do
		if child:IsA("Model") and child:GetAttribute(HelperConstants.HELPER_INSTANCE_ATTRIBUTE) == instanceId then
			return child
		end
	end

	return nil
end

local function setPlotHelperStationary(model: Model)
	local root = model.PrimaryPart
	local humanoid = model:FindFirstChildOfClass("Humanoid")

	if root ~= nil then
		root.Anchored = true
		root.CanCollide = false
	end

	if humanoid ~= nil then
		humanoid.PlatformStand = false
		humanoid.WalkSpeed = 0
		humanoid.AutoRotate = false
		humanoid.HipHeight = 2
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		humanoid.BreakJointsOnDeath = false
	end
end

local function setPlotHelperMobile(model: Model)
	local root = model.PrimaryPart
	local humanoid = model:FindFirstChildOfClass("Humanoid")

	if root ~= nil then
		root.Anchored = false
		root.CanCollide = true
	end

	if humanoid ~= nil then
		humanoid.PlatformStand = false
		humanoid.WalkSpeed = HelperConstants.PLOT_WALK_SPEED
		humanoid.AutoRotate = true
		humanoid.HipHeight = 2
		humanoid.RigType = Enum.HumanoidRigType.R6
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		humanoid.BreakJointsOnDeath = false
	end
end

local function applyPlotHelperModeToModel(model: Model, helperState: HelperTypes.HelperState)
	setPlotHelperStationary(model)

	if not canPlotHelperPatrol(helperState) then
		model:SetAttribute("HelperWorking", false)
		model:SetAttribute("HelperPatrolMoving", false)
	end
end

local function samplePlotGroundY(x: number, z: number, plotPart: BasePart): number
	local rayOrigin = Vector3.new(x, plotPart.Position.Y + 40, z)
	local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -120, 0))

	if rayResult ~= nil then
		return rayResult.Position.Y
	end

	return plotPart.Position.Y + plotPart.Size.Y / 2
end

local function getPlotStandPosition(x: number, z: number, plotPart: BasePart): Vector3
	local groundY = samplePlotGroundY(x, z, plotPart)

	return Vector3.new(x, groundY + PLOT_STAND_Y_OFFSET, z)
end

local function resolvePlotHelperGroundPosition(plotPart: BasePart, slotIndex: number): Vector3
	local offset = PLOT_HELPER_OFFSETS[slotIndex] or Vector3.new(0, 0, 4)
	local sampleX = plotPart.Position.X + offset.X
	local sampleZ = plotPart.Position.Z + offset.Z
	local groundY = samplePlotGroundY(sampleX, sampleZ, plotPart)

	return Vector3.new(sampleX, groundY, sampleZ)
end

local function resolvePlotPatrolPosition(plotPart: BasePart, patrolIndex: number): Vector3
	local offset = PLOT_PATROL_OFFSETS[patrolIndex] or PLOT_PATROL_OFFSETS[1]
	local sampleX = plotPart.Position.X + offset.X
	local sampleZ = plotPart.Position.Z + offset.Z

	return getPlotStandPosition(sampleX, sampleZ, plotPart)
end

local function snapPlotHelperToPosition(model: Model, position: Vector3)
	model:PivotTo(CFrame.new(position))
end

local function movePlotHelperToward(humanoid: Humanoid, root: BasePart, targetPosition: Vector3)
	local flatTarget = Vector3.new(targetPosition.X, root.Position.Y, targetPosition.Z)
	humanoid.WalkSpeed = HelperConstants.PLOT_WALK_SPEED
	humanoid:MoveTo(flatTarget)
end

local function finalizePlotHelperModel(
	model: Model,
	groundPosition: Vector3,
	helperState: HelperTypes.HelperState
)
	local root = model.PrimaryPart

	if root == nil then
		return
	end

	model:PivotTo(CFrame.new(groundPosition + Vector3.new(0, PLOT_STAND_Y_OFFSET, 0)))
	model:SetAttribute("PlotHelper", true)
	model:SetAttribute("UseR6WalkAnimation", true)

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant ~= root then
			descendant.Anchored = false
			descendant.CanCollide = false
		end
	end

	root.CanCollide = false
	applyPlotHelperModeToModel(model, helperState)
end

local function despawnPlotModel(instanceId: string)
	local runtime = helperRuntime[instanceId]

	if runtime ~= nil and runtime.model ~= nil then
		runtime.model:Destroy()
		runtime.model = nil
	end
end

local function spawnPlotModel(
	player: Player,
	data: PlayerProfileTypes.PlayerProfile,
	instanceId: string,
	helperState: HelperTypes.HelperState
)
	if data.camp.plotId == nil then
		return
	end

	local plotPart = CampService.getPlotPart(data.camp.plotId)

	if plotPart == nil then
		return
	end

	local behavior = HelperBehaviorRegistry.get(helperState.helperTypeId)

	if behavior == nil then
		return
	end

	local slotIndex = 1

	for otherId in data.helpers do
		if otherId == instanceId then
			break
		end

		slotIndex += 1
	end

	local runtime = helperRuntime[instanceId]

	if runtime == nil then
		runtime = { lastWorkAt = 0, model = nil, patrolIndex = 1 }
		helperRuntime[instanceId] = runtime
	end

	despawnPlotModel(instanceId)

	local groundPosition = resolvePlotHelperGroundPosition(plotPart, slotIndex)
	local model = behavior.buildModel(groundPosition, { escort = false })
	finalizePlotHelperModel(model, groundPosition, helperState)
	model:SetAttribute(HelperConstants.HELPER_INSTANCE_ATTRIBUTE, instanceId)
	model:SetAttribute(HelperConstants.HELPER_TYPE_ATTRIBUTE, helperState.helperTypeId)
	model:SetAttribute("OwnerUserId", player.UserId)
	model.Parent = getHelpersFolder()
	runtime.model = model

	Logger.info("HelperService", `Spawned plot helper {instanceId} for {player.Name} at {groundPosition}`)
end

local function respawnAllPlotHelpers(player: Player): boolean
	local data = PlayerDataService:GetData(player)

	if data == nil or type(data.helpers) ~= "table" then
		return false
	end

	if data.camp.plotId == nil then
		return false
	end

	if CampService.getPlotPart(data.camp.plotId) == nil then
		return false
	end

	for instanceId, helperState in data.helpers do
		spawnPlotModel(player, data, instanceId, helperState)
	end

	return true
end

local function syncHelpers(player: Player, data: PlayerProfileTypes.PlayerProfile)
	local sessionRemoved = lastRemovedInstanceId[player.UserId]
	lastRemovedInstanceId[player.UserId] = nil

	PlayerSyncService.syncHelpersToClient(player, data, sessionRemoved)
	PlayerDataService:SaveProfile(player)
end

local function removeHelper(player: Player, data: PlayerProfileTypes.PlayerProfile, instanceId: string)
	local helperState = data.helpers[instanceId]

	if helperState == nil then
		return
	end

	despawnPlotModel(instanceId)
	helperRuntime[instanceId] = nil

	local alreadyLost = hasLostHelperType(data, helperState.helperTypeId)

	if not alreadyLost then
		table.insert(data.lostHelpers, helperState.helperTypeId)
	end

	data.helpers[instanceId] = nil
	lastRemovedInstanceId[player.UserId] = instanceId
	syncHelpers(player, data)
end

function HelperService.recruit(player: Player, helperTypeId: string): string?
	local data = PlayerDataService:GetData(player)
	local typeDefinition = Helpers.getType(helperTypeId)
	local behavior = HelperBehaviorRegistry.get(helperTypeId)

	if data == nil or typeDefinition == nil or behavior == nil then
		return nil
	end

	if hasLostHelperType(data, helperTypeId) then
		return nil
	end

	if countHelpers(data) >= HelperConstants.MAX_HELPERS_SOLO then
		return nil
	end

	for _, helperState in data.helpers do
		if helperState.helperTypeId == helperTypeId then
			return nil
		end
	end

	local instanceId = `{helperTypeId}_{os.time()}_{player.UserId}`
	local helperState: HelperTypes.HelperState = {
		helperTypeId = helperTypeId,
		nameKey = typeDefinition.nameKey,
		hunger = 80,
		health = 100,
		statusEffects = {},
		mode = "work",
		recruitedAt = os.time(),
		weakSince = nil,
	}

	data.helpers[instanceId] = helperState
	helperRuntime[instanceId] = { lastWorkAt = os.time(), model = nil, patrolIndex = 1 }
	spawnPlotModel(player, data, instanceId, helperState)
	syncHelpers(player, data)

	Logger.info("HelperService", `Recruited {helperTypeId} for {player.Name}`)
	return instanceId
end

local function applyWeakState(helperState: HelperTypes.HelperState)
	if helperState.hunger <= 0 then
		if not hasStatusEffect(helperState.statusEffects, "weak") then
			table.insert(helperState.statusEffects, {
				id = "weak",
				appliedAt = os.time(),
			})
		end

		if helperState.weakSince == nil then
			helperState.weakSince = os.time()
		end
	else
		removeStatusEffectById(helperState.statusEffects, "weak")
		helperState.weakSince = nil
	end
end

local function processHelperNeeds(
	player: Player,
	data: PlayerProfileTypes.PlayerProfile,
	instanceId: string,
	helperState: HelperTypes.HelperState
)
	local tickMinutes = HelperConstants.TICK_INTERVAL_SECONDS / 60
	local hungerDrain = if helperState.mode == "work"
		then HelperConstants.WORK_HUNGER_DRAIN_PER_MINUTE
		else HelperConstants.SHELTER_HUNGER_DRAIN_PER_MINUTE

	helperState.hunger = math.clamp(helperState.hunger - hungerDrain * tickMinutes, 0, 100)
	applyWeakState(helperState)

	local statusDamage = 0

	if hasStatusEffect(helperState.statusEffects, "bleeding") then
		statusDamage += HelperConstants.BLEEDING_DAMAGE_PER_MINUTE * tickMinutes
	end

	if hasStatusEffect(helperState.statusEffects, "poison") then
		statusDamage += HelperConstants.POISON_DAMAGE_PER_MINUTE * tickMinutes
	end

	if statusDamage > 0 then
		helperState.health = math.clamp(helperState.health - statusDamage, 0, 100)
	end

	if helperState.health <= 0 then
		removeHelper(player, data, instanceId)
		return
	end

	if helperState.weakSince ~= nil and os.time() - helperState.weakSince >= HelperConstants.WEAK_DEATH_SECONDS then
		removeHelper(player, data, instanceId)
	end
end

local function processWorkTick(player: Player, data: PlayerProfileTypes.PlayerProfile, instanceId: string, helperState: HelperTypes.HelperState)
	local behavior = HelperBehaviorRegistry.get(helperState.helperTypeId)

	if behavior == nil then
		return
	end

	local runtime = helperRuntime[instanceId]

	if runtime == nil then
		runtime = { lastWorkAt = os.time(), model = nil, patrolIndex = 1 }
		helperRuntime[instanceId] = runtime
	end

	local now = os.time()

	if now - runtime.lastWorkAt < behavior.definition.workIntervalSeconds then
		return
	end

	local context: HelperTypes.HelperWorkContext = {
		player = player,
		data = data,
		helperInstanceId = instanceId,
		helperState = helperState,
	}

	if not behavior.canWork(context) then
		return
	end

	if behavior.onWorkTick(context) then
		runtime.lastWorkAt = now

		if runtime.model == nil then
			runtime.model = findPlotHelperModel(instanceId)
		end

		if runtime.model ~= nil then
			runtime.model:SetAttribute("HelperWorkPulseAt", workspace:GetServerTimeNow())
			runtime.model:SetAttribute("HelperWorking", true)
		end

		PlayerSyncService.syncInventoryToClient(player, data)
	end
end

local function processPlotHelperLocomotion(
	player: Player,
	data: PlayerProfileTypes.PlayerProfile,
	instanceId: string,
	helperState: HelperTypes.HelperState
)
	local runtime = helperRuntime[instanceId]

	if runtime == nil then
		runtime = { lastWorkAt = os.time(), model = nil, patrolIndex = 1 }
		helperRuntime[instanceId] = runtime
	end

	if runtime.model == nil then
		runtime.model = findPlotHelperModel(instanceId)
	end

	local model = runtime.model

	if model == nil or data.camp.plotId == nil then
		return
	end

	local plotPart = CampService.getPlotPart(data.camp.plotId)

	if plotPart == nil then
		return
	end

	local root = model.PrimaryPart
	local humanoid = model:FindFirstChildOfClass("Humanoid")

	if root == nil or humanoid == nil then
		return
	end

	if not canPlotHelperPatrol(helperState) then
		applyPlotHelperModeToModel(model, helperState)
		return
	end

	setPlotHelperMobile(model)

	if root.Position.Y < plotPart.Position.Y - 8 or not isPositionInPlot(plotPart, root.Position) then
		if runtime.patrolIndex == nil then
			runtime.patrolIndex = 1
		end

		setPlotHelperStationary(model)
		snapPlotHelperToPosition(model, resolvePlotPatrolPosition(plotPart, runtime.patrolIndex :: number))
		setPlotHelperMobile(model)
		model:SetAttribute("HelperPatrolMoving", false)
		return
	end

	if runtime.patrolIndex == nil then
		runtime.patrolIndex = 1
	end

	local patrolIndex = runtime.patrolIndex :: number
	local targetPosition = resolvePlotPatrolPosition(plotPart, patrolIndex)
	local distance = flatDistanceBetween(root.Position, targetPosition)

	if distance <= HelperConstants.PLOT_PATROL_ARRIVE_STUDS then
		runtime.patrolIndex = patrolIndex % #PLOT_PATROL_OFFSETS + 1
		model:SetAttribute("HelperWorking", true)
		model:SetAttribute("HelperPatrolMoving", false)
		humanoid:MoveTo(root.Position)
		return
	end

	model:SetAttribute("HelperWorking", false)
	model:SetAttribute("HelperPatrolMoving", true)
	movePlotHelperToward(humanoid, root, targetPosition)
end

local function processHelperTicks()
	for _, player in Players:GetPlayers() do
		local data = PlayerDataService:GetData(player)

		if data == nil then
			continue
		end

		local changed = false

		for instanceId, helperState in data.helpers do
			local beforeHealth = helperState.health
			local beforeHunger = helperState.hunger
			processHelperNeeds(player, data, instanceId, helperState)

			if data.helpers[instanceId] == nil then
				changed = true
				continue
			end

			processWorkTick(player, data, instanceId, helperState)

			if helperState.health ~= beforeHealth or helperState.hunger ~= beforeHunger then
				changed = true
			end
		end

		if changed then
			syncHelpers(player, data)
		end
	end
end

local function findEscortSpawnPosition(player: Player, helperTypeId: string): Vector3?
	local character = player.Character
	local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
	local playerPosition = if root ~= nil and root:IsA("BasePart") then root.Position else Vector3.zero

	local bestPosition: Vector3? = nil
	local bestDistance = math.huge

	for _, spawnPart in CollectionService:GetTagged(HelperConstants.HELPER_SPAWN_TAG) do
		if not spawnPart:IsA("BasePart") then
			continue
		end

		local spawnTypeId = spawnPart:GetAttribute(HelperConstants.HELPER_TYPE_ATTRIBUTE)

		if spawnTypeId ~= helperTypeId then
			continue
		end

		local distance = (spawnPart.Position - playerPosition).Magnitude

		if distance < bestDistance then
			bestDistance = distance
			bestPosition = spawnPart.Position
		end
	end

	return bestPosition
end

local function resolveEscortGroundPosition(player: Player, helperTypeId: string): Vector3
	local character = player.Character
	local playerRoot = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
	local samplePosition: Vector3

	if playerRoot ~= nil and playerRoot:IsA("BasePart") then
		samplePosition = playerRoot.Position + playerRoot.CFrame.LookVector * 8
	else
		samplePosition = findEscortSpawnPosition(player, helperTypeId) or Vector3.new(295, 0, 38)
	end

	local rayOrigin = Vector3.new(samplePosition.X, samplePosition.Y + 40, samplePosition.Z)
	local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -120, 0))

	if rayResult ~= nil then
		return rayResult.Position
	end

	return Vector3.new(samplePosition.X, 0, samplePosition.Z)
end

local function despawnEscort(player: Player)
	local escort = escorts[player.UserId]

	if escort ~= nil then
		escort.model:Destroy()
		escorts[player.UserId] = nil
	end
end

local function spawnEscort(player: Player, helperTypeId: string)
	if escorts[player.UserId] ~= nil then
		return
	end

	local behavior = HelperBehaviorRegistry.get(helperTypeId)

	if behavior == nil then
		return
	end

	local spawnPosition = resolveEscortGroundPosition(player, helperTypeId)
	local model = behavior.buildModel(spawnPosition, { escort = true })
	model:SetAttribute(HelperConstants.HELPER_TYPE_ATTRIBUTE, helperTypeId)
	model.Parent = getHelpersFolder()

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model.PrimaryPart

	if humanoid == nil or root == nil then
		model:Destroy()
		Logger.warn("HelperService", `Escort model missing humanoid for {helperTypeId}`)
		return
	end

	root.Anchored = false
	root.CanCollide = true

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant ~= root then
			descendant.Anchored = false
			descendant.CanCollide = false
		end
	end

	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.WalkSpeed = HelperConstants.ESCORT_WALK_SPEED
	humanoid.HipHeight = 2
	humanoid.AutoRotate = true
	humanoid.BreakJointsOnDeath = false

	escorts[player.UserId] = {
		model = model,
		helperTypeId = helperTypeId,
	}

	Logger.info("HelperService", `Spawned escort for {player.Name} at {spawnPosition}`)
end

local function moveEscortToward(escortModel: Model, humanoid: Humanoid, escortRoot: BasePart, targetPosition: Vector3)
	local flatTarget = Vector3.new(targetPosition.X, escortRoot.Position.Y, targetPosition.Z)
	humanoid.WalkSpeed = HelperConstants.ESCORT_WALK_SPEED
	humanoid:MoveTo(flatTarget)
end

local function processEscortFollow(player: Player)
	local escort = escorts[player.UserId]

	if escort == nil then
		return
	end

	local character = player.Character
	local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
	local escortRoot = escort.model.PrimaryPart
	local humanoid = escort.model:FindFirstChildOfClass("Humanoid")

	if root == nil or not root:IsA("BasePart") or escortRoot == nil or humanoid == nil then
		return
	end

	local distance = flatDistanceBetween(escortRoot.Position, root.Position)

	if distance > HelperConstants.ESCORT_TELEPORT_RANGE_STUDS then
		escort.model:PivotTo(CFrame.new(root.Position + root.CFrame.LookVector * -4 + Vector3.new(0, 3, 0)))
		return
	end

	if distance <= HelperConstants.ESCORT_STOP_DISTANCE_STUDS then
		return
	end

	moveEscortToward(escort.model, humanoid, escortRoot, root.Position)
end

local function checkEscortCompletion(player: Player)
	local escort = escorts[player.UserId]

	if escort == nil then
		return
	end

	local data = PlayerDataService:GetData(player)

	if data == nil or data.camp.plotId == nil then
		return
	end

	local plotPart = CampService.getPlotPart(data.camp.plotId)
	local character = player.Character
	local playerRoot = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
	local escortRoot = escort.model.PrimaryPart

	if plotPart == nil or playerRoot == nil or not playerRoot:IsA("BasePart") or escortRoot == nil then
		return
	end

	if not isPositionInPlot(plotPart, playerRoot.Position) or not isPositionInPlot(plotPart, escortRoot.Position) then
		return
	end

	despawnEscort(player)
	GameEvents.fireEscortToPlot(player, escort.helperTypeId)
end

local function ensureEscortForActiveQuest(player: Player)
	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	local escortQuest = data.quests.main_05_lumberjack

	if escortQuest == nil or escortQuest.status ~= "active" then
		despawnEscort(player)
		return
	end

	for _, objective in escortQuest.objectives do
		if objective.kind == "escort_to_plot" and objective.current >= objective.target then
			despawnEscort(player)
			return
		end
	end

	if escorts[player.UserId] ~= nil then
		return
	end

	spawnEscort(player, "lumberjack")
end

local function processEscortTicks()
	for _, player in Players:GetPlayers() do
		ensureEscortForActiveQuest(player)
		processEscortFollow(player)
		checkEscortCompletion(player)

		local data = PlayerDataService:GetData(player)

		if data == nil then
			continue
		end

		for instanceId, helperState in data.helpers do
			processPlotHelperLocomotion(player, data, instanceId, helperState)
		end
	end
end

local function getFeedHungerAmount(itemId: string): number?
	local definition = Items.get(itemId)

	if definition == nil or definition.category ~= "food" then
		return nil
	end

	if string.sub(itemId, 1, 7) == "cooked_" then
		return HelperConstants.FEED_COOKED_HUNGER
	end

	return HelperConstants.FEED_BASIC_HUNGER
end

local function onFeedHelper(player: Player, payload: unknown)
	if type(payload) ~= "table" then
		return
	end

	local helperInstanceId = payload.helperInstanceId
	local bagSlotKey = payload.bagSlotKey

	if type(helperInstanceId) ~= "string" or type(bagSlotKey) ~= "string" then
		return
	end

	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	local helperState = data.helpers[helperInstanceId]
	local slotItem = data.inventory[bagSlotKey]

	if helperState == nil or slotItem == nil or slotItem.quantity < 1 then
		return
	end

	local hungerGain = getFeedHungerAmount(slotItem.itemId)

	if hungerGain == nil then
		return
	end

	slotItem.quantity -= 1

	if slotItem.quantity <= 0 then
		data.inventory[bagSlotKey] = nil
	end

	helperState.hunger = math.clamp(helperState.hunger + hungerGain, 0, 100)
	applyWeakState(helperState)
	syncHelpers(player, data)
	PlayerSyncService.syncInventoryToClient(player, data)
end

local function onCureHelper(player: Player, payload: unknown)
	if type(payload) ~= "table" then
		return
	end

	local helperInstanceId = payload.helperInstanceId
	local bagSlotKey = payload.bagSlotKey

	if type(helperInstanceId) ~= "string" or type(bagSlotKey) ~= "string" then
		return
	end

	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	local helperState = data.helpers[helperInstanceId]
	local slotItem = data.inventory[bagSlotKey]

	if helperState == nil or slotItem == nil or slotItem.quantity < 1 then
		return
	end

	local cured = false

	if slotItem.itemId == "bandage" and hasStatusEffect(helperState.statusEffects, "bleeding") then
		removeStatusEffectById(helperState.statusEffects, "bleeding")
		helperState.health = math.clamp(helperState.health + 10, 0, 100)
		cured = true
	elseif slotItem.itemId == "antidote" then
		if hasStatusEffect(helperState.statusEffects, "poison") then
			removeStatusEffectById(helperState.statusEffects, "poison")
		end

		helperState.health = math.clamp(helperState.health + 15, 0, 100)
		cured = true
	end

	if not cured then
		return
	end

	slotItem.quantity -= 1

	if slotItem.quantity <= 0 then
		data.inventory[bagSlotKey] = nil
	end

	syncHelpers(player, data)
	PlayerSyncService.syncInventoryToClient(player, data)
end

local function onSetHelperMode(player: Player, payload: unknown)
	if type(payload) ~= "table" then
		return
	end

	local helperInstanceId = payload.helperInstanceId
	local mode = payload.mode

	if type(helperInstanceId) ~= "string" or (mode ~= "work" and mode ~= "shelter") then
		return
	end

	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	local helperState = data.helpers[helperInstanceId]

	if helperState == nil then
		return
	end

	helperState.mode = mode

	local runtime = helperRuntime[helperInstanceId]

	if runtime == nil then
		runtime = { lastWorkAt = os.time(), model = nil, patrolIndex = 1 }
		helperRuntime[helperInstanceId] = runtime
	end

	if runtime.model == nil then
		runtime.model = findPlotHelperModel(helperInstanceId)
	end

	if runtime.model ~= nil then
		applyPlotHelperModeToModel(runtime.model, helperState)
	end

	syncHelpers(player, data)
end

local function onQuestStarted(player: Player, questId: string)
	if questId == "main_05_lumberjack" then
		ensureEscortForActiveQuest(player)
	end
end

local function onBiomeEntered(player: Player, biomeId: string)
	if biomeId == "forest_deep" then
		ensureEscortForActiveQuest(player)
	end
end

local function reconcileRecruitedHelper(player: Player, data: PlayerProfileTypes.PlayerProfile)
	local lumberjackQuest = data.quests.main_05_lumberjack

	if lumberjackQuest == nil or lumberjackQuest.status ~= "completed" then
		return
	end

	if hasLostHelperType(data, "lumberjack") then
		return
	end

	for _, helperState in data.helpers do
		if helperState.helperTypeId == "lumberjack" then
			return
		end
	end

	HelperService.recruit(player, "lumberjack")
end

local function onCampPlotAssigned(player: Player, _plotId: string)
	respawnAllPlotHelpers(player)
end

local function onClientReady(player: Player)
	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	if type(data.helpers) ~= "table" then
		data.helpers = {}
	end

	if type(data.lostHelpers) ~= "table" then
		data.lostHelpers = {}
	end

	respawnAllPlotHelpers(player)
	reconcileRecruitedHelper(player, data)
	ensureEscortForActiveQuest(player)
	syncHelpers(player, data)
end

local function onPlayerReady(player: Player)
	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	if type(data.helpers) ~= "table" then
		data.helpers = {}
	end

	if type(data.lostHelpers) ~= "table" then
		data.lostHelpers = {}
	end

	task.spawn(function()
		for _ = 1, 40 do
			local profile = PlayerDataService:GetData(player)

			if profile ~= nil and respawnAllPlotHelpers(player) then
				break
			end

			if profile ~= nil and profile.camp.plotId ~= nil and CampService.getPlotPart(profile.camp.plotId) ~= nil then
				respawnAllPlotHelpers(player)
				break
			end

			task.wait(0.25)
		end

		local readyData = PlayerDataService:GetData(player)

		if readyData == nil then
			return
		end

		reconcileRecruitedHelper(player, readyData)
		ensureEscortForActiveQuest(player)
		syncHelpers(player, readyData)
	end)
end

function HelperService:Init()
	local trove = self:GetTrove()

	trove:Connect(Networking.getEvent("FeedHelperEvent").OnServerEvent, onFeedHelper)
	trove:Connect(Networking.getEvent("CureHelperEvent").OnServerEvent, onCureHelper)
	trove:Connect(Networking.getEvent("SetHelperModeEvent").OnServerEvent, onSetHelperMode)
	trove:Connect(GameEvents.QuestStarted.Event, onQuestStarted)
	trove:Connect(GameEvents.BiomeEntered.Event, onBiomeEntered)
	trove:Connect(GameEvents.CampPlotAssigned.Event, onCampPlotAssigned)
	trove:Connect(Networking.getEvent("ClientReadyEvent").OnServerEvent, onClientReady)
end

function HelperService:Start()
	local trove = self:GetTrove()

	trove:Connect(Players.PlayerRemoving, function(player: Player)
		despawnEscort(player)
		lastRemovedInstanceId[player.UserId] = nil

		for instanceId in helperRuntime do
			if string.find(instanceId, `_{player.UserId}`, 1, true) ~= nil then
				despawnPlotModel(instanceId)
				helperRuntime[instanceId] = nil
			end
		end
	end)

	trove:Connect(Players.PlayerAdded, function(player: Player)
		task.spawn(function()
			for _ = 1, 30 do
				if PlayerDataService:GetData(player) ~= nil then
					onPlayerReady(player)
					return
				end

				task.wait(0.25)
			end
		end)
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerReady, player)
	end

	local function scheduleHelperTick()
		processHelperTicks()
		tickThread = task.delay(HelperConstants.TICK_INTERVAL_SECONDS, scheduleHelperTick)
	end

	local function scheduleEscortTick()
		processEscortTicks()
		escortTickThread = task.delay(HelperConstants.ESCORT_TICK_SECONDS, scheduleEscortTick)
	end

	scheduleHelperTick()
	scheduleEscortTick()
	Logger.info("HelperService", "Helper care and escort loops are active")
end

function HelperService:Destroy()
	if tickThread ~= nil then
		task.cancel(tickThread)
		tickThread = nil
	end

	if escortTickThread ~= nil then
		task.cancel(escortTickThread)
		escortTickThread = nil
	end

	BaseService.Destroy(self)
end

return HelperService
