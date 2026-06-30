--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseService = require(ServerScriptService.Kernel.BaseService)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local CampTypes = require(ReplicatedStorage.Shared.Types.Camp)
local CraftingTypes = require(ReplicatedStorage.Shared.Types.Crafting)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)
local QuestTypes = require(ReplicatedStorage.Shared.Types.Quest)
local SurvivalTypes = require(ReplicatedStorage.Shared.Types.Survival)

local PlayerSyncService = BaseService.new("PlayerSyncService")

local function buildSurvivalSnapshot(data: PlayerProfileTypes.PlayerProfile): SurvivalTypes.SurvivalSnapshot
	return {
		stats = {
			hunger = math.clamp(data.survival.hunger, 0, 100),
			thirst = math.clamp(data.survival.thirst, 0, 100),
			health = math.clamp(data.survival.health, 0, 100),
			temperature = math.clamp(data.survival.temperature, 0, 100),
		},
		statusEffects = data.statusEffects,
	}
end

local function buildInventorySnapshot(data: PlayerProfileTypes.PlayerProfile): PlayerProfileTypes.InventorySnapshot
	return {
		inventory = data.inventory,
		hotbar = data.hotbar,
		equipped = data.equipped,
	}
end

local function buildCampSnapshot(data: PlayerProfileTypes.PlayerProfile): CampTypes.CampSnapshot
	return data.camp
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

local function buildQuestSnapshot(
	data: PlayerProfileTypes.PlayerProfile,
	trackedQuestId: string?,
	lastCompletedQuestId: string?
): QuestTypes.QuestSnapshot
	return {
		progress = data.quests,
		tutorialCompleted = data.tutorialCompleted,
		trackedQuestId = trackedQuestId,
		activeQuestIds = getActiveQuestIds(data),
		stats = {
			level = data.stats.level,
			xp = data.stats.xp,
		},
		lastCompletedQuestId = lastCompletedQuestId,
	}
end

local function buildRecipesSnapshot(data: PlayerProfileTypes.PlayerProfile): CraftingTypes.RecipesSnapshot
	return {
		unlocked = data.recipes.unlocked,
	}
end

function PlayerSyncService.syncSurvivalToClient(player: Player, data: PlayerProfileTypes.PlayerProfile)
	Networking.getEvent("SurvivalUpdatedEvent"):FireClient(player, buildSurvivalSnapshot(data))
end

function PlayerSyncService.syncInventoryToClient(player: Player, data: PlayerProfileTypes.PlayerProfile)
	Networking.getEvent("InventoryUpdatedEvent"):FireClient(player, buildInventorySnapshot(data))
end

function PlayerSyncService.syncRecipesToClient(player: Player, data: PlayerProfileTypes.PlayerProfile)
	Networking.getEvent("RecipesUpdatedEvent"):FireClient(player, buildRecipesSnapshot(data))
end

function PlayerSyncService.syncCampToClient(player: Player, data: PlayerProfileTypes.PlayerProfile)
	Networking.getEvent("CampUpdatedEvent"):FireClient(player, buildCampSnapshot(data))
end

function PlayerSyncService.syncQuestToClient(
	player: Player,
	data: PlayerProfileTypes.PlayerProfile,
	trackedQuestId: string?,
	lastCompletedQuestId: string?
)
	Networking.getEvent("QuestProgressEvent"):FireClient(
		player,
		buildQuestSnapshot(data, trackedQuestId, lastCompletedQuestId)
	)
end

function PlayerSyncService.syncToClient(player: Player, data: PlayerProfileTypes.PlayerProfile)
	PlayerSyncService.syncSurvivalToClient(player, data)
	PlayerSyncService.syncInventoryToClient(player, data)
	PlayerSyncService.syncRecipesToClient(player, data)
	PlayerSyncService.syncCampToClient(player, data)
	PlayerSyncService.syncQuestToClient(player, data, nil, nil)
	Logger.debug("PlayerSyncService", `Synced domain state to {player.Name}`)
end

function PlayerSyncService:Start()
	Logger.info("PlayerSyncService", "Player sync is active")
end

return PlayerSyncService
