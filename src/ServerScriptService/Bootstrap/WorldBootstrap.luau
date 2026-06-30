--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local ResourceNodeModelFactory = require(ReplicatedStorage.Shared.World.ResourceNodeModelFactory)
local FaunaConstants = require(ReplicatedStorage.Shared.Constants.FaunaConstants)
local HelperConstants = require(ReplicatedStorage.Shared.Constants.HelperConstants)
local WorldConstants = require(ReplicatedStorage.Shared.Constants.WorldConstants)

export type WorldBootstrapModule = {
	ensureDevWorld: () -> (),
	ensureFaunaSpawns: () -> (),
	ensureHelperSpawns: () -> (),
}

local WorldBootstrap = {}

local function getWorldFolder(): Folder
	local existing = workspace:FindFirstChild("World")

	if existing ~= nil and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = "World"
	folder.Parent = workspace
	return folder
end

local function getSubfolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)

	if existing ~= nil and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function createBiomeZone(
	parent: Folder,
	name: string,
	biomeId: string,
	position: Vector3,
	size: Vector3,
	color: Color3
): BasePart
	local existing = parent:FindFirstChild(name)

	if existing ~= nil and existing:IsA("BasePart") then
		existing.Position = position
		existing.Size = size
		existing:SetAttribute(WorldConstants.BIOME_ID_ATTRIBUTE, biomeId)
		return existing
	end

	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 0.85
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = Enum.Material.Grass
	part:SetAttribute(WorldConstants.BIOME_ID_ATTRIBUTE, biomeId)
	CollectionService:AddTag(part, WorldConstants.BIOME_ZONE_TAG)
	part.Parent = parent

	return part
end

local function attachHarvestPrompt(interactPart: BasePart, nodeType: string)
	local prompt = interactPart:FindFirstChild("HarvestPrompt")

	if prompt == nil or not prompt:IsA("ProximityPrompt") then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "HarvestPrompt"
		prompt.Parent = interactPart
	end

	prompt.ActionText = "Harvest"
	prompt.ObjectText = "Resource"
	prompt.MaxActivationDistance = WorldConstants.HARVEST_MAX_DISTANCE_STUDS
	prompt.HoldDuration = if nodeType == "chop" then 1.5 else 0.75
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
end

local function createResourceNode(
	parent: Folder,
	nodeId: string,
	archetype: ResourceNodeModelFactory.NodeVisualArchetype,
	nodeType: string,
	outputs: string,
	groundPosition: Vector3
): Model
	local existing = parent:FindFirstChild(nodeId)

	if existing ~= nil then
		if existing:IsA("Model") and existing.PrimaryPart ~= nil then
			return existing
		end

		existing:Destroy()
	end

	local model = ResourceNodeModelFactory.build(archetype, groundPosition)
	model.Name = nodeId
	model:SetAttribute(WorldConstants.NODE_ID_ATTRIBUTE, nodeId)
	model:SetAttribute(WorldConstants.NODE_TYPE_ATTRIBUTE, nodeType)
	model:SetAttribute(WorldConstants.NODE_OUTPUTS_ATTRIBUTE, outputs)
	model:SetAttribute(WorldConstants.NODE_DEPLETED_ATTRIBUTE, false)
	CollectionService:AddTag(model, WorldConstants.RESOURCE_NODE_TAG)

	local interactPart = model.PrimaryPart

	if interactPart == nil then
		error(`Resource node model "{nodeId}" is missing PrimaryPart`, 2)
	end

	attachHarvestPrompt(interactPart, nodeType)
	model.Parent = parent

	return model
end

function WorldBootstrap.ensureDevWorld()
	local worldFolder = getWorldFolder()
	local biomeZonesFolder = getSubfolder(worldFolder, "BiomeZones")
	local resourceNodesFolder = getSubfolder(worldFolder, "ResourceNodes")

	createBiomeZone(
		biomeZonesFolder,
		"forest_near",
		"forest_near",
		Vector3.new(102, -5, 64),
		Vector3.new(520, 20, 520),
		Color3.fromRGB(70, 130, 70)
	)

	createBiomeZone(
		biomeZonesFolder,
		"camp_hub",
		"camp_hub",
		Vector3.new(102, -5, 64),
		Vector3.new(240, 20, 140),
		Color3.fromRGB(110, 170, 110)
	)

	createBiomeZone(
		biomeZonesFolder,
		"forest_deep",
		"forest_deep",
		Vector3.new(280, -5, 50),
		Vector3.new(260, 20, 260),
		Color3.fromRGB(45, 95, 45)
	)

	local nodeDefinitions = {
		{ id = "berry_bush_01", archetype = "berry_bush", type = "gather", outputs = "berry:2-3", position = Vector3.new(260, 0, 64) },
		{ id = "berry_bush_02", archetype = "berry_bush", type = "gather", outputs = "berry:2-3", position = Vector3.new(260, 0, 110) },
		{ id = "stick_pile_01", archetype = "stick_pile", type = "gather", outputs = "stick:2", position = Vector3.new(-80, 0, 64) },
		{ id = "stone_pile_01", archetype = "stone_pile", type = "gather", outputs = "stone:2", position = Vector3.new(-80, 0, 110) },
		{ id = "leaf_patch_01", archetype = "leaf_patch", type = "gather", outputs = "leaf:2-3", position = Vector3.new(-80, 0, 20) },
		{ id = "tree_small_01", archetype = "tree_small", type = "chop", outputs = "wood:3,stick:1", position = Vector3.new(300, 0, 40) },
		{ id = "tree_small_02", archetype = "tree_small", type = "chop", outputs = "wood:3,stick:1", position = Vector3.new(-120, 0, 40) },
	}

	for _, nodeInfo in nodeDefinitions do
		createResourceNode(
			resourceNodesFolder,
			nodeInfo.id,
			nodeInfo.archetype,
			nodeInfo.type,
			nodeInfo.outputs,
			nodeInfo.position
		)
	end

	Logger.info("WorldBootstrap", `Dev world ready with {#nodeDefinitions} resource nodes`)
end

local function createFaunaSpawn(parent: Folder, name: string, speciesId: string, position: Vector3): BasePart
	local existing = parent:FindFirstChild(name)

	if existing ~= nil and existing:IsA("BasePart") then
		return existing
	end

	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(2, 1, 2)
	part.Position = position
	part:SetAttribute(FaunaConstants.SPAWN_SPECIES_ATTRIBUTE, speciesId)
	CollectionService:AddTag(part, FaunaConstants.FAUNA_SPAWN_TAG)
	part.Parent = parent

	return part
end

function WorldBootstrap.ensureFaunaSpawns()
	local worldFolder = getWorldFolder()
	local faunaSpawnsFolder = getSubfolder(worldFolder, "FaunaSpawns")
	getSubfolder(worldFolder, "Fauna")

	local spawnDefinitions = {
		{ name = "wolf_spawn_01", speciesId = "wolf", position = Vector3.new(280, 0, 80) },
		{ name = "wolf_spawn_02", speciesId = "wolf", position = Vector3.new(320, 0, 50) },
		{ name = "wolf_spawn_03", speciesId = "wolf", position = Vector3.new(-100, 0, 80) },
		{ name = "snake_spawn_01", speciesId = "snake", position = Vector3.new(240, 0, 20) },
		{ name = "snake_spawn_02", speciesId = "snake", position = Vector3.new(-60, 0, 20) },
	}

	for _, spawnInfo in spawnDefinitions do
		createFaunaSpawn(faunaSpawnsFolder, spawnInfo.name, spawnInfo.speciesId, spawnInfo.position)
	end

	Logger.info("WorldBootstrap", `Fauna spawns ready with {#spawnDefinitions} markers`)
end

local function createHelperSpawn(parent: Folder, name: string, helperTypeId: string, position: Vector3): BasePart
	local existing = parent:FindFirstChild(name)

	if existing ~= nil and existing:IsA("BasePart") then
		existing.Position = position
		existing:SetAttribute(HelperConstants.HELPER_TYPE_ATTRIBUTE, helperTypeId)
		return existing
	end

	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(2, 1, 2)
	part.Position = position
	part:SetAttribute(HelperConstants.HELPER_TYPE_ATTRIBUTE, helperTypeId)
	CollectionService:AddTag(part, HelperConstants.HELPER_SPAWN_TAG)
	part.Parent = parent

	return part
end

function WorldBootstrap.ensureHelperSpawns()
	local worldFolder = getWorldFolder()
	local helperSpawnsFolder = getSubfolder(worldFolder, "HelperSpawns")

	local spawnDefinitions = {
		{ name = "lumberjack_spawn_01", helperTypeId = "lumberjack", position = Vector3.new(295, 0, 38) },
	}

	for _, spawnInfo in spawnDefinitions do
		createHelperSpawn(helperSpawnsFolder, spawnInfo.name, spawnInfo.helperTypeId, spawnInfo.position)
	end

	Logger.info("WorldBootstrap", `Helper spawns ready with {#spawnDefinitions} markers`)
end

return WorldBootstrap
