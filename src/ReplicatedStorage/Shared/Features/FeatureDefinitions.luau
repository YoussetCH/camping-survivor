--!strict

local StructureTypes = require(script.Parent.Parent.Types.Structure)

export type StructureDefinition = StructureTypes.StructureDefinition

export type FeatureDefinitionsModule = {
	getAll: () -> { StructureDefinition },
	get: (blueprintId: string) -> StructureDefinition?,
}

local CampfireDefinition = require(script.Parent.Campfire.CampfireDefinition)
local ChestDefinition = require(script.Parent.Chest.ChestDefinition)
local CraftTableDefinition = require(script.Parent.CraftTable.CraftTableDefinition)

local orderedDefinitions: { StructureDefinition } = {
	CampfireDefinition,
	ChestDefinition,
	CraftTableDefinition,
}

local byId: { [string]: StructureDefinition } = {}

for _, definition in orderedDefinitions do
	byId[definition.id] = definition
end

local FeatureDefinitions: FeatureDefinitionsModule = {
	getAll = function(): { StructureDefinition }
		return orderedDefinitions
	end,
	get = function(blueprintId: string): StructureDefinition?
		return byId[blueprintId]
	end,
}

return FeatureDefinitions
