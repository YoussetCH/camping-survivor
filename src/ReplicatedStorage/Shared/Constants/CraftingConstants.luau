--!strict

export type CraftingConstantsModule = {
	CRAFT_COOLDOWN_SECONDS: number,
	HANDS_STATION: string,
	isStationAvailable: (station: string) -> boolean,
}

local HANDS_STATION = "hands"

local CraftingConstants: CraftingConstantsModule = {
	CRAFT_COOLDOWN_SECONDS = 1,
	HANDS_STATION = HANDS_STATION,
}

function CraftingConstants.isStationAvailable(station: string): boolean
	return station == HANDS_STATION
end

return CraftingConstants
