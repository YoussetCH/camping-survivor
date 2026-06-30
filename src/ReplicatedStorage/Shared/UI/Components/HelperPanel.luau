--!strict

local Localization = require(script.Parent.Parent.Parent.Localization.Localization)
local StatBarModule = require(script.Parent.Parent.StatBar)
local HelperTypes = require(script.Parent.Parent.Parent.Types.Helper)

export type HelperPanelCallbacks = {
	onFeed: (helperInstanceId: string, bagSlotKey: string) -> (),
	onCure: (helperInstanceId: string, bagSlotKey: string) -> (),
	onSetMode: (helperInstanceId: string, mode: HelperTypes.HelperMode) -> (),
}

export type HelperPanel = {
	root: Frame,
	setVisible: (self: HelperPanel, visible: boolean) -> (),
	refresh: (self: HelperPanel, snapshot: HelperTypes.HelperSnapshot) -> (),
	destroy: (self: HelperPanel) -> (),
}

local HelperPanelModule = {}

local function createCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function createActionButton(parent: Instance, labelKey: string, layoutOrder: number): TextButton
	local button = Instance.new("TextButton")
	button.Name = labelKey
	button.Size = UDim2.new(0, 72, 0, 24)
	button.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 11
	button.TextColor3 = Color3.fromRGB(235, 235, 240)
	button.Text = Localization.get(labelKey)
	button.LayoutOrder = layoutOrder
	button.AutoButtonColor = true
	button.Parent = parent
	createCorner(button, 4)

	return button
end

function HelperPanelModule.create(parent: Instance, callbacks: HelperPanelCallbacks): HelperPanel
	local root = Instance.new("Frame")
	root.Name = "HelperPanel"
	root.AnchorPoint = Vector2.new(1, 0)
	root.Position = UDim2.new(1, -12, 0, 220)
	root.Size = UDim2.new(0, 260, 0, 160)
	root.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	root.BackgroundTransparency = 0.1
	root.BorderSizePixel = 0
	root.Visible = false
	root.Parent = parent
	createCorner(root, 8)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = root

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 20)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextColor3 = Color3.fromRGB(240, 240, 245)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = Localization.get("helper.panel.title")
	title.Parent = root

	local list = Instance.new("ScrollingFrame")
	list.Name = "HelperList"
	list.Position = UDim2.new(0, 0, 0, 24)
	list.Size = UDim2.new(1, 0, 1, -24)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 4
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = root

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list

	local self: HelperPanel = {} :: HelperPanel
	self.root = root

	function self.setVisible(_self: HelperPanel, visible: boolean)
		root.Visible = visible
	end

	function self.refresh(_self: HelperPanel, snapshot: HelperTypes.HelperSnapshot)
		for _, child in list:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		local rowIndex = 0

		for instanceId, helperState in snapshot.helpers do
			rowIndex += 1

			local row = Instance.new("Frame")
			row.Name = instanceId
			row.Size = UDim2.new(1, -4, 0, 108)
			row.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
			row.BorderSizePixel = 0
			row.LayoutOrder = rowIndex
			row.Parent = list
			createCorner(row, 6)

			local rowPadding = Instance.new("UIPadding")
			rowPadding.PaddingLeft = UDim.new(0, 8)
			rowPadding.PaddingRight = UDim.new(0, 8)
			rowPadding.PaddingTop = UDim.new(0, 6)
			rowPadding.PaddingBottom = UDim.new(0, 6)
			rowPadding.Parent = row

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "Name"
			nameLabel.Size = UDim2.new(1, 0, 0, 16)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 12
			nameLabel.TextColor3 = Color3.fromRGB(230, 230, 235)
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Text = Localization.get(helperState.nameKey)
			nameLabel.Parent = row

			local hungerBar = StatBarModule.create(row, {
				labelKey = Localization.get("helper.stat.hunger"),
				fillColor = Color3.fromRGB(210, 140, 40),
				maxValue = 100,
			})
			hungerBar.root.Position = UDim2.new(0, 0, 0, 18)
			hungerBar.root.Size = UDim2.new(1, 0, 0, 24)
			hungerBar:setValue(helperState.hunger)

			if helperState.hunger <= 20 then
				hungerBar:setAlertLevel("warning")
				hungerBar:setAlertMessage(Localization.get("helper.hunger_warning"))
			end

			local healthBar = StatBarModule.create(row, {
				labelKey = Localization.get("helper.stat.health"),
				fillColor = Color3.fromRGB(70, 180, 90),
				maxValue = 100,
			})
			healthBar.root.Position = UDim2.new(0, 0, 0, 46)
			healthBar.root.Size = UDim2.new(1, 0, 0, 24)
			healthBar:setValue(helperState.health)

			local actions = Instance.new("Frame")
			actions.Name = "Actions"
			actions.Position = UDim2.new(0, 0, 0, 76)
			actions.Size = UDim2.new(1, 0, 0, 24)
			actions.BackgroundTransparency = 1
			actions.Parent = row

			local actionsLayout = Instance.new("UIListLayout")
			actionsLayout.FillDirection = Enum.FillDirection.Horizontal
			actionsLayout.Padding = UDim.new(0, 6)
			actionsLayout.Parent = actions

			local feedButton = createActionButton(actions, "helper.action.feed", 1)
			local cureButton = createActionButton(actions, "helper.action.cure", 2)
			local modeButton = createActionButton(
				actions,
				if helperState.mode == "work" then "helper.mode.shelter" else "helper.mode.work",
				3
			)

			feedButton.MouseButton1Click:Connect(function()
				callbacks.onFeed(instanceId, "bag_1")
			end)

			cureButton.MouseButton1Click:Connect(function()
				callbacks.onCure(instanceId, "bag_1")
			end)

			modeButton.MouseButton1Click:Connect(function()
				local nextMode: HelperTypes.HelperMode = if helperState.mode == "work" then "shelter" else "work"
				callbacks.onSetMode(instanceId, nextMode)
			end)
		end

		if rowIndex == 0 then
			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.Name = "Empty"
			emptyLabel.Size = UDim2.new(1, 0, 0, 40)
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Font = Enum.Font.Gotham
			emptyLabel.TextSize = 12
			emptyLabel.TextColor3 = Color3.fromRGB(170, 170, 175)
			emptyLabel.Text = Localization.get("helper.panel.empty")
			emptyLabel.Parent = list
		end
	end

	function self.destroy(_self: HelperPanel)
		root:Destroy()
	end

	return self
end

return HelperPanelModule
