--!strict

export type PlayerProfileTemplate = {
	currency: number,
	inventory: {},
	stats: {
		level: number,
		xp: number,
	},
	quests: {},
	settings: {},
}

local PlayerProfileTemplate: PlayerProfileTemplate = {
	currency = 0,
	inventory = {},
	stats = {
		level = 1,
		xp = 0,
	},
	quests = {},
	settings = {},
}

return PlayerProfileTemplate
