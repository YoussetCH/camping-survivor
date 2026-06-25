--!strict

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseService = require(ServerScriptService.Kernel.BaseService)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local WorldConstants = require(ReplicatedStorage.Shared.Constants.WorldConstants)
local WorldTypes = require(ReplicatedStorage.Shared.Types.World)

local DayNightService = BaseService.new("DayNightService")

local cycleStartedAt = os.clock()
local cycleSpeedMultiplier = 1
local lastBroadcastPhase: WorldTypes.WorldPhase? = nil
local syncThread: thread? = nil

local function getCycleElapsed(): number
	return ((os.clock() - cycleStartedAt) * cycleSpeedMultiplier) % WorldConstants.CYCLE_SECONDS
end

local function getElapsedForPhase(phase: WorldTypes.WorldPhase): number
	if phase == "night" then
		return WorldConstants.DAY_SECONDS + WorldConstants.TRANSITION_SECONDS + 1
	end

	if phase == "dusk" then
		return WorldConstants.DAY_SECONDS - (WorldConstants.TRANSITION_SECONDS * 0.5)
	end

	if phase == "dawn" then
		return WorldConstants.DAY_SECONDS + WorldConstants.NIGHT_SECONDS - (WorldConstants.TRANSITION_SECONDS * 0.5)
	end

	return WorldConstants.DAY_SECONDS * 0.5
end

local function getPhaseAndProgress(): (WorldTypes.WorldPhase, number)
	local elapsed = getCycleElapsed()
	local progress = elapsed / WorldConstants.CYCLE_SECONDS
	local nightStart = WorldConstants.DAY_SECONDS
	local nightEnd = nightStart + WorldConstants.NIGHT_SECONDS

	if elapsed >= nightEnd - WorldConstants.TRANSITION_SECONDS then
		return "dawn", progress
	end

	if elapsed >= nightStart + WorldConstants.TRANSITION_SECONDS and elapsed < nightEnd - WorldConstants.TRANSITION_SECONDS then
		return "night", progress
	end

	if elapsed >= nightStart and elapsed < nightStart + WorldConstants.TRANSITION_SECONDS then
		return "dusk", progress
	end

	if elapsed >= nightStart - WorldConstants.TRANSITION_SECONDS and elapsed < nightStart then
		return "dusk", progress
	end

	return "day", progress
end

local function getClockTimeForPhase(phase: WorldTypes.WorldPhase): number
	if phase == "day" then
		return 14
	end

	if phase == "night" then
		return 0
	end

	if phase == "dawn" or phase == "dusk" then
		return 6
	end

	return 14
end

local function buildSnapshot(): WorldTypes.WorldSnapshot
	local phase, progress = getPhaseAndProgress()

	return {
		phase = phase,
		cycleProgress = progress,
		serverTime = os.time(),
	}
end

local function broadcastSnapshot(force: boolean?)
	local phase, _ = getPhaseAndProgress()

	if force ~= true and lastBroadcastPhase == phase then
		return
	end

	lastBroadcastPhase = phase
	Lighting.ClockTime = getClockTimeForPhase(phase)

	local snapshot = buildSnapshot()
	local worldUpdatedEvent = Networking.getEvent("WorldUpdatedEvent")
	worldUpdatedEvent:FireAllClients(snapshot)
end

local function handleDebugChatCommand(message: string)
	if not RunService:IsStudio() then
		return
	end

	local lowered = string.lower(message)
	if lowered == "/night" then
		DayNightService.debugSetPhase("night")
		return
	end

	if lowered == "/dusk" then
		DayNightService.debugSetPhase("dusk")
		return
	end

	if lowered == "/dawn" then
		DayNightService.debugSetPhase("dawn")
		return
	end

	if lowered == "/day" then
		DayNightService.debugSetPhase("day")
		return
	end

	if string.sub(lowered, 1, 11) == "/timescale " then
		local value = tonumber(string.sub(lowered, 12))
		if value ~= nil then
			DayNightService.debugSetCycleSpeed(value)
		end
		return
	end

	if string.sub(lowered, 1, 12) == "/cyclespeed " then
		local value = tonumber(string.sub(lowered, 13))
		if value ~= nil then
			DayNightService.debugSetCycleSpeed(value)
		end
	end
end

function DayNightService.getPhase(): WorldTypes.WorldPhase
	local phase, _ = getPhaseAndProgress()
	return phase
end

function DayNightService.getSnapshot(): WorldTypes.WorldSnapshot
	return buildSnapshot()
end

-- Studio-only helpers for quick gameplay testing.
function DayNightService.debugSetPhase(phase: WorldTypes.WorldPhase): boolean
	if not RunService:IsStudio() then
		return false
	end

	local elapsed = getElapsedForPhase(phase)
	cycleStartedAt = os.clock() - (elapsed / cycleSpeedMultiplier)
	broadcastSnapshot(true)
	return true
end

function DayNightService.debugSetCycleSpeed(multiplier: number): boolean
	if not RunService:IsStudio() then
		return false
	end

	if multiplier <= 0 then
		return false
	end

	local currentElapsed = getCycleElapsed()
	cycleSpeedMultiplier = multiplier
	cycleStartedAt = os.clock() - (currentElapsed / cycleSpeedMultiplier)
	broadcastSnapshot(true)
	return true
end

function DayNightService:Init()
	cycleStartedAt = os.clock()
	cycleSpeedMultiplier = 1
	lastBroadcastPhase = nil
end

function DayNightService:Start()
	local trove = self:GetTrove()
	local worldUpdatedEvent = Networking.getEvent("WorldUpdatedEvent")

	local function sendToPlayer(player: Player)
		worldUpdatedEvent:FireClient(player, buildSnapshot())
	end

	trove:Connect(Players.PlayerAdded, sendToPlayer)
	trove:Connect(Players.PlayerAdded, function(player: Player)
		trove:Connect(player.Chatted, handleDebugChatCommand)
	end)

	for _, player in Players:GetPlayers() do
		task.defer(sendToPlayer, player)
		trove:Connect(player.Chatted, handleDebugChatCommand)
	end

	broadcastSnapshot(true)

	local function scheduleSync()
		broadcastSnapshot(true)
		syncThread = task.delay(WorldConstants.WORLD_SYNC_INTERVAL_SECONDS, scheduleSync)
	end

	scheduleSync()
	Logger.info("DayNightService", "Day/night cycle active (20 min)")
end

function DayNightService:Destroy()
	if syncThread ~= nil then
		task.cancel(syncThread)
		syncThread = nil
	end

	BaseService.Destroy(self)
end

return DayNightService
