--!strict

local HIP_MOTOR_NAMES = {
	left = "Left Hip",
	right = "Right Hip",
}

local ARM_MOTOR_NAMES = {
	left = "Left Shoulder",
	right = "Right Shoulder",
}

local LEG_SWING_RADIANS = math.rad(38)
local ARM_SWING_RADIANS = math.rad(22)
local CYCLE_SPEED = 9

export type HelperR6WalkAnimationModule = {
	isCapable: (model: Model) -> boolean,
	update: (model: Model, walkPhase: number, isMoving: boolean) -> (),
	advancePhase: (walkPhase: number, deltaTime: number, isMoving: boolean) -> number,
	clear: (model: Model) -> (),
}

local function getMotor(model: Model, motorName: string): Motor6D?
	local motor = model:FindFirstChild(motorName, true)

	if motor ~= nil and motor:IsA("Motor6D") then
		return motor
	end

	return nil
end

local function getBaseC0(motor: Motor6D): CFrame
	local stored = motor:GetAttribute("_R6WalkBaseC0")

	if typeof(stored) == "CFrame" then
		return stored
	end

	motor:SetAttribute("_R6WalkBaseC0", motor.C0)
	return motor.C0
end

local function resetMotor(motor: Motor6D)
	motor.C0 = getBaseC0(motor)
end

local HelperR6WalkAnimation: HelperR6WalkAnimationModule = {
	isCapable = function(model: Model): boolean
		if model:GetAttribute("UseR6WalkAnimation") ~= true then
			return false
		end

		return getMotor(model, HIP_MOTOR_NAMES.left) ~= nil and getMotor(model, HIP_MOTOR_NAMES.right) ~= nil
	end,

	advancePhase = function(walkPhase: number, deltaTime: number, isMoving: boolean): number
		if not isMoving then
			return walkPhase
		end

		return walkPhase + deltaTime * CYCLE_SPEED
	end,

	update = function(model: Model, walkPhase: number, isMoving: boolean)
		local leftHip = getMotor(model, HIP_MOTOR_NAMES.left)
		local rightHip = getMotor(model, HIP_MOTOR_NAMES.right)
		local leftShoulder = getMotor(model, ARM_MOTOR_NAMES.left)
		local rightShoulder = getMotor(model, ARM_MOTOR_NAMES.right)
		local reserveRightArm = model:GetAttribute("PlotHelper") == true
			and model:GetAttribute("HelperPatrolMoving") ~= true

		if leftHip == nil or rightHip == nil then
			return
		end

		if not isMoving then
			resetMotor(leftHip)
			resetMotor(rightHip)

			if leftShoulder ~= nil then
				resetMotor(leftShoulder)
			end

			if rightShoulder ~= nil and not reserveRightArm then
				resetMotor(rightShoulder)
			end

			return
		end

		local legSwing = math.sin(walkPhase) * LEG_SWING_RADIANS
		local armSwing = math.sin(walkPhase) * ARM_SWING_RADIANS

		leftHip.C0 = getBaseC0(leftHip) * CFrame.Angles(legSwing, 0, 0)
		rightHip.C0 = getBaseC0(rightHip) * CFrame.Angles(-legSwing, 0, 0)

		if leftShoulder ~= nil then
			leftShoulder.C0 = getBaseC0(leftShoulder) * CFrame.Angles(-armSwing, 0, 0)
		end

		if rightShoulder ~= nil and not reserveRightArm then
			rightShoulder.C0 = getBaseC0(rightShoulder) * CFrame.Angles(armSwing, 0, 0)
		end
	end,

	clear = function(model: Model)
		for _, motorName in { HIP_MOTOR_NAMES.left, HIP_MOTOR_NAMES.right, ARM_MOTOR_NAMES.left, ARM_MOTOR_NAMES.right } do
			local motor = getMotor(model, motorName)

			if motor ~= nil then
				resetMotor(motor)
				motor:SetAttribute("_R6WalkBaseC0", nil)
			end
		end
	end,
}

return HelperR6WalkAnimation
