--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseController = require(script.Parent.Parent.Kernel.BaseController)
local Localization = require(ReplicatedStorage.Shared.Localization.Localization)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local WorldTypes = require(ReplicatedStorage.Shared.Types.World)

local WorldController = BaseController.new("WorldController")

local phaseLabel: TextLabel? = nil
local lastSnapshot: WorldTypes.WorldSnapshot? = nil

local PHASE_LABEL_KEYS: { [WorldTypes.WorldPhase]: string } = {
	dawn = "ui.world.phase.dawn",
	day = "ui.world.phase.day",
	dusk = "ui.world.phase.dusk",
	night = "ui.world.phase.night",
}

local function refreshPhaseLabel()
	if phaseLabel == nil or lastSnapshot == nil then
		return
	end

	local labelKey = PHASE_LABEL_KEYS[lastSnapshot.phase]

	if labelKey ~= nil then
		phaseLabel.Text = Localization.get(labelKey)
	end
end

local function updateSnapshot(snapshot: WorldTypes.WorldSnapshot)
	lastSnapshot = snapshot
	refreshPhaseLabel()
end

function WorldController:Init()
	local trove = self:GetTrove()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WorldHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 90
	screenGui.Parent = playerGui
	trove:Add(screenGui)

	local container = Instance.new("Frame")
	container.Name = "PhaseIndicator"
	container.AnchorPoint = Vector2.new(1, 0)
	container.Position = UDim2.new(1, -12, 0, 12)
	container.Size = UDim2.fromOffset(96, 28)
	container.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	container.BackgroundTransparency = 0.15
	container.BorderSizePixel = 0
	container.Parent = screenGui

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 8)
	containerCorner.Parent = container

	phaseLabel = Instance.new("TextLabel")
	phaseLabel.Size = UDim2.fromScale(1, 1)
	phaseLabel.BackgroundTransparency = 1
	phaseLabel.Font = Enum.Font.GothamMedium
	phaseLabel.TextSize = 13
	phaseLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	phaseLabel.Parent = container

	local worldUpdatedEvent = Networking.getEvent("WorldUpdatedEvent")

	trove:Connect(worldUpdatedEvent.OnClientEvent, function(snapshot: WorldTypes.WorldSnapshot)
		if type(snapshot) == "table" and type(snapshot.phase) == "string" then
			updateSnapshot(snapshot)
		end
	end)

	trove:Connect(Localization.LocaleChanged, refreshPhaseLabel)

	refreshPhaseLabel()
end

return WorldController
