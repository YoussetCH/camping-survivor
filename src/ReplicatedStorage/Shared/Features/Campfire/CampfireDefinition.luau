--!strict

local StructureTypes = require(script.Parent.Parent.Parent.Types.Structure)

export type StructureDefinition = StructureTypes.StructureDefinition

local definition: StructureDefinition = {
	id = "bp_campfire",
	gridWidth = 2,
	gridDepth = 2,
	maxHp = nil,
	station = "campfire",
	modelSize = Vector3.new(8, 4, 8),
	modelColor = Color3.fromRGB(180, 90, 40),
	recipeId = "recipe_campfire",
}

return definition
