--!strict

export type StructureDefinition = {
	id: string,
	gridWidth: number,
	gridDepth: number,
	maxHp: number?,
	station: string?,
	modelSize: Vector3,
	modelColor: Color3,
	recipeId: string?,
}

export type StructuresConstantsModule = {
	get: (blueprintId: string) -> StructureDefinition?,
	getAll: () -> { StructureDefinition },
	isBlueprint: (itemId: string) -> boolean,
}

local definitions: { [string]: StructureDefinition } = {
	bp_campfire = {
		id = "bp_campfire",
		gridWidth = 2,
		gridDepth = 2,
		maxHp = nil,
		station = "campfire",
		modelSize = Vector3.new(8, 4, 8),
		modelColor = Color3.fromRGB(180, 90, 40),
		recipeId = "recipe_campfire",
	},
	bp_chest = {
		id = "bp_chest",
		gridWidth = 2,
		gridDepth = 2,
		maxHp = 80,
		station = nil,
		modelSize = Vector3.new(6, 3.5, 6),
		modelColor = Color3.fromRGB(120, 80, 40),
		recipeId = "recipe_chest",
	},
	bp_craft_table = {
		id = "bp_craft_table",
		gridWidth = 3,
		gridDepth = 2,
		maxHp = 50,
		station = "craft_table",
		modelSize = Vector3.new(12, 3.2, 8),
		modelColor = Color3.fromRGB(100, 100, 100),
		recipeId = "recipe_craft_table",
	},
}

local StructuresConstants: StructuresConstantsModule = {
	get = function(blueprintId: string): StructureDefinition?
		return definitions[blueprintId]
	end,
	getAll = function(): { StructureDefinition }
		local all: { StructureDefinition } = {}

		for _, definition in definitions do
			table.insert(all, definition)
		end

		return all
	end,
	isBlueprint = function(itemId: string): boolean
		return definitions[itemId] ~= nil
	end,
}

return StructuresConstants
