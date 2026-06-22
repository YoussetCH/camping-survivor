--!strict

local RecipeTypes = require(script.Parent.Parent.Types.Recipe)

export type RecipesModule = {
	get: (id: string) -> RecipeTypes.RecipeDefinition?,
	getAll: () -> { RecipeTypes.RecipeDefinition },
	getIconItemId: (id: string) -> string?,
}

local definitions: { [string]: RecipeTypes.RecipeDefinition } = {
	recipe_sparks = {
		id = "recipe_sparks",
		nameKey = "recipe.recipe_sparks.name",
		unlockType = "tutorial",
		station = "hands",
		inputs = {
			{ itemId = "flint", quantity = 1 },
			{ itemId = "stick", quantity = 1 },
		},
		outputs = {
			{ itemId = "sparks", quantity = 1 },
		},
	},
	recipe_tinder = {
		id = "recipe_tinder",
		nameKey = "recipe.recipe_tinder.name",
		unlockType = "tutorial",
		station = "hands",
		inputs = {
			{ itemId = "leaf", quantity = 2 },
			{ itemId = "fiber", quantity = 1 },
		},
		outputs = {
			{ itemId = "tinder", quantity = 1 },
		},
	},
	recipe_bandage = {
		id = "recipe_bandage",
		nameKey = "recipe.recipe_bandage.name",
		unlockType = "tutorial",
		station = "hands",
		inputs = {
			{ itemId = "leaf", quantity = 2 },
			{ itemId = "fiber", quantity = 1 },
		},
		outputs = {
			{ itemId = "bandage", quantity = 2 },
		},
	},
	recipe_campfire = {
		id = "recipe_campfire",
		nameKey = "recipe.recipe_campfire.name",
		unlockType = "tutorial",
		station = "hands",
		inputs = {
			{ itemId = "tinder", quantity = 1 },
			{ itemId = "sparks", quantity = 1 },
			{ itemId = "wood", quantity = 3 },
		},
		outputs = {
			{ itemId = "bp_campfire", quantity = 1 },
		},
	},
	recipe_craft_table = {
		id = "recipe_craft_table",
		nameKey = "recipe.recipe_craft_table.name",
		unlockType = "tutorial",
		station = "hands",
		inputs = {
			{ itemId = "wood", quantity = 4 },
			{ itemId = "stone", quantity = 2 },
		},
		outputs = {
			{ itemId = "bp_craft_table", quantity = 1 },
		},
	},
	recipe_chest = {
		id = "recipe_chest",
		nameKey = "recipe.recipe_chest.name",
		unlockType = "tutorial",
		station = "craft_table",
		inputs = {
			{ itemId = "wood", quantity = 6 },
			{ itemId = "rope", quantity = 1 },
		},
		outputs = {
			{ itemId = "bp_chest", quantity = 1 },
		},
	},
}

local Recipes: RecipesModule = {}

function Recipes.get(id: string): RecipeTypes.RecipeDefinition?
	return definitions[id]
end

function Recipes.getAll(): { RecipeTypes.RecipeDefinition }
	local allRecipes: { RecipeTypes.RecipeDefinition } = {}

	for _, recipe in definitions do
		table.insert(allRecipes, recipe)
	end

	return allRecipes
end

function Recipes.getIconItemId(id: string): string?
	local recipe = definitions[id]

	if recipe == nil or #recipe.outputs == 0 then
		return nil
	end

	return recipe.outputs[1].itemId
end

return Recipes
