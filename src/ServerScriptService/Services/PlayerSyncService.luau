--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseService = require(ServerScriptService.Kernel.BaseService)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local CampTypes = require(ReplicatedStorage.Shared.Types.Camp)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)
local QuestTypes = require(ReplicatedStorage.Shared.Types.Quest)
local SurvivalTypes = require(ReplicatedStorage.Shared.Types.Survival)

local PlayerSyncService = BaseService.new("PlayerSyncService")

local function buildSurvivalSnapshot(data: PlayerProfileTypes.PlayerProfile): SurvivalTypes.SurvivalSnapshot
	return {
		stats = data.survival,
		statusEffects = data.statusEffects,
	}
end

local function buildInventorySnapshot(data: PlayerProfileTypes.PlayerProfile): PlayerProfileTypes.InventorySnapshot
	return {
		inventory = data.inventory,
	}
end

local function buildCampSnapshot(data: PlayerProfileTypes.PlayerProfile): CampTypes.CampSnapshot
	return data.camp
end

local function buildQuestSnapshot(data: PlayerProfileTypes.PlayerProfile): QuestTypes.QuestSnapshot
	return {
		progress = data.quests,
		tutorialCompleted = data.tutorialCompleted,
	}
end

function PlayerSyncService.syncToClient(player: Player, data: PlayerProfileTypes.PlayerProfile)
	Networking.getEvent("SurvivalUpdatedEvent"):FireClient(player, buildSurvivalSnapshot(data))
	Networking.getEvent("InventoryUpdatedEvent"):FireClient(player, buildInventorySnapshot(data))
	Networking.getEvent("CampUpdatedEvent"):FireClient(player, buildCampSnapshot(data))
	Networking.getEvent("QuestProgressEvent"):FireClient(player, buildQuestSnapshot(data))
	Logger.debug("PlayerSyncService", `Synced domain state to {player.Name}`)
end

function PlayerSyncService:Start()
	Logger.info("PlayerSyncService", "Player sync is active")
end

return PlayerSyncService
