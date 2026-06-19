--!strict

export type RecipeUnlockType = "tutorial" | "starter" | "clue" | "mission" | "experiment" | "camp_level"

export type RecipeDefinition = {
	id: string,
	displayName: string,
	unlockType: RecipeUnlockType,
	station: string,
	inputs: { { itemId: string, quantity: number } },
	outputs: { { itemId: string, quantity: number } },
}

return {}
