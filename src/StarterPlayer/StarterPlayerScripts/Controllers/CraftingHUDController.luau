--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BaseController = require(script.Parent.Parent.Kernel.BaseController)
local ClientKernel = require(script.Parent.Parent.Kernel.ClientKernel)
local CraftingConstants = require(ReplicatedStorage.Shared.Constants.CraftingConstants)
local Items = require(ReplicatedStorage.Shared.Constants.Items)
local Localization = require(ReplicatedStorage.Shared.Localization.Localization)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local Recipes = require(ReplicatedStorage.Shared.Constants.Recipes)
local ItemIcon = require(ReplicatedStorage.Shared.UI.ItemIcon)
local CraftingTypes = require(ReplicatedStorage.Shared.Types.Crafting)
local RecipeTypes = require(ReplicatedStorage.Shared.Types.Recipe)

local CraftingHUDController = BaseController.new("CraftingHUDController")

local panelFrame: Frame? = nil
local recipeListFrame: ScrollingFrame? = nil
local detailLabel: TextLabel? = nil
local craftButton: TextButton? = nil
local toastLabel: TextLabel? = nil
local titleLabel: TextLabel? = nil

local unlockedRecipes: { string } = {}
local selectedRecipeId: string? = nil
local toastToken = 0

local function getLocalizedName(nameKey: string): string
	return Localization.get(nameKey)
end

local function formatRecipeDetail(recipe: RecipeTypes.RecipeDefinition): string
	local inputParts: { string } = {}

	for _, input in recipe.inputs do
		local itemName = getLocalizedName(Items.getNameKey(input.itemId))
		table.insert(inputParts, `{input.quantity}x {itemName}`)
	end

	local outputParts: { string } = {}

	for _, output in recipe.outputs do
		local itemName = getLocalizedName(Items.getNameKey(output.itemId))
		table.insert(outputParts, `{output.quantity}x {itemName}`)
	end

	return Localization.format("ui.craft.detail", {
		inputs = table.concat(inputParts, ", "),
		outputs = table.concat(outputParts, ", "),
	})
end

local function isRecipeUnlocked(recipeId: string): boolean
	for _, unlockedId in unlockedRecipes do
		if unlockedId == recipeId then
			return true
		end
	end

	return false
end

local function getVisibleRecipes(): { RecipeTypes.RecipeDefinition }
	local visible: { RecipeTypes.RecipeDefinition } = {}

	for _, recipe in Recipes.getAll() do
		if recipe.station == CraftingConstants.HANDS_STATION and isRecipeUnlocked(recipe.id) then
			table.insert(visible, recipe)
		end
	end

	table.sort(visible, function(left, right)
		return left.id < right.id
	end)

	return visible
end

local function showToast(messageKey: string)
	if toastLabel == nil then
		return
	end

	toastToken += 1
	local currentToken = toastToken
	toastLabel.Text = Localization.get(messageKey)
	toastLabel.Visible = true

	task.delay(2.5, function()
		if toastToken == currentToken and toastLabel ~= nil then
			toastLabel.Visible = false
		end
	end)
end

local function updateDetailPanel()
	if detailLabel == nil then
		return
	end

	if selectedRecipeId == nil then
		detailLabel.Text = Localization.get("ui.craft.select_recipe")
		return
	end

	local recipe = Recipes.get(selectedRecipeId)

	if recipe == nil then
		detailLabel.Text = Localization.get("ui.craft.select_recipe")
		return
	end

	detailLabel.Text = formatRecipeDetail(recipe)
end

local function renderRecipeList()
	if recipeListFrame == nil then
		return
	end

	for _, child in recipeListFrame:GetChildren() do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	local visibleRecipes = getVisibleRecipes()

	if #visibleRecipes == 0 then
		selectedRecipeId = nil
		updateDetailPanel()
		return
	end

	if selectedRecipeId == nil or not isRecipeUnlocked(selectedRecipeId) then
		selectedRecipeId = visibleRecipes[1].id
	end

	for index, recipe in visibleRecipes do
		local button = Instance.new("TextButton")
		button.Name = recipe.id
		button.Size = UDim2.new(1, -8, 0, 40)
		button.BackgroundColor3 = if selectedRecipeId == recipe.id
			then Color3.fromRGB(58, 72, 96)
			else Color3.fromRGB(45, 48, 58)
		button.BorderSizePixel = 0
		button.Text = ""
		button.AutoButtonColor = true
		button.LayoutOrder = index
		button.Parent = recipeListFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = button

		local rowPadding = Instance.new("UIPadding")
		rowPadding.PaddingLeft = UDim.new(0, 8)
		rowPadding.PaddingRight = UDim.new(0, 8)
		rowPadding.Parent = button

		local rowLayout = Instance.new("UIListLayout")
		rowLayout.FillDirection = Enum.FillDirection.Horizontal
		rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		rowLayout.Padding = UDim.new(0, 8)
		rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
		rowLayout.Parent = button

		local iconImage = Instance.new("ImageLabel")
		iconImage.Name = "Icon"
		iconImage.Size = UDim2.fromOffset(28, 28)
		iconImage.BackgroundTransparency = 1
		iconImage.ScaleType = Enum.ScaleType.Fit
		iconImage.LayoutOrder = 1
		iconImage.Parent = button
		ItemIcon.applyTo(iconImage, Recipes.getIconItemId(recipe.id))

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(1, -36, 1, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextSize = 13
		nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Text = getLocalizedName(recipe.nameKey)
		nameLabel.LayoutOrder = 2
		nameLabel.Parent = button

		button.Activated:Connect(function()
			selectedRecipeId = recipe.id
			renderRecipeList()
			updateDetailPanel()
		end)
	end

	updateDetailPanel()
end

local function setPanelVisible(visible: boolean)
	if panelFrame ~= nil then
		panelFrame.Visible = visible
	end
end

local function togglePanel()
	if panelFrame ~= nil then
		panelFrame.Visible = not panelFrame.Visible
	end
end

local function requestCraft()
	if selectedRecipeId == nil then
		showToast("craft.error.select_recipe")
		return
	end

	Networking.getEvent("CraftItemEvent"):FireServer(selectedRecipeId)
end

local function onRecipesUpdated(snapshot: CraftingTypes.RecipesSnapshot)
	unlockedRecipes = snapshot.unlocked
	renderRecipeList()
end

local function onCraftResult(payload: CraftingTypes.CraftResultPayload)
	if payload.success then
		showToast("craft.success.generic")
		return
	end

	if payload.reasonKey ~= nil then
		showToast(payload.reasonKey)
	end
end

function CraftingHUDController:Init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local trove = self:GetTrove()

	local existingGui = playerGui:FindFirstChild("CraftingHUD")

	if existingGui ~= nil then
		existingGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CraftingHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 106
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	trove:Add(screenGui)

	panelFrame = Instance.new("Frame")
	panelFrame.Name = "CraftingPanel"
	panelFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	panelFrame.Position = UDim2.fromScale(0.5, 0.5)
	panelFrame.Size = UDim2.fromOffset(320, 400)
	panelFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	panelFrame.BackgroundTransparency = 0.1
	panelFrame.BorderSizePixel = 0
	panelFrame.Visible = false
	panelFrame.ZIndex = 5
	panelFrame.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 10)
	panelCorner.Parent = panelFrame

	titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -16, 0, 24)
	titleLabel.Position = UDim2.fromOffset(8, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = Localization.get("ui.craft.title")
	titleLabel.Parent = panelFrame

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.new(1, -8, 0, 8)
	closeButton.Size = UDim2.fromOffset(24, 24)
	closeButton.BackgroundColor3 = Color3.fromRGB(45, 48, 58)
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 14
	closeButton.TextColor3 = Color3.fromRGB(240, 240, 240)
	closeButton.Text = "X"
	closeButton.Parent = panelFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton

	closeButton.Activated:Connect(function()
		setPanelVisible(false)
	end)

	recipeListFrame = Instance.new("ScrollingFrame")
	recipeListFrame.Name = "RecipeList"
	recipeListFrame.Position = UDim2.fromOffset(12, 40)
	recipeListFrame.Size = UDim2.fromOffset(296, 180)
	recipeListFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
	recipeListFrame.BackgroundTransparency = 0.2
	recipeListFrame.BorderSizePixel = 0
	recipeListFrame.ScrollBarThickness = 6
	recipeListFrame.CanvasSize = UDim2.fromOffset(0, 0)
	recipeListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	recipeListFrame.Parent = panelFrame

	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 8)
	listCorner.Parent = recipeListFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 4)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = recipeListFrame

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 4)
	listPadding.PaddingBottom = UDim.new(0, 4)
	listPadding.PaddingLeft = UDim.new(0, 4)
	listPadding.PaddingRight = UDim.new(0, 4)
	listPadding.Parent = recipeListFrame

	detailLabel = Instance.new("TextLabel")
	detailLabel.Name = "Detail"
	detailLabel.Position = UDim2.fromOffset(12, 228)
	detailLabel.Size = UDim2.fromOffset(296, 96)
	detailLabel.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
	detailLabel.BackgroundTransparency = 0.2
	detailLabel.BorderSizePixel = 0
	detailLabel.Font = Enum.Font.Gotham
	detailLabel.TextSize = 12
	detailLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	detailLabel.TextXAlignment = Enum.TextXAlignment.Left
	detailLabel.TextYAlignment = Enum.TextYAlignment.Top
	detailLabel.TextWrapped = true
	detailLabel.Text = Localization.get("ui.craft.select_recipe")
	detailLabel.Parent = panelFrame

	local detailCorner = Instance.new("UICorner")
	detailCorner.CornerRadius = UDim.new(0, 8)
	detailCorner.Parent = detailLabel

	local detailPadding = Instance.new("UIPadding")
	detailPadding.PaddingTop = UDim.new(0, 8)
	detailPadding.PaddingLeft = UDim.new(0, 8)
	detailPadding.PaddingRight = UDim.new(0, 8)
	detailPadding.Parent = detailLabel

	craftButton = Instance.new("TextButton")
	craftButton.Name = "CraftButton"
	craftButton.Position = UDim2.fromOffset(12, 336)
	craftButton.Size = UDim2.fromOffset(296, 36)
	craftButton.BackgroundColor3 = Color3.fromRGB(58, 120, 72)
	craftButton.BorderSizePixel = 0
	craftButton.Font = Enum.Font.GothamBold
	craftButton.TextSize = 14
	craftButton.TextColor3 = Color3.fromRGB(240, 240, 240)
	craftButton.Text = Localization.get("ui.craft.craft_button")
	craftButton.Parent = panelFrame

	local craftCorner = Instance.new("UICorner")
	craftCorner.CornerRadius = UDim.new(0, 8)
	craftCorner.Parent = craftButton

	craftButton.Activated:Connect(requestCraft)

	toastLabel = Instance.new("TextLabel")
	toastLabel.Name = "Toast"
	toastLabel.AnchorPoint = Vector2.new(0.5, 1)
	toastLabel.Position = UDim2.new(0.5, 0, 1, -120)
	toastLabel.Size = UDim2.fromOffset(280, 32)
	toastLabel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	toastLabel.BackgroundTransparency = 0.15
	toastLabel.BorderSizePixel = 0
	toastLabel.Font = Enum.Font.Gotham
	toastLabel.TextSize = 13
	toastLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	toastLabel.Visible = false
	toastLabel.Parent = screenGui

	local toastCorner = Instance.new("UICorner")
	toastCorner.CornerRadius = UDim.new(0, 8)
	toastCorner.Parent = toastLabel

	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleCrafting"
	toggleButton.AnchorPoint = Vector2.new(1, 1)
	toggleButton.Position = UDim2.new(1, -60, 1, -80)
	toggleButton.Size = UDim2.fromOffset(40, 40)
	toggleButton.BackgroundColor3 = Color3.fromRGB(45, 48, 58)
	toggleButton.BorderSizePixel = 0
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextSize = 18
	toggleButton.TextColor3 = Color3.fromRGB(240, 240, 240)
	toggleButton.Text = "C"
	toggleButton.ZIndex = 10
	toggleButton.Parent = screenGui

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 8)
	toggleCorner.Parent = toggleButton

	toggleButton.Activated:Connect(togglePanel)

	trove:Connect(UserInputService.InputBegan, function(input, _processed)
		if UserInputService:GetFocusedTextBox() ~= nil then
			return
		end

		if input.KeyCode == Enum.KeyCode.C then
			togglePanel()
			return
		end

		if input.KeyCode == Enum.KeyCode.Escape then
			setPanelVisible(false)
		end
	end)
end

function CraftingHUDController:Start()
	local trove = self:GetTrove()

	trove:Connect(Localization.LocaleChanged, function()
		if titleLabel ~= nil then
			titleLabel.Text = Localization.get("ui.craft.title")
		end

		if craftButton ~= nil then
			craftButton.Text = Localization.get("ui.craft.craft_button")
		end

		renderRecipeList()
	end)

	trove:Connect(Networking.getEvent("RecipesUpdatedEvent").OnClientEvent, onRecipesUpdated)
	trove:Connect(Networking.getEvent("CraftResultEvent").OnClientEvent, onCraftResult)

	local syncController = ClientKernel.getController("ClientSyncController")

	if syncController ~= nil then
		local recipes = syncController:GetRecipes()

		if recipes ~= nil then
			onRecipesUpdated(recipes)
		end
	end
end

return CraftingHUDController
