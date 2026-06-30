--!strict

local CampTypes = require(script.Parent.Camp)
local InventoryTypes = require(script.Parent.Inventory)
local PlayerSettingsTypes = require(script.Parent.PlayerSettings)
local QuestTypes = require(script.Parent.Quest)
local SurvivalTypes = require(script.Parent.Survival)

export type InventoryItem = InventoryTypes.InventoryItem

export type InventorySnapshot = {
	inventory: InventoryTypes.BagSlots,
	hotbar: InventoryTypes.HotbarSlots,
	equipped: InventoryTypes.EquippedItems,
}

export type PlayerStats = {
	level: number,
	xp: number,
	playTime: number,
	deaths: number,
	missionsCompleted: { string },
}

export type PlayerProfile = {
	currency: number,
	inventory: InventoryTypes.BagSlots,
	hotbar: InventoryTypes.HotbarSlots,
	equipped: InventoryTypes.EquippedItems,
	stats: PlayerStats,
	quests: QuestTypes.QuestProgress,
	settings: PlayerSettingsTypes.PlayerSettings,
	survival: SurvivalTypes.SurvivalStats,
	statusEffects: { SurvivalTypes.StatusEffect },
	camp: CampTypes.CampData,
	recipes: { unlocked: { string } },
	clanId: string?,
	monetization: { purchases: { [string]: unknown } },
	tutorialCompleted: boolean,
}

return {}
