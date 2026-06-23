--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local PlayerDataServiceModule = require(ServerScriptService.Services.PlayerDataService)
local ServerKernel = require(ServerScriptService.Kernel.ServerKernel)
local ProfileStore = require(ServerScriptService.Packages.ProfileStore)
local WorldBootstrap = require(ServerScriptService.Bootstrap.WorldBootstrap)

local function ensureDevWorld()
	if workspace:FindFirstChild("DevBaseplate") == nil then
		local baseplate = Instance.new("Part")
		baseplate.Name = "DevBaseplate"
		baseplate.Anchored = true
		baseplate.Size = Vector3.new(800, 20, 800)
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

local function configurePersistence()
	if not RunService:IsStudio() then
		return
	end

	task.spawn(function()
		local timeoutAt = os.clock() + 10

		while ProfileStore.DataStoreState == "NotReady" and os.clock() < timeoutAt do
			task.wait(0.1)
		end

		if ProfileStore.DataStoreState == "Access" then
			ProfileStore.SetConstant("AUTO_SAVE_PERIOD", 60)
			Logger.info("Bootstrap", "Studio API Services enabled — profile data will persist between Play sessions")
			return
		end

		Logger.warn(
			"Bootstrap",
			"Studio API Services disabled — inventory, camp structures, and locale will NOT persist between Play sessions. "
				.. "Enable in Home > Game Settings > Security > 'Enable Studio Access to API Services', then restart Studio."
		)
	end)
end

ensureDevWorld()
WorldBootstrap.ensureDevWorld()

local services = ServerKernel.loadServices()

ServerKernel.initServices(services)
ServerKernel.startServices(services)
configurePersistence()

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
