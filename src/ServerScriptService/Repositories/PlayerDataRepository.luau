--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataStoreNames = require(ReplicatedStorage.Shared.Constants.DataStoreNames)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local PlayerProfileTemplate = require(ReplicatedStorage.Shared.Constants.PlayerProfileTemplate)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)
local CampRepository = require(ServerScriptService.Repositories.CampRepository)

local ProfileStore = require(ServerScriptService.Packages.ProfileStore)

export type ProfileSession = typeof(ProfileStore.New("", {}):StartSessionAsync("", {}))

export type PlayerDataRepository = {
	LoadProfile: (self: PlayerDataRepository, player: Player) -> ProfileSession?,
	GetProfile: (self: PlayerDataRepository, player: Player) -> ProfileSession?,
	GetData: (self: PlayerDataRepository, player: Player) -> PlayerProfileTypes.PlayerProfile?,
	SaveProfile: (self: PlayerDataRepository, player: Player) -> boolean,
	ReleaseProfile: (self: PlayerDataRepository, player: Player) -> (),
	ReleaseAll: (self: PlayerDataRepository) -> (),
}

local PlayerDataRepository = {}
PlayerDataRepository.__index = PlayerDataRepository

function PlayerDataRepository.new(): PlayerDataRepository
	local playerStore = ProfileStore.New(DataStoreNames.PlayerStore, PlayerProfileTemplate)

	local self = setmetatable({
		_playerStore = playerStore,
		_profiles = {} :: { [Player]: ProfileSession },
	}, PlayerDataRepository)

	return self :: PlayerDataRepository
end

function PlayerDataRepository:LoadProfile(player: Player): ProfileSession?
	if self._profiles[player] ~= nil then
		return self._profiles[player]
	end

	local profile = self._playerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		Logger.warn("PlayerDataRepository", `Failed to load profile for {player.Name}`)
		player:Kick("Unable to load your data. Please rejoin.")
		return nil
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		self._profiles[player] = nil

		if player.Parent == Players then
			player:Kick("Your data session ended. Please rejoin.")
		end
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return nil
	end

	self._profiles[player] = profile
	Logger.info("PlayerDataRepository", `Loaded profile for {player.Name}`)

	return profile
end

function PlayerDataRepository:GetProfile(player: Player): ProfileSession?
	return self._profiles[player]
end

function PlayerDataRepository:GetData(player: Player): PlayerProfileTypes.PlayerProfile?
	local profile = self._profiles[player]

	if profile == nil then
		return nil
	end

	return profile.Data :: PlayerProfileTypes.PlayerProfile
end

function PlayerDataRepository:SaveProfile(player: Player): boolean
	local profile = self._profiles[player]

	if profile == nil or profile:IsActive() ~= true then
		return false
	end

	local data = profile.Data :: PlayerProfileTypes.PlayerProfile

	if type(data.camp) == "table" then
		CampRepository.prepareForPersistence(data.camp)
	end

	profile:Save()
	return true
end

function PlayerDataRepository:ReleaseProfile(player: Player)
	local profile = self._profiles[player]

	if profile == nil then
		return
	end

	profile:EndSession()
	self._profiles[player] = nil
	Logger.info("PlayerDataRepository", `Released profile for {player.Name}`)
end

function PlayerDataRepository:ReleaseAll()
	for player in self._profiles do
		self:ReleaseProfile(player)
	end
end

return PlayerDataRepository
