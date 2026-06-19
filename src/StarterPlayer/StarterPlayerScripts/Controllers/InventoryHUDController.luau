--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BaseController = require(script.Parent.Parent.Kernel.BaseController)
local ClientKernel = require(script.Parent.Parent.Kernel.ClientKernel)
local InventoryConstants = require(ReplicatedStorage.Shared.Constants.InventoryConstants)
local Items = require(ReplicatedStorage.Shared.Constants.Items)
local Localization = require(ReplicatedStorage.Shared.Localization.Localization)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local InventorySlotModule = require(ReplicatedStorage.Shared.UI.InventorySlot)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.Inventory)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)

local InventoryHUDController = BaseController.new("InventoryHUDController")

type InventorySlotInstance = InventorySlotModule.InventorySlot

local bagSlots: { InventorySlotInstance } = {}
local hotbarSlots: { InventorySlotInstance } = {}
local panelFrame: Frame? = nil
local selectedBagSlotKey: string? = nil
local latestSnapshot: PlayerProfileTypes.InventorySnapshot? = nil

local function getItemDisplayName(itemId: string): string
	local nameKey = Items.getNameKey(itemId)
	return Localization.get(nameKey)
end

local function refreshSelectedSlotHighlight()
	for index = 1, InventoryConstants.BAG_SLOT_COUNT do
		local slotKey = InventoryConstants.getBagSlotKey(index)
		local slot = bagSlots[index]
		slot:setSelected(selectedBagSlotKey == slotKey)
	end
end

local function renderSnapshot(snapshot: PlayerProfileTypes.InventorySnapshot)
	latestSnapshot = snapshot

	for index = 1, InventoryConstants.BAG_SLOT_COUNT do
		local slotKey = InventoryConstants.getBagSlotKey(index)
		local slot = bagSlots[index]
		local item = snapshot.inventory[slotKey]

		if item == nil then
			slot:setItem(nil, nil, nil)
			slot:setEquipped(false)
			slot:setSelected(selectedBagSlotKey == slotKey)
		else
			local isEquipped = snapshot.equipped.toolItemId == item.itemId
			slot:setItem(item.itemId, item.quantity, getItemDisplayName(item.itemId))
			slot:setEquipped(isEquipped)
			if not isEquipped then
				slot:setSelected(selectedBagSlotKey == slotKey)
			end
		end
	end

	for hotbarIndex = 1, InventoryConstants.HOTBAR_SLOT_COUNT do
		local hotbarSlot = hotbarSlots[hotbarIndex]
		local bagSlotKey = snapshot.hotbar[hotbarIndex]

		if bagSlotKey == nil then
			hotbarSlot:setItem(nil, nil, nil)
			hotbarSlot:setEquipped(false)
		else
			local item = snapshot.inventory[bagSlotKey]

			if item == nil then
				hotbarSlot:setItem(nil, nil, nil)
				hotbarSlot:setEquipped(false)
			else
				hotbarSlot:setItem(item.itemId, item.quantity, getItemDisplayName(item.itemId))
				hotbarSlot:setEquipped(snapshot.equipped.toolItemId == item.itemId)
			end
		end
	end

	refreshSelectedSlotHighlight()
end

local function requestUse(bagSlotKey: string?)
	if bagSlotKey == nil then
		return
	end

	Networking.getEvent("UseItemEvent"):FireServer(bagSlotKey)
end

local function requestEquip(bagSlotKey: string?)
	if bagSlotKey == nil then
		return
	end

	Networking.getEvent("EquipItemEvent"):FireServer(bagSlotKey)
end

local function requestHotbarAssign(hotbarIndex: number, bagSlotKey: string?)
	Networking.getEvent("SetHotbarSlotEvent"):FireServer(hotbarIndex, bagSlotKey)
end

local function onBagSlotActivated(bagSlotKey: string?)
	selectedBagSlotKey = bagSlotKey
	refreshSelectedSlotHighlight()
end

local function onHotbarSlotActivated(hotbarIndex: number)
	if selectedBagSlotKey ~= nil then
		requestHotbarAssign(hotbarIndex, selectedBagSlotKey)
		return
	end

	if latestSnapshot ~= nil then
		local bagSlotKey = latestSnapshot.hotbar[hotbarIndex]

		if bagSlotKey ~= nil then
			requestUse(bagSlotKey)
		end
	end
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

local function createActionButton(parent: Instance, labelKey: string, layoutOrder: number, onClick: () -> ()): TextButton
	local button = Instance.new("TextButton")
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

	button.Activated:Connect(onClick)
	return button
end

function InventoryHUDController:Init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local trove = self:GetTrove()

	local existingGui = playerGui:FindFirstChild("InventoryHUD")

	if existingGui ~= nil then
		existingGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InventoryHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 105
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	trove:Add(screenGui)

	local hotbarFrame = Instance.new("Frame")
	hotbarFrame.Name = "Hotbar"
	hotbarFrame.AnchorPoint = Vector2.new(0.5, 1)
	hotbarFrame.Position = UDim2.new(0.5, 0, 1, -16)
	hotbarFrame.Size = UDim2.fromOffset(336, 56)
	hotbarFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	hotbarFrame.BackgroundTransparency = 0.15
	hotbarFrame.BorderSizePixel = 0
	hotbarFrame.Parent = screenGui

	local hotbarCorner = Instance.new("UICorner")
	hotbarCorner.CornerRadius = UDim.new(0, 8)
	hotbarCorner.Parent = hotbarFrame

	local hotbarLayout = Instance.new("UIListLayout")
	hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
	hotbarLayout.Padding = UDim.new(0, 6)
	hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	hotbarLayout.Parent = hotbarFrame

	for hotbarIndex = 1, InventoryConstants.HOTBAR_SLOT_COUNT do
		local capturedIndex = hotbarIndex
		local slot = InventorySlotModule.create(hotbarFrame, {
			layoutOrder = hotbarIndex,
			onActivated = function()
				onHotbarSlotActivated(capturedIndex)
			end,
		})
		hotbarSlots[hotbarIndex] = slot
	end

	panelFrame = Instance.new("Frame")
	panelFrame.Name = "InventoryPanel"
	panelFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	panelFrame.Position = UDim2.fromScale(0.5, 0.5)
	panelFrame.Size = UDim2.fromOffset(280, 360)
	panelFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	panelFrame.BackgroundTransparency = 0.1
	panelFrame.BorderSizePixel = 0
	panelFrame.Visible = false
	panelFrame.ZIndex = 5
	panelFrame.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 10)
	panelCorner.Parent = panelFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -16, 0, 24)
	title.Position = UDim2.fromOffset(8, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = Color3.fromRGB(240, 240, 240)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = Localization.get("ui.inventory.title")
	title.Parent = panelFrame

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

	local grid = Instance.new("Frame")
	grid.Name = "Grid"
	grid.Position = UDim2.fromOffset(12, 40)
	grid.Size = UDim2.fromOffset(256, 256)
	grid.BackgroundTransparency = 1
	grid.Parent = panelFrame

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.fromOffset(58, 58)
	gridLayout.CellPadding = UDim2.fromOffset(6, 6)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = grid

	for slotIndex = 1, InventoryConstants.BAG_SLOT_COUNT do
		local slotKey = InventoryConstants.getBagSlotKey(slotIndex)
		local slot = InventorySlotModule.create(grid, {
			slotKey = slotKey,
			layoutOrder = slotIndex,
			onActivated = onBagSlotActivated,
		})
		bagSlots[slotIndex] = slot
	end

	local actions = Instance.new("Frame")
	actions.Name = "Actions"
	actions.Position = UDim2.fromOffset(12, 304)
	actions.Size = UDim2.fromOffset(256, 32)
	actions.BackgroundTransparency = 1
	actions.Parent = panelFrame

	local actionsLayout = Instance.new("UIListLayout")
	actionsLayout.FillDirection = Enum.FillDirection.Horizontal
	actionsLayout.Padding = UDim.new(0, 8)
	actionsLayout.Parent = actions

	createActionButton(actions, "ui.inventory.use", 1, function()
		requestUse(selectedBagSlotKey)
	end)

	createActionButton(actions, "ui.inventory.equip", 2, function()
		requestEquip(selectedBagSlotKey)
	end)

	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleInventory"
	toggleButton.AnchorPoint = Vector2.new(1, 1)
	toggleButton.Position = UDim2.new(1, -12, 1, -80)
	toggleButton.Size = UDim2.fromOffset(40, 40)
	toggleButton.BackgroundColor3 = Color3.fromRGB(45, 48, 58)
	toggleButton.BorderSizePixel = 0
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextSize = 18
	toggleButton.TextColor3 = Color3.fromRGB(240, 240, 240)
	toggleButton.Text = "I"
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

		if input.KeyCode == Enum.KeyCode.I then
			togglePanel()
			return
		end

		if input.KeyCode == Enum.KeyCode.Escape then
			setPanelVisible(false)
		end
	end)
end

function InventoryHUDController:Start()
	local trove = self:GetTrove()

	trove:Connect(Localization.LocaleChanged, function()
		if panelFrame ~= nil then
			local title = panelFrame:FindFirstChild("Title")

			if title ~= nil and title:IsA("TextLabel") then
				title.Text = Localization.get("ui.inventory.title")
			end
		end

		if latestSnapshot ~= nil then
			renderSnapshot(latestSnapshot)
		end
	end)

	trove:Connect(Networking.getEvent("InventoryUpdatedEvent").OnClientEvent, function(snapshot: PlayerProfileTypes.InventorySnapshot)
		renderSnapshot(snapshot)
	end)

	local syncController = ClientKernel.getController("ClientSyncController")

	if syncController ~= nil then
		local inventory = syncController:GetInventory()

		if inventory ~= nil then
			renderSnapshot(inventory)
		end
	end
end

return InventoryHUDController
