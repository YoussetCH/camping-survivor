--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CampTypes = require(ReplicatedStorage.Shared.Types.Camp)
local CampProximity = require(ReplicatedStorage.Shared.Utilities.CampProximity)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)

export type CampRepositoryModule = {
	normalize: (camp: CampTypes.CampData) -> (),
	prepareForPersistence: (camp: CampTypes.CampData) -> (),
}

local function normalizePosition(value: unknown): CampTypes.SerializedVector3?
	local vector = CampProximity.toVector3(value)

	if vector == nil then
		return nil
	end

	return CampProximity.serializeVector3(vector)
end

local function normalizeStructures(camp: CampTypes.CampData)
	local validStructures: { CampTypes.CampStructure } = {}

	for _, structure in camp.structures do
		local position = normalizePosition(structure.position)

		if position == nil then
			Logger.warn("CampRepository", `Dropped structure {structure.structureId} with invalid position`)
			continue
		end

		structure.position = position
		table.insert(validStructures, structure)
	end

	camp.structures = validStructures
end

local CampRepository: CampRepositoryModule = {
	normalize = function(camp: CampTypes.CampData)
		if type(camp.level) ~= "number" then
			camp.level = 0
		end

		if type(camp.structures) ~= "table" then
			camp.structures = {}
		end

		if type(camp.chests) ~= "table" then
			camp.chests = {}
		end

		normalizeStructures(camp)
	end,

	prepareForPersistence = function(camp: CampTypes.CampData)
		normalizeStructures(camp)
	end,
}

return CampRepository
