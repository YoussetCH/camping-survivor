--!strict

local StructureTypes = require(script.Parent.Parent.Parent.Types.Structure)

export type StructureDefinition = StructureTypes.StructureDefinition

local definition: StructureDefinition = {
	id = "bp_craft_table",
	gridWidth = 3,
	gridDepth = 2,
	maxHp = 50,
	station = "craft_table",
	modelSize = Vector3.new(12, 3.2, 8),
	modelColor = Color3.fromRGB(100, 100, 100),
	recipeId = "recipe_craft_table",
}

return definition
