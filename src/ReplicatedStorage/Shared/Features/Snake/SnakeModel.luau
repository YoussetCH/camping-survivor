--!strict

local SNAKE_GREEN = Color3.fromRGB(55, 120, 55)
local SNAKE_DARK = Color3.fromRGB(35, 85, 35)
local SNAKE_BELLY = Color3.fromRGB(140, 170, 90)

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
	transparency: number
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.Anchored = false
	part.CanCollide = true
	part.CanQuery = true
	part.Transparency = transparency
	part:SetAttribute("_DefaultTransparency", transparency)
	part.CFrame = root.CFrame * localCFrame
	part.Parent = model
	weld(part, root)
	return part
end

local function setModelHidden(model: Model, hidden: boolean)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local defaultTransparency = descendant:GetAttribute("_DefaultTransparency")

			if type(defaultTransparency) == "number" then
				descendant.Transparency = if hidden then 1 else defaultTransparency
			else
				descendant.Transparency = if hidden then 1 else 0
			end
		end
	end
end

local function build(groundPosition: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Snake"

	local root = Instance.new("Part")
	root.Name = "BodyAnchor"
	root.Size = Vector3.new(0.9, 0.45, 2.4)
	root.Color = SNAKE_GREEN
	root.Material = Enum.Material.Grass
	root.Anchored = true
	root.CanCollide = true
	root.CanQuery = true
	root.CFrame = CFrame.new(groundPosition + Vector3.new(0, 0.35, 0))
	root:SetAttribute("_DefaultTransparency", 0)
	root.Parent = model
	model.PrimaryPart = root

	addPart(model, root, "SegmentMid", Vector3.new(0.85, 0.42, 1.8), CFrame.new(0, 0, 1.8), SNAKE_DARK, Enum.Material.Grass, 0)
	addPart(model, root, "SegmentTail", Vector3.new(0.65, 0.35, 1.4), CFrame.new(0, 0, 3.4), SNAKE_DARK, Enum.Material.Grass, 0)
	addPart(model, root, "Head", Vector3.new(0.75, 0.5, 1.1), CFrame.new(0, 0.05, -1.6), SNAKE_GREEN, Enum.Material.Grass, 0)
	addPart(model, root, "Belly", Vector3.new(0.55, 0.15, 2.2), CFrame.new(0, -0.22, 0.2), SNAKE_BELLY, Enum.Material.SmoothPlastic, 0)
	addPart(model, root, "EyeLeft", Vector3.new(0.12, 0.12, 0.12), CFrame.new(-0.18, 0.12, -2.05), Color3.fromRGB(220, 220, 80), Enum.Material.Neon, 0)
	addPart(model, root, "EyeRight", Vector3.new(0.12, 0.12, 0.12), CFrame.new(0.18, 0.12, -2.05), Color3.fromRGB(220, 220, 80), Enum.Material.Neon, 0)

	model:SetAttribute("AmbushHidden", true)
	setModelHidden(model, true)

	return model
end

local function reveal(model: Model)
	model:SetAttribute("AmbushHidden", false)
	setModelHidden(model, false)
end

return {
	build = build,
	reveal = reveal,
	setModelHidden = setModelHidden,
}
