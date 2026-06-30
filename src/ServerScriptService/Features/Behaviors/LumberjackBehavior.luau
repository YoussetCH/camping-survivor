--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local HelperBehaviorRegistry = require(ServerScriptService.Features.HelperBehaviorRegistry)
local InventoryService = require(ServerScriptService.Services.InventoryService)
local ResourceNodesConstants = require(ReplicatedStorage.Shared.Constants.ResourceNodesConstants)
local LumberjackDefinition = require(ReplicatedStorage.Shared.Features.Lumberjack.LumberjackDefinition)
local LumberjackModel = require(ReplicatedStorage.Shared.Features.Lumberjack.LumberjackModel)
local HelperTypes = require(ReplicatedStorage.Shared.Types.Helper)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)

local function hasActiveCampfire(data: PlayerProfileTypes.PlayerProfile): boolean
	if type(data.camp.structures) ~= "table" then
		return false
	end

	for _, structure in data.camp.structures do
		if structure.blueprintId == "bp_campfire" then
			if structure.hp == nil or structure.hp > 0 then
				return true
			end
		end
	end

	return false
end

local function hasAxeInChests(data: PlayerProfileTypes.PlayerProfile): boolean
	if type(data.camp.chests) ~= "table" then
		return false
	end

	for _, chestSlots in data.camp.chests do
		if type(chestSlots) ~= "table" then
			continue
		end

		for _, slot in chestSlots do
			if type(slot) == "table" and type(slot.itemId) == "string" then
				if ResourceNodesConstants.matchesAxeTool(slot.itemId) then
					return true
				end
			end
		end
	end

	return false
end

local function hasAxeOnPlayer(data: PlayerProfileTypes.PlayerProfile): boolean
	if ResourceNodesConstants.matchesAxeTool(data.equipped.toolItemId) then
		return true
	end

	if type(data.inventory) ~= "table" then
		return false
	end

	for _, slotItem in data.inventory do
		if type(slotItem) == "table" and ResourceNodesConstants.matchesAxeTool(slotItem.itemId) then
			return true
		end
	end

	return false
end

local function hasWeakStatus(helperState: HelperTypes.HelperState): boolean
	for _, effect in helperState.statusEffects do
		if effect.id == "weak" then
			return true
		end
	end

	return false
end

HelperBehaviorRegistry.register({
	helperTypeId = LumberjackDefinition.helperTypeId,
	definition = LumberjackDefinition,
	buildModel = LumberjackModel.build,
	canWork = function(context: HelperTypes.HelperWorkContext): boolean
		local data = context.data :: PlayerProfileTypes.PlayerProfile
		local helperState = context.helperState

		if helperState.mode ~= "work" or helperState.health <= 0 or helperState.hunger <= 0 then
			return false
		end

		if hasWeakStatus(helperState) then
			return false
		end

		if data.camp.plotId == nil then
			return false
		end

		return hasActiveCampfire(data) or hasAxeInChests(data) or hasAxeOnPlayer(data)
	end,
	onWorkTick = function(context: HelperTypes.HelperWorkContext): boolean
		local helperState = context.helperState

		if helperState.hunger <= 0 then
			return false
		end

		if helperState.hunger <= 20 and math.random() > 0.5 then
			return false
		end

		return InventoryService.grantItem(context.player, "wood", 1)
	end,
})

return {}
