--!strict

local LEG_MOTOR_NAMES = {
	"LegFrontLeftMotor",
	"LegFrontRightMotor",
	"LegBackLeftMotor",
	"LegBackRightMotor",
}

local SWING_RADIANS = math.rad(32)
local CYCLE_SPEED = 9

export type FaunaWalkAnimationModule = {
	isWalkCapable: (model: Model) -> boolean,
	update: (model: Model, walkPhase: number, isMoving: boolean) -> (),
	advancePhase: (walkPhase: number, deltaTime: number, isMoving: boolean) -> number,
}

local function getMotor(model: Model, motorName: string): Motor6D?
	local motor = model:FindFirstChild(motorName, true)
	if motor ~= nil and motor:IsA("Motor6D") then
		return motor
	end
	return nil
end

local function getBaseC0(motor: Motor6D): CFrame
	local stored = motor:GetAttribute("_BaseC0")
	if typeof(stored) == "CFrame" then
		return stored
	end

	motor:SetAttribute("_BaseC0", motor.C0)
	return motor.C0
end

local FaunaWalkAnimation: FaunaWalkAnimationModule = {
	isWalkCapable = function(model: Model): boolean
		return getMotor(model, LEG_MOTOR_NAMES[1]) ~= nil
	end,

	advancePhase = function(walkPhase: number, deltaTime: number, isMoving: boolean): number
		if not isMoving then
			return walkPhase
		end

		return walkPhase + deltaTime * CYCLE_SPEED
	end,

	update = function(model: Model, walkPhase: number, isMoving: boolean)
		local motors: { Motor6D? } = {}
		for _, motorName in LEG_MOTOR_NAMES do
			table.insert(motors, getMotor(model, motorName))
		end

		if motors[1] == nil then
			return
		end

		local swing = if isMoving then math.sin(walkPhase) * SWING_RADIANS else 0
		local oppositeSwing = if isMoving then math.sin(walkPhase + math.pi) * SWING_RADIANS else 0

		local pairs = {
			{ motors[1], swing },
			{ motors[2], oppositeSwing },
			{ motors[3], oppositeSwing },
			{ motors[4], swing },
		}

		for _, pair in pairs do
			local motor = pair[1]
			local angle = pair[2]

			if motor ~= nil then
				motor.C0 = getBaseC0(motor) * CFrame.Angles(angle, 0, 0)
			end
		end
	end,
}

return FaunaWalkAnimation
