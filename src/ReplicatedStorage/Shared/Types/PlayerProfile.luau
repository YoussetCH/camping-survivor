--!strict

local CampTypes = require(script.Parent.Camp)
local SurvivalTypes = require(script.Parent.Survival)

export type InventoryItem = {
	itemId: string,
	quantity: number,
	metadata: { [string]: unknown }?,
}

export type InventorySnapshot = {
	inventory: { InventoryItem },
	hotbar: { string }?,
}

export type PlayerStats = {
	level: number,
	xp: number,
	playTime: number,
	deaths: number,
}

export type PlayerProfile = {
	currency: number,
	inventory: { InventoryItem },
	stats: PlayerStats,
	quests: { [string]: unknown },
	settings: { [string]: unknown },
	survival: SurvivalTypes.SurvivalStats,
	statusEffects: { SurvivalTypes.StatusEffect },
	camp: CampTypes.CampData,
	recipes: { unlocked: { string } },
	clanId: string?,
	monetization: { purchases: { [string]: unknown } },
	tutorialCompleted: boolean,
}

return {}
