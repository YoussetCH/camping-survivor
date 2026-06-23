--!strict

local WOLF_BACK = Color3.fromRGB(72, 72, 82)
local WOLF_SIDE = Color3.fromRGB(98, 98, 108)
local WOLF_BELLY = Color3.fromRGB(145, 140, 130)
local WOLF_DARK = Color3.fromRGB(45, 45, 52)
local WOLF_NOSE = Color3.fromRGB(30, 30, 35)
local WOLF_EYE = Color3.fromRGB(200, 50, 45)

local function weld(part: BasePart, root: BasePart)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = root
	weldConstraint.Part1 = part
	weldConstraint.Parent = part
end

local function addPart(
	model: Model,
	root: BasePart,
	name: string,
	size: Vector3,
	localCFrame: CFrame,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean,
	shape: Enum.PartType?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.Anchored = false
	part.CanCollide = canCollide
	part.CanQuery = true
	part.Shape = shape or Enum.PartType.Block
	part.CFrame = root.CFrame * localCFrame
	part.Parent = model
	weld(part, root)
	return part
end

local function addLeg(
	model: Model,
	root: BasePart,
	motorName: string,
	legName: string,
	pawName: string,
	hipOffset: CFrame,
	legSize: Vector3,
	pawSize: Vector3,
	color: Color3
): Part
	local leg = Instance.new("Part")
	leg.Name = legName
	leg.Size = legSize
	leg.Color = color
	leg.Material = Enum.Material.Fabric
	leg.Anchored = false
	leg.CanCollide = true
	leg.CanQuery = true
	leg.CFrame = root.CFrame * hipOffset * CFrame.new(0, -legSize.Y * 0.5, 0)
	leg.Parent = model

	local motor = Instance.new("Motor6D")
	motor.Name = motorName
	motor.Part0 = root
	motor.Part1 = leg
	motor.C0 = hipOffset
	motor.C1 = CFrame.new(0, legSize.Y * 0.5, 0)
	motor.Parent = root

	local paw = Instance.new("Part")
	paw.Name = pawName
	paw.Size = pawSize
	paw.Color = color
	paw.Material = Enum.Material.SmoothPlastic
	paw.Anchored = false
	paw.CanCollide = true
	paw.CanQuery = true
	paw.CFrame = leg.CFrame * CFrame.new(0, -legSize.Y * 0.5 - pawSize.Y * 0.5, 0)
	paw.Parent = model
	weld(paw, leg)

	return leg
end

local function build(groundPosition: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Wolf"

	local root = Instance.new("Part")
	root.Name = "BodyAnchor"
	root.Size = Vector3.new(1.3, 0.95, 3.2)
	root.Color = WOLF_SIDE
	root.Material = Enum.Material.Fabric
	root.Anchored = true
	root.CanCollide = true
	root.CanQuery = true
	root.CFrame = CFrame.new(groundPosition + Vector3.new(0, 0.85, 0))
	root.Parent = model
	model.PrimaryPart = root

	addPart(model, root, "Chest", Vector3.new(1.45, 1.05, 1.2), CFrame.new(0, 0.15, -1.05), WOLF_SIDE, Enum.Material.Fabric, true)
	addPart(model, root, "Back", Vector3.new(1.2, 0.75, 1.4), CFrame.new(0, 0.35, 0.55), WOLF_BACK, Enum.Material.Fabric, false)
	addPart(model, root, "Belly", Vector3.new(1.05, 0.25, 2.6), CFrame.new(0, -0.42, 0.1), WOLF_BELLY, Enum.Material.SmoothPlastic, false)

	addPart(model, root, "Head", Vector3.new(1.05, 0.95, 1.15), CFrame.new(0, 0.35, -2.05), WOLF_SIDE, Enum.Material.Fabric, true)
	addPart(model, root, "Snout", Vector3.new(0.55, 0.42, 0.95), CFrame.new(0, -0.05, -2.85), WOLF_BELLY, Enum.Material.SmoothPlastic, true)
	addPart(model, root, "Nose", Vector3.new(0.28, 0.22, 0.22), CFrame.new(0, 0, -3.35), WOLF_NOSE, Enum.Material.SmoothPlastic, false)

	addPart(model, root, "EarLeft", Vector3.new(0.22, 0.55, 0.18), CFrame.new(-0.42, 0.72, -1.85) * CFrame.Angles(0, 0, math.rad(18)), WOLF_DARK, Enum.Material.Fabric, false)
	addPart(model, root, "EarRight", Vector3.new(0.22, 0.55, 0.18), CFrame.new(0.42, 0.72, -1.85) * CFrame.Angles(0, 0, math.rad(-18)), WOLF_DARK, Enum.Material.Fabric, false)

	local legSize = Vector3.new(0.38, 1.05, 0.42)
	local pawSize = Vector3.new(0.42, 0.18, 0.48)

	addLeg(model, root, "LegFrontLeftMotor", "LegFrontLeft", "PawFrontLeft", CFrame.new(-0.48, -0.35, -1.05), legSize, pawSize, WOLF_DARK)
	addLeg(model, root, "LegFrontRightMotor", "LegFrontRight", "PawFrontRight", CFrame.new(0.48, -0.35, -1.05), legSize, pawSize, WOLF_DARK)
	addLeg(model, root, "LegBackLeftMotor", "LegBackLeft", "PawBackLeft", CFrame.new(-0.48, -0.35, 1.05), legSize, pawSize, WOLF_DARK)
	addLeg(model, root, "LegBackRightMotor", "LegBackRight", "PawBackRight", CFrame.new(0.48, -0.35, 1.05), legSize, pawSize, WOLF_DARK)

	addPart(model, root, "TailBase", Vector3.new(0.35, 0.35, 0.85), CFrame.new(0, 0.25, 1.75), WOLF_BACK, Enum.Material.Fabric, false)
	addPart(model, root, "TailTip", Vector3.new(0.28, 0.28, 0.75), CFrame.new(0, 0.45, 2.45), WOLF_DARK, Enum.Material.Fabric, false)

	addPart(model, root, "EyeLeft", Vector3.new(0.14, 0.14, 0.14), CFrame.new(-0.28, 0.45, -2.45), WOLF_EYE, Enum.Material.Neon, false, Enum.PartType.Ball)
	addPart(model, root, "EyeRight", Vector3.new(0.14, 0.14, 0.14), CFrame.new(0.28, 0.45, -2.45), WOLF_EYE, Enum.Material.Neon, false, Enum.PartType.Ball)

	model:SetAttribute("WalkAnimated", true)

	return model
end

return {
	build = build,
}
