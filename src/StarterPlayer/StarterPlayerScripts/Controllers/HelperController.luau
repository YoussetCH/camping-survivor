--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local BaseController = require(script.Parent.Parent.Kernel.BaseController)
local ClientKernel = require(script.Parent.Parent.Kernel.ClientKernel)
local HelperPanelModule = require(ReplicatedStorage.Shared.UI.Components.HelperPanel)
local HelperPlotAnimation = require(ReplicatedStorage.Shared.World.HelperPlotAnimation)
local InventoryConstants = require(ReplicatedStorage.Shared.Constants.InventoryConstants)
local Items = require(ReplicatedStorage.Shared.Constants.Items)
local Localization = require(ReplicatedStorage.Shared.Localization.Localization)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local HelperTypes = require(ReplicatedStorage.Shared.Types.Helper)

local HelperController = BaseController.new("HelperController")

local screenGui: ScreenGui? = nil
local panel: HelperPanelModule.HelperPanel? = nil
local toastLabel: TextLabel? = nil

local latestSnapshot: HelperTypes.HelperSnapshot? = nil
local panelVisible = false
local toastToken = 0
local lastRemovedInstanceId: string? = nil

local function showToast(text: string)
	if toastLabel == nil then
		return
	end

	toastToken += 1
	local currentToken = toastToken
	toastLabel.Text = text
	toastLabel.Visible = true

	task.delay(2.8, function()
		if toastToken == currentToken and toastLabel ~= nil then
			toastLabel.Visible = false
		end
	end)
end

local function findFirstBagSlotMatching(matcher: (itemId: string) -> boolean): string?
	local syncController = ClientKernel.getController("ClientSyncController")

	if syncController == nil then
		return nil
	end

	local inventorySnapshot = syncController:GetInventory()

	if inventorySnapshot == nil then
		return nil
	end

	for slotIndex = 1, InventoryConstants.BAG_SLOT_COUNT do
		local slotKey = InventoryConstants.getBagSlotKey(slotIndex)
		local slotItem = inventorySnapshot.inventory[slotKey]

		if slotItem ~= nil and matcher(slotItem.itemId) then
			return slotKey
		end
	end

	return nil
end

local function findFoodSlotKey(): string?
	return findFirstBagSlotMatching(function(itemId: string)
		local definition = Items.get(itemId)

		return definition ~= nil and definition.category == "food"
	end)
end

local function findMedicineSlotKey(): string?
	return findFirstBagSlotMatching(function(itemId: string)
		return itemId == "bandage" or itemId == "antidote"
	end)
end

local function refreshUi()
	if latestSnapshot == nil or panel == nil then
		return
	end

	panel:refresh(latestSnapshot)
	panel:setVisible(panelVisible)
end

local function applySnapshot(snapshot: HelperTypes.HelperSnapshot)
	if snapshot.lastRemovedInstanceId ~= nil and snapshot.lastRemovedInstanceId ~= lastRemovedInstanceId then
		showToast(Localization.get("helper.death_toast"))
		lastRemovedInstanceId = snapshot.lastRemovedInstanceId
	end

	latestSnapshot = snapshot
	refreshUi()
end

local function ensureUi()
	if screenGui ~= nil then
		return
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HelperUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	panel = HelperPanelModule.create(screenGui, {
		onFeed = function(helperInstanceId: string, _bagSlotKey: string)
			local slotKey = findFoodSlotKey()

			if slotKey == nil then
				showToast(Localization.get("helper.feed.missing_food"))
				return
			end

			Networking.getEvent("FeedHelperEvent"):FireServer({
				helperInstanceId = helperInstanceId,
				bagSlotKey = slotKey,
			})
		end,
		onCure = function(helperInstanceId: string, _bagSlotKey: string)
			local slotKey = findMedicineSlotKey()

			if slotKey == nil then
				showToast(Localization.get("helper.cure.missing_medicine"))
				return
			end

			Networking.getEvent("CureHelperEvent"):FireServer({
				helperInstanceId = helperInstanceId,
				bagSlotKey = slotKey,
			})
		end,
		onSetMode = function(helperInstanceId: string, mode: HelperTypes.HelperMode)
			Networking.getEvent("SetHelperModeEvent"):FireServer({
				helperInstanceId = helperInstanceId,
				mode = mode,
			})
		end,
	})

	toastLabel = Instance.new("TextLabel")
	toastLabel.Name = "HelperToast"
	toastLabel.AnchorPoint = Vector2.new(0.5, 1)
	toastLabel.Position = UDim2.new(0.5, 0, 1, -160)
	toastLabel.Size = UDim2.new(0, 360, 0, 36)
	toastLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	toastLabel.BackgroundTransparency = 0.1
	toastLabel.BorderSizePixel = 0
	toastLabel.Font = Enum.Font.GothamBold
	toastLabel.TextSize = 14
	toastLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
	toastLabel.Visible = false
	toastLabel.Parent = screenGui

	local toastCorner = Instance.new("UICorner")
	toastCorner.CornerRadius = UDim.new(0, 8)
	toastCorner.Parent = toastLabel
end

function HelperController:Init()
	local trove = self:GetTrove()

	ensureUi()

	trove:Connect(Networking.getEvent("HelperUpdatedEvent").OnClientEvent, function(snapshot: HelperTypes.HelperSnapshot)
		if type(snapshot.helpers) ~= "table" then
			snapshot.helpers = {}
		end

		if type(snapshot.lostHelpers) ~= "table" then
			snapshot.lostHelpers = {}
		end

		applySnapshot(snapshot)
	end)

	trove:Connect(Localization.LocaleChanged, function()
		refreshUi()
	end)

	trove:Connect(UserInputService.InputBegan, function(input, processed)
		if processed or input.KeyCode ~= Enum.KeyCode.H then
			return
		end

		panelVisible = not panelVisible
		refreshUi()
	end)
end

function HelperController:Start()
	local trove = self:GetTrove()

	trove:Connect(RunService.Heartbeat, function(deltaTime: number)
		for _, descendant in workspace:GetDescendants() do
			if not descendant:IsA("Model") or descendant:GetAttribute("PlotHelper") ~= true then
				continue
			end

			if descendant:GetAttribute("HelperPatrolMoving") == true then
				HelperPlotAnimation.clear(descendant)
			elseif HelperPlotAnimation.isCapable(descendant) then
				HelperPlotAnimation.update(descendant, deltaTime)
			end
		end
	end)
end

return HelperController
