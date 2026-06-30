--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseService = require(ServerScriptService.Kernel.BaseService)
local DayNightService = require(ServerScriptService.Services.DayNightService)
local GameEvents = require(ServerScriptService.Features.GameEvents)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local WorldConstants = require(ReplicatedStorage.Shared.Constants.WorldConstants)

local BiomeService = BaseService.new("BiomeService")

type BiomeZoneEntry = {
	part: BasePart,
	volume: number,
	biomeId: string,
}

local biomeZones: { BiomeZoneEntry } = {}
local playerBiomeIds: { [number]: string } = {}
local biomeTickThread: thread? = nil

local function getPartVolume(part: BasePart): number
	local size = part.Size
	return size.X * size.Y * size.Z
end

local function isPointInsidePart(point: Vector3, part: BasePart): boolean
	local localPoint = part.CFrame:PointToObjectSpace(point)
	local halfSize = part.Size / 2

	return math.abs(localPoint.X) <= halfSize.X
		and math.abs(localPoint.Y) <= halfSize.Y + 12
		and math.abs(localPoint.Z) <= halfSize.Z
end

local function scanBiomeZones()
	table.clear(biomeZones)

	for _, instance in CollectionService:GetTagged(WorldConstants.BIOME_ZONE_TAG) do
		if instance:IsA("BasePart") then
			local biomeId = instance:GetAttribute(WorldConstants.BIOME_ID_ATTRIBUTE)

			if type(biomeId) == "string" and biomeId ~= "" then
				table.insert(biomeZones, {
					part = instance,
					volume = getPartVolume(instance),
					biomeId = biomeId,
				})
			end
		end
	end

	table.sort(biomeZones, function(left, right)
		return left.volume < right.volume
	end)

	Logger.info("BiomeService", `Registered {#biomeZones} biome zones`)
end

function BiomeService.getBiomeIdAtPosition(position: Vector3): string
	for _, zone in biomeZones do
		if isPointInsidePart(position, zone.part) then
			return zone.biomeId
		end
	end

	return WorldConstants.DEFAULT_BIOME_ID
end

function BiomeService.getBiomeIdForPlayer(player: Player): string
	local character = player.Character

	if character == nil then
		return WorldConstants.DEFAULT_BIOME_ID
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if rootPart == nil or not rootPart:IsA("BasePart") then
		return WorldConstants.DEFAULT_BIOME_ID
	end

	return BiomeService.getBiomeIdAtPosition(rootPart.Position)
end

function BiomeService.getAmbientForPlayer(player: Player): number
	local biomeId = BiomeService.getBiomeIdForPlayer(player)
	local phase = DayNightService.getPhase()

	return WorldConstants.getAmbientForBiome(biomeId, phase)
end

function BiomeService:Init()
	scanBiomeZones()

	self:GetTrove():Connect(CollectionService:GetInstanceAddedSignal(WorldConstants.BIOME_ZONE_TAG), function(instance: Instance)
		if instance:IsA("BasePart") then
			scanBiomeZones()
		end
	end)
end

function BiomeService:Start()
	local function scheduleBiomeTick()
		for _, player in Players:GetPlayers() do
			local biomeId = BiomeService.getBiomeIdForPlayer(player)
			local previousBiomeId = playerBiomeIds[player.UserId]

			if previousBiomeId ~= biomeId then
				playerBiomeIds[player.UserId] = biomeId
				GameEvents.fireBiomeEntered(player, biomeId)
			end
		end

		biomeTickThread = task.delay(2, scheduleBiomeTick)
	end

	scheduleBiomeTick()
end

function BiomeService:Destroy()
	if biomeTickThread ~= nil then
		task.cancel(biomeTickThread)
		biomeTickThread = nil
	end

	BaseService.Destroy(self)
end

return BiomeService
