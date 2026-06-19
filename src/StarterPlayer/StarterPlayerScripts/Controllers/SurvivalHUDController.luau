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

local lastSnapshot: SurvivalTypes.SurvivalSnapshot? = nil

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
	container.Position = UDim2.fromOffset(12, 12)
	container.Size = UDim2.fromOffset(280, 132)
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

	trove:Connect(Networking.getEvent("SurvivalUpdatedEvent").OnClientEvent, function(snapshot: SurvivalTypes.SurvivalSnapshot)
		updateFromSnapshot(snapshot)
	end)
end

function SurvivalHUDController:Start()
	local trove = self:GetTrove()

	trove:Connect(Localization.LocaleChanged, function()
		refreshBarLabels()

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
