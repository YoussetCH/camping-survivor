--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StructureModelUtils = require(ReplicatedStorage.Shared.Structures.StructureModelUtils)
local WorldConstants = require(ReplicatedStorage.Shared.Constants.WorldConstants)

export type NodeVisualArchetype = "tree_small" | "berry_bush" | "stone_pile" | "stick_pile" | "leaf_patch"

export type ResourceNodeModelFactoryModule = {
	build: (archetype: NodeVisualArchetype, groundPosition: Vector3) -> Model,
	setDepletedVisual: (container: Instance, depleted: boolean) -> (),
}

local LEAF_GREEN = Color3.fromRGB(72, 128, 58)
local LEAF_LIGHT = Color3.fromRGB(96, 152, 72)
local LEAF_DARK = Color3.fromRGB(58, 102, 48)
local BERRY_RED = Color3.fromRGB(190, 45, 55)
local STICK_BROWN = Color3.fromRGB(118, 86, 52)

local ResourceNodeModelFactory = {}

local function weld(part: BasePart, root: BasePart)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = root
	weldConstraint.Part1 = part
	weldConstraint.Parent = part
end

local function addPart(
	model: Model,
	root: BasePart,
	name: string,
	size: Vector3,
	localCFrame: CFrame,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean,
	shape: Enum.PartType?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = canCollide
	part.CanQuery = true
	part.Shape = shape or Enum.PartType.Block
	part.CFrame = root.CFrame * localCFrame
	part:SetAttribute("_DefaultTransparency", part.Transparency)
	part.Parent = model
	weld(part, root)
	return part
end

local function addBall(
	model: Model,
	root: BasePart,
	name: string,
	diameter: number,
	localCFrame: CFrame,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean
): Part
	return addPart(
		model,
		root,
		name,
		Vector3.new(diameter, diameter, diameter),
		localCFrame,
		color,
		material,
		canCollide,
		Enum.PartType.Ball
	)
end

local function buildTreeSmall(groundPosition: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "tree_small"

	local trunkHeight = 6
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(1.4, trunkHeight, 1.4)
	trunk.Color = StructureModelUtils.WOOD_MID
	trunk.Material = Enum.Material.Wood
	trunk.Anchored = true
	trunk.CanCollide = true
	trunk.CanQuery = true
	trunk.CFrame = CFrame.new(groundPosition + Vector3.new(0, trunkHeight / 2, 0))
	trunk:SetAttribute("_DefaultTransparency", 0)
	trunk.Parent = model
	model.PrimaryPart = trunk

	addBall(model, trunk, "CanopyCenter", 5.5, CFrame.new(0, trunkHeight / 2 + 1.8, 0), LEAF_GREEN, Enum.Material.Grass, false)
	addBall(model, trunk, "CanopyLeft", 4.2, CFrame.new(-1.6, trunkHeight / 2 + 1.2, 0.8), LEAF_LIGHT, Enum.Material.LeafyGrass, false)
	addBall(model, trunk, "CanopyRight", 4, CFrame.new(1.5, trunkHeight / 2 + 1.4, -0.6), LEAF_GREEN, Enum.Material.Grass, false)
	addPart(
		model,
		trunk,
		"RootFlare",
		Vector3.new(2.2, 0.8, 2.2),
		CFrame.new(0, -trunkHeight / 2 + 0.2, 0),
		StructureModelUtils.WOOD_DARK,
		Enum.Material.Wood,
		false
	)

	return model
end

local function buildBerryBush(groundPosition: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "berry_bush"

	local root = Instance.new("Part")
	root.Name = "BushBase"
	root.Size = Vector3.new(3.6, 1.2, 3.6)
	root.Color = LEAF_DARK
	root.Material = Enum.Material.Grass
	root.Anchored = true
	root.CanCollide = true
	root.CanQuery = true
	root.CFrame = CFrame.new(groundPosition + Vector3.new(0, 0.6, 0))
	root:SetAttribute("_DefaultTransparency", 0)
	root.Parent = model
	model.PrimaryPart = root

	addBall(model, root, "FoliageBack", 3.8, CFrame.new(0, 1.1, -0.2), LEAF_GREEN, Enum.Material.LeafyGrass, false)
	addBall(model, root, "FoliageFront", 3.4, CFrame.new(0.2, 1.3, 0.5), LEAF_LIGHT, Enum.Material.Grass, false)
	addBall(model, root, "FoliageSide", 2.8, CFrame.new(-1.1, 0.9, 0.3), LEAF_GREEN, Enum.Material.LeafyGrass, false)

	local berryOffsets = {
		CFrame.new(0.8, 1.5, 0.6),
		CFrame.new(-0.6, 1.4, 0.9),
		CFrame.new(0.1, 1.7, -0.5),
		CFrame.new(-0.9, 1.2, -0.2),
		CFrame.new(0.5, 1.0, -0.8),
	}

	for index, offset in berryOffsets do
		addBall(model, root, `Berry{index}`, 0.55, offset, BERRY_RED, Enum.Material.SmoothPlastic, false)
	end

	return model
end

local function buildStonePile(groundPosition: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "stone_pile"

	local anchor = Instance.new("Part")
	anchor.Name = "StoneAnchor"
	anchor.Size = Vector3.new(2, 1, 2)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = true
	anchor.CFrame = CFrame.new(groundPosition + Vector3.new(0, 0.5, 0))
	anchor:SetAttribute("_DefaultTransparency", 1)
	anchor.Parent = model
	model.PrimaryPart = anchor

	local rocks = {
		{ size = Vector3.new(2.8, 1.6, 2.4), offset = CFrame.new(0, 0.4, 0) * CFrame.Angles(0, 0.4, 0.15), color = StructureModelUtils.STONE },
		{ size = Vector3.new(2.2, 1.4, 2), offset = CFrame.new(1.1, 0.2, 0.4) * CFrame.Angles(0.1, -0.5, -0.2), color = StructureModelUtils.STONE_LIGHT },
		{ size = Vector3.new(1.8, 1.2, 1.6), offset = CFrame.new(-0.9, 0.15, 0.5) * CFrame.Angles(-0.15, 0.35, 0.1), color = StructureModelUtils.STONE_DARK },
		{ size = Vector3.new(1.4, 0.9, 1.2), offset = CFrame.new(0.2, 0.95, -0.5) * CFrame.Angles(0.25, 0.1, 0.05), color = StructureModelUtils.STONE },
	}

	for index, rock in rocks do
		addPart(
			model,
			anchor,
			`Rock{index}`,
			rock.size,
			rock.offset,
			rock.color,
			Enum.Material.Slate,
			index == 1
		)
	end

	return model
end

local function buildStickPile(groundPosition: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "stick_pile"

	local anchor = Instance.new("Part")
	anchor.Name = "StickAnchor"
	anchor.Size = Vector3.new(3, 0.6, 3)
	anchor.Color = STICK_BROWN
	anchor.Material = Enum.Material.Wood
	anchor.Anchored = true
	anchor.CanCollide = true
	anchor.CanQuery = true
	anchor.CFrame = CFrame.new(groundPosition + Vector3.new(0, 0.3, 0))
	anchor:SetAttribute("_DefaultTransparency", 0)
	anchor.Parent = model
	model.PrimaryPart = anchor

	local stickAngles = {
		CFrame.Angles(0.15, 0.3, 0.45),
		CFrame.Angles(-0.2, -0.4, -0.35),
		CFrame.Angles(0.05, 0.8, 0.25),
		CFrame.Angles(-0.1, -0.9, 0.5),
		CFrame.Angles(0.25, 0.1, -0.4),
	}

	for index, angle in stickAngles do
		addPart(
			model,
			anchor,
			`Stick{index}`,
			Vector3.new(0.35, 0.35, 2.8),
			CFrame.new((index - 3) * 0.35, 0.35, 0) * angle,
			STICK_BROWN,
			Enum.Material.Wood,
			false
		)
	end

	return model
end

local function buildLeafPatch(groundPosition: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "leaf_patch"

	local root = Instance.new("Part")
	root.Name = "PatchBase"
	root.Size = Vector3.new(4, 0.35, 4)
	root.Color = LEAF_DARK
	root.Material = Enum.Material.Grass
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = true
	root.CFrame = CFrame.new(groundPosition + Vector3.new(0, 0.18, 0))
	root:SetAttribute("_DefaultTransparency", 0)
	root.Parent = model
	model.PrimaryPart = root

	local leafOffsets = {
		CFrame.new(0.8, 0.25, 0.4),
		CFrame.new(-0.7, 0.2, -0.5),
		CFrame.new(0.2, 0.3, -0.9),
		CFrame.new(-0.3, 0.22, 0.8),
	}

	for index, offset in leafOffsets do
		addPart(
			model,
			root,
			`Leaf{index}`,
			Vector3.new(1.2, 0.15, 1.4),
			offset * CFrame.Angles(0, index * 0.4, 0),
			LEAF_LIGHT,
			Enum.Material.LeafyGrass,
			false
		)
	end

	return model
end

local BUILDERS: { [NodeVisualArchetype]: (Vector3) -> Model } = {
	tree_small = buildTreeSmall,
	berry_bush = buildBerryBush,
	stone_pile = buildStonePile,
	stick_pile = buildStickPile,
	leaf_patch = buildLeafPatch,
}

function ResourceNodeModelFactory.build(archetype: NodeVisualArchetype, groundPosition: Vector3): Model
	local builder = BUILDERS[archetype]

	if builder == nil then
		error(`Unknown resource node archetype "{archetype}"`, 2)
	end

	return builder(groundPosition)
end

function ResourceNodeModelFactory.setDepletedVisual(container: Instance, depleted: boolean)
	container:SetAttribute(WorldConstants.NODE_DEPLETED_ATTRIBUTE, depleted)

	for _, descendant in container:GetDescendants() do
		if descendant:IsA("BasePart") then
			local defaultTransparency = descendant:GetAttribute("_DefaultTransparency")

			if type(defaultTransparency) ~= "number" then
				defaultTransparency = descendant.Transparency
				descendant:SetAttribute("_DefaultTransparency", defaultTransparency)
			end

			if depleted then
				descendant.Transparency = math.clamp(defaultTransparency + 0.55, 0, 1)
			else
				descendant.Transparency = defaultTransparency
			end
		end
	end

	local prompt = container:FindFirstChild("HarvestPrompt", true)

	if prompt ~= nil and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = not depleted
	end
end

return ResourceNodeModelFactory
