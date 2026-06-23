--!strict

export type FaunaModelUtilsModule = {
	setupMotor: (model: Model, walkSpeed: number) -> Humanoid?,
}

local function setupMotor(model: Model, walkSpeed: number): Humanoid?
	local root = model.PrimaryPart
	if root == nil then
		return nil
	end

	root.Name = "HumanoidRootPart"
	root.Anchored = false
	root.CanCollide = true

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant ~= root then
			descendant.Anchored = false
		end
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		humanoid = Instance.new("Humanoid")
		humanoid.Name = "FaunaHumanoid"
		humanoid.Parent = model
	end

	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.WalkSpeed = walkSpeed
	humanoid.HipHeight = 1.05
	humanoid.MaxHealth = 100
	humanoid.Health = 100

	return humanoid
end

local FaunaModelUtils: FaunaModelUtilsModule = {
	setupMotor = setupMotor,
}

return FaunaModelUtils
