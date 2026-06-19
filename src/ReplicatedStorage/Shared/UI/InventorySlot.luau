--!strict

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
	quantityLabel.Parent = root

	local self: InventorySlot = {} :: InventorySlot
	local bagSlotKey: string? = config.slotKey

	function self.setBagSlotKey(_self: InventorySlot, nextSlotKey: string?)
		bagSlotKey = nextSlotKey
		root.Name = if nextSlotKey ~= nil then `Slot_{nextSlotKey}` else "Slot"
	end

	function self.setItem(_self: InventorySlot, itemId: string?, quantity: number?, displayName: string?)
		if itemId == nil or quantity == nil or quantity <= 0 then
			nameLabel.Text = ""
			quantityLabel.Text = ""
			root.BackgroundColor3 = EMPTY_COLOR
			return
		end

		nameLabel.Text = displayName or itemId
		quantityLabel.Text = if quantity > 1 then tostring(quantity) else ""
	end

	function self.setSelected(_self: InventorySlot, selected: boolean)
		if selected then
			root.BackgroundColor3 = SELECTED_COLOR
			return
		end

		root.BackgroundColor3 = EMPTY_COLOR
	end

	function self.setEquipped(_self: InventorySlot, equipped: boolean)
		if equipped then
			root.BackgroundColor3 = EQUIPPED_COLOR
		elseif root.BackgroundColor3 == EQUIPPED_COLOR then
			root.BackgroundColor3 = EMPTY_COLOR
		end
	end

	function self.destroy(_self: InventorySlot)
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
