--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseService = require(ServerScriptService.Kernel.BaseService)
local CampService = require(ServerScriptService.Services.CampService)
local GameEvents = require(ServerScriptService.Features.GameEvents)
local InventoryService = require(ServerScriptService.Services.InventoryService)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local QuestConstants = require(ReplicatedStorage.Shared.Constants.QuestConstants)
local Quests = require(ReplicatedStorage.Shared.Constants.Quests)
local CampProximity = require(ReplicatedStorage.Shared.Utilities.CampProximity)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local PlayerSyncService = require(ServerScriptService.Services.PlayerSyncService)
local QuestTypes = require(ReplicatedStorage.Shared.Types.Quest)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)

local QuestService = BaseService.new("QuestService")

type PlayerQuestSession = {
	trackedQuestId: string?,
	lastCompletedQuestId: string?,
	coldDipApplied: boolean,
}

local playerSessions: { [number]: PlayerQuestSession } = {}
local coldTickThread: thread? = nil

local function getSession(player: Player): PlayerQuestSession
	local session = playerSessions[player.UserId]

	if session == nil then
		session = {
			trackedQuestId = nil,
			lastCompletedQuestId = nil,
			coldDipApplied = false,
		}
		playerSessions[player.UserId] = session
	end

	return session
end

local function isQuestRecordCompleted(data: PlayerProfileTypes.PlayerProfile, questId: string): boolean
	local state = data.quests[questId]

	return state ~= nil and state.status == "completed"
end

local function countActiveQuests(data: PlayerProfileTypes.PlayerProfile, questType: string): number
	local count = 0

	for questId, state in data.quests do
		if state.status == "active" then
			local definition = Quests.get(questId)

			if definition ~= nil and definition.questType == questType then
				count += 1
			end
		end
	end

	return count
end

local function buildObjectiveProgress(definition: Quests.QuestDefinition): { QuestTypes.QuestObjectiveProgress }
	local objectives: { QuestTypes.QuestObjectiveProgress } = {}

	for _, objective in definition.objectives do
		table.insert(objectives, {
			kind = objective.kind,
			current = 0,
			target = objective.target,
			itemId = objective.itemId,
			recipeId = objective.recipeId,
			outputItemId = objective.outputItemId,
			blueprintId = objective.blueprintId,
			speciesId = objective.speciesId,
			panelId = objective.panelId,
			helperTypeId = objective.helperTypeId,
		})
	end

	return objectives
end

local function allObjectivesComplete(state: QuestTypes.QuestState): boolean
	for _, objective in state.objectives do
		if objective.current < objective.target then
			return false
		end
	end

	return true
end

local function markMissionCompleted(data: PlayerProfileTypes.PlayerProfile, questId: string)
	for _, completedId in data.stats.missionsCompleted do
		if completedId == questId then
			return
		end
	end

	table.insert(data.stats.missionsCompleted, questId)
end

local function applyRetroactiveObjective(
	data: PlayerProfileTypes.PlayerProfile,
	objective: QuestTypes.QuestObjectiveProgress
)
	if objective.kind == "gather" and objective.itemId ~= nil then
		objective.current = math.min(objective.target, InventoryService.countItem(data, objective.itemId))
	elseif objective.kind == "place_structure" and objective.blueprintId ~= nil then
		local placed = 0

		if type(data.camp.structures) == "table" then
			for _, structure in data.camp.structures do
				if structure.blueprintId == objective.blueprintId then
					if structure.hp == nil or structure.hp > 0 then
						placed += 1
					end
				end
			end
		end

		objective.current = math.min(objective.target, placed)
	elseif objective.kind == "open_ui" then
		objective.current = objective.target
	end
end

local function applyRetroactiveProgress(data: PlayerProfileTypes.PlayerProfile, state: QuestTypes.QuestState)
	for _, objective in state.objectives do
		applyRetroactiveObjective(data, objective)
	end
end

local function getDefaultTrackedQuestId(data: PlayerProfileTypes.PlayerProfile): string?
	for questId, state in data.quests do
		if state.status == "active" then
			local definition = Quests.get(questId)

			if definition ~= nil and definition.questType == "main" then
				return questId
			end
		end
	end

	for questId, state in data.quests do
		if state.status == "active" then
			return questId
		end
	end

	return nil
end

local function getActiveQuestIds(data: PlayerProfileTypes.PlayerProfile): { string }
	local activeIds: { string } = {}

	for questId, state in data.quests do
		if state.status == "active" then
			table.insert(activeIds, questId)
		end
	end

	table.sort(activeIds)
	return activeIds
end

local function syncQuest(player: Player, data: PlayerProfileTypes.PlayerProfile, completedQuestId: string?)
	local session = getSession(player)
	session.lastCompletedQuestId = completedQuestId
	PlayerSyncService.syncQuestToClient(player, data, session.trackedQuestId, completedQuestId)
	PlayerDataService:SaveProfile(player)
end

local function applyLevelFromXp(data: PlayerProfileTypes.PlayerProfile)
	local thresholds = QuestConstants.LEVEL_XP_THRESHOLDS
	local level = 1

	for index = #thresholds, 1, -1 do
		if data.stats.xp >= thresholds[index] then
			level = index
			break
		end
	end

	data.stats.level = math.min(level, #thresholds)
end

local function grantRewards(player: Player, data: PlayerProfileTypes.PlayerProfile, definition: Quests.QuestDefinition)
	local rewards = definition.rewards

	if rewards.xp ~= nil and rewards.xp > 0 then
		data.stats.xp += rewards.xp
		applyLevelFromXp(data)
	end

	if rewards.currency ~= nil and rewards.currency > 0 then
		data.currency += rewards.currency
	end

	if rewards.items ~= nil then
		for _, item in rewards.items do
			InventoryService.grantItem(player, item.itemId, item.quantity)
		end
	end

	if rewards.grantBlueprint ~= nil then
		InventoryService.grantItem(player, rewards.grantBlueprint, 1)
	end
end

local function tryAutoStartNext(player: Player, data: PlayerProfileTypes.PlayerProfile, definition: Quests.QuestDefinition)
	if definition.nextQuestId == nil then
		return
	end

	QuestService.startQuest(player, definition.nextQuestId)
end

local function completeQuest(player: Player, data: PlayerProfileTypes.PlayerProfile, questId: string)
	local state = data.quests[questId]
	local definition = Quests.get(questId)

	if state == nil or definition == nil or state.status ~= "active" then
		return
	end

	if not allObjectivesComplete(state) then
		return
	end

	state.status = "completed"
	state.completedAt = os.time()
	markMissionCompleted(data, questId)
	grantRewards(player, data, definition)

	if questId == "main_05_lumberjack" then
		local HelperService = require(ServerScriptService.Services.HelperService)
		HelperService.recruit(player, "lumberjack")
	end

	if definition.setsTutorialCompleted == true then
		data.tutorialCompleted = true
	end

	syncQuest(player, data, questId)
	tryAutoStartNext(player, data, definition)

	if data.tutorialCompleted and data.stats.level >= 2 then
		if QuestService.canStartQuest(data, "side_01_berries") then
			QuestService.startQuest(player, "side_01_berries")
		end

		if QuestService.canStartQuest(data, "side_02_wolf") then
			QuestService.startQuest(player, "side_02_wolf")
		end
	end
end

local function checkQuestCompletion(player: Player, data: PlayerProfileTypes.PlayerProfile, questId: string)
	local state = data.quests[questId]

	if state == nil or state.status ~= "active" then
		return
	end

	if allObjectivesComplete(state) then
		completeQuest(player, data, questId)
	else
		syncQuest(player, data, nil)
	end
end

local function incrementMatchingObjectives(
	player: Player,
	data: PlayerProfileTypes.PlayerProfile,
	matcher: (objective: QuestTypes.QuestObjectiveProgress) -> boolean,
	amount: number
)
	for questId, state in data.quests do
		if state.status ~= "active" then
			continue
		end

		local questChanged = false

		for _, objective in state.objectives do
			if objective.current < objective.target and matcher(objective) then
				objective.current = math.min(objective.target, objective.current + amount)
				questChanged = true
			end
		end

		if questChanged then
			checkQuestCompletion(player, data, questId)
		end
	end
end

function QuestService.canStartQuest(data: PlayerProfileTypes.PlayerProfile, questId: string): boolean
	local definition = Quests.get(questId)

	if definition == nil or isQuestRecordCompleted(data, questId) then
		return false
	end

	if data.quests[questId] ~= nil and data.quests[questId].status == "active" then
		return false
	end

	if definition.requiresTutorialCompleted == true and not data.tutorialCompleted then
		return false
	end

	if definition.minLevel ~= nil and data.stats.level < definition.minLevel then
		return false
	end

	if definition.prerequisites ~= nil then
		for _, prerequisiteId in definition.prerequisites do
			if not isQuestRecordCompleted(data, prerequisiteId) then
				return false
			end
		end
	end

	if definition.questType == "main" and countActiveQuests(data, "main") >= QuestConstants.MAX_ACTIVE_MAIN then
		return false
	end

	if definition.questType == "side" and countActiveQuests(data, "side") >= QuestConstants.MAX_ACTIVE_SIDE then
		return false
	end

	return true
end

function QuestService.startQuest(player: Player, questId: string): boolean
	local data = PlayerDataService:GetData(player)
	local definition = Quests.get(questId)

	if data == nil or definition == nil then
		return false
	end

	if not QuestService.canStartQuest(data, questId) then
		return false
	end

	local state: QuestTypes.QuestState = {
		status = "active",
		objectives = buildObjectiveProgress(definition),
		startedAt = os.time(),
		completedAt = nil,
	}

	applyRetroactiveProgress(data, state)
	data.quests[questId] = state

	if questId == "t06_cold" then
		getSession(player).coldDipApplied = false
	end

	if questId == "t01_spawn" and allObjectivesComplete(state) then
		completeQuest(player, data, questId)
		return true
	end

	checkQuestCompletion(player, data, questId)

	if data.quests[questId] ~= nil and data.quests[questId].status == "active" then
		syncQuest(player, data, nil)
		GameEvents.fireQuestStarted(player, questId)
	end

	return true
end

function QuestService.isTutorialActive(player: Player): boolean
	local data = PlayerDataService:GetData(player)

	if data == nil then
		return false
	end

	return not data.tutorialCompleted
end

function QuestService.isPlayerInTutorialSafeZone(player: Player): boolean
	if not QuestService.isTutorialActive(player) then
		return false
	end

	local data = PlayerDataService:GetData(player)

	if data == nil then
		return true
	end

	if data.camp.plotId == nil then
		return true
	end

	local plotPart = CampService.getPlotPart(data.camp.plotId)
	local character = player.Character
	local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil

	if plotPart == nil or root == nil or not root:IsA("BasePart") then
		return true
	end

	return (root.Position - plotPart.Position).Magnitude <= QuestConstants.TUTORIAL_SAFE_RADIUS_STUDS
end

local MAIN_QUEST_CHAIN = {
	"m00_wood",
	"main_01_chest",
	"main_05_lumberjack",
}

local TUTORIAL_QUEST_IDS = {
	"t01_spawn",
	"t02_gather",
	"t03_sparks",
	"t04_tinder",
	"t05_campfire",
	"t06_cold",
	"t07_bandage",
	"t08_complete",
}

local function countBlueprintPlaced(data: PlayerProfileTypes.PlayerProfile, blueprintId: string): number
	local count = 0

	if type(data.camp.structures) ~= "table" then
		return 0
	end

	for _, structure in data.camp.structures do
		if structure.blueprintId == blueprintId then
			count += 1
		end
	end

	return count
end

local function countChestsOnPlot(data: PlayerProfileTypes.PlayerProfile): number
	local count = countBlueprintPlaced(data, "bp_chest")

	if count == 0 and type(data.camp.chests) == "table" then
		for _ in data.camp.chests do
			count += 1
		end
	end

	return count
end

local function hasChestOnPlot(data: PlayerProfileTypes.PlayerProfile): boolean
	return countChestsOnPlot(data) >= 1
end

local function countActiveQuestsAny(data: PlayerProfileTypes.PlayerProfile): number
	local count = 0

	for _, state in data.quests do
		if state.status == "active" then
			count += 1
		end
	end

	return count
end

local function isLegacyPostTutorialCamp(data: PlayerProfileTypes.PlayerProfile): boolean
	local hasCampfire = countBlueprintPlaced(data, "bp_campfire") >= 1
	local hasChest = hasChestOnPlot(data)
	local hasCraftTable = countBlueprintPlaced(data, "bp_craft_table") >= 1

	if hasCraftTable then
		return true
	end

	if hasCampfire and hasChest then
		return true
	end

	return data.camp.level >= 1 and hasChest
end

local function forceCompleteQuestRecord(data: PlayerProfileTypes.PlayerProfile, questId: string)
	local definition = Quests.get(questId)

	if definition == nil or isQuestRecordCompleted(data, questId) then
		return
	end

	local objectives = buildObjectiveProgress(definition)

	for _, objective in objectives do
		objective.current = objective.target
	end

	data.quests[questId] = {
		status = "completed",
		objectives = objectives,
		startedAt = os.time(),
		completedAt = os.time(),
	}
	markMissionCompleted(data, questId)
end

local function reconcileLegacyMainProgress(player: Player, data: PlayerProfileTypes.PlayerProfile)
	if not data.tutorialCompleted or not hasChestOnPlot(data) then
		return
	end

	if not isQuestRecordCompleted(data, "m00_wood") then
		forceCompleteQuestRecord(data, "m00_wood")
	end

	if isQuestRecordCompleted(data, "main_01_chest") then
		return
	end

	local main01State = data.quests.main_01_chest

	if main01State == nil or main01State.status ~= "active" then
		if QuestService.canStartQuest(data, "main_01_chest") then
			QuestService.startQuest(player, "main_01_chest")
		end
	end

	main01State = data.quests.main_01_chest

	if main01State ~= nil and main01State.status == "active" then
		applyRetroactiveProgress(data, main01State)
		checkQuestCompletion(player, data, "main_01_chest")
	end
end

local function tryProgressMainQuestChain(player: Player, data: PlayerProfileTypes.PlayerProfile)
	if not data.tutorialCompleted then
		return
	end

	for _, questId in MAIN_QUEST_CHAIN do
		if isQuestRecordCompleted(data, questId) then
			continue
		end

		local state = data.quests[questId]

		if state ~= nil and state.status == "active" then
			applyRetroactiveProgress(data, state)
			checkQuestCompletion(player, data, questId)

			if data.quests[questId] ~= nil and data.quests[questId].status == "active" then
				return
			end

			continue
		end

		if QuestService.canStartQuest(data, questId) then
			QuestService.startQuest(player, questId)
			return
		end

		return
	end
end

local function bootstrapLegacyTutorialCompletion(data: PlayerProfileTypes.PlayerProfile)
	if data.tutorialCompleted or not isLegacyPostTutorialCamp(data) then
		return
	end

	data.tutorialCompleted = true

	for _, questId in TUTORIAL_QUEST_IDS do
		forceCompleteQuestRecord(data, questId)
	end

	Logger.info("QuestService", "Bootstrapped tutorial completion for legacy camp progress")
end

local function repairQuestObjectiveProgress(data: PlayerProfileTypes.PlayerProfile)
	for questId, state in data.quests do
		if state.status ~= "active" then
			continue
		end

		local definition = Quests.get(questId)

		if definition == nil then
			continue
		end

		if type(state.objectives) ~= "table" or #state.objectives ~= #definition.objectives then
			state.objectives = buildObjectiveProgress(definition)
		end
	end
end

local function reconcileActiveQuestRecords(player: Player, data: PlayerProfileTypes.PlayerProfile)
	for questId, state in data.quests do
		if state.status ~= "active" then
			continue
		end

		applyRetroactiveProgress(data, state)
		checkQuestCompletion(player, data, questId)
	end
end

local function repairTutorialQuestChain(player: Player, data: PlayerProfileTypes.PlayerProfile)
	for _, questId in TUTORIAL_QUEST_IDS do
		if isQuestRecordCompleted(data, questId) then
			continue
		end

		local definition = Quests.get(questId)

		if definition == nil then
			continue
		end

		if definition.prerequisites ~= nil then
			for _, prerequisiteId in definition.prerequisites do
				if not isQuestRecordCompleted(data, prerequisiteId) then
					forceCompleteQuestRecord(data, prerequisiteId)
				end
			end
		end

		if QuestService.canStartQuest(data, questId) then
			QuestService.startQuest(player, questId)
			return
		end

		forceCompleteQuestRecord(data, questId)
	end

	if isQuestRecordCompleted(data, "t08_complete") then
		data.tutorialCompleted = true
	end
end

local function ensureAtLeastOneActiveQuest(player: Player, data: PlayerProfileTypes.PlayerProfile)
	if countActiveQuestsAny(data) > 0 then
		return
	end

	if not data.tutorialCompleted then
		repairTutorialQuestChain(player, data)
	else
		reconcileLegacyMainProgress(player, data)
		tryProgressMainQuestChain(player, data)
	end

	if countActiveQuestsAny(data) > 0 then
		return
	end

	if data.tutorialCompleted then
		for _, questId in MAIN_QUEST_CHAIN do
			if QuestService.canStartQuest(data, questId) then
				QuestService.startQuest(player, questId)
				return
			end
		end
	end

	if countActiveQuestsAny(data) == 0 then
		Logger.warn("QuestService", `No active quest after reconcile for {player.Name}`)
	end
end

local function reconcilePlayerQuests(player: Player)
	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	if type(data.stats.missionsCompleted) ~= "table" then
		data.stats.missionsCompleted = {}
	end

	if type(data.quests) ~= "table" then
		data.quests = {}
	end

	if type(data.camp.structures) ~= "table" then
		data.camp.structures = {}
	end

	if type(data.camp.chests) ~= "table" then
		data.camp.chests = {}
	end

	repairQuestObjectiveProgress(data)
	bootstrapLegacyTutorialCompletion(data)
	reconcileActiveQuestRecords(player, data)

	local session = getSession(player)

	if session.trackedQuestId == nil then
		session.trackedQuestId = getDefaultTrackedQuestId(data)
	end

	if not data.tutorialCompleted then
		local hasActiveTutorial = false

		for questId, state in data.quests do
			if state.status == "active" then
				local definition = Quests.get(questId)

				if definition ~= nil and definition.questType == "tutorial" then
					hasActiveTutorial = true
					applyRetroactiveProgress(data, state)
					checkQuestCompletion(player, data, questId)
					break
				end
			end
		end

		if not hasActiveTutorial and not QuestService.startQuest(player, "t01_spawn") then
			repairTutorialQuestChain(player, data)
		end
	else
		reconcileLegacyMainProgress(player, data)
		tryProgressMainQuestChain(player, data)
	end

	if data.tutorialCompleted and data.stats.level >= 2 then
		if QuestService.canStartQuest(data, "side_01_berries") then
			QuestService.startQuest(player, "side_01_berries")
		end

		if QuestService.canStartQuest(data, "side_02_wolf") then
			QuestService.startQuest(player, "side_02_wolf")
		end
	end

	ensureAtLeastOneActiveQuest(player, data)

	session.trackedQuestId = session.trackedQuestId or getDefaultTrackedQuestId(data)
	syncQuest(player, data, nil)
end

function QuestService.reconcileForPlayer(player: Player)
	reconcilePlayerQuests(player)
end

local function onPlayerReady(player: Player)
	reconcilePlayerQuests(player)
end

local function onClientReady(player: Player)
	reconcilePlayerQuests(player)
end

local function isNearCampfire(player: Player, data: PlayerProfileTypes.PlayerProfile): boolean
	local character = player.Character
	local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil

	if root == nil or not root:IsA("BasePart") then
		return false
	end

	for _, structure in data.camp.structures do
		if structure.blueprintId == "bp_campfire" then
			local position = CampProximity.toVector3(structure.position)

			if position ~= nil and CampProximity.horizontalDistance(root.Position, position) <= QuestConstants.COLD_SURVIVAL_CAMPFIRE_RANGE_STUDS then
				return true
			end
		end
	end

	return false
end

local function processColdSurvivalTick()
	for _, player in Players:GetPlayers() do
		local data = PlayerDataService:GetData(player)

		if data == nil then
			continue
		end

		local coldQuest = data.quests.t06_cold

		if coldQuest == nil or coldQuest.status ~= "active" then
			continue
		end

		local session = getSession(player)

		if not session.coldDipApplied then
			data.survival.temperature = QuestConstants.COLD_DIP_TEMPERATURE
			session.coldDipApplied = true
			PlayerSyncService.syncSurvivalToClient(player, data)
		end

		if not isNearCampfire(player, data) then
			continue
		end

		data.survival.temperature = math.min(100, data.survival.temperature + 2)
		PlayerSyncService.syncSurvivalToClient(player, data)

		incrementMatchingObjectives(player, data, function(objective)
			return objective.kind == "survive_cold"
		end, 1)
	end
end

local function onItemHarvested(player: Player, itemId: string, quantity: number)
	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	incrementMatchingObjectives(player, data, function(objective)
		return objective.kind == "gather" and objective.itemId == itemId
	end, quantity)
end

local function onItemCrafted(player: Player, recipeId: string, outputItemId: string, quantity: number)
	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	incrementMatchingObjectives(player, data, function(objective)
		return objective.kind == "craft"
			and (objective.recipeId == recipeId or objective.outputItemId == outputItemId)
	end, quantity)
end

local function onStructurePlaced(player: Player, blueprintId: string)
	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	incrementMatchingObjectives(player, data, function(objective)
		return objective.kind == "place_structure" and objective.blueprintId == blueprintId
	end, 1)
end

local function onFaunaDefeated(player: Player, speciesId: string)
	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	incrementMatchingObjectives(player, data, function(objective)
		return objective.kind == "defeat_fauna" and objective.speciesId == speciesId
	end, 1)
end

local function onQuestUiOpened(player: Player, panelId: string)
	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	incrementMatchingObjectives(player, data, function(objective)
		return objective.kind == "open_ui" and objective.panelId == panelId
	end, 1)
end

local function onCampPlotAssigned(player: Player, _plotId: string)
	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	incrementMatchingObjectives(player, data, function(objective)
		return objective.kind == "open_ui" and objective.panelId == "stats"
	end, 1)
end

local function onEscortToPlot(player: Player, helperTypeId: string)
	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	incrementMatchingObjectives(player, data, function(objective)
		return objective.kind == "escort_to_plot" and objective.helperTypeId == helperTypeId
	end, 1)
end

local function onQuestTrack(player: Player, questId: unknown)
	if type(questId) ~= "string" then
		return
	end

	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	local state = data.quests[questId]

	if state == nil or (state.status ~= "active" and state.status ~= "completed") then
		return
	end

	getSession(player).trackedQuestId = questId
	syncQuest(player, data, nil)
end

local function onQuestUiOpenedRemote(player: Player, panelId: unknown)
	if type(panelId) ~= "string" then
		return
	end

	GameEvents.fireQuestUiOpened(player, panelId)
end

function QuestService:Init()
	local trove = self:GetTrove()

	trove:Connect(GameEvents.ItemHarvested.Event, onItemHarvested)
	trove:Connect(GameEvents.ItemCrafted.Event, onItemCrafted)
	trove:Connect(GameEvents.StructurePlaced.Event, onStructurePlaced)
	trove:Connect(GameEvents.FaunaDefeated.Event, onFaunaDefeated)
	trove:Connect(GameEvents.QuestUiOpened.Event, onQuestUiOpened)
	trove:Connect(GameEvents.CampPlotAssigned.Event, onCampPlotAssigned)
	trove:Connect(GameEvents.EscortToPlot.Event, onEscortToPlot)
	trove:Connect(Networking.getEvent("QuestTrackEvent").OnServerEvent, onQuestTrack)
	trove:Connect(Networking.getEvent("QuestUiOpenedEvent").OnServerEvent, onQuestUiOpenedRemote)
	trove:Connect(Networking.getEvent("ClientReadyEvent").OnServerEvent, onClientReady)
end

function QuestService:Start()
	local trove = self:GetTrove()

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

	local function scheduleColdTick()
		processColdSurvivalTick()
		coldTickThread = task.delay(1, scheduleColdTick)
	end

	scheduleColdTick()
	Logger.info("QuestService", "Quest progression is active")
end

function QuestService:Destroy()
	if coldTickThread ~= nil then
		task.cancel(coldTickThread)
		coldTickThread = nil
	end

	BaseService.Destroy(self)
end

return QuestService
