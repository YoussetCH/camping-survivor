--!strict

local FaunaTypes = require(script.Parent.Parent.Parent.Types.Fauna)

local SnakeDefinition: FaunaTypes.FaunaSpeciesDefinition = {
	speciesId = "snake",
	maxHp = 15,
	damage = 8,
	detectRangeStuds = 25,
	meleeRangeStuds = 8,
	attackCooldownSeconds = 1.5,
	moveSpeedStuds = 10,
	statusOnHit = {
		{ id = "poison", chance = 1 },
	},
	drops = {
		{ itemId = "herb_common", quantity = 1, chance = 0.3 },
	},
	ambush = true,
	aggressiveByDay = true,
}

return SnakeDefinition
