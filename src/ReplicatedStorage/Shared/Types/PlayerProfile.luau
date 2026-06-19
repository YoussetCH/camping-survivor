--!strict

export type InventoryItem = {
	itemId: string,
	quantity: number,
	metadata: { [string]: unknown }?,
}

export type PlayerStats = {
	level: number,
	xp: number,
}

export type PlayerProfile = {
	currency: number,
	inventory: { InventoryItem },
	stats: PlayerStats,
	quests: { [string]: unknown },
	settings: { [string]: unknown },
}

return {}
