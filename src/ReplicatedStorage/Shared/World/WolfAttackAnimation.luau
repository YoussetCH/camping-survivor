--!strict
-- WolfAttackAnimation
-- Three-phase pose: crouch → rear up on hind legs → pounce forward.

local FRONT_LEFT_MOTOR  = "LegFrontLeftMotor"
local FRONT_RIGHT_MOTOR = "LegFrontRightMotor"
local BACK_LEFT_MOTOR   = "LegBackLeftMotor"
local BACK_RIGHT_MOTOR  = "LegBackRightMotor"
local HEAD_MOTOR        = "HeadMotor"

-- Phase boundaries
local CROUCH_END = 0.35   -- 0 → 0.35  : back legs crouch, front legs pull back
local REAR_END   = 0.65   -- 0.35→ 0.65: wolf rises on back legs, front legs lift HIGH
local POUNCE_END = 1.0    -- 0.65→ 1.0 : explosive forward slam

-- Resting pose (will lerp back to 0 when alpha = 0)
local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function easeInOut(t: number): number
	return t * t * (3 - 2 * t)
end

local function getPose(alpha: number): (number, number, number)
	-- returns: frontAngle, backAngle, headAngle
	local clamped = math.clamp(alpha, 0, 1)

	if clamped <= CROUCH_END then
		local t = easeInOut(clamped / CROUCH_END)
		-- Back legs crouch, front legs start pulling back
		local front = lerp(0, math.rad(-18), t)
		local back  = lerp(0, math.rad(28), t)
		local head  = lerp(0, math.rad(-10), t)
		return front, back, head
	end

	if clamped <= REAR_END then
		local t = easeInOut((clamped - CROUCH_END) / (REAR_END - CROUCH_END))
		-- Front legs swing way back (rearing up), back legs deeply bent
		local front = lerp(math.rad(-18), math.rad(-95), t)
		local back  = lerp(math.rad(28), math.rad(42), t)
		local head  = lerp(math.rad(-10), math.rad(18), t) -- head raises proud
		return front, back, head
	end

	local t = easeInOut((clamped - REAR_END) / (POUNCE_END - REAR_END))
	-- Front legs SLAM forward hard, back legs extend into the jump
	local front = lerp(math.rad(-95), math.rad(55), t)
	local back  = lerp(math.rad(42), math.rad(-32), t)
	local head  = lerp(math.rad(18), math.rad(-28), t) -- head dips into bite
	return front, back, head
end

export type WolfAttackAnimationModule = {
	isAttackCapable: (model: Model) -> boolean,
	update: (model: Model, attackAlpha: number) -> (),
}

local function getMotor(model: Model, name: string): Motor6D?
	local motor = model:FindFirstChild(name, true)
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

local WolfAttackAnimation: WolfAttackAnimationModule = {
	isAttackCapable = function(model: Model): boolean
		return getMotor(model, FRONT_LEFT_MOTOR) ~= nil
			and getMotor(model, BACK_LEFT_MOTOR) ~= nil
	end,

	update = function(model: Model, attackAlpha: number)
		local fl = getMotor(model, FRONT_LEFT_MOTOR)
		local fr = getMotor(model, FRONT_RIGHT_MOTOR)
		local bl = getMotor(model, BACK_LEFT_MOTOR)
		local br = getMotor(model, BACK_RIGHT_MOTOR)
		local hm = getMotor(model, HEAD_MOTOR)

		if fl == nil or fr == nil or bl == nil or br == nil then
			return
		end

		local frontAngle, backAngle, headAngle = getPose(attackAlpha)

		fl.C0 = getBaseC0(fl) * CFrame.Angles(frontAngle, 0, 0)
		fr.C0 = getBaseC0(fr) * CFrame.Angles(frontAngle, 0, 0)
		bl.C0 = getBaseC0(bl) * CFrame.Angles(backAngle, 0, 0)
		br.C0 = getBaseC0(br) * CFrame.Angles(backAngle, 0, 0)

		if hm ~= nil then
			hm.C0 = getBaseC0(hm) * CFrame.Angles(headAngle, 0, 0)
		end
	end,
}

return WolfAttackAnimation
