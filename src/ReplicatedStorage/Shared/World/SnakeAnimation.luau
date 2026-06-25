--!strict

local BODY_CYCLE_SPEED = 7
local BODY_SWAY_YAW = math.rad(10)
local BODY_SWAY_ROLL = math.rad(4)
local BODY_SWAY_OFFSET = 0.05
local HEAD_IDLE_BOB = math.rad(2)

local MID_ATTACK_RAISE = math.rad(-10)
local MID_ATTACK_STRIKE = math.rad(4)
local NECK_ATTACK_RAISE = math.rad(-56)
local NECK_ATTACK_STRIKE = math.rad(18)
local HEAD_ATTACK_RAISE = math.rad(-8)
local HEAD_ATTACK_STRIKE = math.rad(24)

export type SnakeAnimationModule = {
	isSnakeCapable: (model: Model) -> boolean,
	advancePhase: (walkPhase: number, deltaTime: number, isMoving: boolean) -> number,
	update: (model: Model, walkPhase: number, isMoving: boolean, attackAlpha: number) -> (),
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

local function computeAttackPose(attackAlpha: number): (number, number, number, number, number, number, number)
	if attackAlpha <= 0 then
		return 0, 0, 0, 0, 0, 0, 0
	end

	local clamped = math.clamp(attackAlpha, 0, 1)
	local raisePortion = math.clamp(clamped / 0.55, 0, 1)
	local strikePortion = math.clamp((clamped - 0.82) / 0.18, 0, 1)

	local midLift = raisePortion * 0.08
	local midPitch = raisePortion * MID_ATTACK_RAISE + strikePortion * MID_ATTACK_STRIKE
	local neckLift = raisePortion * 0.42
	local neckPitch = raisePortion * NECK_ATTACK_RAISE + strikePortion * NECK_ATTACK_STRIKE
	local headLift = raisePortion * 0.18
	local headForward = strikePortion * -0.22
	local headPitch = raisePortion * HEAD_ATTACK_RAISE + strikePortion * HEAD_ATTACK_STRIKE

	return midLift, midPitch, neckLift, neckPitch, headLift, headForward, headPitch
end

local SnakeAnimation: SnakeAnimationModule = {
	isSnakeCapable = function(model: Model): boolean
		return getMotor(model, "SegmentMidMotor") ~= nil and getMotor(model, "NeckMotor") ~= nil and getMotor(model, "HeadMotor") ~= nil
	end,

	advancePhase = function(walkPhase: number, deltaTime: number, isMoving: boolean): number
		if not isMoving then
			return walkPhase + deltaTime * (BODY_CYCLE_SPEED * 0.2)
		end

		return walkPhase + deltaTime * BODY_CYCLE_SPEED
	end,

	update = function(model: Model, walkPhase: number, isMoving: boolean, attackAlpha: number)
		local midMotor = getMotor(model, "SegmentMidMotor")
		local tailMotor = getMotor(model, "SegmentTailMotor")
		local neckMotor = getMotor(model, "NeckMotor")
		local headMotor = getMotor(model, "HeadMotor")
		if midMotor == nil or tailMotor == nil or neckMotor == nil or headMotor == nil then
			return
		end

		local movementWeight = if isMoving then 1 else 0.25
		local attackWeight = math.clamp(attackAlpha, 0, 1)
		local attackMovementDampen = 1 - (attackWeight * 0.55)
		local midWave = math.sin(walkPhase)
		local tailWave = math.sin(walkPhase + 1.15)
		local motionWeight = movementWeight * attackMovementDampen
		local midLift, midPitch, neckLift, neckPitch, headLift, headForward, attackPitch = computeAttackPose(attackAlpha)

		midMotor.C0 = getBaseC0(midMotor)
			* CFrame.new(midWave * BODY_SWAY_OFFSET * motionWeight, midLift, 0)
			* CFrame.Angles(midPitch, midWave * BODY_SWAY_YAW * motionWeight, math.cos(walkPhase) * BODY_SWAY_ROLL * motionWeight)

		tailMotor.C0 = getBaseC0(tailMotor)
			* CFrame.new(tailWave * BODY_SWAY_OFFSET * 1.15 * motionWeight, -midLift * 0.05, 0)
			* CFrame.Angles(0, tailWave * BODY_SWAY_YAW * 1.2 * motionWeight, 0)

		neckMotor.C0 = getBaseC0(neckMotor)
			* CFrame.new(0, neckLift, 0)
			* CFrame.Angles(neckPitch, 0, 0)

		local idlePitch = math.sin(walkPhase * 1.3) * HEAD_IDLE_BOB * motionWeight
		local headYaw = math.sin(walkPhase * 1.05) * math.rad(3) * motionWeight * (1 - attackWeight)
		headMotor.C0 = getBaseC0(headMotor)
			* CFrame.new(0, headLift, headForward)
			* CFrame.Angles(idlePitch + attackPitch, headYaw, 0)
	end,
}

return SnakeAnimation
