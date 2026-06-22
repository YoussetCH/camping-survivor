--!strict

local CampConstants = {
	PLOT_SIZE_STUDS = 48,
	GRID_CELL_SIZE = 4,
	MAX_BUILD_HEIGHT = 16,
	MAX_STRUCTURES_LEVEL_0_1 = 10,
	CHEST_SLOT_COUNT = 24,
	CRAFT_TABLE_RANGE = 18,
	CAMPFIRE_RANGE = 8,
	CHEST_INTERACT_RANGE = 12,
	PLOT_TAG = "CampPlot",
}

function CampConstants.getChestSlotKey(slotIndex: number): string
	return tostring(slotIndex)
end

function CampConstants.isValidChestSlotKey(slotKey: string): boolean
	local slotIndex = tonumber(slotKey)

	if slotIndex == nil then
		return false
	end

	return slotIndex >= 1 and slotIndex <= CampConstants.CHEST_SLOT_COUNT and math.floor(slotIndex) == slotIndex
end

function CampConstants.isValidRotation(rotation: number): boolean
	return rotation == 0 or rotation == 90 or rotation == 180 or rotation == 270
end

return CampConstants
