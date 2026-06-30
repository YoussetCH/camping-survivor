--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseService = require(ServerScriptService.Kernel.BaseService)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.Inventory)
local LocaleRegistry = require(ReplicatedStorage.Shared.Localization.LocaleRegistry)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local PlayerDataRepositoryModule = require(ServerScriptService.Repositories.PlayerDataRepository)
local PlayerSyncService = require(ServerScriptService.Services.PlayerSyncService)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)

local PlayerDataService = BaseService.new("PlayerDataService")

local repository: PlayerDataRepositoryModule.PlayerDataRepository? = nil

local function normalizeInventory(data: PlayerProfileTypes.PlayerProfile)
	data.inventory = InventoryTypes.normalizeLegacyInventory(data.inventory)

	if type(data.hotbar) ~= "table" then
		data.hotbar = InventoryTypes.createEmptyHotbar()
	elseif #data.hotbar < 6 then
		local hotbar = InventoryTypes.createEmptyHotbar()

		for index, bagSlotKey in data.hotbar do
			hotbar[index] = bagSlotKey
		end

		data.hotbar = hotbar
	end

	if type(data.equipped) ~= "table" then
		data.equipped = InventoryTypes.createEmptyEquipped()
	end
end

local function normalizeSettings(data: PlayerProfileTypes.PlayerProfile)
	if type(data.settings) ~= "table" then
		data.settings = { locale = LocaleRegistry.DEFAULT_LOCALE }
		return
	end

	if not LocaleRegistry.isSupported(data.settings.locale) then
		data.settings.locale = LocaleRegistry.DEFAULT_LOCALE
	end
end

local function normalizeStats(data: PlayerProfileTypes.PlayerProfile)
	if type(data.stats.missionsCompleted) ~= "table" then
		data.stats.missionsCompleted = {}
	end

	if type(data.quests) ~= "table" then
		data.quests = {}
	end
end

local function normalizeHelpers(data: PlayerProfileTypes.PlayerProfile)
	if type(data.helpers) ~= "table" then
		data.helpers = {}
	end

	if type(data.lostHelpers) ~= "table" then
		data.lostHelpers = {}
	end
end

local function onClientReady(player: Player)
	if repository == nil then
		return
	end

	task.defer(function()
		local QuestService = require(ServerScriptService.Services.QuestService)
		QuestService.reconcileForPlayer(player)

		local data = repository:GetData(player)

		if data == nil then
			return
		end

		Networking.getEvent("PlayerDataLoadedEvent"):FireClient(player, data)
		PlayerSyncService.syncToClient(player, data)
		Logger.debug("PlayerDataService", `Re-synced profile for {player.Name} after client ready`)
	end)
end

local function onPlayerAdded(player: Player)
	if repository == nil then
		return
	end

	local profile = repository:LoadProfile(player)

	if profile == nil then
		return
	end

	local data = repository:GetData(player)

	if data ~= nil then
		normalizeSettings(data)
		normalizeInventory(data)
		normalizeStats(data)
		normalizeHelpers(data)

		local CraftingService = require(ServerScriptService.Services.CraftingService)
		CraftingService.ensureTutorialRecipesUnlocked(player, data)

		Networking.getEvent("PlayerDataLoadedEvent"):FireClient(player, data)
		PlayerSyncService.syncToClient(player, data)
	end
end

local function onPlayerRemoving(player: Player)
	if repository == nil then
		return
	end

	repository:ReleaseProfile(player)
end

function PlayerDataService:Init()
	repository = PlayerDataRepositoryModule.new()

	local trove = self:GetTrove()

	trove:Connect(Players.PlayerAdded, onPlayerAdded)
	trove:Connect(Players.PlayerRemoving, onPlayerRemoving)
	trove:Connect(Networking.getEvent("ClientReadyEvent").OnServerEvent, onClientReady)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

function PlayerDataService:Start()
	Logger.info("PlayerDataService", "Player data sessions are active")
end

function PlayerDataService:GetRepository(): PlayerDataRepositoryModule.PlayerDataRepository
	if repository == nil then
		error("PlayerDataRepository is not initialized", 2)
	end

	return repository
end

function PlayerDataService:GetData(player: Player)
	if repository == nil then
		return nil
	end

	return repository:GetData(player)
end

function PlayerDataService:SaveProfile(player: Player): boolean
	if repository == nil then
		return false
	end

	return repository:SaveProfile(player)
end

return PlayerDataService
