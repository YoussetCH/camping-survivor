--!strict

local LocaleTypes = require(script.Parent.Parent.Parent.Types.Locale)

local es: LocaleTypes.LocaleTable = {
	["ui.hud.health"] = "HP",
	["ui.hud.hunger"] = "Comida",
	["ui.hud.thirst"] = "Sed",
	["ui.hud.temperature"] = "Temp",

	["alert.health"] = "¡Salud baja!",
	["alert.hunger"] = "¡Hambre!",
	["alert.thirst"] = "¡Sed!",
	["alert.temperature_low"] = "¡Hace frío!",
	["alert.temperature_high"] = "¡Calor extremo!",

	["ui.settings.language"] = "Idioma",
	["ui.settings.language_en"] = "English",
	["ui.settings.language_es"] = "Español",

	["item.stick.name"] = "Palo",
	["item.stone.name"] = "Piedra",
	["item.flint.name"] = "Pedernal",
	["item.leaf.name"] = "Hojas",
	["item.fiber.name"] = "Fibra",
	["item.tinder.name"] = "Yesca",
	["item.berry.name"] = "Bayas",
	["item.bandage.name"] = "Vendaje",
	["item.sparks.name"] = "Chispas",
	["item.wood.name"] = "Madera",

	["recipe.recipe_sparks.name"] = "Chispas",
	["recipe.recipe_tinder.name"] = "Yesca",
	["recipe.recipe_bandage.name"] = "Vendaje",
	["recipe.recipe_campfire.name"] = "Fogata",
}

return es
