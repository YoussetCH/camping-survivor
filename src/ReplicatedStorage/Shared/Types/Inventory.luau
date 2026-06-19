--!strict

export type InventoryItem = {
	itemId: string,
	quantity: number,
	metadata: { [string]: unknown }?,
}

export type BagSlots = { [string]: InventoryItem }

export type EquippedItems = {
	toolItemId: string?,
	coatItemId: string?,
}

export type HotbarSlots = { string? }

local InventoryTypes = {}

function InventoryTypes.isValidBagSlotKey(slotKey: string): boolean
	local slotIndex = tonumber(slotKey)

	if slotIndex == nil then
		return false
	end

	return slotIndex >= 1 and slotIndex <= 16 and math.floor(slotIndex) == slotIndex
end

function InventoryTypes.createEmptyBag(): BagSlots
	return {}
end

function InventoryTypes.createEmptyHotbar(): HotbarSlots
	return { nil, nil, nil, nil, nil, nil }
end

function InventoryTypes.createEmptyEquipped(): EquippedItems
	return {
		toolItemId = nil,
		coatItemId = nil,
	}
end

function InventoryTypes.getOccupiedBagKeys(bag: BagSlots): { string }
	local keys: { string } = {}

	for slotKey, item in bag do
		if item.quantity > 0 then
			table.insert(keys, slotKey)
		end
	end

	table.sort(keys, function(left, right)
		return (tonumber(left) or 0) < (tonumber(right) or 0)
	end)

	return keys
end

function InventoryTypes.clearHotbarReferences(hotbar: HotbarSlots, removedKeys: { [string]: boolean })
	for index, bagSlotKey in hotbar do
		if bagSlotKey ~= nil and removedKeys[bagSlotKey] then
			hotbar[index] = nil
		end
	end
end

function InventoryTypes.normalizeLegacyInventory(rawInventory: unknown): BagSlots
	if type(rawInventory) ~= "table" then
		return InventoryTypes.createEmptyBag()
	end

	local rawTable = rawInventory :: { [any]: any }
	local hasNumericKeys = false

	for key in rawTable do
		if type(key) == "number" then
			hasNumericKeys = true
			break
		end
	end

	if not hasNumericKeys then
		return rawTable :: BagSlots
	end

	local bag: BagSlots = {}

	for index, item in rawTable do
		if type(index) == "number" and type(item) == "table" and type(item.itemId) == "string" then
			bag[tostring(index)] = item :: InventoryItem
		end
	end

	return bag
end

return InventoryTypes
