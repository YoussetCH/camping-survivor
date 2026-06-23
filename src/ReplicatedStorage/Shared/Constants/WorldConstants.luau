--!strict

local WorldTypes = require(script.Parent.Parent.Types.World)

export type BiomeDefinition = {
	id: string,
	dayAmbient: number,
	nightAmbient: number,
}

export type WorldConstantsModule = {
	BIOME_ZONE_TAG: string,
	RESOURCE_NODE_TAG: string,
	BIOME_ID_ATTRIBUTE: string,
	NODE_ID_ATTRIBUTE: string,
	NODE_TYPE_ATTRIBUTE: string,
	NODE_OUTPUTS_ATTRIBUTE: string,
	NODE_DEPLETED_ATTRIBUTE: string,
	DEFAULT_BIOME_ID: string,
	CYCLE_SECONDS: number,
	DAY_SECONDS: number,
	NIGHT_SECONDS: number,
	TRANSITION_SECONDS: number,
	WORLD_SYNC_INTERVAL_SECONDS: number,
	HARVEST_MAX_DISTANCE_STUDS: number,
	getBiome: (biomeId: string) -> BiomeDefinition?,
	getAmbientForBiome: (biomeId: string, phase: WorldTypes.WorldPhase) -> number,
}

local BIOME_DEFINITIONS: { [string]: BiomeDefinition } = {
	camp_hub = { id = "camp_hub", dayAmbient = 50, nightAmbient = 45 },
	forest_near = { id = "forest_near", dayAmbient = 45, nightAmbient = 25 },
	forest_deep = { id = "forest_deep", dayAmbient = 42, nightAmbient = 22 },
	mountain = { id = "mountain", dayAmbient = 30, nightAmbient = 10 },
	swamp = { id = "swamp", dayAmbient = 40, nightAmbient = 35 },
	coast = { id = "coast", dayAmbient = 55, nightAmbient = 48 },
	default = { id = "default", dayAmbient = 45, nightAmbient = 30 },
}

local function isNightPhase(phase: WorldTypes.WorldPhase): boolean
	return phase == "night" or phase == "dusk"
end

local WorldConstants: WorldConstantsModule = {
	BIOME_ZONE_TAG = "BiomeZone",
	RESOURCE_NODE_TAG = "ResourceNode",
	BIOME_ID_ATTRIBUTE = "BiomeId",
	NODE_ID_ATTRIBUTE = "NodeId",
	NODE_TYPE_ATTRIBUTE = "NodeType",
	NODE_OUTPUTS_ATTRIBUTE = "Outputs",
	NODE_DEPLETED_ATTRIBUTE = "Depleted",
	DEFAULT_BIOME_ID = "default",
	CYCLE_SECONDS = 1200,
	DAY_SECONDS = 840,
	NIGHT_SECONDS = 360,
	TRANSITION_SECONDS = 30,
	WORLD_SYNC_INTERVAL_SECONDS = 30,
	HARVEST_MAX_DISTANCE_STUDS = 12,
}

function WorldConstants.getBiome(biomeId: string): BiomeDefinition?
	return BIOME_DEFINITIONS[biomeId]
end

function WorldConstants.getAmbientForBiome(biomeId: string, phase: WorldTypes.WorldPhase): number
	local biome = BIOME_DEFINITIONS[biomeId] or BIOME_DEFINITIONS.default

	if isNightPhase(phase) then
		return biome.nightAmbient
	end

	return biome.dayAmbient
end

return WorldConstants
