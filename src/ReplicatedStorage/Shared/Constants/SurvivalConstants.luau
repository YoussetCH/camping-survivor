--!strict

export type AlertLevel = "normal" | "warning" | "danger"

export type StatThresholds = {
	warning: number?,
	danger: number?,
	warningLow: number?,
	warningHigh: number?,
	dangerLow: number?,
	dangerHigh: number?,
}

export type SurvivalConstantsModule = {
	TICK_INTERVAL_SECONDS: number,
	HUNGER_DRAIN_PER_MINUTE: number,
	THIRST_DRAIN_PER_MINUTE: number,
	TEMPERATURE_DRIFT_PER_MINUTE: number,
	DEFAULT_AMBIENT_TEMPERATURE: number,
	HP_DAMAGE_CAP_PER_MINUTE: number,
	DEATH_INVENTORY_LOSS_FRACTION: number,
	RESPAWN_STATS: {
		hunger: number,
		thirst: number,
		health: number,
		temperature: number,
	},
	ALERT_THRESHOLDS: {
		health: StatThresholds,
		hunger: StatThresholds,
		thirst: StatThresholds,
		temperature: StatThresholds,
	},
	getAlertLevel: (statName: string, value: number) -> AlertLevel,
	getAlertKey: (statName: string, value: number) -> string?,
}

local ALERT_THRESHOLDS = {
	health = {
		warning = 40,
		danger = 20,
	},
	hunger = {
		warning = 40,
		danger = 20,
	},
	thirst = {
		warning = 35,
		danger = 15,
	},
	temperature = {
		warningLow = 30,
		warningHigh = 70,
		dangerLow = 15,
		dangerHigh = 85,
	},
}

local ALERT_KEYS = {
	health = "alert.health",
	hunger = "alert.hunger",
	thirst = "alert.thirst",
	temperatureLow = "alert.temperature_low",
	temperatureHigh = "alert.temperature_high",
}

local function getThresholds(statName: string): StatThresholds?
	if statName == "health" then
		return ALERT_THRESHOLDS.health
	end

	if statName == "hunger" then
		return ALERT_THRESHOLDS.hunger
	end

	if statName == "thirst" then
		return ALERT_THRESHOLDS.thirst
	end

	if statName == "temperature" then
		return ALERT_THRESHOLDS.temperature
	end

	return nil
end

local function getAlertLevel(statName: string, value: number): AlertLevel
	local thresholds = getThresholds(statName)

	if thresholds == nil then
		return "normal"
	end

	if statName == "temperature" then
		if thresholds.dangerLow ~= nil and value <= thresholds.dangerLow then
			return "danger"
		end

		if thresholds.dangerHigh ~= nil and value >= thresholds.dangerHigh then
			return "danger"
		end

		if thresholds.warningLow ~= nil and value <= thresholds.warningLow then
			return "warning"
		end

		if thresholds.warningHigh ~= nil and value >= thresholds.warningHigh then
			return "warning"
		end

		return "normal"
	end

	if thresholds.danger ~= nil and value <= thresholds.danger then
		return "danger"
	end

	if thresholds.warning ~= nil and value <= thresholds.warning then
		return "warning"
	end

	return "normal"
end

local function getAlertKey(statName: string, value: number): string?
	local alertLevel = getAlertLevel(statName, value)

	if alertLevel == "normal" then
		return nil
	end

	if statName == "temperature" then
		if value <= (ALERT_THRESHOLDS.temperature.dangerLow or 15) then
			return ALERT_KEYS.temperatureLow
		end

		if value >= (ALERT_THRESHOLDS.temperature.dangerHigh or 85) then
			return ALERT_KEYS.temperatureHigh
		end

		if value <= (ALERT_THRESHOLDS.temperature.warningLow or 30) then
			return ALERT_KEYS.temperatureLow
		end

		if value >= (ALERT_THRESHOLDS.temperature.warningHigh or 70) then
			return ALERT_KEYS.temperatureHigh
		end
	end

	return (ALERT_KEYS :: { [string]: string })[statName]
end

local SurvivalConstants: SurvivalConstantsModule = {
	TICK_INTERVAL_SECONDS = 6,
	HUNGER_DRAIN_PER_MINUTE = 1,
	THIRST_DRAIN_PER_MINUTE = 1.5,
	TEMPERATURE_DRIFT_PER_MINUTE = 2,
	DEFAULT_AMBIENT_TEMPERATURE = 45,
	HP_DAMAGE_CAP_PER_MINUTE = 4,
	DEATH_INVENTORY_LOSS_FRACTION = 0.35,
	RESPAWN_STATS = {
		hunger = 60,
		thirst = 60,
		health = 100,
		temperature = 50,
	},
	ALERT_THRESHOLDS = ALERT_THRESHOLDS,
	getAlertLevel = getAlertLevel,
	getAlertKey = getAlertKey,
}

return SurvivalConstants
