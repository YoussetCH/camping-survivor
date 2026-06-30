--!strict

local R6_WALK_ANIMATION_ID = "rbxassetid://180426354"
local R6_IDLE_ANIMATION_ID = "rbxassetid://180435571"
local DEFAULT_WALK_SPEED = 16

export type HelperEscortAnimationModule = {
	isCapable: (model: Model) -> boolean,
	update: (model: Model, isMoving: boolean, walkSpeed: number) -> (),
	clear: (model: Model) -> (),
}

type ModelAnimationState = {
	walkTrack: AnimationTrack?,
	idleTrack: AnimationTrack?,
}

local modelStates: { [Model]: ModelAnimationState } = {}

local function getHumanoid(model: Model): Humanoid?
	local humanoid = model:FindFirstChildOfClass("Humanoid")

	if humanoid ~= nil then
		return humanoid
	end

	return nil
end

local function getAnimator(humanoid: Humanoid): Animator
	local animator = humanoid:FindFirstChildOfClass("Animator")

	if animator == nil then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	return animator
end

local function loadTrack(animator: Animator, animationId: string): AnimationTrack
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId

	local track = animator:LoadAnimation(animation)
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Movement

	return track
end

local function ensureState(model: Model): ModelAnimationState?
	local humanoid = getHumanoid(model)

	if humanoid == nil then
		return nil
	end

	local state = modelStates[model]

	if state ~= nil then
		return state
	end

	local animator = getAnimator(humanoid)
	state = {
		walkTrack = loadTrack(animator, R6_WALK_ANIMATION_ID),
		idleTrack = loadTrack(animator, R6_IDLE_ANIMATION_ID),
	}
	modelStates[model] = state

	if model:GetAttribute("_EscortAnimCleanup") ~= true then
		model:SetAttribute("_EscortAnimCleanup", true)
		model.Destroying:Connect(function()
			HelperEscortAnimation.clear(model)
		end)
	end

	return state
end

local HelperEscortAnimation: HelperEscortAnimationModule = {
	isCapable = function(model: Model): boolean
		return model:GetAttribute("UseR6WalkAnimation") == true and getHumanoid(model) ~= nil
	end,

	update = function(model: Model, isMoving: boolean, walkSpeed: number)
		local state = ensureState(model)

		if state == nil or state.walkTrack == nil or state.idleTrack == nil then
			return
		end

		local speedRatio = math.clamp(walkSpeed / DEFAULT_WALK_SPEED, 0.35, 2)
		state.walkTrack:AdjustSpeed(speedRatio)

		if isMoving then
			if not state.walkTrack.IsPlaying then
				state.walkTrack:Play(0.15)
			end

			if state.idleTrack.IsPlaying then
				state.idleTrack:Stop(0.15)
			end
		else
			if state.walkTrack.IsPlaying then
				state.walkTrack:Stop(0.2)
			end

			if not state.idleTrack.IsPlaying then
				state.idleTrack:Play(0.15)
			end
		end
	end,

	clear = function(model: Model)
		local state = modelStates[model]

		if state == nil then
			return
		end

		if state.walkTrack ~= nil then
			state.walkTrack:Stop(0)
			state.walkTrack:Destroy()
		end

		if state.idleTrack ~= nil then
			state.idleTrack:Stop(0)
			state.idleTrack:Destroy()
		end

		modelStates[model] = nil
	end,
}

return HelperEscortAnimation
