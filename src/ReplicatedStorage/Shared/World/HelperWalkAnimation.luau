--!strict

local LEG_MOTOR_NAMES = {
	"LegLeftMotor",
	"LegRightMotor",
}

local SWING_RADIANS = math.rad(30)
local CYCLE_SPEED = 10

export type HelperWalkAnimationModule = {
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

local HelperWalkAnimation: HelperWalkAnimationModule = {
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
		local leftMotor = getMotor(model, LEG_MOTOR_NAMES[1])
		local rightMotor = getMotor(model, LEG_MOTOR_NAMES[2])

		if leftMotor == nil or rightMotor == nil then
			return
		end

		local swing = if isMoving then math.sin(walkPhase) * SWING_RADIANS else 0
		local oppositeSwing = if isMoving then math.sin(walkPhase + math.pi) * SWING_RADIANS else 0

		leftMotor.C0 = getBaseC0(leftMotor) * CFrame.Angles(swing, 0, 0)
		rightMotor.C0 = getBaseC0(rightMotor) * CFrame.Angles(oppositeSwing, 0, 0)
	end,
}

return HelperWalkAnimation
