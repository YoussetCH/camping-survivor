--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local BaseController = require(script.Parent.Parent.Kernel.BaseController)
local ClientKernel = require(script.Parent.Parent.Kernel.ClientKernel)
local CampConstants = require(ReplicatedStorage.Shared.Constants.CampConstants)
local InventoryConstants = require(ReplicatedStorage.Shared.Constants.InventoryConstants)
local Items = require(ReplicatedStorage.Shared.Constants.Items)
local Localization = require(ReplicatedStorage.Shared.Localization.Localization)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local InventorySlotModule = require(ReplicatedStorage.Shared.UI.InventorySlot)
local CampTypes = require(ReplicatedStorage.Shared.Types.Camp)
local CampProximity = require(ReplicatedStorage.Shared.Utilities.CampProximity)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)

local ChestController = BaseController.new("ChestController")

type InventorySlotInstance = InventorySlotModule.InventorySlot

local panelFrame: Frame? = nil
local hintLabel: TextLabel? = nil
local toastLabel: TextLabel? = nil
local bagSlots: { InventorySlotInstance } = {}
local chestSlots: { InventorySlotInstance } = {}
local activeChestStructureId: string? = nil
local selectedChestSlotKey: string? = nil
local selectedBagSlotKey: string? = nil
local toastToken = 0
local pendingInventorySnapshot: PlayerProfileTypes.InventorySnapshot? = nil
local pendingCampSnapshot: CampTypes.CampSnapshot? = nil
local panelRenderScheduled = false

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

local function getCampSnapshot(): CampTypes.CampSnapshot?
	local syncController = ClientKernel.getController("ClientSyncController")

	if syncController == nil then
		return nil
	end

	return syncController:GetCamp()
end

local function getInventorySnapshot(): PlayerProfileTypes.InventorySnapshot?
	local syncController = ClientKernel.getController("ClientSyncController")

	if syncController == nil then
		return nil
	end

	return syncController:GetInventory()
end

local function getItemDisplayName(itemId: string): string
	return Localization.get(Items.getNameKey(itemId))
end

local function getPlayerRoot(): BasePart?
	local character = Players.LocalPlayer.Character
	local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil

	if root ~= nil and root:IsA("BasePart") then
		return root
	end

	return nil
end

local function findNearestChestStructureId(): string?
	local root = getPlayerRoot()

	if root == nil then
		return nil
	end

	local nearestId: string? = nil
	local nearestDistance = CampConstants.CHEST_INTERACT_RANGE + 1
	local camp = getCampSnapshot()

	if camp ~= nil then
		for _, structure in camp.structures do
			if structure.blueprintId ~= "bp_chest" then
				continue
			end

			local position = CampProximity.toVector3(structure.position)

			if position == nil then
				continue
			end

			local distance = (root.Position - position).Magnitude

			if distance <= CampConstants.CHEST_INTERACT_RANGE and distance < nearestDistance then
				nearestDistance = distance
				nearestId = structure.structureId
			end
		end
	end

	local userId = Players.LocalPlayer.UserId
	local campHub = workspace:FindFirstChild("CampHub")
	local structuresRoot = if campHub ~= nil then campHub:FindFirstChild("Structures") else nil

	if structuresRoot ~= nil then
		for _, plotFolder in structuresRoot:GetChildren() do
			for _, child in plotFolder:GetChildren() do
				if not child:IsA("Model") then
					continue
				end

				if child:GetAttribute("BlueprintId") ~= "bp_chest" or child:GetAttribute("OwnerUserId") ~= userId then
					continue
				end

				local structureId = child:GetAttribute("StructureId")

				if type(structureId) ~= "string" then
					continue
				end

				local pivot = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")

				if pivot == nil then
					continue
				end

				local distance = (root.Position - pivot.Position).Magnitude

				if distance <= CampConstants.CHEST_INTERACT_RANGE and distance < nearestDistance then
					nearestDistance = distance
					nearestId = structureId
				end
			end
		end
	end

	return nearestId
end

local function refreshSelectionHighlights()
	for index = 1, InventoryConstants.BAG_SLOT_COUNT do
		local slot = bagSlots[index]

		if slot ~= nil then
			slot:setSelected(selectedBagSlotKey == InventoryConstants.getBagSlotKey(index))
		end
	end

	for index = 1, CampConstants.CHEST_SLOT_COUNT do
		local slot = chestSlots[index]

		if slot ~= nil then
			slot:setSelected(selectedChestSlotKey == CampConstants.getChestSlotKey(index))
		end
	end
end

local function renderBagInventory(snapshot: PlayerProfileTypes.InventorySnapshot?)
	local inventory = snapshot or getInventorySnapshot()

	for index = 1, InventoryConstants.BAG_SLOT_COUNT do
		local slotKey = InventoryConstants.getBagSlotKey(index)
		local slot = bagSlots[index]

		if slot == nil then
			continue
		end

		if inventory == nil then
			slot:setItem(nil, nil, nil)
			slot:setEquipped(false)
			slot:setSelected(selectedBagSlotKey == slotKey)
			continue
		end

		local item = inventory.inventory[slotKey]

		if item == nil then
			slot:setItem(nil, nil, nil)
			slot:setEquipped(false)
			slot:setSelected(selectedBagSlotKey == slotKey)
		else
			slot:setItem(item.itemId, item.quantity, getItemDisplayName(item.itemId))
			slot:setEquipped(inventory.equipped.toolItemId == item.itemId)
			if inventory.equipped.toolItemId ~= item.itemId then
				slot:setSelected(selectedBagSlotKey == slotKey)
			end
		end
	end
end

local function renderChestContents(chestStructureId: string, campSnapshot: CampTypes.CampSnapshot?)
	local camp = campSnapshot or getCampSnapshot()

	if camp == nil then
		return
	end

	local chest = camp.chests[chestStructureId] or {}

	for index = 1, CampConstants.CHEST_SLOT_COUNT do
		local slotKey = CampConstants.getChestSlotKey(index)
		local slot = chestSlots[index]

		if slot == nil then
			continue
		end

		local item = chest[slotKey]

		if item == nil then
			slot:setItem(nil, nil, nil)
			slot:setEquipped(false)
			slot:setSelected(selectedChestSlotKey == slotKey)
		else
			slot:setItem(item.itemId, item.quantity, getItemDisplayName(item.itemId))
			slot:setEquipped(false)
			slot:setSelected(selectedChestSlotKey == slotKey)
		end
	end
end

local function renderPanel(inventorySnapshot: PlayerProfileTypes.InventorySnapshot?, campSnapshot: CampTypes.CampSnapshot?)
	renderBagInventory(inventorySnapshot)

	if activeChestStructureId ~= nil then
		renderChestContents(activeChestStructureId, campSnapshot)
	end

	refreshSelectionHighlights()
end

local function flushScheduledPanelRender()
	panelRenderScheduled = false

	if activeChestStructureId == nil then
		pendingInventorySnapshot = nil
		pendingCampSnapshot = nil
		return
	end

	local inventorySnapshot = pendingInventorySnapshot
	local campSnapshot = pendingCampSnapshot
	pendingInventorySnapshot = nil
	pendingCampSnapshot = nil

	renderPanel(inventorySnapshot, campSnapshot)
end

local function schedulePanelRender()
	if panelRenderScheduled then
		return
	end

	panelRenderScheduled = true
	task.defer(flushScheduledPanelRender)
end

local function onInventorySnapshot(snapshot: PlayerProfileTypes.InventorySnapshot)
	pendingInventorySnapshot = snapshot
	schedulePanelRender()
end

local function onCampSnapshot(snapshot: CampTypes.CampSnapshot)
	pendingCampSnapshot = snapshot
	schedulePanelRender()
end

local function setPanelVisible(visible: boolean)
	if panelFrame ~= nil then
		panelFrame.Visible = visible
	end

	if not visible then
		activeChestStructureId = nil
		selectedChestSlotKey = nil
		selectedBagSlotKey = nil
		refreshSelectionHighlights()
	end
end

function ChestController:ClosePanel()
	setPanelVisible(false)
end

local function openChest(chestStructureId: string)
	local inventoryController = ClientKernel.getController("InventoryHUDController")

	if inventoryController ~= nil then
		local closePanel = (inventoryController :: any).ClosePanel

		if type(closePanel) == "function" then
			closePanel(inventoryController)
		end
	end

	activeChestStructureId = chestStructureId
	selectedChestSlotKey = nil
	selectedBagSlotKey = nil
	renderPanel()
	setPanelVisible(true)
end

local function tryToggleNearbyChest()
	if panelFrame ~= nil and panelFrame.Visible then
		setPanelVisible(false)
		return
	end

	local chestStructureId = findNearestChestStructureId()

	if chestStructureId ~= nil then
		openChest(chestStructureId)
	end
end

local requestDeposit: () -> ()
local requestWithdraw: () -> ()

local function onBagSlotActivated(bagSlotKey: string?)
	selectedBagSlotKey = bagSlotKey
	selectedChestSlotKey = nil
	refreshSelectionHighlights()
end

local function onChestSlotActivated(chestSlotKey: string?)
	selectedChestSlotKey = chestSlotKey

	if selectedBagSlotKey ~= nil then
		requestDeposit()
		return
	end

	selectedBagSlotKey = nil
	refreshSelectionHighlights()
end

requestDeposit = function()
	if activeChestStructureId == nil or selectedBagSlotKey == nil then
		showToast("ui.chest.error.select_bag")
		return
	end

	Networking.getEvent("TransferItemEvent"):FireServer({
		direction = "toChest",
		chestStructureId = activeChestStructureId,
		bagSlotKey = selectedBagSlotKey,
		chestSlotKey = selectedChestSlotKey,
	})

	selectedBagSlotKey = nil
	selectedChestSlotKey = nil
	refreshSelectionHighlights()
end

requestWithdraw = function()
	if activeChestStructureId == nil or selectedChestSlotKey == nil then
		showToast("ui.chest.error.select_chest")
		return
	end

	Networking.getEvent("TransferItemEvent"):FireServer({
		direction = "toBag",
		chestStructureId = activeChestStructureId,
		chestSlotKey = selectedChestSlotKey,
		bagSlotKey = selectedBagSlotKey,
	})

	selectedBagSlotKey = nil
	selectedChestSlotKey = nil
	refreshSelectionHighlights()
end

local function bindChestPrompt(prompt: ProximityPrompt)
	if prompt:GetAttribute("ChestPromptBound") == true then
		return
	end

	prompt:SetAttribute("ChestPromptBound", true)
	prompt.ActionText = Localization.get("ui.chest.open")
	prompt.ObjectText = Localization.get("ui.chest.title")

	prompt.Triggered:Connect(function()
		local model = prompt:FindFirstAncestorOfClass("Model")
		local structureId = if model ~= nil then model:GetAttribute("StructureId") else nil

		if type(structureId) == "string" then
			openChest(structureId)
		end
	end)
end

local function scanChestPrompts(root: Instance)
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("ProximityPrompt") and descendant.Name == "ChestPrompt" then
			bindChestPrompt(descendant)
		end
	end
end

function ChestController:Init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local trove = self:GetTrove()

	local existingGui = playerGui:FindFirstChild("ChestHUD")

	if existingGui ~= nil then
		existingGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ChestHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 115
	screenGui.Parent = playerGui
	trove:Add(screenGui)

	panelFrame = Instance.new("Frame")
	panelFrame.Name = "ChestPanel"
	panelFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	panelFrame.Position = UDim2.fromScale(0.5, 0.5)
	panelFrame.Size = UDim2.fromOffset(392, 560)
	panelFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	panelFrame.BackgroundTransparency = 0.1
	panelFrame.BorderSizePixel = 0
	panelFrame.Visible = false
	panelFrame.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 10)
	panelCorner.Parent = panelFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -48, 0, 24)
	title.Position = UDim2.fromOffset(8, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = Color3.fromRGB(240, 240, 240)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = Localization.get("ui.chest.title")
	title.Parent = panelFrame

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.fromOffset(28, 28)
	closeButton.Position = UDim2.new(1, -36, 0, 8)
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

	hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "Hint"
	hintLabel.Size = UDim2.new(1, -16, 0, 36)
	hintLabel.Position = UDim2.fromOffset(8, 34)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Font = Enum.Font.Gotham
	hintLabel.TextSize = 11
	hintLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	hintLabel.TextWrapped = true
	hintLabel.TextXAlignment = Enum.TextXAlignment.Left
	hintLabel.TextYAlignment = Enum.TextYAlignment.Top
	hintLabel.Text = Localization.get("ui.chest.hint")
	hintLabel.Parent = panelFrame

	local bagTitle = Instance.new("TextLabel")
	bagTitle.Name = "BagTitle"
	bagTitle.Size = UDim2.new(1, -16, 0, 18)
	bagTitle.Position = UDim2.fromOffset(8, 72)
	bagTitle.BackgroundTransparency = 1
	bagTitle.Font = Enum.Font.GothamBold
	bagTitle.TextSize = 12
	bagTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
	bagTitle.TextXAlignment = Enum.TextXAlignment.Left
	bagTitle.Text = Localization.get("ui.chest.bag_title")
	bagTitle.Parent = panelFrame

	local bagGrid = Instance.new("Frame")
	bagGrid.Name = "BagGrid"
	bagGrid.Position = UDim2.fromOffset(12, 92)
	bagGrid.Size = UDim2.fromOffset(368, 116)
	bagGrid.BackgroundTransparency = 1
	bagGrid.Parent = panelFrame

	local bagLayout = Instance.new("UIGridLayout")
	bagLayout.CellSize = UDim2.fromOffset(44, 44)
	bagLayout.CellPadding = UDim2.fromOffset(4, 4)
	bagLayout.FillDirectionMaxCells = 8
	bagLayout.Parent = bagGrid

	for index = 1, InventoryConstants.BAG_SLOT_COUNT do
		local slotKey = InventoryConstants.getBagSlotKey(index)
		local slot = InventorySlotModule.create(bagGrid, {
			slotKey = slotKey,
			layoutOrder = index,
			onActivated = onBagSlotActivated,
		})
		bagSlots[index] = slot
	end

	local chestTitle = Instance.new("TextLabel")
	chestTitle.Name = "ChestTitle"
	chestTitle.Size = UDim2.new(1, -16, 0, 18)
	chestTitle.Position = UDim2.fromOffset(8, 216)
	chestTitle.BackgroundTransparency = 1
	chestTitle.Font = Enum.Font.GothamBold
	chestTitle.TextSize = 12
	chestTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
	chestTitle.TextXAlignment = Enum.TextXAlignment.Left
	chestTitle.Text = Localization.get("ui.chest.storage_title")
	chestTitle.Parent = panelFrame

	local chestGrid = Instance.new("Frame")
	chestGrid.Name = "ChestGrid"
	chestGrid.Position = UDim2.fromOffset(12, 236)
	chestGrid.Size = UDim2.fromOffset(368, 244)
	chestGrid.BackgroundTransparency = 1
	chestGrid.Parent = panelFrame

	local chestLayout = Instance.new("UIGridLayout")
	chestLayout.CellSize = UDim2.fromOffset(44, 44)
	chestLayout.CellPadding = UDim2.fromOffset(4, 4)
	chestLayout.FillDirectionMaxCells = 6
	chestLayout.Parent = chestGrid

	for index = 1, CampConstants.CHEST_SLOT_COUNT do
		local slotKey = CampConstants.getChestSlotKey(index)
		local slot = InventorySlotModule.create(chestGrid, {
			slotKey = slotKey,
			layoutOrder = index,
			onActivated = onChestSlotActivated,
		})
		chestSlots[index] = slot
	end

	local depositButton = Instance.new("TextButton")
	depositButton.Size = UDim2.fromOffset(176, 36)
	depositButton.Position = UDim2.fromOffset(12, 492)
	depositButton.BackgroundColor3 = Color3.fromRGB(58, 120, 72)
	depositButton.BorderSizePixel = 0
	depositButton.Font = Enum.Font.GothamBold
	depositButton.TextSize = 13
	depositButton.TextColor3 = Color3.fromRGB(240, 240, 240)
	depositButton.Text = Localization.get("ui.chest.deposit")
	depositButton.Parent = panelFrame

	local withdrawButton = Instance.new("TextButton")
	withdrawButton.Size = UDim2.fromOffset(176, 36)
	withdrawButton.Position = UDim2.fromOffset(204, 492)
	withdrawButton.BackgroundColor3 = Color3.fromRGB(58, 96, 120)
	withdrawButton.BorderSizePixel = 0
	withdrawButton.Font = Enum.Font.GothamBold
	withdrawButton.TextSize = 13
	withdrawButton.TextColor3 = Color3.fromRGB(240, 240, 240)
	withdrawButton.Text = Localization.get("ui.chest.withdraw")
	withdrawButton.Parent = panelFrame

	toastLabel = Instance.new("TextLabel")
	toastLabel.AnchorPoint = Vector2.new(0.5, 1)
	toastLabel.Position = UDim2.new(0.5, 0, 1, -8)
	toastLabel.Size = UDim2.new(1, -16, 0, 28)
	toastLabel.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
	toastLabel.BackgroundTransparency = 0.1
	toastLabel.BorderSizePixel = 0
	toastLabel.Font = Enum.Font.Gotham
	toastLabel.TextSize = 12
	toastLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	toastLabel.TextWrapped = true
	toastLabel.Visible = false
	toastLabel.Parent = panelFrame

	depositButton.Activated:Connect(requestDeposit)
	withdrawButton.Activated:Connect(requestWithdraw)

	ContextActionService:BindAction(
		"ToggleChest",
		function(_actionName, inputState)
			if inputState ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Pass
			end

			if UserInputService:GetFocusedTextBox() ~= nil then
				return Enum.ContextActionResult.Pass
			end

			if findNearestChestStructureId() == nil and (panelFrame == nil or not panelFrame.Visible) then
				return Enum.ContextActionResult.Pass
			end

			tryToggleNearbyChest()
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.KeyCode.E
	)

	trove:Add(function()
		ContextActionService:UnbindAction("ToggleChest")
	end)

	trove:Connect(Networking.getEvent("CampUpdatedEvent").OnClientEvent, function(snapshot: CampTypes.CampSnapshot)
		if activeChestStructureId ~= nil then
			onCampSnapshot(snapshot)
		end
	end)

	trove:Connect(Networking.getEvent("InventoryUpdatedEvent").OnClientEvent, function(snapshot: PlayerProfileTypes.InventorySnapshot)
		if activeChestStructureId ~= nil then
			onInventorySnapshot(snapshot)
		end
	end)

	trove:Connect(Localization.LocaleChanged, function()
		title.Text = Localization.get("ui.chest.title")
		hintLabel.Text = Localization.get("ui.chest.hint")
		bagTitle.Text = Localization.get("ui.chest.bag_title")
		chestTitle.Text = Localization.get("ui.chest.storage_title")
		depositButton.Text = Localization.get("ui.chest.deposit")
		withdrawButton.Text = Localization.get("ui.chest.withdraw")

		for _, descendant in workspace:GetDescendants() do
			if descendant:IsA("ProximityPrompt") and descendant.Name == "ChestPrompt" then
				descendant.ActionText = Localization.get("ui.chest.open")
				descendant.ObjectText = Localization.get("ui.chest.title")
			end
		end

		if activeChestStructureId ~= nil then
			renderPanel()
		end
	end)
end

function ChestController:Start()
	local trove = self:GetTrove()

	scanChestPrompts(workspace)

	trove:Connect(workspace.DescendantAdded, function(descendant)
		if descendant:IsA("ProximityPrompt") and descendant.Name == "ChestPrompt" then
			bindChestPrompt(descendant)
		end
	end)

	trove:Connect(RunService.Heartbeat, function()
		if panelFrame == nil or not panelFrame.Visible or activeChestStructureId == nil then
			return
		end

		local nearestChestId = findNearestChestStructureId()

		if nearestChestId ~= activeChestStructureId then
			setPanelVisible(false)
		end
	end)
end

function ChestController.SetSelectedBagSlot(bagSlotKey: string?)
	selectedBagSlotKey = bagSlotKey
	selectedChestSlotKey = nil
	refreshSelectionHighlights()
end

return ChestController
