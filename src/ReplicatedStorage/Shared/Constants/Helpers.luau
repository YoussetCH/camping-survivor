--!strict

local HelperTypes = require(script.Parent.Parent.Types.Helper)

export type HelpersModule = {
	getType: (helperTypeId: string) -> HelperTypes.HelperTypeDefinition?,
	getAllTypes: () -> { HelperTypes.HelperTypeDefinition },
}

local definitions: { [string]: HelperTypes.HelperTypeDefinition } = {
	lumberjack = {
		helperTypeId = "lumberjack",
		nameKey = "helper.lumberjack.name",
		workIntervalSeconds = 60,
		biomeOrigin = "forest_deep",
	},
	cook = {
		helperTypeId = "cook",
		nameKey = "helper.cook.name",
		workIntervalSeconds = 60,
		biomeOrigin = "forest_near",
	},
	herbalist = {
		helperTypeId = "herbalist",
		nameKey = "helper.herbalist.name",
		workIntervalSeconds = 90,
		biomeOrigin = "swamp",
	},
	guardian = {
		helperTypeId = "guardian",
		nameKey = "helper.guardian.name",
		workIntervalSeconds = 60,
		biomeOrigin = "mountain",
	},
	miner = {
		helperTypeId = "miner",
		nameKey = "helper.miner.name",
		workIntervalSeconds = 90,
		biomeOrigin = "mountain",
	},
	fisher = {
		helperTypeId = "fisher",
		nameKey = "helper.fisher.name",
		workIntervalSeconds = 75,
		biomeOrigin = "coast",
	},
}

local Helpers: HelpersModule = {
	getType = function(helperTypeId: string): HelperTypes.HelperTypeDefinition?
		return definitions[helperTypeId]
	end,
	getAllTypes = function(): { HelperTypes.HelperTypeDefinition }
		local all: { HelperTypes.HelperTypeDefinition } = {}

		for _, definition in definitions do
			table.insert(all, definition)
		end

		table.sort(all, function(left, right)
			return left.helperTypeId < right.helperTypeId
		end)

		return all
	end,
}

return Helpers
