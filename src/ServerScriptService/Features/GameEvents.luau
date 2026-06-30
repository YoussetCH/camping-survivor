--!strict

export type GameEventsModule = {
	CampPlotAssigned: BindableEvent,
	CampLevelChanged: BindableEvent,
	RequestPlotTeleport: BindableEvent,
	ItemHarvested: BindableEvent,
	ItemCrafted: BindableEvent,
	StructurePlaced: BindableEvent,
	FaunaDefeated: BindableEvent,
	BiomeEntered: BindableEvent,
	QuestUiOpened: BindableEvent,
	QuestStarted: BindableEvent,
	EscortToPlot: BindableEvent,
	fireCampPlotAssigned: (player: Player, plotId: string) -> (),
	fireCampLevelChanged: (player: Player, newLevel: number, oldLevel: number) -> (),
	fireRequestPlotTeleport: (player: Player, plotId: string) -> (),
	fireItemHarvested: (player: Player, itemId: string, quantity: number) -> (),
	fireItemCrafted: (player: Player, recipeId: string, outputItemId: string, quantity: number) -> (),
	fireStructurePlaced: (player: Player, blueprintId: string) -> (),
	fireFaunaDefeated: (player: Player, speciesId: string) -> (),
	fireBiomeEntered: (player: Player, biomeId: string) -> (),
	fireQuestUiOpened: (player: Player, panelId: string) -> (),
	fireQuestStarted: (player: Player, questId: string) -> (),
	fireEscortToPlot: (player: Player, helperTypeId: string) -> (),
}

local campPlotAssigned = Instance.new("BindableEvent")
local campLevelChanged = Instance.new("BindableEvent")
local requestPlotTeleport = Instance.new("BindableEvent")
local itemHarvested = Instance.new("BindableEvent")
local itemCrafted = Instance.new("BindableEvent")
local structurePlaced = Instance.new("BindableEvent")
local faunaDefeated = Instance.new("BindableEvent")
local biomeEntered = Instance.new("BindableEvent")
local questUiOpened = Instance.new("BindableEvent")
local questStarted = Instance.new("BindableEvent")
local escortToPlot = Instance.new("BindableEvent")

local GameEvents: GameEventsModule = {
	CampPlotAssigned = campPlotAssigned,
	CampLevelChanged = campLevelChanged,
	RequestPlotTeleport = requestPlotTeleport,
	ItemHarvested = itemHarvested,
	ItemCrafted = itemCrafted,
	StructurePlaced = structurePlaced,
	FaunaDefeated = faunaDefeated,
	BiomeEntered = biomeEntered,
	QuestUiOpened = questUiOpened,
	QuestStarted = questStarted,
	EscortToPlot = escortToPlot,
	fireCampPlotAssigned = function(player: Player, plotId: string)
		campPlotAssigned:Fire(player, plotId)
	end,
	fireCampLevelChanged = function(player: Player, newLevel: number, oldLevel: number)
		campLevelChanged:Fire(player, newLevel, oldLevel)
	end,
	fireRequestPlotTeleport = function(player: Player, plotId: string)
		requestPlotTeleport:Fire(player, plotId)
	end,
	fireItemHarvested = function(player: Player, itemId: string, quantity: number)
		itemHarvested:Fire(player, itemId, quantity)
	end,
	fireItemCrafted = function(player: Player, recipeId: string, outputItemId: string, quantity: number)
		itemCrafted:Fire(player, recipeId, outputItemId, quantity)
	end,
	fireStructurePlaced = function(player: Player, blueprintId: string)
		structurePlaced:Fire(player, blueprintId)
	end,
	fireFaunaDefeated = function(player: Player, speciesId: string)
		faunaDefeated:Fire(player, speciesId)
	end,
	fireBiomeEntered = function(player: Player, biomeId: string)
		biomeEntered:Fire(player, biomeId)
	end,
	fireQuestUiOpened = function(player: Player, panelId: string)
		questUiOpened:Fire(player, panelId)
	end,
	fireQuestStarted = function(player: Player, questId: string)
		questStarted:Fire(player, questId)
	end,
	fireEscortToPlot = function(player: Player, helperTypeId: string)
		escortToPlot:Fire(player, helperTypeId)
	end,
}

return GameEvents
