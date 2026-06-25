--!strict

local WOLF_BACK = Color3.fromRGB(72, 72, 82)
local WOLF_SIDE = Color3.fromRGB(98, 98, 108)
local WOLF_BELLY = Color3.fromRGB(145, 140, 130)
local WOLF_DARK = Color3.fromRGB(45, 45, 52)
local WOLF_NOSE = Color3.fromRGB(30, 30, 35)
local WOLF_EYE = Color3.fromRGB(200, 50, 45)
local WOLF_GROWL_SOUND_ID = "rbxassetid://139412217660571"
local STUN_HIGHLIGHT_NAME = "StunnedHighlight"

-- Head motor: local offset from root to head pivot
local HEAD_OFFSET = CFrame.new(0, 0.5, -2.75)

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

-- Returns the head part and creates a Motor6D so we can animate it
local function addHeadWithMotor(model: Model, root: BasePart): Part
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.45, 1.25, 1.55)
	head.Color = WOLF_SIDE
	head.Material = Enum.Material.Fabric
	head.Anchored = false
	head.CanCollide = true
	head.CanQuery = true
	head.CFrame = root.CFrame * HEAD_OFFSET
	head.Parent = model

	local motor = Instance.new("Motor6D")
	motor.Name = "HeadMotor"
	motor.Part0 = root
	motor.Part1 = head
	motor.C0 = HEAD_OFFSET
	motor.C1 = CFrame.new(0, 0, 0)
	motor.Parent = root

	return head
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

local function addGrowlSound(model: Model, root: BasePart)
	local sound = Instance.new("Sound")
	sound.Name = "Growl"
	sound.SoundId = WOLF_GROWL_SOUND_ID
	sound.Volume = 0.8
	sound.RollOffMaxDistance = 70
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.Parent = root
end

local function playGrowlSound(model: Model)
	local sound = model:FindFirstChild("Growl", true)
	if sound ~= nil and sound:IsA("Sound") then
		sound:Play()
	end
end

local function setStunnedVisual(model: Model, enabled: boolean)
	local root = model.PrimaryPart
	if root == nil then
		return
	end

	local existingHighlight = model:FindFirstChild(STUN_HIGHLIGHT_NAME)

	if not enabled then
		if existingHighlight ~= nil then
			existingHighlight:Destroy()
		end
		return
	end

	if existingHighlight == nil then
		local highlight = Instance.new("Highlight")
		highlight.Name = STUN_HIGHLIGHT_NAME
		highlight.Adornee = model
		highlight.FillTransparency = 0.65
		highlight.FillColor = Color3.fromRGB(120, 180, 255)
		highlight.OutlineColor = Color3.fromRGB(255, 245, 120)
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = model
	end

end

local function build(groundPosition: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Wolf"

	local root = Instance.new("Part")
	root.Name = "BodyAnchor"
	root.Size = Vector3.new(1.75, 1.25, 4.2)
	root.Color = WOLF_SIDE
	root.Material = Enum.Material.Fabric
	root.Anchored = true
	root.CanCollide = true
	root.CanQuery = true
	root.CFrame = CFrame.new(groundPosition + Vector3.new(0, 1.15, 0))
	root.Parent = model
	model.PrimaryPart = root

	addPart(model, root, "Chest", Vector3.new(1.95, 1.45, 1.55), CFrame.new(0, 0.2, -1.4), WOLF_SIDE, Enum.Material.Fabric, true)
	addPart(model, root, "Back", Vector3.new(1.65, 1.05, 1.9), CFrame.new(0, 0.45, 0.8), WOLF_BACK, Enum.Material.Fabric, false)
	addPart(model, root, "Belly", Vector3.new(1.45, 0.34, 3.4), CFrame.new(0, -0.57, 0.2), WOLF_BELLY, Enum.Material.SmoothPlastic, false)

	-- Head via Motor6D so it can tilt during attack
	local head = addHeadWithMotor(model, root)
	addPart(model, head, "Snout", Vector3.new(0.78, 0.56, 1.35), CFrame.new(0, -0.42, -0.85), WOLF_BELLY, Enum.Material.SmoothPlastic, true)
	addPart(model, head, "Nose", Vector3.new(0.38, 0.3, 0.3), CFrame.new(0, -0.38, -1.55), WOLF_NOSE, Enum.Material.SmoothPlastic, false)
	addPart(model, head, "EarLeft", Vector3.new(0.3, 0.78, 0.24), CFrame.new(-0.58, 0.55, -0.3) * CFrame.Angles(0, 0, math.rad(20)), WOLF_DARK, Enum.Material.Fabric, false)
	addPart(model, head, "EarRight", Vector3.new(0.3, 0.78, 0.24), CFrame.new(0.58, 0.55, -0.3) * CFrame.Angles(0, 0, math.rad(-20)), WOLF_DARK, Enum.Material.Fabric, false)
	addPart(model, head, "EyeLeft", Vector3.new(0.2, 0.2, 0.2), CFrame.new(-0.38, 0.1, -0.7), WOLF_EYE, Enum.Material.Neon, false, Enum.PartType.Ball)
	addPart(model, head, "EyeRight", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0.38, 0.1, -0.7), WOLF_EYE, Enum.Material.Neon, false, Enum.PartType.Ball)

	local legSize = Vector3.new(0.52, 1.45, 0.56)
	local pawSize = Vector3.new(0.58, 0.24, 0.66)

	addLeg(model, root, "LegFrontLeftMotor", "LegFrontLeft", "PawFrontLeft", CFrame.new(-0.62, -0.42, -1.35), legSize, pawSize, WOLF_DARK)
	addLeg(model, root, "LegFrontRightMotor", "LegFrontRight", "PawFrontRight", CFrame.new(0.62, -0.42, -1.35), legSize, pawSize, WOLF_DARK)
	addLeg(model, root, "LegBackLeftMotor", "LegBackLeft", "PawBackLeft", CFrame.new(-0.62, -0.42, 1.35), legSize, pawSize, WOLF_DARK)
	addLeg(model, root, "LegBackRightMotor", "LegBackRight", "PawBackRight", CFrame.new(0.62, -0.42, 1.35), legSize, pawSize, WOLF_DARK)

	addPart(model, root, "TailBase", Vector3.new(0.48, 0.48, 1.15), CFrame.new(0, 0.35, 2.35), WOLF_BACK, Enum.Material.Fabric, false)
	addPart(model, root, "TailTip", Vector3.new(0.36, 0.36, 1), CFrame.new(0, 0.58, 3.25), WOLF_DARK, Enum.Material.Fabric, false)

	addGrowlSound(model, root)
	model:SetAttribute("WalkAnimated", true)

	return model
end

return {
	build = build,
	playGrowlSound = playGrowlSound,
	setStunnedVisual = setStunnedVisual,
}
