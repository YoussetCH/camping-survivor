--!strict

local RunService = game:GetService("RunService")

local EquippedToolVisuals = require(script.Parent.EquippedToolVisuals)
local PlayerMeleeAnimation = require(script.Parent.Parent.Character.PlayerMeleeAnimation)

export type ToolSwingAnimationModule = {
	play: (character: Model) -> (),
}

local SWING_DURATION_SECONDS = 0.38
local renderStepName = "EquippedToolSwing"
local RENDER_PRIORITY = Enum.RenderPriority.Last.Value + 1

type GripDriver = {
	apply: (amount: number) -> (),
	reset: () -> (),
}

local function swingAmountForProgress(progress: number): number
	if progress < 0.2 then
		return -0.25 * (progress / 0.2)
	end

	local swingProgress = (progress - 0.2) / 0.8

	return math.sin(swingProgress * math.pi)
end

local function buildGripDriver(character: Model): GripDriver?
	local toolModel = character:FindFirstChild(EquippedToolVisuals.ATTACH_NAME)

	if toolModel == nil or not toolModel:IsA("Model") then
		return nil
	end

	local gripPart = toolModel.PrimaryPart

	if gripPart == nil then
		return nil
	end

	local gripMotor = gripPart:FindFirstChild(EquippedToolVisuals.TOOL_GRIP_NAME)

	if gripMotor ~= nil and gripMotor:IsA("Motor6D") then
		return {
			apply = function(amount: number)
				gripMotor.Transform = CFrame.Angles(math.rad(-85 * amount), math.rad(22 * amount), math.rad(-18 * amount))
					* CFrame.new(0, 0.04 * amount, -0.3 * amount)
			end,
			reset = function()
				gripMotor.Transform = CFrame.new()
			end,
		}
	end

	local gripWeld = gripPart:FindFirstChild(EquippedToolVisuals.TOOL_GRIP_NAME)

	if gripWeld ~= nil and gripWeld:IsA("Weld") then
		local restC0 = gripWeld.C0

		return {
			apply = function(amount: number)
				gripWeld.C0 = restC0
					* CFrame.Angles(math.rad(-85 * amount), math.rad(22 * amount), math.rad(-18 * amount))
					* CFrame.new(0, 0.04 * amount, -0.3 * amount)
			end,
			reset = function()
				gripWeld.C0 = restC0
			end,
		}
	end

	return nil
end

local ToolSwingAnimation: ToolSwingAnimationModule = {
	play = function(character: Model)
		PlayerMeleeAnimation.play(character)

		local gripDriver = buildGripDriver(character)

		if gripDriver == nil then
			return
		end

		RunService:UnbindFromRenderStep(renderStepName)

		local startedAt = os.clock()

		RunService:BindToRenderStep(renderStepName, RENDER_PRIORITY, function()
			local elapsed = os.clock() - startedAt
			local progress = elapsed / SWING_DURATION_SECONDS

			if progress >= 1 then
				gripDriver.reset()
				RunService:UnbindFromRenderStep(renderStepName)
				return
			end

			gripDriver.apply(swingAmountForProgress(progress))
		end)
	end,
}

return ToolSwingAnimation
