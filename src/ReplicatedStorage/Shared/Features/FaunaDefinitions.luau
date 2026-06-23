--!strict

local WolfDefinition = require(script.Parent.Wolf.WolfDefinition)
local SnakeDefinition = require(script.Parent.Snake.SnakeDefinition)
local FaunaTypes = require(script.Parent.Parent.Types.Fauna)

export type FaunaDefinitionsModule = {
	get: (speciesId: string) -> FaunaTypes.FaunaSpeciesDefinition?,
	getAll: () -> { FaunaTypes.FaunaSpeciesDefinition },
}

local definitions: { [string]: FaunaTypes.FaunaSpeciesDefinition } = {
	wolf = WolfDefinition,
	snake = SnakeDefinition,
}

local FaunaDefinitions: FaunaDefinitionsModule = {
	get = function(speciesId: string): FaunaTypes.FaunaSpeciesDefinition?
		return definitions[speciesId]
	end,
	getAll = function(): { FaunaTypes.FaunaSpeciesDefinition }
		local all: { FaunaTypes.FaunaSpeciesDefinition } = {}

		for _, definition in definitions do
			table.insert(all, definition)
		end

		return all
	end,
}

return FaunaDefinitions
