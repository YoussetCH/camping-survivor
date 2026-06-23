--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CampConstants = require(ReplicatedStorage.Shared.Constants.CampConstants)
local StructureModelRegistry = require(ReplicatedStorage.Shared.Features.StructureModelRegistry)
local StructureModelUtils = require(ReplicatedStorage.Shared.Structures.StructureModelUtils)

local METAL = StructureModelUtils.METAL
local WOOD_DARK = StructureModelUtils.WOOD_DARK
local WOOD_LIGHT = StructureModelUtils.WOOD_LIGHT
local addPart = StructureModelUtils.addPart

local function buildChest(ctx: StructureModelRegistry.ModelBuildContext)
	local model = ctx.model
	local root = ctx.root
	local ghost = ctx.ghost
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

StructureModelRegistry.register("bp_chest", buildChest)

return {
	build = buildChest,
}
