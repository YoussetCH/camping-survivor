--!strict

local SNAKE_GREEN = Color3.fromRGB(55, 120, 55)
local SNAKE_COLOR_VARIANTS = {
	Color3.new(0.666667, 0, 0),
	Color3.new(1, 1, 1),
	Color3.new(0, 0.333333, 0.498039),
	Color3.new(0.686275, 0.686275, 0),
	Color3.new(0, 0.666667, 0),
	Color3.new(1, 0.333333, 0),
}

local BODY_COLOR_PARTS = {
	Head = true,
	Tail = true,
	ETail = true,
	Torso1 = true,
	Torso2 = true,
	Torso3 = true,
	Torso4 = true,
	Torso5 = true,
}

local function setModelHidden(model: Model, hidden: boolean)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local defaultTransparency = descendant:GetAttribute("_DefaultTransparency")
			if type(defaultTransparency) == "number" then
				descendant.Transparency = if hidden then 1 else defaultTransparency
			else
				descendant.Transparency = if hidden then 1 else descendant.Transparency
			end
		end
	end
end

local function findTemplateModel(): Model?
	local referenceFolder = script.Parent:FindFirstChild("ReferenceAsset")
	if referenceFolder == nil then
		return nil
	end

	for _, descendant in referenceFolder:GetDescendants() do
		if descendant:IsA("Model") then
			local hasHead = descendant:FindFirstChild("Head", true) ~= nil
			local hasTail = descendant:FindFirstChild("Tail", true) ~= nil or descendant:FindFirstChild("ETail", true) ~= nil
			local hasBody = descendant:FindFirstChild("Torso1", true) ~= nil or descendant:FindFirstChild("Torso", true) ~= nil
			if hasHead and hasTail and hasBody then
				return descendant
			end
		end
	end

	return nil
end

local function choosePrimaryPart(model: Model): BasePart?
	local candidates = {
		"HumanoidRootPart",
		"Torso1",
		"Head",
	}

	for _, name in candidates do
		local part = model:FindFirstChild(name, true)
		if part ~= nil and part:IsA("BasePart") then
			return part
		end
	end

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			return descendant
		end
	end

	return nil
end

local function sanitizeTemplateClone(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = true
			descendant.CanQuery = true
			descendant.CastShadow = true
			descendant:SetAttribute("_DefaultTransparency", descendant.Transparency)
		elseif descendant:IsA("Sound") then
			descendant.RollOffMaxDistance = math.max(descendant.RollOffMaxDistance, 35)
		elseif descendant:IsA("Script") then
			descendant.Disabled = true
		end
	end
end

local function applyRandomBodyColor(model: Model)
	local bodyColor = SNAKE_COLOR_VARIANTS[math.random(1, #SNAKE_COLOR_VARIANTS)]
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and BODY_COLOR_PARTS[descendant.Name] then
			descendant.Color = bodyColor
		end
	end
end

local function cloneFromReference(groundPosition: Vector3): Model?
	local template = findTemplateModel()
	if template == nil then
		return nil
	end

	local clone = template:Clone()
	clone.Name = "Snake"
	sanitizeTemplateClone(clone)
	applyRandomBodyColor(clone)

	local primaryPart = choosePrimaryPart(clone)
	if primaryPart == nil then
		clone:Destroy()
		return nil
	end

	clone.PrimaryPart = primaryPart
	clone:PivotTo(CFrame.new(groundPosition + Vector3.new(0, 0.4, 0)))
	clone:SetAttribute("AmbushHidden", false)
	clone:SetAttribute("WalkAnimated", false)
	clone:SetAttribute("UsesEmbeddedAi", true)
	setModelHidden(clone, false)
	return clone
end

local function buildFallback(groundPosition: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Snake"

	local root = Instance.new("Part")
	root.Name = "BodyAnchor"
	root.Size = Vector3.new(1, 0.7, 2)
	root.Color = SNAKE_GREEN
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = true
	root.CFrame = CFrame.new(groundPosition + Vector3.new(0, 0.45, 0))
	root:SetAttribute("_DefaultTransparency", 0)
	root.Parent = model
	model.PrimaryPart = root

	local mid = Instance.new("Part")
	mid.Name = "Torso1"
	mid.Size = Vector3.new(0.92, 0.6, 1.7)
	mid.Color = SNAKE_GREEN
	mid.Material = Enum.Material.SmoothPlastic
	mid.Anchored = true
	mid.CanCollide = false
	mid.CanQuery = true
	mid.CFrame = root.CFrame * CFrame.new(0, 0, 1.45)
	mid:SetAttribute("_DefaultTransparency", 0)
	mid.Parent = model

	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.62, 0.42, 1.4)
	tail.Color = SNAKE_GREEN
	tail.Material = Enum.Material.SmoothPlastic
	tail.Anchored = true
	tail.CanCollide = false
	tail.CanQuery = true
	tail.CFrame = root.CFrame * CFrame.new(0, 0, 2.6)
	tail:SetAttribute("_DefaultTransparency", 0)
	tail.Parent = model

	model:SetAttribute("AmbushHidden", true)
	model:SetAttribute("WalkAnimated", true)
	model:SetAttribute("UsesEmbeddedAi", false)
	setModelHidden(model, true)
	return model
end

local function findSound(model: Model, keywords: { string }): Sound?
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Sound") then
			local lowered = string.lower(descendant.Name)
			for _, keyword in keywords do
				if string.find(lowered, keyword, 1, true) ~= nil then
					return descendant
				end
			end
		end
	end
	return nil
end

local function playRevealSound(model: Model)
	local sound = findSound(model, { "hiss", "growl" })
	if sound ~= nil then
		sound:Play()
	end
end

local function playAttackSound(model: Model)
	local sound = findSound(model, { "bite", "hiss", "growl" })
	if sound ~= nil then
		sound:Play()
	end
end

local function build(groundPosition: Vector3): Model
	local fromReference = cloneFromReference(groundPosition)
	if fromReference ~= nil then
		return fromReference
	end

	warn("[SnakeModel] ReferenceAsset not found – using fallback. Ensure Snake.rbxm is inside ReferenceAsset/ sibling to SnakeModel.luau")
	return buildFallback(groundPosition)
end

local function reveal(model: Model)
	model:SetAttribute("AmbushHidden", false)
	setModelHidden(model, false)
	playRevealSound(model)
end

return {
	build = build,
	reveal = reveal,
	setModelHidden = setModelHidden,
	playRevealSound = playRevealSound,
	playAttackSound = playAttackSound,
}
