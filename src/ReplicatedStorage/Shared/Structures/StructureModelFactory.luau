--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Shared.Features.FeatureModelBootstrap)
local StructureModelRegistry = require(ReplicatedStorage.Shared.Features.StructureModelRegistry)
local StructuresConstants = require(ReplicatedStorage.Shared.Constants.StructuresConstants)
local StructureModelUtils = require(ReplicatedStorage.Shared.Structures.StructureModelUtils)

export type BuildOptions = {
	ghost: boolean?,
}

export type StructureModelFactoryModule = {
	MODEL_VERSION: number,
	build: (blueprintId: string, options: BuildOptions?) -> Model?,
	setGhostVisible: (model: Model, visible: boolean) -> (),
}

local MODEL_VERSION = 3

require(ReplicatedStorage.Shared.Features.FeatureModelBootstrap)

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
	local builder = StructureModelRegistry.get(blueprintId)

	if builder ~= nil then
		builder({
			model = model,
			root = root,
			ghost = ghost,
		})
	else
		StructureModelUtils.addPart(
			model,
			root,
			"Fallback",
			definition.modelSize,
			Vector3.new(0, 0, 0),
			definition.modelColor,
			Enum.Material.Wood,
			not ghost
		)
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
