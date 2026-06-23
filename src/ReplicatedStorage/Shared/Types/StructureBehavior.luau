--!strict

local CampTypes = require(script.Parent.Camp)
local PlayerProfileTypes = require(script.Parent.PlayerProfile)

export type StructureContext = {
	player: Player,
	data: PlayerProfileTypes.PlayerProfile,
	structure: CampTypes.CampStructure,
	plotId: string,
}

export type PlacementContext = StructureContext & {
	position: Vector3,
	rotation: number,
}

export type CampLevelContext = {
	player: Player,
	data: PlayerProfileTypes.PlayerProfile,
}

export type StructureBehavior = {
	blueprintId: string,
	onPlace: ((ctx: StructureContext) -> ())?,
	onDemolish: ((ctx: StructureContext) -> ())?,
	validatePlacement: ((ctx: PlacementContext) -> (boolean, string?))?,
	onCampLevelRecalculate: ((ctx: CampLevelContext) -> ())?,
}

return {}
