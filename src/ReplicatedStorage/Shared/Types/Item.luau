--!strict

export type ItemCategory = "raw" | "processed" | "tool" | "medicine" | "food" | "blueprint" | "clue" | "ammo"

export type ItemDefinition = {
	id: string,
	displayName: string,
	category: ItemCategory,
	maxStack: number,
}

return {}
