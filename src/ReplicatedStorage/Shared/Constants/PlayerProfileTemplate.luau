--!strict

export type PlayerProfileTemplate = {
	currency: number,
	inventory: {},
	stats: {
		level: number,
		xp: number,
		playTime: number,
		deaths: number,
	},
	quests: {},
	settings: {
		locale: string,
	},
	survival: {
		hunger: number,
		thirst: number,
		health: number,
		temperature: number,
	},
	statusEffects: {},
	camp: {
		plotId: string?,
		level: number,
	},
	recipes: {
		unlocked: { string },
	},
	clanId: string?,
	monetization: {
		purchases: { [string]: unknown },
	},
	tutorialCompleted: boolean,
}

local PlayerProfileTemplate: PlayerProfileTemplate = {
	currency = 0,
	inventory = {},
	stats = {
		level = 1,
		xp = 0,
		playTime = 0,
		deaths = 0,
	},
	quests = {},
	settings = {
		locale = "en",
	},
	survival = {
		hunger = 80,
		thirst = 80,
		health = 100,
		temperature = 50,
	},
	statusEffects = {},
	camp = {
		plotId = nil,
		level = 0,
	},
	recipes = {
		unlocked = {},
	},
	clanId = nil,
	monetization = {
		purchases = {},
	},
	tutorialCompleted = false,
}

return PlayerProfileTemplate
