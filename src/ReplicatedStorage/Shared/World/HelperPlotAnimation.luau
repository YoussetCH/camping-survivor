--!strict

local CHOP_SWING_RADIANS = math.rad(55)
local CHOP_CYCLE_SPEED = 6
local WORK_PULSE_WINDOW_SECONDS = 1.2

export type HelperPlotAnimationModule = {
	isCapable: (model: Model) -> boolean,
	update: (model: Model, deltaTime: number) -> (),
	clear: (model: Model) -> (),
}

local function getShoulderMotor(model: Model): Motor6D?
	local motor = model:FindFirstChild("Right Shoulder", true)

	if motor ~= nil and motor:IsA("Motor6D") then
		return motor
	end

	return nil
end

local function getBaseC0(motor: Motor6D): CFrame
	local stored = motor:GetAttribute("_PlotChopBaseC0")

	if typeof(stored) == "CFrame" then
		return stored
	end

	motor:SetAttribute("_PlotChopBaseC0", motor.C0)
	return motor.C0
end

local chopPhases: { [Model]: number } = {}

local HelperPlotAnimation: HelperPlotAnimationModule = {
	isCapable = function(model: Model): boolean
		return model:GetAttribute("PlotHelper") == true and getShoulderMotor(model) ~= nil
	end,

	update = function(model: Model, deltaTime: number)
		local shoulder = getShoulderMotor(model)

		if shoulder == nil then
			return
		end

		local isWorking = model:GetAttribute("HelperWorking") == true
		local pulseAt = model:GetAttribute("HelperWorkPulseAt")
		local recentPulse = type(pulseAt) == "number"
			and workspace:GetServerTimeNow() - pulseAt <= WORK_PULSE_WINDOW_SECONDS

		if not isWorking and not recentPulse then
			shoulder.C0 = getBaseC0(shoulder)
			chopPhases[model] = nil
			return
		end

		local phase = chopPhases[model] or 0
		phase += deltaTime * CHOP_CYCLE_SPEED
		chopPhases[model] = phase

		local swing = math.abs(math.sin(phase)) * CHOP_SWING_RADIANS
		shoulder.C0 = getBaseC0(shoulder) * CFrame.Angles(swing, 0, math.rad(-20))
	end,

	clear = function(model: Model)
		local shoulder = getShoulderMotor(model)

		if shoulder ~= nil then
			shoulder.C0 = getBaseC0(shoulder)
		end

		chopPhases[model] = nil
	end,
}

return HelperPlotAnimation
