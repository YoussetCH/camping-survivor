--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Constants.Items)
local StructureModelUtils = require(ReplicatedStorage.Shared.Structures.StructureModelUtils)

export type ToolVisualBuildResult = {
	model: Model,
	gripOffset: CFrame,
}

export type EquippedToolModelFactoryModule = {
	build: (toolItemId: string) -> ToolVisualBuildResult?,
	hasVisual: (toolItemId: string) -> boolean,
}

local EquippedToolModelFactory = {}

local DEFAULT_GRIP_OFFSET = CFrame.new(0, -0.22, 0) * CFrame.Angles(math.rad(90), 0, 0)

local function configureVisualPart(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Massless = true
end

local function weldTo(part0: BasePart, part1: BasePart)
	local weld = Instance.new("Weld")
	weld.Name = `{part0.Name}_To_{part1.Name}`
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = part0.CFrame:ToObjectSpace(part1.CFrame)
	weld.C1 = CFrame.new()
	weld.Parent = part1
end

local function createPart(
	model: Model,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.CFrame = cframe
	configureVisualPart(part)
	part.Parent = model
	return part
end

local function createWedge(
	model: Model,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
): WedgePart
	local part = Instance.new("WedgePart")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.CFrame = cframe
	configureVisualPart(part)
	part.Parent = model
	return part
end

local function buildStoneAxe(): ToolVisualBuildResult
	local model = Instance.new("Model")
	model.Name = "EquippedTool_stone_axe"

	local grip = createPart(
		model,
		"Grip",
		Vector3.new(0.1, 0.1, 0.1),
		CFrame.new(),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic
	)
	grip.Transparency = 1
	model.PrimaryPart = grip

	local handle = createPart(
		model,
		"Handle",
		Vector3.new(0.22, 0.22, 2.15),
		CFrame.new(0, 0, -0.55),
		StructureModelUtils.WOOD_MID,
		Enum.Material.Wood
	)

	local headCenter = Vector3.new(0, 0.18, -1.42)

	local poll = createPart(
		model,
		"Poll",
		Vector3.new(0.46, 0.42, 0.72),
		CFrame.new(headCenter),
		StructureModelUtils.STONE,
		Enum.Material.Slate
	)

	local blade = createWedge(
		model,
		"Blade",
		Vector3.new(0.3, 0.68, 0.52),
		CFrame.new(headCenter + Vector3.new(0, 0, -0.42)) * CFrame.Angles(0, math.rad(180), 0),
		StructureModelUtils.STONE_LIGHT,
		Enum.Material.Slate
	)

	local pollBack = createPart(
		model,
		"PollBack",
		Vector3.new(0.32, 0.34, 0.28),
		CFrame.new(headCenter + Vector3.new(0, 0, 0.38)),
		StructureModelUtils.STONE_DARK,
		Enum.Material.Slate
	)

	local bindUpper = createPart(
		model,
		"BindUpper",
		Vector3.new(0.3, 0.12, 0.3),
		CFrame.new(0, 0.04, -0.92),
		StructureModelUtils.WOOD_DARK,
		Enum.Material.Fabric
	)

	local bindLower = createPart(
		model,
		"BindLower",
		Vector3.new(0.32, 0.1, 0.32),
		CFrame.new(0, -0.04, -0.78),
		StructureModelUtils.WOOD_DARK,
		Enum.Material.Fabric
	)

	weldTo(grip, handle)
	weldTo(grip, poll)
	weldTo(grip, blade)
	weldTo(grip, pollBack)
	weldTo(grip, bindUpper)
	weldTo(grip, bindLower)

	return {
		model = model,
		gripOffset = DEFAULT_GRIP_OFFSET,
	}
end

local BUILDERS: { [string]: () -> ToolVisualBuildResult } = {
	stone_axe = buildStoneAxe,
}

function EquippedToolModelFactory.hasVisual(toolItemId: string): boolean
	if BUILDERS[toolItemId] ~= nil then
		return true
	end

	local definition = Items.get(toolItemId)

	return definition ~= nil and definition.category == "tool"
end

function EquippedToolModelFactory.build(toolItemId: string): ToolVisualBuildResult?
	local builder = BUILDERS[toolItemId]

	if builder ~= nil then
		return builder()
	end

	local definition = Items.get(toolItemId)

	if definition == nil or definition.category ~= "tool" then
		return nil
	end

	local model = Instance.new("Model")
	model.Name = `EquippedTool_{toolItemId}`

	local grip = createPart(
		model,
		"Grip",
		Vector3.new(0.1, 0.1, 0.1),
		CFrame.new(),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic
	)
	grip.Transparency = 1
	model.PrimaryPart = grip

	local handle = createPart(
		model,
		"Handle",
		Vector3.new(0.26, 0.26, 1.65),
		CFrame.new(0, 0, -0.45),
		StructureModelUtils.WOOD_MID,
		Enum.Material.Wood
	)

	weldTo(grip, handle)

	return {
		model = model,
		gripOffset = DEFAULT_GRIP_OFFSET,
	}
end

return EquippedToolModelFactory
