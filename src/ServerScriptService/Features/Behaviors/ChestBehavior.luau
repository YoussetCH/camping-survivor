--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CampConstants = require(ReplicatedStorage.Shared.Constants.CampConstants)
local InventoryConstants = require(ReplicatedStorage.Shared.Constants.InventoryConstants)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local CampTypes = require(ReplicatedStorage.Shared.Types.Camp)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.Inventory)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)
local InventoryService = require(ServerScriptService.Services.InventoryService)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local PlayerSyncService = require(ServerScriptService.Services.PlayerSyncService)
local StructureBehaviorRegistry = require(ServerScriptService.Features.StructureBehaviorRegistry)

local BLUEPRINT_ID = "bp_chest"

local syncCamp: ((player: Player, data: PlayerProfileTypes.PlayerProfile) -> ())? = nil

local function findChestItem(chest: InventoryTypes.BagSlots, chestSlotKey: string): InventoryTypes.InventoryItem?
	if not CampConstants.isValidChestSlotKey(chestSlotKey) then
		return nil
	end

	return chest[chestSlotKey]
end

local function findEmptyChestSlot(chest: InventoryTypes.BagSlots): string?
	for slotIndex = 1, CampConstants.CHEST_SLOT_COUNT do
		local slotKey = CampConstants.getChestSlotKey(slotIndex)

		if chest[slotKey] == nil then
			return slotKey
		end
	end

	return nil
end

local function syncChestState(player: Player, data: PlayerProfileTypes.PlayerProfile)
	PlayerSyncService.syncInventoryToClient(player, data)

	if syncCamp ~= nil then
		syncCamp(player, data)
	end
end

local function transferToChest(
	player: Player,
	data: PlayerProfileTypes.PlayerProfile,
	chestStructureId: string,
	bagSlotKey: string,
	chestSlotKey: string?
)
	local chest = data.camp.chests[chestStructureId]

	if chest == nil then
		return
	end

	local bagItem = data.inventory[bagSlotKey]

	if bagItem == nil then
		return
	end

	local targetChestSlotKey = chestSlotKey or findEmptyChestSlot(chest)

	if targetChestSlotKey == nil then
		return
	end

	local maxStack = InventoryConstants.getMaxStack(bagItem.itemId)
	local chestItem = chest[targetChestSlotKey]

	if chestItem ~= nil and chestItem.itemId ~= bagItem.itemId then
		return
	end

	if chestItem == nil then
		chest[targetChestSlotKey] = {
			itemId = bagItem.itemId,
			quantity = bagItem.quantity,
		}
		data.inventory[bagSlotKey] = nil
		InventoryTypes.clearHotbarReferences(data.hotbar, { [bagSlotKey] = true })
	else
		local space = maxStack - chestItem.quantity

		if space <= 0 then
			return
		end

		local moved = math.min(space, bagItem.quantity)
		chestItem.quantity += moved
		bagItem.quantity -= moved

		if bagItem.quantity <= 0 then
			data.inventory[bagSlotKey] = nil
			InventoryTypes.clearHotbarReferences(data.hotbar, { [bagSlotKey] = true })
		end
	end

	syncChestState(player, data)
end

local function transferToBag(
	player: Player,
	data: PlayerProfileTypes.PlayerProfile,
	chestStructureId: string,
	chestSlotKey: string,
	bagSlotKey: string?
)
	local chest = data.camp.chests[chestStructureId]

	if chest == nil then
		return
	end

	local chestItem = findChestItem(chest, chestSlotKey)

	if chestItem == nil then
		return
	end

	if bagSlotKey ~= nil then
		local bagItem = data.inventory[bagSlotKey]

		if bagItem == nil then
			data.inventory[bagSlotKey] = {
				itemId = chestItem.itemId,
				quantity = chestItem.quantity,
			}
			chest[chestSlotKey] = nil
		elseif bagItem.itemId == chestItem.itemId then
			local maxStack = InventoryConstants.getMaxStack(chestItem.itemId)
			local space = maxStack - bagItem.quantity

			if space <= 0 then
				return
			end

			local moved = math.min(space, chestItem.quantity)
			bagItem.quantity += moved
			chestItem.quantity -= moved

			if chestItem.quantity <= 0 then
				chest[chestSlotKey] = nil
			end
		else
			return
		end
	else
		local granted = InventoryService.grantItem(player, chestItem.itemId, chestItem.quantity)

		if not granted then
			return
		end

		chest[chestSlotKey] = nil
	end

	syncChestState(player, data)
end

local function ownsChestStructure(data: PlayerProfileTypes.PlayerProfile, chestStructureId: string): boolean
	for _, structure in data.camp.structures do
		if structure.structureId == chestStructureId and structure.blueprintId == BLUEPRINT_ID then
			return true
		end
	end

	return false
end

local function transferItem(player: Player, request: unknown)
	if type(request) ~= "table" then
		return
	end

	local payload = request :: CampTypes.TransferItemRequest
	local direction = payload.direction
	local chestStructureId = payload.chestStructureId

	if direction ~= "toChest" and direction ~= "toBag" then
		return
	end

	if type(chestStructureId) ~= "string" then
		return
	end

	local data = PlayerDataService:GetData(player)

	if data == nil or not ownsChestStructure(data, chestStructureId) then
		return
	end

	if direction == "toChest" then
		if type(payload.bagSlotKey) ~= "string" or not InventoryTypes.isValidBagSlotKey(payload.bagSlotKey) then
			return
		end

		local chestSlotKey = if type(payload.chestSlotKey) == "string" then payload.chestSlotKey else nil

		if chestSlotKey ~= nil and not CampConstants.isValidChestSlotKey(chestSlotKey) then
			return
		end

		transferToChest(player, data, chestStructureId, payload.bagSlotKey, chestSlotKey)
		return
	end

	if type(payload.chestSlotKey) ~= "string" or not CampConstants.isValidChestSlotKey(payload.chestSlotKey) then
		return
	end

	local bagSlotKey = if type(payload.bagSlotKey) == "string" then payload.bagSlotKey else nil

	if bagSlotKey ~= nil and not InventoryTypes.isValidBagSlotKey(bagSlotKey) then
		return
	end

	transferToBag(player, data, chestStructureId, payload.chestSlotKey, bagSlotKey)
end

local ChestBehavior = {}

function ChestBehavior.setSyncCamp(callback: (player: Player, data: PlayerProfileTypes.PlayerProfile) -> ())
	syncCamp = callback
end

function ChestBehavior.bindRemotes(connect: (signal: RBXScriptSignal, handler: (Player, ...any) -> ()) -> ())
	connect(Networking.getEvent("TransferItemEvent").OnServerEvent, transferItem)
end

local function register()
	StructureBehaviorRegistry.register({
		blueprintId = BLUEPRINT_ID,
		onPlace = function(ctx)
			ctx.data.camp.chests[ctx.structure.structureId] = {}
		end,
		onDemolish = function(ctx)
			ctx.data.camp.chests[ctx.structure.structureId] = nil
		end,
	})
end

register()

return ChestBehavior
