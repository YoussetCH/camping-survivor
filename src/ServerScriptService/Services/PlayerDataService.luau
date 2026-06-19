--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseService = require(ServerScriptService.Kernel.BaseService)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local PlayerDataRepositoryModule = require(ServerScriptService.Repositories.PlayerDataRepository)

local PlayerDataService = BaseService.new("PlayerDataService")

local repository: PlayerDataRepositoryModule.PlayerDataRepository? = nil

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
		Networking.getEvent("PlayerDataLoadedEvent"):FireClient(player, data)
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

return PlayerDataService
