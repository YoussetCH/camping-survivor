--!strict

export type FaunaAiState = "idle" | "patrol" | "alert" | "chase" | "attack" | "flee" | "stunned"

export type FaunaDropDefinition = {
	itemId: string,
	quantity: number,
	chance: number,
}

export type FaunaStatusOnHit = {
	id: string,
	chance: number,
}

export type FaunaSpeciesDefinition = {
	speciesId: string,
	maxHp: number,
	damage: number,
	detectRangeStuds: number,
	detectRangeNightStuds: number?,
	meleeRangeStuds: number,
	attackCooldownSeconds: number,
	attackWindupSeconds: number?,
	attackAnimationSeconds: number?,
	moveSpeedStuds: number,
	statusOnHit: { FaunaStatusOnHit },
	drops: { FaunaDropDefinition },
	ambush: boolean,
	aggressiveByDay: boolean,
}

export type FaunaSnapshot = {
	faunaId: string,
	speciesId: string,
	hp: number,
	maxHp: number,
	state: FaunaAiState?,
	removed: boolean?,
}

export type FaunaBehaviorModule = {
	speciesId: string,
	definition: FaunaSpeciesDefinition,
	buildModel: (groundPosition: Vector3) -> Model,
	onReveal: ((model: Model) -> ())?,
	onAttackTelegraphStart: ((model: Model, definition: FaunaSpeciesDefinition) -> ())?,
	onAttackTelegraphEnd: ((model: Model) -> ())?,
	onStunStart: ((model: Model) -> ())?,
	onStunEnd: ((model: Model) -> ())?,
}

return {}
