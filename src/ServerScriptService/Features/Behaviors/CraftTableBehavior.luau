--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CampConstants = require(ReplicatedStorage.Shared.Constants.CampConstants)
local CraftingConstants = require(ReplicatedStorage.Shared.Constants.CraftingConstants)
local StructureBehaviorRegistry = require(ServerScriptService.Features.StructureBehaviorRegistry)
local StationRegistry = require(ServerScriptService.Features.StationRegistry)

local BLUEPRINT_ID = "bp_craft_table"

local function register()
	StationRegistry.register({
		stationId = CraftingConstants.CRAFT_TABLE_STATION,
		blueprintId = BLUEPRINT_ID,
		rangeStuds = CampConstants.CRAFT_TABLE_RANGE,
	})

	StructureBehaviorRegistry.register({
		blueprintId = BLUEPRINT_ID,
	})
end

register()

return {}
