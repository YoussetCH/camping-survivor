--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ItemIcon = require(ReplicatedStorage.Shared.UI.ItemIcon)
local ItemTooltip = require(ReplicatedStorage.Shared.UI.ItemTooltip)

export type InventorySlotConfig = {
	slotKey: string?,
	layoutOrder: number?,
	onActivated: ((slotKey: string?) -> ())?,
}

export type InventorySlot = {
	root: TextButton,
	setBagSlotKey: (self: InventorySlot, slotKey: string?) -> (),
	setItem: (self: InventorySlot, itemId: string?, quantity: number?, displayName: string?) -> (),
	setSelected: (self: InventorySlot, selected: boolean) -> (),
	setEquipped: (self: InventorySlot, equipped: boolean) -> (),
	destroy: (self: InventorySlot) -> (),
}

local SELECTED_COLOR = Color3.fromRGB(90, 140, 220)
local EMPTY_COLOR = Color3.fromRGB(45, 48, 58)
local EQUIPPED_COLOR = Color3.fromRGB(70, 120, 80)

local InventorySlotModule = {}

local function createCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

function InventorySlotModule.create(parent: Instance, config: InventorySlotConfig): InventorySlot
	local root = Instance.new("TextButton")
	root.Name = if config.slotKey ~= nil then `Slot_{config.slotKey}` else "Slot"
	root.Size = UDim2.fromOffset(48, 48)
	root.BackgroundColor3 = EMPTY_COLOR
	root.BorderSizePixel = 0
	root.Text = ""
	root.AutoButtonColor = true
	root.LayoutOrder = config.layoutOrder or 0
	root.Parent = parent
	createCorner(root, 8)

	local iconImage = Instance.new("ImageLabel")
	iconImage.Name = "Icon"
	iconImage.AnchorPoint = Vector2.new(0.5, 0.5)
	iconImage.Position = UDim2.fromScale(0.5, 0.5)
	iconImage.Size = UDim2.fromOffset(36, 36)
	iconImage.BackgroundTransparency = 1
	iconImage.ScaleType = Enum.ScaleType.Fit
	iconImage.Visible = false
	iconImage.Parent = root

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, -4, 0, 14)
	nameLabel.Position = UDim2.fromOffset(2, 2)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 9
	nameLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Text = ""
	nameLabel.Visible = false
	nameLabel.Parent = root

	local quantityLabel = Instance.new("TextLabel")
	quantityLabel.Name = "Quantity"
	quantityLabel.Size = UDim2.fromOffset(20, 14)
	quantityLabel.AnchorPoint = Vector2.new(1, 1)
	quantityLabel.Position = UDim2.new(1, -2, 1, -2)
	quantityLabel.BackgroundTransparency = 1
	quantityLabel.Font = Enum.Font.GothamBold
	quantityLabel.TextSize = 11
	quantityLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
	quantityLabel.TextXAlignment = Enum.TextXAlignment.Right
	quantityLabel.Text = ""
	quantityLabel.ZIndex = 2
	quantityLabel.Parent = root

	local self: InventorySlot = {} :: InventorySlot
	local bagSlotKey: string? = config.slotKey
	local isEquipped = false
	local isSelected = false
	local tooltipText: string? = nil
	local unbindTooltip: (() -> ())? = nil

	if RunService:IsClient() then
		unbindTooltip = ItemTooltip.bind(root, function()
			return tooltipText
		end)
	end

	local function refreshBackground()
		if isEquipped then
			root.BackgroundColor3 = EQUIPPED_COLOR
		elseif isSelected then
			root.BackgroundColor3 = SELECTED_COLOR
		else
			root.BackgroundColor3 = EMPTY_COLOR
		end
	end

	function self.setBagSlotKey(_self: InventorySlot, nextSlotKey: string?)
		bagSlotKey = nextSlotKey
		root.Name = if nextSlotKey ~= nil then `Slot_{nextSlotKey}` else "Slot"
	end

	function self.setItem(_self: InventorySlot, itemId: string?, quantity: number?, displayName: string?)
		if itemId == nil or quantity == nil or quantity <= 0 then
			nameLabel.Text = ""
			nameLabel.Visible = false
			quantityLabel.Text = ""
			tooltipText = nil
			ItemIcon.applyTo(iconImage, nil)
			refreshBackground()
			return
		end

		ItemIcon.applyTo(iconImage, itemId)
		nameLabel.Text = displayName or itemId
		nameLabel.Visible = not iconImage.Visible
		quantityLabel.Text = if quantity > 1 then tostring(quantity) else ""
		tooltipText = displayName or itemId
	end

	function self.setSelected(_self: InventorySlot, selected: boolean)
		isSelected = selected
		refreshBackground()
	end

	function self.setEquipped(_self: InventorySlot, equipped: boolean)
		isEquipped = equipped
		refreshBackground()
	end

	function self.destroy(_self: InventorySlot)
		if unbindTooltip ~= nil then
			unbindTooltip()
			unbindTooltip = nil
		end

		root:Destroy()
	end

	root.Activated:Connect(function()
		if config.onActivated ~= nil then
			config.onActivated(bagSlotKey)
		end
	end)

	return self
end

return InventorySlotModule
