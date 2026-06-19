--!strict

local LocaleTypes = require(script.Parent.Parent.Parent.Types.Locale)

local en: LocaleTypes.LocaleTable = {
	["ui.hud.health"] = "HP",
	["ui.hud.hunger"] = "Food",
	["ui.hud.thirst"] = "Thirst",
	["ui.hud.temperature"] = "Temp",

	["alert.health"] = "Low health!",
	["alert.hunger"] = "Hungry!",
	["alert.thirst"] = "Thirsty!",
	["alert.temperature_low"] = "Too cold!",
	["alert.temperature_high"] = "Too hot!",

	["ui.settings.language"] = "Language",
	["ui.settings.language_en"] = "English",
	["ui.settings.language_es"] = "Spanish",

	["item.stick.name"] = "Stick",
	["item.stone.name"] = "Stone",
	["item.flint.name"] = "Flint",
	["item.leaf.name"] = "Leaves",
	["item.fiber.name"] = "Fiber",
	["item.tinder.name"] = "Tinder",
	["item.berry.name"] = "Berries",
	["item.bandage.name"] = "Bandage",
	["item.sparks.name"] = "Sparks",
	["item.wood.name"] = "Wood",
	["item.stone_axe.name"] = "Stone Axe",
	["item.bp_campfire.name"] = "Campfire Blueprint",

	["ui.inventory.title"] = "Inventory",
	["ui.inventory.use"] = "Use",
	["ui.inventory.equip"] = "Equip",

	["ui.craft.title"] = "Crafting",
	["ui.craft.craft_button"] = "Craft",
	["ui.craft.select_recipe"] = "Select a recipe to see details.",
	["ui.craft.detail"] = "Inputs: {inputs}\nOutputs: {outputs}",

	["craft.success.generic"] = "Crafted successfully!",
	["craft.error.cooldown"] = "Wait before crafting again.",
	["craft.error.not_unlocked"] = "Recipe not unlocked yet.",
	["craft.error.wrong_station"] = "You need the right crafting station.",
	["craft.error.missing_items"] = "Missing required materials.",
	["craft.error.no_space"] = "Not enough inventory space.",
	["craft.error.select_recipe"] = "Select a recipe first.",

	["recipe.recipe_sparks.name"] = "Sparks",
	["recipe.recipe_tinder.name"] = "Tinder",
	["recipe.recipe_bandage.name"] = "Bandage",
	["recipe.recipe_campfire.name"] = "Campfire",
}

return en
