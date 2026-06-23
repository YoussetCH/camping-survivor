--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseController = require(script.Parent.Parent.Kernel.BaseController)
local ClientKernel = require(script.Parent.Parent.Kernel.ClientKernel)
local Localization = require(ReplicatedStorage.Shared.Localization.Localization)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local StatBarModule = require(ReplicatedStorage.Shared.UI.StatBar)
local SurvivalConstants = require(ReplicatedStorage.Shared.Constants.SurvivalConstants)
local SurvivalTypes = require(ReplicatedStorage.Shared.Types.Survival)

local SurvivalHUDController = BaseController.new("SurvivalHUDController")

type StatBarInstance = StatBarModule.StatBar

local BAR_LABEL_KEYS = {
	health = "ui.hud.health",
	hunger = "ui.hud.hunger",
	thirst = "ui.hud.thirst",
	temperature = "ui.hud.temperature",
}

local bars: {
	health: StatBarInstance,
	hunger: StatBarInstance,
	thirst: StatBarInstance,
	temperature: StatBarInstance,
}? = nil

local STATUS_EFFECT_KEYS = {
	bleeding = "status.bleeding.name",
	poison = "status.poison.name",
	infection = "status.infection.name",
}

local STATUS_CURE_HINT_KEYS = {
	bleeding = "status.bleeding.hint",
	poison = "status.poison.hint",
	infection = "status.infection.hint",
}

local statusRow: Frame? = nil
local statusHintLabel: TextLabel? = nil
local statusIcons: { [string]: TextLabel } = {}
local lastSnapshot: SurvivalTypes.SurvivalSnapshot? = nil

local STATUS_ICON_COLORS = {
	bleeding = Color3.fromRGB(240, 90, 90),
	poison = Color3.fromRGB(90, 220, 100),
	infection = Color3.fromRGB(240, 170, 70),
}

local function refreshBarLabels()
	if bars == nil then
		return
	end

	for statName, bar in bars do
		local labelKey = BAR_LABEL_KEYS[statName]

		if labelKey ~= nil then
			bar:setLabel(Localization.get(labelKey))
		end
	end
end

local function updateBar(statName: string, bar: StatBarInstance, value: number)
	bar:setValue(value)
	bar:setAlertLevel(SurvivalConstants.getAlertLevel(statName, value))

	local alertKey = SurvivalConstants.getAlertKey(statName, value)

	if alertKey == nil then
		bar:setAlertMessage(nil)
		return
	end

	bar:setAlertMessage(Localization.get(alertKey))
end

local function refreshStatusIcons(snapshot: SurvivalTypes.SurvivalSnapshot)
	if statusRow == nil then
		return
	end

	local activeIds: { [string]: boolean } = {}

	for _, effect in snapshot.statusEffects do
		activeIds[effect.id] = true
	end

	for effectId, icon in statusIcons do
		local isActive = activeIds[effectId] == true
		icon.Visible = isActive

		if isActive then
			local labelKey = STATUS_EFFECT_KEYS[effectId]
			if labelKey ~= nil then
				icon.Text = Localization.get(labelKey)
			end
		end
	end

	if statusHintLabel ~= nil then
		local hintKey: string? = nil

		if activeIds.poison == true then
			hintKey = STATUS_CURE_HINT_KEYS.poison
		elseif activeIds.bleeding == true then
			hintKey = STATUS_CURE_HINT_KEYS.bleeding
		elseif activeIds.infection == true then
			hintKey = STATUS_CURE_HINT_KEYS.infection
		end

		if hintKey ~= nil then
			statusHintLabel.Text = Localization.get(hintKey)
			statusHintLabel.Visible = true
		else
			statusHintLabel.Visible = false
		end
	end
end

local function updateFromSnapshot(snapshot: SurvivalTypes.SurvivalSnapshot)
	if bars == nil then
		return
	end

	lastSnapshot = snapshot
	local stats = snapshot.stats
	updateBar("health", bars.health, stats.health)
	updateBar("hunger", bars.hunger, stats.hunger)
	updateBar("thirst", bars.thirst, stats.thirst)
	updateBar("temperature", bars.temperature, stats.temperature)
	refreshStatusIcons(snapshot)
end

function SurvivalHUDController:Init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local trove = self:GetTrove()

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SurvivalHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 100
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	trove:Add(screenGui)

	local container = Instance.new("Frame")
	container.Name = "StatBars"
	container.AnchorPoint = Vector2.new(0, 0)
	container.Position = UDim2.fromOffset(12, 52)
	container.Size = UDim2.fromOffset(280, 176)
	container.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	container.BackgroundTransparency = 0.15
	container.BorderSizePixel = 0
	container.Parent = screenGui

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 8)
	containerCorner.Parent = container

	local containerPadding = Instance.new("UIPadding")
	containerPadding.PaddingTop = UDim.new(0, 6)
	containerPadding.PaddingBottom = UDim.new(0, 6)
	containerPadding.PaddingLeft = UDim.new(0, 6)
	containerPadding.PaddingRight = UDim.new(0, 6)
	containerPadding.Parent = container

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	bars = {
		health = StatBarModule.create(container, {
			labelKey = BAR_LABEL_KEYS.health,
			fillColor = Color3.fromRGB(210, 70, 70),
			maxValue = 100,
		}),
		hunger = StatBarModule.create(container, {
			labelKey = BAR_LABEL_KEYS.hunger,
			fillColor = Color3.fromRGB(230, 140, 60),
			maxValue = 100,
		}),
		thirst = StatBarModule.create(container, {
			labelKey = BAR_LABEL_KEYS.thirst,
			fillColor = Color3.fromRGB(70, 140, 230),
			maxValue = 100,
		}),
		temperature = StatBarModule.create(container, {
			labelKey = BAR_LABEL_KEYS.temperature,
			fillColor = Color3.fromRGB(120, 180, 220),
			maxValue = 100,
		}),
	}

	refreshBarLabels()

	statusRow = Instance.new("Frame")
	statusRow.Name = "StatusEffects"
	statusRow.Size = UDim2.new(1, 0, 0, 18)
	statusRow.BackgroundTransparency = 1
	statusRow.LayoutOrder = 10
	statusRow.Parent = container

	local statusLayout = Instance.new("UIListLayout")
	statusLayout.FillDirection = Enum.FillDirection.Horizontal
	statusLayout.Padding = UDim.new(0, 4)
	statusLayout.Parent = statusRow

	for effectId, labelKey in STATUS_EFFECT_KEYS do
		local icon = Instance.new("TextLabel")
		icon.Name = effectId
		icon.Size = UDim2.fromOffset(72, 16)
		icon.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		icon.BackgroundTransparency = 0.2
		icon.TextColor3 = STATUS_ICON_COLORS[effectId] or Color3.fromRGB(240, 240, 240)
		icon.TextSize = 11
		icon.Font = Enum.Font.GothamMedium
		icon.Text = Localization.get(labelKey)
		icon.Visible = false
		icon.Parent = statusRow

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = icon

		statusIcons[effectId] = icon
	end

	statusHintLabel = Instance.new("TextLabel")
	statusHintLabel.Name = "StatusHint"
	statusHintLabel.Size = UDim2.new(1, 0, 0, 28)
	statusHintLabel.BackgroundTransparency = 1
	statusHintLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
	statusHintLabel.TextSize = 10
	statusHintLabel.Font = Enum.Font.Gotham
	statusHintLabel.TextWrapped = true
	statusHintLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusHintLabel.TextYAlignment = Enum.TextYAlignment.Top
	statusHintLabel.Visible = false
	statusHintLabel.LayoutOrder = 11
	statusHintLabel.Parent = container

	trove:Connect(Networking.getEvent("SurvivalUpdatedEvent").OnClientEvent, function(snapshot: SurvivalTypes.SurvivalSnapshot)
		updateFromSnapshot(snapshot)
	end)
end

function SurvivalHUDController:Start()
	local trove = self:GetTrove()

	trove:Connect(Localization.LocaleChanged, function()
		refreshBarLabels()

		for effectId, icon in statusIcons do
			local labelKey = STATUS_EFFECT_KEYS[effectId]
			if labelKey ~= nil then
				icon.Text = Localization.get(labelKey)
			end
		end

		if lastSnapshot ~= nil then
			updateFromSnapshot(lastSnapshot)
		end
	end)

	local syncController = ClientKernel.getController("ClientSyncController")

	if syncController == nil then
		return
	end

	local survival = syncController:GetSurvival()

	if survival ~= nil then
		updateFromSnapshot(survival)
	end
end

return SurvivalHUDController
