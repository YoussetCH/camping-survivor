--!strict

export type EquippedToolVisualsModule = {
	ATTACH_NAME: string,
	TOOL_GRIP_NAME: string,
	getHandPart: (character: Model) -> BasePart?,
	getGripCFrame: (hand: BasePart) -> CFrame,
	getToolGripMotor: (character: Model) -> Motor6D?,
	attachToHand: (character: Model, toolModel: Model, gripOffset: CFrame) -> boolean,
	detachFromCharacter: (character: Model) -> (),
}

local EquippedToolVisuals: EquippedToolVisualsModule = {
	ATTACH_NAME = "EquippedToolVisual",
	TOOL_GRIP_NAME = "ToolGrip",
}

function EquippedToolVisuals.getHandPart(character: Model): BasePart?
	local rightHand = character:FindFirstChild("RightHand")

	if rightHand ~= nil and rightHand:IsA("BasePart") then
		return rightHand
	end

	local rightArm = character:FindFirstChild("Right Arm")

	if rightArm ~= nil and rightArm:IsA("BasePart") then
		return rightArm
	end

	return nil
end

function EquippedToolVisuals.getGripCFrame(hand: BasePart): CFrame
	local gripAttachment = hand:FindFirstChild("RightGripAttachment")

	if gripAttachment ~= nil and gripAttachment:IsA("Attachment") then
		return gripAttachment.CFrame
	end

	return CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
end

function EquippedToolVisuals.getToolGripMotor(character: Model): Motor6D?
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
		return gripMotor
	end

	return nil
end

function EquippedToolVisuals.detachFromCharacter(character: Model)
	local existing = character:FindFirstChild(EquippedToolVisuals.ATTACH_NAME)

	if existing ~= nil then
		existing:Destroy()
	end
end

function EquippedToolVisuals.attachToHand(character: Model, toolModel: Model, gripOffset: CFrame): boolean
	local hand = EquippedToolVisuals.getHandPart(character)
	local gripPart = toolModel.PrimaryPart

	if hand == nil or gripPart == nil then
		toolModel:Destroy()
		return false
	end

	EquippedToolVisuals.detachFromCharacter(character)

	toolModel.Name = EquippedToolVisuals.ATTACH_NAME
	toolModel.Parent = character

	local gripC0 = EquippedToolVisuals.getGripCFrame(hand) * gripOffset

	local gripMotor = Instance.new("Motor6D")
	gripMotor.Name = EquippedToolVisuals.TOOL_GRIP_NAME
	gripMotor.Part0 = hand
	gripMotor.Part1 = gripPart
	gripMotor.C0 = gripC0
	gripMotor.C1 = CFrame.new()
	gripMotor.Parent = gripPart

	for _, descendant in toolModel:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.Massless = true
		end
	end

	return true
end

return EquippedToolVisuals
