--!strict

local StructureTypes = require(script.Parent.Parent.Types.Structure)
local FeatureDefinitions = require(script.Parent.Parent.Features.FeatureDefinitions)

export type StructureDefinition = StructureTypes.StructureDefinition

export type StructuresConstantsModule = {
	get: (blueprintId: string) -> StructureDefinition?,
	getAll: () -> { StructureDefinition },
	isBlueprint: (itemId: string) -> boolean,
}

local StructuresConstants: StructuresConstantsModule = {
	get = function(blueprintId: string): StructureDefinition?
		return FeatureDefinitions.get(blueprintId)
	end,
	getAll = function(): { StructureDefinition }
		return FeatureDefinitions.getAll()
	end,
	isBlueprint = function(itemId: string): boolean
		return FeatureDefinitions.get(itemId) ~= nil
	end,
}

return StructuresConstants
