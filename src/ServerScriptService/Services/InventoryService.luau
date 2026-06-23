--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseService = require(ServerScriptService.Kernel.BaseService)
local InventoryConstants = require(ReplicatedStorage.Shared.Constants.InventoryConstants)
local Items = require(ReplicatedStorage.Shared.Constants.Items)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local SurvivalConstants = require(ReplicatedStorage.Shared.Constants.SurvivalConstants)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.Inventory)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local PlayerSyncService = require(ServerScriptService.Services.PlayerSyncService)

local InventoryService = BaseService.new("InventoryService")

local lastActionAt: { [number]: number } = {}

local function canPerformAction(player: Player): boolean
	local now = os.clock()
	local lastAt = lastActionAt[player.UserId]

	if lastAt ~= nil and now - lastAt < InventoryConstants.ACTION_COOLDOWN_SECONDS then
		return false
	end

	lastActionAt[player.UserId] = now
	return true
end

local function getBagItem(data: PlayerProfileTypes.PlayerProfile, bagSlotKey: string): InventoryTypes.InventoryItem?
	if not InventoryTypes.isValidBagSlotKey(bagSlotKey) then
		return nil
	end

	return data.inventory[bagSlotKey]
end

local function findEmptyBagSlotKey(bag: InventoryTypes.BagSlots): string?
	for slotIndex = 1, InventoryConstants.BAG_SLOT_COUNT do
		local slotKey = InventoryConstants.getBagSlotKey(slotIndex)

		if bag[slotKey] == nil then
			return slotKey
		end
	end

	return nil
end

local function syncInventory(player: Player, data: PlayerProfileTypes.PlayerProfile)
	PlayerSyncService.syncInventoryToClient(player, data)
	PlayerDataService:SaveProfile(player)
end

function InventoryService.grantItem(player: Player, itemId: string, quantity: number): boolean
	if quantity <= 0 then
		return false
	end

	local definition = Items.get(itemId)

	if definition == nil then
		return false
	end

	local data = PlayerDataService:GetData(player)

	if data == nil then
		return false
	end

	local remaining = quantity
	local maxStack = InventoryConstants.getMaxStack(itemId)

	for slotIndex = 1, InventoryConstants.BAG_SLOT_COUNT do
		if remaining <= 0 then
			break
		end

		local slotKey = InventoryConstants.getBagSlotKey(slotIndex)
		local slotItem = data.inventory[slotKey]

		if slotItem ~= nil and slotItem.itemId == itemId then
			local space = maxStack - slotItem.quantity

			if space > 0 then
				local added = math.min(space, remaining)
				slotItem.quantity += added
				remaining -= added
			end
		end
	end

	while remaining > 0 do
		local emptySlotKey = findEmptyBagSlotKey(data.inventory)

		if emptySlotKey == nil then
			break
		end

		local added = math.min(maxStack, remaining)
		data.inventory[emptySlotKey] = {
			itemId = itemId,
			quantity = added,
		}
		remaining -= added
	end

	if remaining < quantity then
		syncInventory(player, data)
	end

	return remaining <= 0
end

function InventoryService.countItem(data: PlayerProfileTypes.PlayerProfile, itemId: string): number
	local total = 0

	for _, slotItem in data.inventory do
		if slotItem.itemId == itemId then
			total += slotItem.quantity
		end
	end

	return total
end

function InventoryService.canFitOutputs(
	data: PlayerProfileTypes.PlayerProfile,
	outputs: { { itemId: string, quantity: number } }
): boolean
	local simulatedBag: InventoryTypes.BagSlots = {}

	for slotKey, slotItem in data.inventory do
		simulatedBag[slotKey] = {
			itemId = slotItem.itemId,
			quantity = slotItem.quantity,
		}
	end

	for _, output in outputs do
		local definition = Items.get(output.itemId)

		if definition == nil or output.quantity <= 0 then
			return false
		end

		local remaining = output.quantity
		local maxStack = InventoryConstants.getMaxStack(output.itemId)

		for slotIndex = 1, InventoryConstants.BAG_SLOT_COUNT do
			if remaining <= 0 then
				break
			end

			local slotKey = InventoryConstants.getBagSlotKey(slotIndex)
			local slotItem = simulatedBag[slotKey]

			if slotItem ~= nil and slotItem.itemId == output.itemId then
				local space = maxStack - slotItem.quantity

				if space > 0 then
					local added = math.min(space, remaining)
					slotItem.quantity += added
					remaining -= added
				end
			end
		end

		while remaining > 0 do
			local emptySlotKey: string? = nil

			for slotIndex = 1, InventoryConstants.BAG_SLOT_COUNT do
				local slotKey = InventoryConstants.getBagSlotKey(slotIndex)

				if simulatedBag[slotKey] == nil then
					emptySlotKey = slotKey
					break
				end
			end

			if emptySlotKey == nil then
				return false
			end

			local added = math.min(maxStack, remaining)
			simulatedBag[emptySlotKey] = {
				itemId = output.itemId,
				quantity = added,
			}
			remaining -= added
		end
	end

	return true
end

function InventoryService.removeItems(
	player: Player,
	data: PlayerProfileTypes.PlayerProfile,
	inputs: { { itemId: string, quantity: number } }
): boolean
	for _, input in inputs do
		if InventoryService.countItem(data, input.itemId) < input.quantity then
			return false
		end
	end

	local removedKeys: { [string]: boolean } = {}

	for _, input in inputs do
		local remaining = input.quantity

		for slotIndex = 1, InventoryConstants.BAG_SLOT_COUNT do
			if remaining <= 0 then
				break
			end

			local slotKey = InventoryConstants.getBagSlotKey(slotIndex)
			local slotItem = data.inventory[slotKey]

			if slotItem ~= nil and slotItem.itemId == input.itemId then
				local removed = math.min(slotItem.quantity, remaining)
				slotItem.quantity -= removed
				remaining -= removed

				if slotItem.quantity <= 0 then
					data.inventory[slotKey] = nil
					removedKeys[slotKey] = true

					if data.equipped.toolItemId == input.itemId then
						local stillHasItem = InventoryService.countItem(data, input.itemId) > 0

						if not stillHasItem then
							data.equipped.toolItemId = nil
						end
					end
				end
			end
		end

		if remaining > 0 then
			return false
		end
	end

	InventoryTypes.clearHotbarReferences(data.hotbar, removedKeys)
	syncInventory(player, data)
	return true
end

function InventoryService.grantItems(
	player: Player,
	outputs: { { itemId: string, quantity: number } }
): boolean
	for _, output in outputs do
		local granted = InventoryService.grantItem(player, output.itemId, output.quantity)

		if not granted then
			return false
		end
	end

	return true
end

function InventoryService.removeFromBagSlot(
	player: Player,
	data: PlayerProfileTypes.PlayerProfile,
	bagSlotKey: string,
	quantity: number
): boolean
	local slotItem = getBagItem(data, bagSlotKey)

	if slotItem == nil or quantity <= 0 or slotItem.quantity < quantity then
		return false
	end

	slotItem.quantity -= quantity
	local removedItemId = slotItem.itemId

	if slotItem.quantity <= 0 then
		data.inventory[bagSlotKey] = nil
		InventoryTypes.clearHotbarReferences(data.hotbar, { [bagSlotKey] = true })

		if data.equipped.toolItemId == removedItemId then
			data.equipped.toolItemId = nil
		end
	end

	syncInventory(player, data)
	return true
end

function InventoryService.applyDeathPenalty(player: Player, data: PlayerProfileTypes.PlayerProfile)
	local occupiedKeys = InventoryTypes.getOccupiedBagKeys(data.inventory)

	if #occupiedKeys == 0 then
		return
	end

	local slotsToRemove = math.ceil(#occupiedKeys * SurvivalConstants.DEATH_INVENTORY_LOSS_FRACTION)
	local shuffledKeys = table.clone(occupiedKeys)

	for index = #shuffledKeys, 2, -1 do
		local swapIndex = math.random(1, index)
		shuffledKeys[index], shuffledKeys[swapIndex] = shuffledKeys[swapIndex], shuffledKeys[index]
	end

	local removedKeys: { [string]: boolean } = {}

	for index = 1, slotsToRemove do
		local slotKey = shuffledKeys[index]
		removedKeys[slotKey] = true
		data.inventory[slotKey] = nil
	end

	InventoryTypes.clearHotbarReferences(data.hotbar, removedKeys)

	if data.equipped.toolItemId ~= nil then
		local stillEquipped = false

		for _, item in data.inventory do
			if item.itemId == data.equipped.toolItemId then
				stillEquipped = true
				break
			end
		end

		if not stillEquipped then
			data.equipped.toolItemId = nil
		end
	end
end

local function equipTool(player: Player, bagSlotKey: unknown)
	if type(bagSlotKey) ~= "string" or not canPerformAction(player) then
		return
	end

	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	local slotItem = getBagItem(data, bagSlotKey)

	if slotItem == nil then
		return
	end

	local definition = Items.get(slotItem.itemId)

	if definition == nil or definition.category ~= "tool" then
		return
	end

	if data.equipped.toolItemId == slotItem.itemId then
		data.equipped.toolItemId = nil
		syncInventory(player, data)
		return
	end

	data.equipped.toolItemId = slotItem.itemId
	syncInventory(player, data)
end

local function unequipTool(player: Player)
	if not canPerformAction(player) then
		return
	end

	local data = PlayerDataService:GetData(player)

	if data == nil or data.equipped.toolItemId == nil then
		return
	end

	data.equipped.toolItemId = nil
	syncInventory(player, data)
end

local function setHotbarSlot(player: Player, hotbarIndex: unknown, bagSlotKey: unknown)
	if type(hotbarIndex) ~= "number" or not canPerformAction(player) then
		return
	end

	local normalizedIndex = math.floor(hotbarIndex)

	if normalizedIndex < 1 or normalizedIndex > InventoryConstants.HOTBAR_SLOT_COUNT then
		return
	end

	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	if bagSlotKey == nil then
		data.hotbar[normalizedIndex] = nil
		syncInventory(player, data)
		return
	end

	if type(bagSlotKey) ~= "string" or not InventoryTypes.isValidBagSlotKey(bagSlotKey) then
		return
	end

	if getBagItem(data, bagSlotKey) == nil then
		return
	end

	data.hotbar[normalizedIndex] = bagSlotKey
	syncInventory(player, data)
end

local function useItem(player: Player, bagSlotKey: unknown)
	if type(bagSlotKey) ~= "string" or not canPerformAction(player) then
		return
	end

	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	local slotItem = getBagItem(data, bagSlotKey)

	if slotItem == nil then
		return
	end

	if slotItem.itemId == "bandage" then
		data.survival.health = math.clamp(data.survival.health + InventoryConstants.BANDAGE_HEAL_AMOUNT, 0, 100)
		InventoryService.removeFromBagSlot(player, data, bagSlotKey, 1)
		PlayerSyncService.syncSurvivalToClient(player, data)
		return
	end
end

local function grantStudioStarterItems(player: Player)
	if not RunService:IsStudio() then
		return
	end

	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	if #InventoryTypes.getOccupiedBagKeys(data.inventory) > 0 then
		return
	end

	InventoryService.grantItem(player, "stick", 5)
	InventoryService.grantItem(player, "flint", 2)
	InventoryService.grantItem(player, "leaf", 4)
	InventoryService.grantItem(player, "fiber", 4)
	InventoryService.grantItem(player, "wood", 16)
	InventoryService.grantItem(player, "stone", 4)
	InventoryService.grantItem(player, "rope", 2)
	InventoryService.grantItem(player, "bandage", 3)
	InventoryService.grantItem(player, "stone_axe", 1)
	Logger.info("InventoryService", `Granted studio starter items to {player.Name}`)
end

local function onPlayerAdded(player: Player)
	task.spawn(function()
		for _ = 1, 20 do
			if PlayerDataService:GetData(player) ~= nil then
				grantStudioStarterItems(player)
				return
			end

			task.wait(0.25)
		end
	end)
end

function InventoryService:Init()
	local trove = self:GetTrove()

	trove:Connect(Networking.getEvent("EquipItemEvent").OnServerEvent, equipTool)
	trove:Connect(Networking.getEvent("UnequipItemEvent").OnServerEvent, unequipTool)
	trove:Connect(Networking.getEvent("SetHotbarSlotEvent").OnServerEvent, setHotbarSlot)
	trove:Connect(Networking.getEvent("UseItemEvent").OnServerEvent, useItem)
end

function InventoryService:Start()
	local trove = self:GetTrove()

	trove:Connect(Players.PlayerAdded, onPlayerAdded)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Logger.info("InventoryService", "Inventory is active")
end

return InventoryService
