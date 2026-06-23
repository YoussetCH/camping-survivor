--!strict

export type StatusEffectConstantsModule = {
	BLEEDING_HP_PER_TICK: number,
	POISON_HP_PER_TICK: number,
	INFECTION_HP_PER_TICK: number,
	BLEEDING_TO_INFECTION_SECONDS: number,
	BANDAGE_HEAL_AMOUNT: number,
	ANTIDOTE_HEAL_AMOUNT: number,
	BLOCKING_EFFECT_IDS: { string },
}

local StatusEffectConstants: StatusEffectConstantsModule = {
	BLEEDING_HP_PER_TICK = 1,
	POISON_HP_PER_TICK = 0.2,
	INFECTION_HP_PER_TICK = 0.1,
	BLEEDING_TO_INFECTION_SECONDS = 300,
	BANDAGE_HEAL_AMOUNT = 10,
	ANTIDOTE_HEAL_AMOUNT = 15,
	BLOCKING_EFFECT_IDS = { "bleeding", "poison", "infection" },
}

return StatusEffectConstants
