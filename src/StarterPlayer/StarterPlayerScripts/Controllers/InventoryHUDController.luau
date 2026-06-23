--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
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
local screenGui: ScreenGui? = nil
local selectedBagSlotKey: string? = nil
local latestSnapshot: PlayerProfileTypes.InventorySnapshot? = nil
local equipButton: TextButton? = nil
local unequipButton: TextButton? = nil

local PANEL_DISPLAY_ORDER = 105
local PANEL_OPEN_DISPLAY_ORDER = 115

local BUTTON_ENABLED_BG = Color3.fromRGB(45, 48, 58)
local BUTTON_DISABLED_BG = Color3.fromRGB(32, 34, 40)
local BUTTON_ENABLED_TEXT = Color3.fromRGB(240, 240, 240)
local BUTTON_DISABLED_TEXT = Color3.fromRGB(120, 124, 132)

local function normalizeSnapshot(snapshot: PlayerProfileTypes.InventorySnapshot): PlayerProfileTypes.InventorySnapshot
	return {
		inventory = if type(snapshot.inventory) == "table" then snapshot.inventory else InventoryTypes.createEmptyBag(),
		hotbar = if type(snapshot.hotbar) == "table" then snapshot.hotbar else InventoryTypes.createEmptyHotbar(),
		equipped = if type(snapshot.equipped) == "table" then snapshot.equipped else InventoryTypes.createEmptyEquipped(),
	}
end

local function closeOtherHudPanels()
	for _, controllerName in { "CraftingHUDController", "BuildingController", "ChestController" } do
		local controller = ClientKernel.getController(controllerName)

		if controller ~= nil then
			local closePanel = (controller :: any).ClosePanel

			if type(closePanel) == "function" then
				closePanel(controller)
			end
		end
	end
end

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

local function hasEquippedTool(): boolean
	if latestSnapshot == nil then
		return false
	end

	return latestSnapshot.equipped.toolItemId ~= nil
end

local function getSelectedItem(): InventoryTypes.InventoryItem?
	if latestSnapshot == nil or selectedBagSlotKey == nil then
		return nil
	end

	return latestSnapshot.inventory[selectedBagSlotKey]
end

local function isEquippableTool(itemId: string): boolean
	local definition = Items.get(itemId)

	return definition ~= nil and definition.category == "tool"
end

local function canEquipSelected(): boolean
	local item = getSelectedItem()

	if item == nil then
		return false
	end

	if not isEquippableTool(item.itemId) then
		return false
	end

	if latestSnapshot == nil then
		return false
	end

	return latestSnapshot.equipped.toolItemId ~= item.itemId
end

local function canUnequip(): boolean
	return hasEquippedTool()
end

local function setActionButtonEnabled(button: TextButton?, enabled: boolean)
	if button == nil then
		return
	end

	button.Active = enabled
	button.AutoButtonColor = enabled
	button.BackgroundColor3 = if enabled then BUTTON_ENABLED_BG else BUTTON_DISABLED_BG
	button.TextColor3 = if enabled then BUTTON_ENABLED_TEXT else BUTTON_DISABLED_TEXT
end

local function refreshActionButtons()
	if equipButton ~= nil then
		equipButton.Text = Localization.get("ui.inventory.equip")
		setActionButtonEnabled(equipButton, canEquipSelected())
	end

	if unequipButton ~= nil then
		unequipButton.Text = Localization.get("ui.inventory.unequip")
		setActionButtonEnabled(unequipButton, canUnequip())
	end
end

local function renderSnapshot(snapshot: PlayerProfileTypes.InventorySnapshot)
	local normalizedSnapshot = normalizeSnapshot(snapshot)
	latestSnapshot = normalizedSnapshot

	for index = 1, InventoryConstants.BAG_SLOT_COUNT do
		local slotKey = InventoryConstants.getBagSlotKey(index)
		local slot = bagSlots[index]

		if slot == nil then
			continue
		end

		local item = normalizedSnapshot.inventory[slotKey]

		if item == nil then
			slot:setItem(nil, nil, nil)
			slot:setEquipped(false)
			slot:setSelected(selectedBagSlotKey == slotKey)
		else
			local isEquipped = normalizedSnapshot.equipped.toolItemId == item.itemId
			slot:setItem(item.itemId, item.quantity, getItemDisplayName(item.itemId))
			slot:setEquipped(isEquipped)
			if not isEquipped then
				slot:setSelected(selectedBagSlotKey == slotKey)
			end
		end
	end

	for hotbarIndex = 1, InventoryConstants.HOTBAR_SLOT_COUNT do
		local hotbarSlot = hotbarSlots[hotbarIndex]

		if hotbarSlot == nil then
			continue
		end

		local bagSlotKey = normalizedSnapshot.hotbar[hotbarIndex]

		if bagSlotKey == nil then
			hotbarSlot:setItem(nil, nil, nil)
			hotbarSlot:setEquipped(false)
		else
			local item = normalizedSnapshot.inventory[bagSlotKey]

			if item == nil then
				hotbarSlot:setItem(nil, nil, nil)
				hotbarSlot:setEquipped(false)
			else
				hotbarSlot:setItem(item.itemId, item.quantity, getItemDisplayName(item.itemId))
				hotbarSlot:setEquipped(normalizedSnapshot.equipped.toolItemId == item.itemId)
			end
		end
	end

	refreshSelectedSlotHighlight()
	refreshActionButtons()
end

local function requestUse(bagSlotKey: string?)
	if bagSlotKey == nil then
		return
	end

	Networking.getEvent("UseItemEvent"):FireServer(bagSlotKey)
end

local function requestUnequip()
	if not canUnequip() then
		return
	end

	Networking.getEvent("UnequipItemEvent"):FireServer()
end

local function requestEquip(bagSlotKey: string?)
	if bagSlotKey == nil or not canEquipSelected() then
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
	refreshActionButtons()

	local chestController = ClientKernel.getController("ChestController")

	if chestController ~= nil then
		local setSelectedBagSlot = (chestController :: any).SetSelectedBagSlot

		if type(setSelectedBagSlot) == "function" then
			setSelectedBagSlot(bagSlotKey)
		end
	end
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

	if screenGui ~= nil then
		screenGui.DisplayOrder = if visible then PANEL_OPEN_DISPLAY_ORDER else PANEL_DISPLAY_ORDER
	end
end

local function openPanel()
	closeOtherHudPanels()
	setPanelVisible(true)
end

local function togglePanel()
	if panelFrame == nil then
		return
	end

	if panelFrame.Visible then
		setPanelVisible(false)
	else
		openPanel()
	end
end

function InventoryHUDController:ClosePanel()
	setPanelVisible(false)
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

	local gui = Instance.new("ScreenGui")
	gui.Name = "InventoryHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = PANEL_DISPLAY_ORDER
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	screenGui = gui
	trove:Add(gui)

	local hotbarFrame = Instance.new("Frame")
	hotbarFrame.Name = "Hotbar"
	hotbarFrame.AnchorPoint = Vector2.new(0.5, 1)
	hotbarFrame.Position = UDim2.new(0.5, 0, 1, -16)
	hotbarFrame.Size = UDim2.fromOffset(336, 56)
	hotbarFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	hotbarFrame.BackgroundTransparency = 0.15
	hotbarFrame.BorderSizePixel = 0
	hotbarFrame.Parent = gui

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
	panelFrame.Parent = gui

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

	equipButton = createActionButton(actions, "ui.inventory.equip", 2, function()
		requestEquip(selectedBagSlotKey)
	end)

	unequipButton = createActionButton(actions, "ui.inventory.unequip", 3, function()
		requestUnequip()
	end)
	unequipButton.Size = UDim2.fromOffset(84, 28)
	equipButton.Size = UDim2.fromOffset(84, 28)
	refreshActionButtons()

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
	toggleButton.Parent = gui

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 8)
	toggleCorner.Parent = toggleButton

	toggleButton.Activated:Connect(togglePanel)

	trove:Connect(UserInputService.InputBegan, function(input, _processed)
		if UserInputService:GetFocusedTextBox() ~= nil then
			return
		end

		if input.KeyCode == Enum.KeyCode.Escape then
			setPanelVisible(false)
		end
	end)

	ContextActionService:BindAction(
		"ToggleInventory",
		function(_actionName, inputState)
			if inputState ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Pass
			end

			if UserInputService:GetFocusedTextBox() ~= nil then
				return Enum.ContextActionResult.Pass
			end

			togglePanel()
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.KeyCode.I
	)

	trove:Add(function()
		ContextActionService:UnbindAction("ToggleInventory")
	end)

	trove:Connect(Networking.getEvent("InventoryUpdatedEvent").OnClientEvent, function(snapshot: PlayerProfileTypes.InventorySnapshot)
		renderSnapshot(snapshot)
	end)

	trove:Connect(Networking.getEvent("PlayerDataLoadedEvent").OnClientEvent, function(profileData: PlayerProfileTypes.PlayerProfile)
		if type(profileData.inventory) ~= "table" then
			return
		end

		renderSnapshot({
			inventory = profileData.inventory,
			hotbar = profileData.hotbar,
			equipped = profileData.equipped,
		})
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

		refreshActionButtons()

		if latestSnapshot ~= nil then
			renderSnapshot(latestSnapshot)
		end
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
