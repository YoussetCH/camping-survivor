--!strict

local Items = require(script.Parent.Items)

local InventoryConstants = {
	BAG_SLOT_COUNT = 16,
	HOTBAR_SLOT_COUNT = 6,
	ACTION_COOLDOWN_SECONDS = 0.25,
	BANDAGE_HEAL_AMOUNT = 15,
}

function InventoryConstants.getBagSlotKey(slotIndex: number): string
	return tostring(slotIndex)
end

function InventoryConstants.getMaxStack(itemId: string): number
	local definition = Items.get(itemId)

	if definition == nil then
		return 1
	end

	return definition.maxStack
end

return InventoryConstants
