--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CampProximity = require(ReplicatedStorage.Shared.Utilities.CampProximity)
local PlayerDataService = require(script.Parent.Parent.Services.PlayerDataService)
local StructuresConstants = require(ReplicatedStorage.Shared.Constants.StructuresConstants)

export type StationRegistration = {
	stationId: string,
	blueprintId: string,
	rangeStuds: number,
}

export type StationRegistryModule = {
	register: (registration: StationRegistration) -> (),
	isPlayerNearStation: (player: Player, stationId: string) -> boolean,
}

local stations: { [string]: StationRegistration } = {}

local StationRegistry: StationRegistryModule = {
	register = function(registration: StationRegistration)
		stations[registration.stationId] = registration
	end,
	isPlayerNearStation = function(player: Player, stationId: string): boolean
		local registration = stations[stationId]

		if registration == nil then
			return false
		end

		local data = PlayerDataService:GetData(player)

		if data == nil or data.camp.plotId == nil then
			return false
		end

		local character = player.Character
		local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil

		if root == nil or not root:IsA("BasePart") then
			return false
		end

		local plotId = data.camp.plotId :: string
		local plotFolder = CampProximity.findPlotStructureFolder(plotId)

		if plotFolder ~= nil and CampProximity.isNearStationInFolder(root.Position, plotFolder, stationId, player.UserId) then
			return true
		end

		local range = registration.rangeStuds

		for _, structure in data.camp.structures do
			if structure.blueprintId ~= registration.blueprintId then
				continue
			end

			local definition = StructuresConstants.get(structure.blueprintId)

			if definition ~= nil and definition.station == stationId then
				local position = CampProximity.toVector3(structure.position)

				if position ~= nil and CampProximity.horizontalDistance(root.Position, position) <= range then
					return true
				end
			end
		end

		return false
	end,
}

return StationRegistry
