--!strict

export type EquippedToolVisualsModule = {
	ATTACH_NAME: string,
	getHandPart: (character: Model) -> BasePart?,
	getGripCFrame: (hand: BasePart) -> CFrame,
	attachToHand: (character: Model, toolModel: Model, gripOffset: CFrame) -> boolean,
	detachFromCharacter: (character: Model) -> (),
}

local EquippedToolVisuals: EquippedToolVisualsModule = {
	ATTACH_NAME = "EquippedToolVisual",
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

	local weldC0 = EquippedToolVisuals.getGripCFrame(hand) * gripOffset

	local handWeld = Instance.new("Weld")
	handWeld.Name = "ToolGrip"
	handWeld.Part0 = hand
	handWeld.Part1 = gripPart
	handWeld.C0 = weldC0
	handWeld.C1 = CFrame.new()
	handWeld.Parent = gripPart

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
