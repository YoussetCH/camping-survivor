--!strict

export type StatusEffect = {
	id: string,
	expiresAt: number?,
}

export type SurvivalStats = {
	hunger: number,
	thirst: number,
	health: number,
	temperature: number,
}

export type SurvivalSnapshot = {
	stats: SurvivalStats,
	statusEffects: { StatusEffect },
}

return {}
