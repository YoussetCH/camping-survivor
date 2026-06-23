--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StructureModelRegistry = require(ReplicatedStorage.Shared.Features.StructureModelRegistry)
local StructureModelUtils = require(ReplicatedStorage.Shared.Structures.StructureModelUtils)

local METAL = StructureModelUtils.METAL
local WOOD_DARK = StructureModelUtils.WOOD_DARK
local WOOD_LIGHT = StructureModelUtils.WOOD_LIGHT
local WOOD_MID = StructureModelUtils.WOOD_MID
local addPart = StructureModelUtils.addPart

local function buildCraftTable(ctx: StructureModelRegistry.ModelBuildContext)
	local model = ctx.model
	local root = ctx.root
	local ghost = ctx.ghost
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

StructureModelRegistry.register("bp_craft_table", buildCraftTable)

return {
	build = buildCraftTable,
}
