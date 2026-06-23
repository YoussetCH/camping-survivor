--!strict

export type ModelBuildContext = {
	model: Model,
	root: BasePart,
	ghost: boolean,
}

export type ModelBuilder = (ctx: ModelBuildContext) -> ()

export type StructureModelRegistryModule = {
	register: (blueprintId: string, builder: ModelBuilder) -> (),
	get: (blueprintId: string) -> ModelBuilder?,
}

local builders: { [string]: ModelBuilder } = {}

local StructureModelRegistry: StructureModelRegistryModule = {
	register = function(blueprintId: string, builder: ModelBuilder)
		builders[blueprintId] = builder
	end,
	get = function(blueprintId: string): ModelBuilder?
		return builders[blueprintId]
	end,
}

return StructureModelRegistry
