--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StructureModelRegistry = require(ReplicatedStorage.Shared.Features.StructureModelRegistry)
local StructureModelUtils = require(ReplicatedStorage.Shared.Structures.StructureModelUtils)

local ASH = StructureModelUtils.ASH
local EMBER = StructureModelUtils.EMBER
local STONE = StructureModelUtils.STONE
local STONE_DARK = StructureModelUtils.STONE_DARK
local STONE_LIGHT = StructureModelUtils.STONE_LIGHT
local WOOD_CHARRED = StructureModelUtils.WOOD_CHARRED
local addPartAt = StructureModelUtils.addPartAt
local addLog = StructureModelUtils.addLog

local function attachCampfireEffects(anchor: BasePart)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = true

	local fire = Instance.new("Fire")
	fire.Name = "CampfireFlame"
	fire.Size = 5
	fire.Heat = 8
	fire.TimeScale = 0.9
	fire.Color = Color3.fromRGB(255, 95, 25)
	fire.SecondaryColor = Color3.fromRGB(255, 190, 70)
	fire.Parent = anchor

	local light = Instance.new("PointLight")
	light.Name = "CampfireLight"
	light.Color = Color3.fromRGB(255, 145, 55)
	light.Brightness = 1.8
	light.Range = 18
	light.Shadows = true
	light.Parent = anchor

	local embers = Instance.new("ParticleEmitter")
	embers.Name = "CampfireEmbers"
	embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	embers.Rate = 18
	embers.Lifetime = NumberRange.new(0.4, 1.1)
	embers.Speed = NumberRange.new(3, 7)
	embers.SpreadAngle = Vector2.new(35, 35)
	embers.Acceleration = Vector3.new(0, 2, 0)
	embers.Drag = 1.5
	embers.LightEmission = 1
	embers.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 80)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 40, 20)),
	})
	embers.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.22),
		NumberSequenceKeypoint.new(1, 0),
	})
	embers.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	embers.Parent = anchor

	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "CampfireSmoke"
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Rate = 10
	smoke.Lifetime = NumberRange.new(2.5, 4.5)
	smoke.Speed = NumberRange.new(1.5, 3.5)
	smoke.SpreadAngle = Vector2.new(18, 18)
	smoke.Acceleration = Vector3.new(0, 1.5, 0)
	smoke.RotSpeed = NumberRange.new(-25, 25)
	smoke.LightEmission = 0.15
	smoke.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 90, 90)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 160, 160)),
	})
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 2.4),
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	smoke.Parent = anchor
end

local function buildCampfire(ctx: StructureModelRegistry.ModelBuildContext)
	local model = ctx.model
	local root = ctx.root
	local ghost = ctx.ghost
	local baseY = -root.Size.Y / 2 + 0.12
	local canCollide = not ghost

	addPartAt(
		model,
		root,
		"AshBed",
		Vector3.new(3.4, 0.12, 3.4),
		CFrame.new(0, baseY + 0.06, 0),
		ASH,
		Enum.Material.Ground,
		false
	)

	local rockCount = 12
	for index = 0, rockCount - 1 do
		local angle = (index / rockCount) * math.pi * 2
		local radius = 2.15 + (index % 3) * 0.08
		local rockHeight = 0.45 + (index % 4) * 0.12
		local rockWidth = 0.85 + (index % 2) * 0.25
		local rockDepth = 1.05 + (index % 3) * 0.2
		local rockColor = if index % 2 == 0 then STONE else if index % 3 == 0 then STONE_DARK else STONE_LIGHT

		addPartAt(
			model,
			root,
			`Rock_{index}`,
			Vector3.new(rockWidth, rockHeight, rockDepth),
			CFrame.new(math.cos(angle) * radius, baseY + rockHeight / 2 + 0.04, math.sin(angle) * radius)
				* CFrame.Angles(math.rad((index % 5) - 2), angle + math.rad(index * 11), math.rad((index % 4) - 1)),
			rockColor,
			Enum.Material.Rock,
			canCollide
		)
	end

	local logLayout = {
		{ angle = 35, length = 3.4, offset = 0.55 },
		{ angle = -35, length = 3.4, offset = 0.55 },
		{ angle = 145, length = 3.2, offset = 0.5 },
		{ angle = -145, length = 3.2, offset = 0.5 },
	}

	for index, layout in logLayout do
		local angle = math.rad(layout.angle)
		local logSize = Vector3.new(0.65, 0.65, layout.length)
		local offset = Vector3.new(math.cos(angle) * layout.offset, baseY + 0.38, math.sin(angle) * layout.offset)
		addLog(
			model,
			root,
			`Log_{index}`,
			logSize,
			CFrame.new(offset) * CFrame.Angles(0, angle, math.rad(14)),
			canCollide
		)
	end

	for index = 0, 3 do
		local angle = math.rad(index * 90 + 20)
		local kindlingSize = Vector3.new(0.25, 0.25, 1.2)
		local offset = Vector3.new(math.cos(angle) * 0.35, baseY + 0.42, math.sin(angle) * 0.35)
		addPartAt(
			model,
			root,
			`Kindling_{index}`,
			kindlingSize,
			CFrame.new(offset) * CFrame.Angles(math.rad(18), angle, math.rad(8)),
			WOOD_CHARRED,
			Enum.Material.Wood,
			false
		)
	end

	local emberGlow = addPartAt(
		model,
		root,
		"EmberGlow",
		Vector3.new(1.2, 0.35, 1.2),
		CFrame.new(0, baseY + 0.28, 0),
		EMBER,
		Enum.Material.Neon,
		false
	)
	emberGlow.Transparency = if ghost then 0.55 else 0.35

	local effectAnchor = addPartAt(
		model,
		root,
		"FireAnchor",
		Vector3.new(0.6, 0.6, 0.6),
		CFrame.new(0, baseY + 0.72, 0),
		EMBER,
		Enum.Material.SmoothPlastic,
		false
	)

	if ghost then
		effectAnchor.Transparency = 1
	else
		attachCampfireEffects(effectAnchor)
	end
end

StructureModelRegistry.register("bp_campfire", buildCampfire)

return {
	build = buildCampfire,
}
