--!strict

export type CraftingConstantsModule = {
	CRAFT_COOLDOWN_SECONDS: number,
	HANDS_STATION: string,
	CRAFT_TABLE_STATION: string,
	CAMPFIRE_STATION: string,
	isHandsStation: (station: string) -> boolean,
	isCampStation: (station: string) -> boolean,
}

local HANDS_STATION = "hands"
local CRAFT_TABLE_STATION = "craft_table"
local CAMPFIRE_STATION = "campfire"

local CraftingConstants: CraftingConstantsModule = {
	CRAFT_COOLDOWN_SECONDS = 1,
	HANDS_STATION = HANDS_STATION,
	CRAFT_TABLE_STATION = CRAFT_TABLE_STATION,
	CAMPFIRE_STATION = CAMPFIRE_STATION,
}

function CraftingConstants.isHandsStation(station: string): boolean
	return station == HANDS_STATION
end

function CraftingConstants.isCampStation(station: string): boolean
	return station == CRAFT_TABLE_STATION or station == CAMPFIRE_STATION
end

return CraftingConstants
