--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseController = require(script.Parent.Parent.Kernel.BaseController)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local CampTypes = require(ReplicatedStorage.Shared.Types.Camp)
local CraftingTypes = require(ReplicatedStorage.Shared.Types.Crafting)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)
local QuestTypes = require(ReplicatedStorage.Shared.Types.Quest)
local SurvivalTypes = require(ReplicatedStorage.Shared.Types.Survival)

local ClientSyncController = BaseController.new("ClientSyncController")

local latestSurvival: SurvivalTypes.SurvivalSnapshot? = nil
local latestInventory: PlayerProfileTypes.InventorySnapshot? = nil
local latestCamp: CampTypes.CampSnapshot? = nil
local latestQuest: QuestTypes.QuestSnapshot? = nil
local latestRecipes: CraftingTypes.RecipesSnapshot? = nil

function ClientSyncController:GetSurvival(): SurvivalTypes.SurvivalSnapshot?
	return latestSurvival
end

function ClientSyncController:GetInventory(): PlayerProfileTypes.InventorySnapshot?
	return latestInventory
end

function ClientSyncController:GetCamp(): CampTypes.CampSnapshot?
	return latestCamp
end

function ClientSyncController:GetQuest(): QuestTypes.QuestSnapshot?
	return latestQuest
end

function ClientSyncController:GetRecipes(): CraftingTypes.RecipesSnapshot?
	return latestRecipes
end

function ClientSyncController:Init()
	local trove = self:GetTrove()

	trove:Connect(Networking.getEvent("SurvivalUpdatedEvent").OnClientEvent, function(snapshot: SurvivalTypes.SurvivalSnapshot)
		latestSurvival = snapshot
		Logger.debug("ClientSyncController", "Received survival sync")
	end)

	trove:Connect(Networking.getEvent("InventoryUpdatedEvent").OnClientEvent, function(snapshot: PlayerProfileTypes.InventorySnapshot)
		latestInventory = snapshot
		Logger.debug("ClientSyncController", "Received inventory sync")
	end)

	trove:Connect(Networking.getEvent("CampUpdatedEvent").OnClientEvent, function(snapshot: CampTypes.CampSnapshot)
		latestCamp = snapshot
		Logger.debug("ClientSyncController", "Received camp sync")
	end)

	trove:Connect(Networking.getEvent("QuestProgressEvent").OnClientEvent, function(snapshot: QuestTypes.QuestSnapshot)
		latestQuest = snapshot
		Logger.debug("ClientSyncController", "Received quest sync")
	end)

	trove:Connect(Networking.getEvent("RecipesUpdatedEvent").OnClientEvent, function(snapshot: CraftingTypes.RecipesSnapshot)
		latestRecipes = snapshot
		Logger.debug("ClientSyncController", "Received recipes sync")
	end)

	trove:Connect(Networking.getEvent("PlayerDataLoadedEvent").OnClientEvent, function(profileData: PlayerProfileTypes.PlayerProfile)
		if type(profileData.recipes) == "table" and type(profileData.recipes.unlocked) == "table" then
			latestRecipes = {
				unlocked = profileData.recipes.unlocked,
			}
		end
	end)
end

return ClientSyncController
