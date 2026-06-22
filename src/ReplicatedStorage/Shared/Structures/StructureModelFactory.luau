--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StructuresConstants = require(ReplicatedStorage.Shared.Constants.StructuresConstants)
local CampConstants = require(ReplicatedStorage.Shared.Constants.CampConstants)

export type BuildOptions = {
	ghost: boolean?,
}

export type StructureModelFactoryModule = {
	MODEL_VERSION: number,
	build: (blueprintId: string, options: BuildOptions?) -> Model?,
	setGhostVisible: (model: Model, visible: boolean) -> (),
}

local MODEL_VERSION = 3

local WOOD_DARK = Color3.fromRGB(101, 67, 33)
local WOOD_MID = Color3.fromRGB(130, 86, 42)
local WOOD_LIGHT = Color3.fromRGB(158, 110, 58)
local WOOD_CHARRED = Color3.fromRGB(42, 34, 30)
local STONE = Color3.fromRGB(96, 92, 86)
local STONE_DARK = Color3.fromRGB(72, 68, 64)
local STONE_LIGHT = Color3.fromRGB(118, 112, 104)
local METAL = Color3.fromRGB(118, 118, 124)
local ASH = Color3.fromRGB(38, 34, 32)
local EMBER = Color3.fromRGB(255, 110, 35)

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
	offset: Vector3,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = canCollide
	part.CanQuery = true
	part.CFrame = root.CFrame * CFrame.new(offset)
	part.Parent = model
	weld(part, root)
	return part
end

local function addPartAt(
	model: Model,
	root: BasePart,
	name: string,
	size: Vector3,
	localCFrame: CFrame,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = canCollide
	part.CanQuery = true
	part.CFrame = root.CFrame * localCFrame
	part.Parent = model
	weld(part, root)
	return part
end

local function addLog(
	model: Model,
	root: BasePart,
	name: string,
	size: Vector3,
	localCFrame: CFrame,
	canCollide: boolean
)
	addPartAt(model, root, name, size, localCFrame, WOOD_MID, Enum.Material.Wood, canCollide)

	local charLength = math.min(size.Z * 0.35, 1.1)
	local charSize = Vector3.new(size.X * 1.05, size.Y * 1.05, charLength)
	local charOffset = CFrame.new(0, 0, size.Z / 2 - charLength / 2)
	addPartAt(model, root, `{name}_Char`, charSize, localCFrame * charOffset, WOOD_CHARRED, Enum.Material.Slate, false)
end

local function attachCampfireEffects(anchor: BasePart)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = true

	local fire = Instance.new("Fire")
	fire.Name = "CampfireFlame"
	fire.Size = 5
	fire.Heat = 8
	fire.TimeScale = 0.9
	fire.Color = Color3.fromRGB(255, 95, 25)
	fire.SecondaryColor = Color3.fromRGB(255, 190, 70)
	fire.Parent = anchor

	local light = Instance.new("PointLight")
	light.Name = "CampfireLight"
	light.Color = Color3.fromRGB(255, 145, 55)
	light.Brightness = 1.8
	light.Range = 18
	light.Shadows = true
	light.Parent = anchor

	local embers = Instance.new("ParticleEmitter")
	embers.Name = "CampfireEmbers"
	embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	embers.Rate = 18
	embers.Lifetime = NumberRange.new(0.4, 1.1)
	embers.Speed = NumberRange.new(3, 7)
	embers.SpreadAngle = Vector2.new(35, 35)
	embers.Acceleration = Vector3.new(0, 2, 0)
	embers.Drag = 1.5
	embers.LightEmission = 1
	embers.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 80)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 40, 20)),
	})
	embers.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.22),
		NumberSequenceKeypoint.new(1, 0),
	})
	embers.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	embers.Parent = anchor

	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "CampfireSmoke"
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Rate = 10
	smoke.Lifetime = NumberRange.new(2.5, 4.5)
	smoke.Speed = NumberRange.new(1.5, 3.5)
	smoke.SpreadAngle = Vector2.new(18, 18)
	smoke.Acceleration = Vector3.new(0, 1.5, 0)
	smoke.RotSpeed = NumberRange.new(-25, 25)
	smoke.LightEmission = 0.15
	smoke.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 90, 90)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 160, 160)),
	})
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 2.4),
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	smoke.Parent = anchor
end

local function addMeshPart(
	model: Model,
	root: BasePart,
	name: string,
	size: Vector3,
	offset: Vector3,
	color: Color3,
	material: Enum.Material,
	meshType: Enum.MeshType,
	canCollide: boolean
): Part
	local part = addPart(model, root, name, size, offset, color, material, canCollide)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = meshType
	mesh.Parent = part
	return part
end

local function createRoot(model: Model, definition: StructuresConstants.StructureDefinition): Part
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = definition.modelSize
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = true
	root.CanQuery = true
	root.CFrame = CFrame.new(0, 0, 0)
	root.Parent = model
	model.PrimaryPart = root
	return root
end

local function buildCampfire(model: Model, root: BasePart, ghost: boolean)
	local baseY = -root.Size.Y / 2 + 0.12
	local canCollide = not ghost

	addPartAt(
		model,
		root,
		"AshBed",
		Vector3.new(3.4, 0.12, 3.4),
		CFrame.new(0, baseY + 0.06, 0),
		ASH,
		Enum.Material.Ground,
		false
	)

	local rockCount = 12
	for index = 0, rockCount - 1 do
		local angle = (index / rockCount) * math.pi * 2
		local radius = 2.15 + (index % 3) * 0.08
		local rockHeight = 0.45 + (index % 4) * 0.12
		local rockWidth = 0.85 + (index % 2) * 0.25
		local rockDepth = 1.05 + (index % 3) * 0.2
		local rockColor = if index % 2 == 0 then STONE else if index % 3 == 0 then STONE_DARK else STONE_LIGHT

		addPartAt(
			model,
			root,
			`Rock_{index}`,
			Vector3.new(rockWidth, rockHeight, rockDepth),
			CFrame.new(math.cos(angle) * radius, baseY + rockHeight / 2 + 0.04, math.sin(angle) * radius)
				* CFrame.Angles(math.rad((index % 5) - 2), angle + math.rad(index * 11), math.rad((index % 4) - 1)),
			rockColor,
			Enum.Material.Rock,
			canCollide
		)
	end

	local logLayout = {
		{ angle = 35, length = 3.4, offset = 0.55 },
		{ angle = -35, length = 3.4, offset = 0.55 },
		{ angle = 145, length = 3.2, offset = 0.5 },
		{ angle = -145, length = 3.2, offset = 0.5 },
	}

	for index, layout in logLayout do
		local angle = math.rad(layout.angle)
		local logSize = Vector3.new(0.65, 0.65, layout.length)
		local offset = Vector3.new(math.cos(angle) * layout.offset, baseY + 0.38, math.sin(angle) * layout.offset)
		addLog(
			model,
			root,
			`Log_{index}`,
			logSize,
			CFrame.new(offset) * CFrame.Angles(0, angle, math.rad(14)),
			canCollide
		)
	end

	for index = 0, 3 do
		local angle = math.rad(index * 90 + 20)
		local kindlingSize = Vector3.new(0.25, 0.25, 1.2)
		local offset = Vector3.new(math.cos(angle) * 0.35, baseY + 0.42, math.sin(angle) * 0.35)
		addPartAt(
			model,
			root,
			`Kindling_{index}`,
			kindlingSize,
			CFrame.new(offset) * CFrame.Angles(math.rad(18), angle, math.rad(8)),
			WOOD_CHARRED,
			Enum.Material.Wood,
			false
		)
	end

	local emberGlow = addPartAt(
		model,
		root,
		"EmberGlow",
		Vector3.new(1.2, 0.35, 1.2),
		CFrame.new(0, baseY + 0.28, 0),
		EMBER,
		Enum.Material.Neon,
		false
	)
	emberGlow.Transparency = if ghost then 0.55 else 0.35

	local effectAnchor = addPartAt(
		model,
		root,
		"FireAnchor",
		Vector3.new(0.6, 0.6, 0.6),
		CFrame.new(0, baseY + 0.72, 0),
		EMBER,
		Enum.Material.SmoothPlastic,
		false
	)

	if ghost then
		effectAnchor.Transparency = 1
	else
		attachCampfireEffects(effectAnchor)
	end
end

local function buildChest(model: Model, root: BasePart, ghost: boolean)
	local baseY = -root.Size.Y / 2
	local bodyHeight = 2.2

	addPart(
		model,
		root,
		"Body",
		Vector3.new(5, bodyHeight, 3.4),
		Vector3.new(0, baseY + bodyHeight / 2, 0),
		WOOD_DARK,
		Enum.Material.Wood,
		not ghost
	)

	addPart(
		model,
		root,
		"Lid",
		Vector3.new(5.2, 0.45, 3.6),
		Vector3.new(0, baseY + bodyHeight + 0.2, -0.05),
		WOOD_LIGHT,
		Enum.Material.Wood,
		false
	)

	addPart(model, root, "BandFront", Vector3.new(5.3, 0.25, 0.2), Vector3.new(0, baseY + 1.1, 1.75), METAL, Enum.Material.Metal, false)
	addPart(model, root, "BandBack", Vector3.new(5.3, 0.25, 0.2), Vector3.new(0, baseY + 1.1, -1.75), METAL, Enum.Material.Metal, false)
	addPart(model, root, "LockPlate", Vector3.new(0.8, 0.9, 0.15), Vector3.new(0, baseY + 1.35, 1.82), METAL, Enum.Material.Metal, false)

	if not ghost then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ChestPrompt"
		prompt.ActionText = "Open"
		prompt.ObjectText = "Chest"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = CampConstants.CHEST_INTERACT_RANGE
		prompt.RequiresLineOfSight = false
		prompt.Parent = root
	end
end

local function buildCraftTable(model: Model, root: BasePart, ghost: boolean)
	local baseY = -root.Size.Y / 2
	local legHeight = 2.2
	local topThickness = 0.45
	local topY = baseY + legHeight + topThickness / 2

	addPart(
		model,
		root,
		"TableTop",
		Vector3.new(11.5, topThickness, 7.5),
		Vector3.new(0, topY, 0),
		WOOD_MID,
		Enum.Material.WoodPlanks,
		not ghost
	)

	local legOffsetX = 5.2
	local legOffsetZ = 3.2

	for index, offset in {
		Vector3.new(-legOffsetX, baseY + legHeight / 2, -legOffsetZ),
		Vector3.new(legOffsetX, baseY + legHeight / 2, -legOffsetZ),
		Vector3.new(-legOffsetX, baseY + legHeight / 2, legOffsetZ),
		Vector3.new(legOffsetX, baseY + legHeight / 2, legOffsetZ),
	} do
		addPart(model, root, `Leg_{index}`, Vector3.new(0.75, legHeight, 0.75), offset, WOOD_DARK, Enum.Material.Wood, not ghost)
	end

	addPart(model, root, "ViseBase", Vector3.new(1.4, 0.35, 1.2), Vector3.new(3.8, topY + 0.35, 2.2), METAL, Enum.Material.Metal, false)
	addPart(model, root, "ViseJaw", Vector3.new(0.9, 0.55, 0.55), Vector3.new(3.8, topY + 0.65, 2.85), METAL, Enum.Material.Metal, false)
	addPart(model, root, "HammerHandle", Vector3.new(0.35, 0.35, 2.2), Vector3.new(-3.5, topY + 0.35, -1.8), WOOD_LIGHT, Enum.Material.Wood, false)
	addPart(model, root, "HammerHead", Vector3.new(0.9, 0.55, 0.55), Vector3.new(-3.5, topY + 0.35, -0.75), METAL, Enum.Material.Metal, false)
end

local function applyGhostStyle(model: Model, visible: boolean)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local isRoot = descendant.Name == "Root"

			if isRoot then
				descendant.Transparency = 1
				descendant.CanCollide = false
				continue
			end

			descendant.Material = Enum.Material.Neon
			descendant.CanCollide = false
			descendant.Transparency = if visible then 0.5 else 1
		elseif descendant:IsA("Fire") then
			descendant.Enabled = false
		elseif descendant:IsA("ParticleEmitter") then
			descendant.Enabled = false
		elseif descendant:IsA("PointLight") then
			descendant.Enabled = false
		end
	end
end

local function buildModel(blueprintId: string, options: BuildOptions?): Model?
	local definition = StructuresConstants.get(blueprintId)

	if definition == nil then
		return nil
	end

	local ghost = options ~= nil and options.ghost == true
	local model = Instance.new("Model")
	model.Name = blueprintId
	model:SetAttribute("ModelVersion", MODEL_VERSION)

	local root = createRoot(model, definition)

	if blueprintId == "bp_campfire" then
		buildCampfire(model, root, ghost)
	elseif blueprintId == "bp_chest" then
		buildChest(model, root, ghost)
	elseif blueprintId == "bp_craft_table" then
		buildCraftTable(model, root, ghost)
	else
		addPart(model, root, "Fallback", definition.modelSize, Vector3.new(0, 0, 0), definition.modelColor, Enum.Material.Wood, not ghost)
		root.Transparency = if ghost then 0.5 else 0
	end

	if ghost then
		applyGhostStyle(model, true)
	end

	return model
end

local StructureModelFactory: StructureModelFactoryModule = {
	MODEL_VERSION = MODEL_VERSION,
	build = buildModel,
	setGhostVisible = applyGhostStyle,
}

return StructureModelFactory
