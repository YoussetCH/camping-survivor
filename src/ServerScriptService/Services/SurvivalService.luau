--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseService = require(ServerScriptService.Kernel.BaseService)
local BiomeService = require(ServerScriptService.Services.BiomeService)
local GameEvents = require(ServerScriptService.Features.GameEvents)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local InventoryService = require(ServerScriptService.Services.InventoryService)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local PlayerSyncService = require(ServerScriptService.Services.PlayerSyncService)
local StatusEffectConstants = require(ReplicatedStorage.Shared.Constants.StatusEffectConstants)
local SurvivalConstants = require(ReplicatedStorage.Shared.Constants.SurvivalConstants)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)
local SurvivalTypes = require(ReplicatedStorage.Shared.Types.Survival)

local SurvivalService = BaseService.new("SurvivalService")

local tickThread: thread? = nil

local function roundStat(value: number): number
	return math.clamp(math.round(value), 0, 100)
end

local function clampStats(survival: SurvivalTypes.SurvivalStats)
	survival.hunger = math.clamp(survival.hunger, 0, 100)
	survival.thirst = math.clamp(survival.thirst, 0, 100)
	survival.health = math.clamp(survival.health, 0, 100)
	survival.temperature = math.clamp(survival.temperature, 0, 100)
end

local function haveStatsChanged(previous: SurvivalTypes.SurvivalStats, current: SurvivalTypes.SurvivalStats): boolean
	local epsilon = 0.01

	return math.abs(previous.hunger - current.hunger) >= epsilon
		or math.abs(previous.thirst - current.thirst) >= epsilon
		or math.abs(previous.health - current.health) >= epsilon
		or math.abs(previous.temperature - current.temperature) >= epsilon
end

local function hasStatusEffect(statusEffects: { SurvivalTypes.StatusEffect }, effectId: string): boolean
	for _, effect in statusEffects do
		if effect.id == effectId then
			return true
		end
	end

	return false
end

local function removeStatusEffectById(statusEffects: { SurvivalTypes.StatusEffect }, effectId: string): boolean
	for index, effect in statusEffects do
		if effect.id == effectId then
			table.remove(statusEffects, index)
			return true
		end
	end

	return false
end

local function computeStatusHpDamagePerMinute(statusEffects: { SurvivalTypes.StatusEffect }): number
	local damage = 0

	if hasStatusEffect(statusEffects, "bleeding") then
		damage += StatusEffectConstants.BLEEDING_HP_PER_TICK * (60 / SurvivalConstants.TICK_INTERVAL_SECONDS)
	end

	if hasStatusEffect(statusEffects, "poison") then
		damage += StatusEffectConstants.POISON_HP_PER_TICK * (60 / SurvivalConstants.TICK_INTERVAL_SECONDS)
	end

	if hasStatusEffect(statusEffects, "infection") then
		damage += StatusEffectConstants.INFECTION_HP_PER_TICK * (60 / SurvivalConstants.TICK_INTERVAL_SECONDS)
	end

	return damage
end

local function updateStatusTransitions(data: PlayerProfileTypes.PlayerProfile)
	local now = os.clock()

	for _, effect in data.statusEffects do
		if effect.id == "bleeding" and effect.appliedAt ~= nil then
			if now - effect.appliedAt >= StatusEffectConstants.BLEEDING_TO_INFECTION_SECONDS then
				if not hasStatusEffect(data.statusEffects, "infection") then
					table.insert(data.statusEffects, {
						id = "infection",
						appliedAt = now,
					})
				end
			end
		end
	end
end

local function applyStatusTickDamage(data: PlayerProfileTypes.PlayerProfile, tickMinutes: number)
	local statusDamagePerMinute = computeStatusHpDamagePerMinute(data.statusEffects)
	data.survival.health -= statusDamagePerMinute * tickMinutes
end
local function hasBlockingStatusEffects(statusEffects: { SurvivalTypes.StatusEffect }): boolean
	for _, effect in statusEffects do
		if effect.id == "bleeding" or effect.id == "poison" or effect.id == "infection" then
			return true
		end
	end

	return false
end

local function computeHpDamagePerMinute(survival: SurvivalTypes.SurvivalStats): number
	local damage = 0

	if survival.hunger <= 10 then
		damage += 1.5
	elseif survival.hunger <= 20 then
		damage += 0.5
	end

	if survival.thirst <= 5 then
		damage += 2
	elseif survival.thirst <= 15 then
		damage += 1
	end

	if survival.temperature <= 15 then
		damage += 2
	end

	if survival.temperature >= 85 then
		damage += 0.5
	end

	return math.min(damage, SurvivalConstants.HP_DAMAGE_CAP_PER_MINUTE)
end

local function computeHpRegenPerMinute(data: PlayerProfileTypes.PlayerProfile): number
	if hasBlockingStatusEffects(data.statusEffects) then
		return 0
	end

	if data.survival.hunger <= 20 or data.survival.thirst <= 15 then
		return 0
	end

	if data.survival.hunger > 40 and data.survival.thirst > 30 then
		if data.camp.plotId ~= nil then
			return 1
		end

		return 0.5
	end

	return 0
end

local function teleportToSpawn(player: Player)
	local character = player.Character

	if character == nil then
		return
	end

	local data = PlayerDataService:GetData(player)

	if data ~= nil and data.camp.plotId ~= nil then
		GameEvents.fireRequestPlotTeleport(player, data.camp.plotId)
		return
	end

	local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation")

	if spawnLocation ~= nil then
		character:PivotTo(spawnLocation.CFrame + Vector3.new(0, 4, 0))
	end
end

local function handleDeath(player: Player, data: PlayerProfileTypes.PlayerProfile)
	if data.tutorialCompleted then
		InventoryService.applyDeathPenalty(player, data)
		PlayerSyncService.syncInventoryToClient(player, data)
		PlayerDataService:SaveProfile(player)
	end

	table.clear(data.statusEffects)

	data.survival.hunger = roundStat(SurvivalConstants.RESPAWN_STATS.hunger)
	data.survival.thirst = roundStat(SurvivalConstants.RESPAWN_STATS.thirst)
	data.survival.health = roundStat(SurvivalConstants.RESPAWN_STATS.health)
	data.survival.temperature = roundStat(SurvivalConstants.RESPAWN_STATS.temperature)
	data.stats.deaths += 1

	PlayerSyncService.syncSurvivalToClient(player, data)
	PlayerDataService:SaveProfile(player)
	player:LoadCharacter()
	teleportToSpawn(player)
	Logger.info("SurvivalService", `{player.Name} died and respawned (deaths: {data.stats.deaths})`)
end

local function processPlayerTick(player: Player, tickMinutes: number)
	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	local character = player.Character

	if character == nil then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid == nil or humanoid.Health <= 0 then
		return
	end

	local previousStats = table.clone(data.survival)
	local survival = data.survival
	local ambient = BiomeService.getAmbientForPlayer(player)

	survival.hunger -= SurvivalConstants.HUNGER_DRAIN_PER_MINUTE * tickMinutes
	survival.thirst -= SurvivalConstants.THIRST_DRAIN_PER_MINUTE * tickMinutes

	if survival.temperature >= 85 then
		survival.thirst -= 1 * tickMinutes
	end

	local temperatureDelta = ambient - survival.temperature

	if temperatureDelta ~= 0 then
		local drift = SurvivalConstants.TEMPERATURE_DRIFT_PER_MINUTE * tickMinutes
		local move = math.sign(temperatureDelta) * math.min(math.abs(temperatureDelta), drift)
		survival.temperature += move
	end

	local hpDeltaPerMinute = computeHpRegenPerMinute(data) - computeHpDamagePerMinute(survival)
	survival.health += hpDeltaPerMinute * tickMinutes
	updateStatusTransitions(data)
	applyStatusTickDamage(data, tickMinutes)
	clampStats(survival)

	local didStatsChange = haveStatsChanged(previousStats, survival)

	if survival.health <= 0 then
		handleDeath(player, data)
		return
	end

	if didStatsChange then
		PlayerSyncService.syncSurvivalToClient(player, data)
	end
end

local function processTick()
	for _, player in Players:GetPlayers() do
		processPlayerTick(player, SurvivalConstants.TICK_INTERVAL_SECONDS / 60)
	end
end

function SurvivalService.addStatusEffect(player: Player, effectId: string)
	local data = PlayerDataService:GetData(player)
	if data == nil or hasStatusEffect(data.statusEffects, effectId) then
		return
	end

	table.insert(data.statusEffects, {
		id = effectId,
		appliedAt = os.clock(),
	})
	PlayerSyncService.syncSurvivalToClient(player, data)
end

function SurvivalService.removeStatusEffect(player: Player, effectId: string)
	local data = PlayerDataService:GetData(player)
	if data == nil then
		return
	end

	if removeStatusEffectById(data.statusEffects, effectId) then
		PlayerSyncService.syncSurvivalToClient(player, data)
	end
end

function SurvivalService.clearStatusEffects(player: Player)
	local data = PlayerDataService:GetData(player)
	if data == nil then
		return
	end

	table.clear(data.statusEffects)
	PlayerSyncService.syncSurvivalToClient(player, data)
end

function SurvivalService.applyDamage(player: Player, amount: number, statusEffectIds: { string }?)
	local QuestService = require(ServerScriptService.Services.QuestService)

	if QuestService.isTutorialActive(player) then
		return
	end

	local data = PlayerDataService:GetData(player)
	if data == nil then
		return
	end

	data.survival.health = math.clamp(data.survival.health - amount, 0, 100)

	if statusEffectIds ~= nil then
		for _, effectId in statusEffectIds do
			if not hasStatusEffect(data.statusEffects, effectId) then
				table.insert(data.statusEffects, {
					id = effectId,
					appliedAt = os.clock(),
				})
			end
		end
	end

	PlayerSyncService.syncSurvivalToClient(player, data)

	if data.survival.health <= 0 then
		handleDeath(player, data)
	end
end

function SurvivalService:Start()
	local function scheduleTick()
		processTick()
		tickThread = task.delay(SurvivalConstants.TICK_INTERVAL_SECONDS, scheduleTick)
	end

	scheduleTick()
	Logger.info("SurvivalService", `Survival tick active every {SurvivalConstants.TICK_INTERVAL_SECONDS}s`)
end

function SurvivalService:Destroy()
	if tickThread ~= nil then
		task.cancel(tickThread)
		tickThread = nil
	end

	BaseService.Destroy(self)
end

return SurvivalService
