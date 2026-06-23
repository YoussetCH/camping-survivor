--!strict

local StructureTypes = require(script.Parent.Parent.Parent.Types.Structure)

export type StructureDefinition = StructureTypes.StructureDefinition

local definition: StructureDefinition = {
	id = "bp_chest",
	gridWidth = 2,
	gridDepth = 2,
	maxHp = 80,
	station = nil,
	modelSize = Vector3.new(6, 3.5, 6),
	modelColor = Color3.fromRGB(120, 80, 40),
	recipeId = "recipe_chest",
}

return definition
