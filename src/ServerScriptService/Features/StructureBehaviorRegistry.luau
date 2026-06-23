--!strict

local StructureBehaviorTypes = require(game:GetService("ReplicatedStorage").Shared.Types.StructureBehavior)

export type StructureBehavior = StructureBehaviorTypes.StructureBehavior

export type StructureBehaviorRegistryModule = {
	register: (behavior: StructureBehavior) -> (),
	get: (blueprintId: string) -> StructureBehavior?,
	getAll: () -> { StructureBehavior },
}

local behaviors: { [string]: StructureBehavior } = {}

local StructureBehaviorRegistry: StructureBehaviorRegistryModule = {
	register = function(behavior: StructureBehavior)
		behaviors[behavior.blueprintId] = behavior
	end,
	get = function(blueprintId: string): StructureBehavior?
		return behaviors[blueprintId]
	end,
	getAll = function(): { StructureBehavior }
		local all: { StructureBehavior } = {}

		for _, behavior in behaviors do
			table.insert(all, behavior)
		end

		return all
	end,
}

return StructureBehaviorRegistry
