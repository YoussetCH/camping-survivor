--!strict

local FaunaTypes = require(game:GetService("ReplicatedStorage").Shared.Types.Fauna)

export type FaunaRegistryModule = {
	register: (behavior: FaunaTypes.FaunaBehaviorModule) -> (),
	get: (speciesId: string) -> FaunaTypes.FaunaBehaviorModule?,
	getAll: () -> { FaunaTypes.FaunaBehaviorModule },
}

local behaviors: { [string]: FaunaTypes.FaunaBehaviorModule } = {}

local FaunaRegistry: FaunaRegistryModule = {
	register = function(behavior: FaunaTypes.FaunaBehaviorModule)
		behaviors[behavior.speciesId] = behavior
	end,
	get = function(speciesId: string): FaunaTypes.FaunaBehaviorModule?
		return behaviors[speciesId]
	end,
	getAll = function(): { FaunaTypes.FaunaBehaviorModule }
		local all: { FaunaTypes.FaunaBehaviorModule } = {}

		for _, behavior in behaviors do
			table.insert(all, behavior)
		end

		return all
	end,
}

return FaunaRegistry
