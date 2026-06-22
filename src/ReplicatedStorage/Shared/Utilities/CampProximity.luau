--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CampConstants = require(ReplicatedStorage.Shared.Constants.CampConstants)
local CraftingConstants = require(ReplicatedStorage.Shared.Constants.CraftingConstants)
local StructuresConstants = require(ReplicatedStorage.Shared.Constants.StructuresConstants)

local CampProximity = {}

function CampProximity.toVector3(value: unknown): Vector3?
	if typeof(value) == "Vector3" then
		return value
	end

	if type(value) == "table" then
		local raw = value :: { [string]: unknown }
		local x = raw.X or raw.x or raw[1]
		local y = raw.Y or raw.y or raw[2]
		local z = raw.Z or raw.z or raw[3]

		if type(x) == "number" and type(y) == "number" and type(z) == "number" then
			return Vector3.new(x, y, z)
		end
	end

	return nil
end

function CampProximity.serializeVector3(value: Vector3): { x: number, y: number, z: number }
	return {
		x = value.X,
		y = value.Y,
		z = value.Z,
	}
end

function CampProximity.horizontalDistance(fromPosition: Vector3, toPosition: Vector3): number
	local flatFrom = Vector3.new(fromPosition.X, 0, fromPosition.Z)
	local flatTo = Vector3.new(toPosition.X, 0, toPosition.Z)

	return (flatFrom - flatTo).Magnitude
end

function CampProximity.getStationRange(station: string): number
	if station == CraftingConstants.CRAFT_TABLE_STATION then
		return CampConstants.CRAFT_TABLE_RANGE
	end

	if station == CraftingConstants.CAMPFIRE_STATION then
		return CampConstants.CAMPFIRE_RANGE
	end

	return 0
end

function CampProximity.isNearStructureModel(
	playerPosition: Vector3,
	structureModel: Model,
	station: string
): boolean
	local definition = StructuresConstants.get(structureModel:GetAttribute("BlueprintId") :: string)

	if definition == nil or definition.station ~= station then
		return false
	end

	local root = structureModel.PrimaryPart

	if root == nil then
		return false
	end

	return CampProximity.horizontalDistance(playerPosition, root.Position) <= CampProximity.getStationRange(station)
end

function CampProximity.isNearStationInFolder(
	playerPosition: Vector3,
	plotFolder: Instance,
	station: string,
	ownerUserId: number?
): boolean
	for _, child in plotFolder:GetChildren() do
		if not child:IsA("Model") then
			continue
		end

		if ownerUserId ~= nil then
			local structureOwner = child:GetAttribute("OwnerUserId")

			if structureOwner ~= ownerUserId then
				continue
			end
		end

		if CampProximity.isNearStructureModel(playerPosition, child, station) then
			return true
		end
	end

	return false
end

function CampProximity.findPlotStructureFolder(plotId: string): Folder?
	local campHub = workspace:FindFirstChild("CampHub")

	if campHub == nil then
		return nil
	end

	local structuresRoot = campHub:FindFirstChild("Structures")

	if structuresRoot == nil then
		return nil
	end

	local plotFolder = structuresRoot:FindFirstChild(plotId)

	if plotFolder ~= nil and plotFolder:IsA("Folder") then
		return plotFolder
	end

	return nil
end

return CampProximity
