--!strict

local FaunaTypes = require(script.Parent.Parent.Parent.Types.Fauna)
local FaunaConstants = require(script.Parent.Parent.Parent.Constants.FaunaConstants)

local SnakeDefinition: FaunaTypes.FaunaSpeciesDefinition = {
	speciesId = "snake",
	maxHp = 15,
	damage = 8,
	detectRangeStuds = 25,
	meleeRangeStuds = 8,
	attackCooldownSeconds = 1.5,
	attackWindupSeconds = FaunaConstants.SNAKE_ATTACK_WINDUP_SECONDS,
	attackAnimationSeconds = FaunaConstants.SNAKE_ATTACK_TOTAL_SECONDS,
	moveSpeedStuds = 10,
	statusOnHit = {
		{ id = "poison", chance = 1 },
	},
	drops = {
		{ itemId = "herb_common", quantity = 1, chance = 0.3 },
	},
	ambush = false,
	aggressiveByDay = true,
}

return SnakeDefinition
