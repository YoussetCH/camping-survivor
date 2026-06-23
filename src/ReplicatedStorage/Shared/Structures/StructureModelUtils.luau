--!strict

export type ModelBuildContext = {
	model: Model,
	root: BasePart,
	ghost: boolean,
}

local StructureModelUtils = {}

StructureModelUtils.WOOD_DARK = Color3.fromRGB(101, 67, 33)
StructureModelUtils.WOOD_MID = Color3.fromRGB(130, 86, 42)
StructureModelUtils.WOOD_LIGHT = Color3.fromRGB(158, 110, 58)
StructureModelUtils.WOOD_CHARRED = Color3.fromRGB(42, 34, 30)
StructureModelUtils.STONE = Color3.fromRGB(96, 92, 86)
StructureModelUtils.STONE_DARK = Color3.fromRGB(72, 68, 64)
StructureModelUtils.STONE_LIGHT = Color3.fromRGB(118, 112, 104)
StructureModelUtils.METAL = Color3.fromRGB(118, 118, 124)
StructureModelUtils.ASH = Color3.fromRGB(38, 34, 32)
StructureModelUtils.EMBER = Color3.fromRGB(255, 110, 35)

function StructureModelUtils.weld(part: BasePart, root: BasePart)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = root
	weldConstraint.Part1 = part
	weldConstraint.Parent = part
end

function StructureModelUtils.addPart(
	model: Model,
	root: BasePart,
	name: string,
	size: Vector3,
	offset: Vector3,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = canCollide
	part.CanQuery = true
	part.CFrame = root.CFrame * CFrame.new(offset)
	part.Parent = model
	StructureModelUtils.weld(part, root)
	return part
end

function StructureModelUtils.addPartAt(
	model: Model,
	root: BasePart,
	name: string,
	size: Vector3,
	localCFrame: CFrame,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = canCollide
	part.CanQuery = true
	part.CFrame = root.CFrame * localCFrame
	part.Parent = model
	StructureModelUtils.weld(part, root)
	return part
end

function StructureModelUtils.addLog(
	model: Model,
	root: BasePart,
	name: string,
	size: Vector3,
	localCFrame: CFrame,
	canCollide: boolean
)
	StructureModelUtils.addPartAt(model, root, name, size, localCFrame, StructureModelUtils.WOOD_MID, Enum.Material.Wood, canCollide)

	local charLength = math.min(size.Z * 0.35, 1.1)
	local charSize = Vector3.new(size.X * 1.05, size.Y * 1.05, charLength)
	local charOffset = CFrame.new(0, 0, size.Z / 2 - charLength / 2)
	StructureModelUtils.addPartAt(
		model,
		root,
		`{name}_Char`,
		charSize,
		localCFrame * charOffset,
		StructureModelUtils.WOOD_CHARRED,
		Enum.Material.Slate,
		false
	)
end

return StructureModelUtils
