--!strict

local HelperTypes = require(game:GetService("ReplicatedStorage").Shared.Types.Helper)

export type HelperBehaviorRegistryModule = {
	register: (behavior: HelperTypes.HelperBehaviorModule) -> (),
	get: (helperTypeId: string) -> HelperTypes.HelperBehaviorModule?,
	getAll: () -> { HelperTypes.HelperBehaviorModule },
}

local behaviors: { [string]: HelperTypes.HelperBehaviorModule } = {}

local HelperBehaviorRegistry: HelperBehaviorRegistryModule = {
	register = function(behavior: HelperTypes.HelperBehaviorModule)
		behaviors[behavior.helperTypeId] = behavior
	end,
	get = function(helperTypeId: string): HelperTypes.HelperBehaviorModule?
		return behaviors[helperTypeId]
	end,
	getAll = function(): { HelperTypes.HelperBehaviorModule }
		local all: { HelperTypes.HelperBehaviorModule } = {}

		for _, behavior in behaviors do
			table.insert(all, behavior)
		end

		return all
	end,
}

return HelperBehaviorRegistry
