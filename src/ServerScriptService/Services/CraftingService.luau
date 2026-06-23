--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseService = require(ServerScriptService.Kernel.BaseService)
local CraftingConstants = require(ReplicatedStorage.Shared.Constants.CraftingConstants)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local Recipes = require(ReplicatedStorage.Shared.Constants.Recipes)
local StationRegistry = require(ServerScriptService.Features.StationRegistry)
local CraftingTypes = require(ReplicatedStorage.Shared.Types.Crafting)
local RecipeTypes = require(ReplicatedStorage.Shared.Types.Recipe)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)
local InventoryService = require(ServerScriptService.Services.InventoryService)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local PlayerSyncService = require(ServerScriptService.Services.PlayerSyncService)

local CraftingService = BaseService.new("CraftingService")

local lastCraftAt: { [number]: number } = {}

local function normalizeRecipes(data: PlayerProfileTypes.PlayerProfile)
	if type(data.recipes) ~= "table" then
		data.recipes = { unlocked = {} }
	end

	if type(data.recipes.unlocked) ~= "table" then
		data.recipes.unlocked = {}
	end
end

local function isRecipeUnlocked(data: PlayerProfileTypes.PlayerProfile, recipeId: string): boolean
	for _, unlockedId in data.recipes.unlocked do
		if unlockedId == recipeId then
			return true
		end
	end

	return false
end

function CraftingService.ensureTutorialRecipesUnlocked(player: Player, data: PlayerProfileTypes.PlayerProfile): boolean
	normalizeRecipes(data)

	local changed = false
	local unlockedSet: { [string]: boolean } = {}

	for _, recipeId in data.recipes.unlocked do
		unlockedSet[recipeId] = true
	end

	for _, recipe in Recipes.getAll() do
		if recipe.unlockType == "tutorial" and unlockedSet[recipe.id] ~= true then
			table.insert(data.recipes.unlocked, recipe.id)
			unlockedSet[recipe.id] = true
			changed = true
		end
	end

	if changed then
		PlayerSyncService.syncRecipesToClient(player, data)
		PlayerDataService:SaveProfile(player)
	end

	return changed
end

function CraftingService.ensureStarterRecipesUnlocked(player: Player, data: PlayerProfileTypes.PlayerProfile): boolean
	normalizeRecipes(data)

	local changed = false
	local unlockedSet: { [string]: boolean } = {}

	for _, recipeId in data.recipes.unlocked do
		unlockedSet[recipeId] = true
	end

	for _, recipe in Recipes.getAll() do
		if recipe.unlockType == "starter" and unlockedSet[recipe.id] ~= true then
			table.insert(data.recipes.unlocked, recipe.id)
			unlockedSet[recipe.id] = true
			changed = true
		end
	end

	if changed then
		PlayerSyncService.syncRecipesToClient(player, data)
		PlayerDataService:SaveProfile(player)
	end

	return changed
end

local function fireCraftResult(player: Player, payload: CraftingTypes.CraftResultPayload)
	Networking.getEvent("CraftResultEvent"):FireClient(player, payload)
end

local function hasRecipeInputs(data: PlayerProfileTypes.PlayerProfile, recipe: RecipeTypes.RecipeDefinition): boolean
	for _, input in recipe.inputs do
		if InventoryService.countItem(data, input.itemId) < input.quantity then
			return false
		end
	end

	return true
end

local function craftItem(player: Player, recipeId: unknown)
	if type(recipeId) ~= "string" then
		return
	end

	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	local recipe = Recipes.get(recipeId)

	if recipe == nil then
		return
	end

	local now = os.clock()
	local lastAt = lastCraftAt[player.UserId]

	if lastAt ~= nil and now - lastAt < CraftingConstants.CRAFT_COOLDOWN_SECONDS then
		fireCraftResult(player, {
			success = false,
			recipeId = recipeId,
			reasonKey = "craft.error.cooldown",
		})
		return
	end

	lastCraftAt[player.UserId] = now

	if not isRecipeUnlocked(data, recipeId) then
		fireCraftResult(player, {
			success = false,
			recipeId = recipeId,
			reasonKey = "craft.error.not_unlocked",
		})
		return
	end

	if not CraftingConstants.isHandsStation(recipe.station) then
		if not StationRegistry.isPlayerNearStation(player, recipe.station) then
			fireCraftResult(player, {
				success = false,
				recipeId = recipeId,
				reasonKey = "craft.error.wrong_station",
			})
			return
		end
	end

	if not hasRecipeInputs(data, recipe) then
		fireCraftResult(player, {
			success = false,
			recipeId = recipeId,
			reasonKey = "craft.error.missing_items",
		})
		return
	end

	if not InventoryService.canFitOutputs(data, recipe.outputs) then
		fireCraftResult(player, {
			success = false,
			recipeId = recipeId,
			reasonKey = "craft.error.no_space",
		})
		return
	end

	if not InventoryService.removeItems(player, data, recipe.inputs) then
		fireCraftResult(player, {
			success = false,
			recipeId = recipeId,
			reasonKey = "craft.error.missing_items",
		})
		return
	end

	if not InventoryService.grantItems(player, recipe.outputs) then
		Logger.warn("CraftingService", `Craft outputs failed after consuming inputs for {recipeId}`)
		fireCraftResult(player, {
			success = false,
			recipeId = recipeId,
			reasonKey = "craft.error.no_space",
		})
		return
	end

	fireCraftResult(player, {
		success = true,
		recipeId = recipeId,
		reasonKey = nil,
	})
	PlayerDataService:SaveProfile(player)
	Logger.debug("CraftingService", `{player.Name} crafted {recipeId}`)
end

local function onPlayerDataReady(player: Player)
	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	CraftingService.ensureTutorialRecipesUnlocked(player, data)
end

function CraftingService:Init()
	local trove = self:GetTrove()

	trove:Connect(Networking.getEvent("CraftItemEvent").OnServerEvent, craftItem)
end

function CraftingService:Start()
	local trove = self:GetTrove()

	trove:Connect(Players.PlayerAdded, function(player: Player)
		task.spawn(function()
			for _ = 1, 20 do
				if PlayerDataService:GetData(player) ~= nil then
					onPlayerDataReady(player)
					return
				end

				task.wait(0.25)
			end
		end)
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerDataReady, player)
	end

	Logger.info("CraftingService", "Crafting is active")
end

return CraftingService
