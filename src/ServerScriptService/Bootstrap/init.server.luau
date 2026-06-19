--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local PlayerDataServiceModule = require(ServerScriptService.Services.PlayerDataService)
local ServerKernel = require(ServerScriptService.Kernel.ServerKernel)

local function ensureDevWorld()
	if workspace:FindFirstChild("DevBaseplate") == nil then
		local baseplate = Instance.new("Part")
		baseplate.Name = "DevBaseplate"
		baseplate.Anchored = true
		baseplate.Size = Vector3.new(512, 20, 512)
		baseplate.Position = Vector3.new(0, -10, 0)
		baseplate.Material = Enum.Material.Grass
		baseplate.Color = Color3.fromRGB(90, 165, 90)
		baseplate.TopSurface = Enum.SurfaceType.Smooth
		baseplate.BottomSurface = Enum.SurfaceType.Smooth
		baseplate.Parent = workspace
		Logger.info("Bootstrap", "Created DevBaseplate")
	end

	if workspace:FindFirstChildOfClass("SpawnLocation") == nil then
		local spawnLocation = Instance.new("SpawnLocation")
		spawnLocation.Name = "SpawnLocation"
		spawnLocation.Anchored = true
		spawnLocation.Size = Vector3.new(12, 1, 12)
		spawnLocation.Position = Vector3.new(0, 0.5, 0)
		spawnLocation.Neutral = true
		spawnLocation.Duration = 0
		spawnLocation.Material = Enum.Material.Concrete
		spawnLocation.Color = Color3.fromRGB(160, 160, 160)
		spawnLocation.Parent = workspace
		Logger.info("Bootstrap", "Created SpawnLocation")
	end
end

ensureDevWorld()

local services = ServerKernel.loadServices()

ServerKernel.initServices(services)
ServerKernel.startServices(services)

local function onBindToClose()
	Logger.info("Bootstrap", "BindToClose triggered, releasing player profiles")

	local playerDataService = ServerKernel.getService("PlayerDataService") :: typeof(PlayerDataServiceModule)?

	if playerDataService ~= nil then
		playerDataService:GetRepository():ReleaseAll()
	end

	ServerKernel.destroyServices(services)
end

game:BindToClose(onBindToClose)

Logger.info("Bootstrap", "Server bootstrap complete")
