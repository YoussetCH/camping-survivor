--!strict

local FaunaTypes = require(script.Parent.Parent.Parent.Types.Fauna)

local WolfDefinition: FaunaTypes.FaunaSpeciesDefinition = {
	speciesId = "wolf",
	maxHp = 40,
	damage = 18,
	detectRangeStuds = 40,
	detectRangeNightStuds = 52,
	meleeRangeStuds = 12,
	attackCooldownSeconds = 2,
	attackWindupSeconds = 0.25,
	attackAnimationSeconds = 0.45,
	moveSpeedStuds = 14,
	statusOnHit = {
		{ id = "bleeding", chance = 0.6 },
	},
	drops = {
		{ itemId = "fiber", quantity = 1, chance = 0.5 },
	},
	ambush = false,
	aggressiveByDay = false,
}

return WolfDefinition
