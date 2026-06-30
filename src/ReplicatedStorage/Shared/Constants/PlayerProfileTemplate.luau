--!strict

export type PlayerProfileTemplate = {
	currency: number,
	inventory: {},
	hotbar: { string? },
	equipped: {
		toolItemId: string?,
		coatItemId: string?,
	},
	stats: {
		level: number,
		xp: number,
		playTime: number,
		deaths: number,
		missionsCompleted: { string },
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
		structures: {},
		chests: {},
	},
	helpers: {},
	lostHelpers: { string },
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
	hotbar = { nil, nil, nil, nil, nil, nil },
	equipped = {
		toolItemId = nil,
		coatItemId = nil,
	},
	stats = {
		level = 1,
		xp = 0,
		playTime = 0,
		deaths = 0,
		missionsCompleted = {},
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
		structures = {},
		chests = {},
	},
	helpers = {},
	lostHelpers = {},
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
