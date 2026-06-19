--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseController = require(script.Parent.Parent.Kernel.BaseController)
local Localization = require(ReplicatedStorage.Shared.Localization.Localization)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local LocaleRegistry = require(ReplicatedStorage.Shared.Localization.LocaleRegistry)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)
local PlayerSettingsTypes = require(ReplicatedStorage.Shared.Types.PlayerSettings)
local LocaleTypes = require(ReplicatedStorage.Shared.Types.Locale)

local LocalizationController = BaseController.new("LocalizationController")

local englishButton: TextButton? = nil
local spanishButton: TextButton? = nil

local function updateButtonStyles(activeLocale: LocaleTypes.LocaleCode)
	if englishButton == nil or spanishButton == nil then
		return
	end

	local activeColor = Color3.fromRGB(90, 140, 220)
	local inactiveColor = Color3.fromRGB(45, 48, 58)

	englishButton.BackgroundColor3 = if activeLocale == "en" then activeColor else inactiveColor
	spanishButton.BackgroundColor3 = if activeLocale == "es" then activeColor else inactiveColor
end

local function applyLocale(locale: string)
	local normalized = Localization.applyLocale(locale)
	updateButtonStyles(normalized)
end

local function requestLocaleChange(locale: LocaleTypes.LocaleCode)
	if locale == Localization.getLocale() then
		return
	end

	Networking.getEvent("SetLocaleEvent"):FireServer(locale)
end

local function createLanguageButton(
	parent: Instance,
	labelKey: string,
	locale: LocaleTypes.LocaleCode,
	layoutOrder: number
): TextButton
	local button = Instance.new("TextButton")
	button.Name = `{locale}Button`
	button.Size = UDim2.fromOffset(72, 28)
	button.BackgroundColor3 = Color3.fromRGB(45, 48, 58)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	button.TextColor3 = Color3.fromRGB(240, 240, 240)
	button.Text = Localization.get(labelKey)
	button.LayoutOrder = layoutOrder
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	button.Activated:Connect(function()
		requestLocaleChange(locale)
	end)

	return button
end

function LocalizationController:Init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local trove = self:GetTrove()

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LocalizationHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 110
	screenGui.Parent = playerGui
	trove:Add(screenGui)

	local panel = Instance.new("Frame")
	panel.Name = "LanguagePanel"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -12, 0, 12)
	panel.Size = UDim2.fromOffset(180, 72)
	panel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel = 0
	panel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 8)
	panelCorner.Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 16)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 12
	title.TextColor3 = Color3.fromRGB(220, 220, 220)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = Localization.get("ui.settings.language")
	title.Parent = panel

	local buttonRow = Instance.new("Frame")
	buttonRow.Name = "Buttons"
	buttonRow.Position = UDim2.fromOffset(0, 24)
	buttonRow.Size = UDim2.new(1, 0, 0, 28)
	buttonRow.BackgroundTransparency = 1
	buttonRow.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.Parent = buttonRow

	englishButton = createLanguageButton(buttonRow, "ui.settings.language_en", "en", 1)
	spanishButton = createLanguageButton(buttonRow, "ui.settings.language_es", "es", 2)

	updateButtonStyles(Localization.getLocale())
end

function LocalizationController:Start()
	local trove = self:GetTrove()

	trove:Connect(Localization.LocaleChanged, function(locale: LocaleTypes.LocaleCode)
		if englishButton ~= nil then
			englishButton.Text = Localization.get("ui.settings.language_en")
		end

		if spanishButton ~= nil then
			spanishButton.Text = Localization.get("ui.settings.language_es")
		end

		updateButtonStyles(locale)
	end)

	trove:Connect(Networking.getEvent("PlayerDataLoadedEvent").OnClientEvent, function(profileData: PlayerProfileTypes.PlayerProfile)
		local locale = PlayerSettingsTypes.readLocale(profileData.settings)
		applyLocale(locale)
		Logger.info("LocalizationController", `Applied profile locale: {locale}`)
	end)

	trove:Connect(Networking.getEvent("LocaleChangedEvent").OnClientEvent, function(locale: string)
		if not LocaleRegistry.isSupported(locale) then
			return
		end

		applyLocale(locale)
	end)
end

return LocalizationController
