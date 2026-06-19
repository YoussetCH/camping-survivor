--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local PlayerDataServiceModule = require(ServerScriptService.Services.PlayerDataService)
local ServerKernel = require(ServerScriptService.Kernel.ServerKernel)

local ProfileStore = require(ServerScriptService.Packages.ProfileStore)

local services = ServerKernel.loadServices()

ServerKernel.initServices(services)
ServerKernel.startServices(services)

ProfileStore.OnClose:Bind(function()
	Logger.info("Bootstrap", "BindToClose triggered, releasing player profiles")

	local playerDataService = ServerKernel.getService("PlayerDataService") :: typeof(PlayerDataServiceModule)?

	if playerDataService ~= nil then
		playerDataService:GetRepository():ReleaseAll()
	end

	ServerKernel.destroyServices(services)
end)

Logger.info("Bootstrap", "Server bootstrap complete")
