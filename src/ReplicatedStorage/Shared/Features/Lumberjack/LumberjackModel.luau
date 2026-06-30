--!strict

local HelperConstants = require(script.Parent.Parent.Parent.Constants.HelperConstants)

local SHIRT = Color3.fromRGB(120, 85, 55)
local PANTS = Color3.fromRGB(70, 55, 40)
local SKIN = Color3.fromRGB(210, 180, 140)
local BEARD = Color3.fromRGB(90, 60, 35)
local AXE_WOOD = Color3.fromRGB(110, 75, 45)
local AXE_METAL = Color3.fromRGB(140, 140, 150)

local function weld(part0: BasePart, part1: BasePart)
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = part0
	constraint.Part1 = part1
	constraint.Parent = part1
end

local function addMotor(
	root: BasePart,
	part: BasePart,
	motorName: string,
	c0: CFrame,
	c1: CFrame
)
	local motor = Instance.new("Motor6D")
	motor.Name = motorName
	motor.Part0 = root
	motor.Part1 = part
	motor.C0 = c0
	motor.C1 = c1
	motor.Parent = root
end

local function buildEscortR6(groundPosition: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "LumberjackEscort"

	local spawnCFrame = CFrame.new(groundPosition + Vector3.new(0, 3, 0))

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = false
	root.CFrame = spawnCFrame
	root.Parent = model
	model.PrimaryPart = root

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Color = SHIRT
	torso.Material = Enum.Material.Fabric
	torso.CanCollide = false
	torso.Anchored = false
	torso.CFrame = spawnCFrame
	torso.Parent = model

	local rootJoint = Instance.new("Motor6D")
	rootJoint.Name = "RootJoint"
	rootJoint.Part0 = root
	rootJoint.Part1 = torso
	rootJoint.C0 = CFrame.new()
	rootJoint.C1 = CFrame.new()
	rootJoint.Parent = root

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.Color = SKIN
	head.Material = Enum.Material.SmoothPlastic
	head.CanCollide = false
	head.Anchored = false
	head.CFrame = spawnCFrame * CFrame.new(0, 1.5, 0)
	head.Parent = model
	addMotor(torso, head, "Neck", CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))

	local beard = Instance.new("Part")
	beard.Name = "Beard"
	beard.Size = Vector3.new(0.9, 0.5, 0.4)
	beard.Color = BEARD
	beard.Material = Enum.Material.Fabric
	beard.CanCollide = false
	beard.Anchored = false
	beard.CFrame = head.CFrame * CFrame.new(0, -0.35, -0.35)
	beard.Parent = model
	weld(head, beard)

	local leftArm = Instance.new("Part")
	leftArm.Name = "Left Arm"
	leftArm.Size = Vector3.new(1, 2, 1)
	leftArm.Color = SHIRT
	leftArm.Material = Enum.Material.Fabric
	leftArm.CanCollide = false
	leftArm.Anchored = false
	leftArm.CFrame = spawnCFrame * CFrame.new(-1.5, 0, 0)
	leftArm.Parent = model
	addMotor(torso, leftArm, "Left Shoulder", CFrame.new(-1, 0.5, 0), CFrame.new(0.5, 0.5, 0))

	local rightArm = Instance.new("Part")
	rightArm.Name = "Right Arm"
	rightArm.Size = Vector3.new(1, 2, 1)
	rightArm.Color = SHIRT
	rightArm.Material = Enum.Material.Fabric
	rightArm.CanCollide = false
	rightArm.Anchored = false
	rightArm.CFrame = spawnCFrame * CFrame.new(1.5, 0, 0)
	rightArm.Parent = model
	addMotor(torso, rightArm, "Right Shoulder", CFrame.new(1, 0.5, 0), CFrame.new(-0.5, 0.5, 0))

	local leftLeg = Instance.new("Part")
	leftLeg.Name = "Left Leg"
	leftLeg.Size = Vector3.new(1, 2, 1)
	leftLeg.Color = PANTS
	leftLeg.Material = Enum.Material.Fabric
	leftLeg.CanCollide = false
	leftLeg.Anchored = false
	leftLeg.CFrame = spawnCFrame * CFrame.new(-1, -2, 0)
	leftLeg.Parent = model
	addMotor(torso, leftLeg, "Left Hip", CFrame.new(-1, -1, 0), CFrame.new(0, 1, 0))

	local rightLeg = Instance.new("Part")
	rightLeg.Name = "Right Leg"
	rightLeg.Size = Vector3.new(1, 2, 1)
	rightLeg.Color = PANTS
	rightLeg.Material = Enum.Material.Fabric
	rightLeg.CanCollide = false
	rightLeg.Anchored = false
	rightLeg.CFrame = spawnCFrame * CFrame.new(1, -2, 0)
	rightLeg.Parent = model
	addMotor(torso, rightLeg, "Right Hip", CFrame.new(1, -1, 0), CFrame.new(0, 1, 0))

	local axeHandle = Instance.new("Part")
	axeHandle.Name = "AxeHandle"
	axeHandle.Size = Vector3.new(0.25, 1.4, 0.25)
	axeHandle.Color = AXE_WOOD
	axeHandle.Material = Enum.Material.Wood
	axeHandle.CanCollide = false
	axeHandle.Anchored = false
	axeHandle.CFrame = rightArm.CFrame * CFrame.new(0, -0.8, -0.35) * CFrame.Angles(0, 0, math.rad(-25))
	axeHandle.Parent = model
	weld(rightArm, axeHandle)

	local axeHead = Instance.new("Part")
	axeHead.Name = "AxeHead"
	axeHead.Size = Vector3.new(0.8, 0.5, 0.15)
	axeHead.Color = AXE_METAL
	axeHead.Material = Enum.Material.Metal
	axeHead.CanCollide = false
	axeHead.Anchored = false
	axeHead.CFrame = axeHandle.CFrame * CFrame.new(0, 0.65, 0)
	axeHead.Parent = model
	weld(axeHandle, axeHead)

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "HelperHumanoid"
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.WalkSpeed = 12
	humanoid.AutoRotate = true
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.Parent = model

	model:SetAttribute("WalkAnimated", true)
	model:SetAttribute("UseR6WalkAnimation", true)
	model:SetAttribute(HelperConstants.HELPER_TYPE_ATTRIBUTE, "lumberjack")

	return model
end

local function build(groundPosition: Vector3, options: { escort: boolean }?): Model
	local escort = options ~= nil and options.escort == true
	local model = buildEscortR6(groundPosition)
	model.Name = if escort then "LumberjackEscort" else "LumberjackHelper"

	return model
end

return {
	build = build,
}
