--!strict

local RunService = game:GetService("RunService")

export type PlayerMeleeAnimationModule = {
	play: (character: Model) -> (),
}

local SWING_DURATION_SECONDS = 0.38
local R15_SLASH_ANIMATION_ID = "rbxassetid://522635514"
local R6_SLASH_ANIMATION_ID = "rbxassetid://75454664"
local RENDER_PRIORITY = Enum.RenderPriority.Last.Value

local MOTOR_NAMES = {
	{ r15 = "RightShoulder", r6 = "Right Shoulder", weight = 1, axis = "shoulder" },
	{ r15 = "RightElbow", r6 = "Right Elbow", weight = 0.75, axis = "elbow" },
	{ r15 = "RightWrist", r6 = "Right Wrist", weight = 0.45, axis = "wrist" },
}

type MotorState = {
	motor: Motor6D,
	restC0: CFrame,
	useTransform: boolean,
	weight: number,
	axis: string,
}

local motorStates: { MotorState } = {}
local activeTrack: AnimationTrack? = nil
local renderStepName = "PlayerMeleeSwing"

local PlayerMeleeAnimation: PlayerMeleeAnimationModule = {
	play = function(_character: Model) end,
}

local function isR15Character(character: Model): boolean
	return character:FindFirstChild("UpperTorso") ~= nil
end

local function findMotor(character: Model, r15Name: string, r6Name: string): Motor6D?
	local targetName = if isR15Character(character) then r15Name else r6Name

	for _, descendant in character:GetDescendants() do
		if descendant:IsA("Motor6D") and descendant.Name == targetName then
			return descendant
		end
	end

	return nil
end

local function resetMotorStates()
	for _, state in motorStates do
		if state.useTransform then
			state.motor.Transform = CFrame.new()
		else
			state.motor.C0 = state.restC0
		end
	end

	table.clear(motorStates)
end

local function stopProceduralSwing()
	RunService:UnbindFromRenderStep(renderStepName)
	resetMotorStates()
end

local function stopActiveSwing()
	stopProceduralSwing()

	if activeTrack ~= nil then
		activeTrack:Stop(0.05)
		activeTrack = nil
	end
end

local function swingAmountForProgress(progress: number): number
	if progress < 0.2 then
		return -0.3 * (progress / 0.2)
	end

	local swingProgress = (progress - 0.2) / 0.8

	return math.sin(swingProgress * math.pi)
end

local function buildSwingTransform(amount: number, weight: number, axis: string): CFrame
	local scaled = amount * weight

	if axis == "shoulder" then
		return CFrame.Angles(math.rad(-120 * scaled), math.rad(30 * scaled), math.rad(-50 * scaled))
	end

	if axis == "elbow" then
		return CFrame.Angles(math.rad(-65 * scaled), 0, math.rad(18 * scaled))
	end

	return CFrame.Angles(math.rad(-30 * scaled), math.rad(-12 * scaled), 0)
end

local function playSlashAnimationTrack(character: Model): boolean
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid == nil then
		return false
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")

	if animator == nil then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = if isR15Character(character) then R15_SLASH_ANIMATION_ID else R6_SLASH_ANIMATION_ID

	local loadOk, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if not loadOk or track == nil then
		return false
	end

	track.Priority = Enum.AnimationPriority.Action4
	track:Play(0.05, 1, 1.25)
	activeTrack = track

	return true
end

local function playProceduralSwing(character: Model)
	for _, motorConfig in MOTOR_NAMES do
		local motor = findMotor(character, motorConfig.r15, motorConfig.r6)

		if motor ~= nil then
			table.insert(motorStates, {
				motor = motor,
				restC0 = motor.C0,
				useTransform = isR15Character(character),
				weight = motorConfig.weight,
				axis = motorConfig.axis,
			})
		end
	end

	if #motorStates == 0 then
		return
	end

	local startedAt = os.clock()

	RunService:BindToRenderStep(renderStepName, RENDER_PRIORITY, function()
		local elapsed = os.clock() - startedAt
		local progress = elapsed / SWING_DURATION_SECONDS

		if progress >= 1 then
			stopProceduralSwing()
			return
		end

		local amount = swingAmountForProgress(progress)

		for _, state in motorStates do
			local swing = buildSwingTransform(amount, state.weight, state.axis)

			if state.useTransform then
				state.motor.Transform = swing
			else
				state.motor.C0 = state.restC0 * swing
			end
		end
	end)
end

function PlayerMeleeAnimation.play(character: Model)
	stopActiveSwing()

	local usedTrack = playSlashAnimationTrack(character)

	if not usedTrack then
		playProceduralSwing(character)
	end
end

return PlayerMeleeAnimation
