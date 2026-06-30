--!strict

local QuestTypes = require(script.Parent.Parent.Types.Quest)

export type QuestType = "tutorial" | "main" | "side"

export type QuestObjectiveDef = {
	kind: QuestTypes.QuestObjectiveKind,
	target: number,
	itemId: string?,
	recipeId: string?,
	outputItemId: string?,
	blueprintId: string?,
	speciesId: string?,
	panelId: string?,
}

export type QuestRewardItems = { itemId: string, quantity: number }

export type QuestReward = {
	xp: number?,
	currency: number?,
	items: { QuestRewardItems }?,
	grantBlueprint: string?,
}

export type QuestDefinition = {
	id: string,
	questType: QuestType,
	titleKey: string,
	objectiveKeys: { string },
	objectives: { QuestObjectiveDef },
	rewards: QuestReward,
	prerequisites: { string }?,
	requiresTutorialCompleted: boolean?,
	minLevel: number?,
	nextQuestId: string?,
	setsTutorialCompleted: boolean?,
}

export type QuestsModule = {
	get: (id: string) -> QuestDefinition?,
	getAll: () -> { QuestDefinition },
	getTutorialChain: () -> { QuestDefinition },
}

local function quest(def: QuestDefinition): QuestDefinition
	return def
end

local definitions: { [string]: QuestDefinition } = {
	t01_spawn = quest({
		id = "t01_spawn",
		questType = "tutorial",
		titleKey = "quest.t01_spawn.title",
		objectiveKeys = { "quest.t01_spawn.objective.1" },
		objectives = {
			{ kind = "open_ui", target = 1, panelId = "stats" },
		},
		rewards = {},
		nextQuestId = "t02_gather",
	}),
	t02_gather = quest({
		id = "t02_gather",
		questType = "tutorial",
		titleKey = "quest.t02_gather.title",
		objectiveKeys = {
			"quest.t02_gather.objective.1",
			"quest.t02_gather.objective.2",
		},
		objectives = {
			{ kind = "gather", target = 3, itemId = "stick" },
			{ kind = "gather", target = 2, itemId = "stone" },
		},
		rewards = { xp = 10 },
		prerequisites = { "t01_spawn" },
		nextQuestId = "t03_sparks",
	}),
	t03_sparks = quest({
		id = "t03_sparks",
		questType = "tutorial",
		titleKey = "quest.t03_sparks.title",
		objectiveKeys = { "quest.t03_sparks.objective.1" },
		objectives = {
			{ kind = "craft", target = 1, recipeId = "recipe_sparks", outputItemId = "sparks" },
		},
		rewards = { xp = 15 },
		prerequisites = { "t02_gather" },
		nextQuestId = "t04_tinder",
	}),
	t04_tinder = quest({
		id = "t04_tinder",
		questType = "tutorial",
		titleKey = "quest.t04_tinder.title",
		objectiveKeys = { "quest.t04_tinder.objective.1" },
		objectives = {
			{ kind = "craft", target = 1, recipeId = "recipe_tinder", outputItemId = "tinder" },
		},
		rewards = { xp = 10 },
		prerequisites = { "t03_sparks" },
		nextQuestId = "t05_campfire",
	}),
	t05_campfire = quest({
		id = "t05_campfire",
		questType = "tutorial",
		titleKey = "quest.t05_campfire.title",
		objectiveKeys = {
			"quest.t05_campfire.objective.1",
			"quest.t05_campfire.objective.2",
		},
		objectives = {
			{ kind = "craft", target = 1, recipeId = "recipe_campfire", outputItemId = "bp_campfire" },
			{ kind = "place_structure", target = 1, blueprintId = "bp_campfire" },
		},
		rewards = { xp = 25, grantBlueprint = "bp_craft_table" },
		prerequisites = { "t04_tinder" },
		nextQuestId = "t06_cold",
	}),
	t06_cold = quest({
		id = "t06_cold",
		questType = "tutorial",
		titleKey = "quest.t06_cold.title",
		objectiveKeys = { "quest.t06_cold.objective.1" },
		objectives = {
			{ kind = "survive_cold", target = 30 },
		},
		rewards = { xp = 15 },
		prerequisites = { "t05_campfire" },
		nextQuestId = "t07_bandage",
	}),
	t07_bandage = quest({
		id = "t07_bandage",
		questType = "tutorial",
		titleKey = "quest.t07_bandage.title",
		objectiveKeys = { "quest.t07_bandage.objective.1" },
		objectives = {
			{ kind = "craft", target = 2, recipeId = "recipe_bandage", outputItemId = "bandage" },
		},
		rewards = {
			xp = 20,
			items = { { itemId = "berry", quantity = 5 } },
		},
		prerequisites = { "t06_cold" },
		nextQuestId = "t08_complete",
	}),
	t08_complete = quest({
		id = "t08_complete",
		questType = "tutorial",
		titleKey = "quest.t08_complete.title",
		objectiveKeys = { "quest.t08_complete.objective.1" },
		objectives = {
			{ kind = "place_structure", target = 1, blueprintId = "bp_craft_table" },
		},
		rewards = { xp = 25 },
		prerequisites = { "t07_bandage" },
		setsTutorialCompleted = true,
		nextQuestId = "m00_wood",
	}),
	m00_wood = quest({
		id = "m00_wood",
		questType = "main",
		titleKey = "quest.m00_wood.title",
		objectiveKeys = { "quest.m00_wood.objective.1" },
		objectives = {
			{ kind = "gather", target = 10, itemId = "wood" },
		},
		rewards = { xp = 30, currency = 25 },
		requiresTutorialCompleted = true,
		nextQuestId = "main_01_chest",
	}),
	main_01_chest = quest({
		id = "main_01_chest",
		questType = "main",
		titleKey = "quest.main_01_chest.title",
		objectiveKeys = { "quest.main_01_chest.objective.1" },
		objectives = {
			{ kind = "place_structure", target = 1, blueprintId = "bp_chest" },
		},
		rewards = {
			xp = 50,
			items = { { itemId = "berry", quantity = 3 } },
		},
		prerequisites = { "m00_wood" },
	}),
	side_01_berries = quest({
		id = "side_01_berries",
		questType = "side",
		titleKey = "quest.side_01_berries.title",
		objectiveKeys = { "quest.side_01_berries.objective.1" },
		objectives = {
			{ kind = "gather", target = 20, itemId = "berry" },
		},
		rewards = {
			xp = 40,
			items = { { itemId = "berry", quantity = 5 } },
		},
		requiresTutorialCompleted = true,
		minLevel = 2,
	}),
	side_02_wolf = quest({
		id = "side_02_wolf",
		questType = "side",
		titleKey = "quest.side_02_wolf.title",
		objectiveKeys = { "quest.side_02_wolf.objective.1" },
		objectives = {
			{ kind = "defeat_fauna", target = 3, speciesId = "wolf" },
		},
		rewards = {
			xp = 50,
			items = { { itemId = "fiber", quantity = 5 } },
		},
		requiresTutorialCompleted = true,
		minLevel = 2,
	}),
}

local TUTORIAL_CHAIN_ORDER = {
	"t01_spawn",
	"t02_gather",
	"t03_sparks",
	"t04_tinder",
	"t05_campfire",
	"t06_cold",
	"t07_bandage",
	"t08_complete",
}

local Quests: QuestsModule = {
	get = function(id: string): QuestDefinition?
		return definitions[id]
	end,
	getAll = function(): { QuestDefinition }
		local all: { QuestDefinition } = {}

		for _, definition in definitions do
			table.insert(all, definition)
		end

		table.sort(all, function(left, right)
			return left.id < right.id
		end)

		return all
	end,
	getTutorialChain = function(): { QuestDefinition }
		local chain: { QuestDefinition } = {}

		for _, questId in TUTORIAL_CHAIN_ORDER do
			local definition = definitions[questId]

			if definition ~= nil then
				table.insert(chain, definition)
			end
		end

		return chain
	end,
}

return Quests
