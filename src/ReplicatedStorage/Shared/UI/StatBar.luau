--!strict

export type AlertLevel = "normal" | "warning" | "danger"

export type StatBarConfig = {
	labelKey: string,
	fillColor: Color3,
	maxValue: number,
}

export type StatBar = {
	root: Frame,
	setValue: (self: StatBar, value: number) -> (),
	setLabel: (self: StatBar, text: string) -> (),
	setAlertLevel: (self: StatBar, level: AlertLevel) -> (),
	setAlertMessage: (self: StatBar, message: string?) -> (),
	destroy: (self: StatBar) -> (),
}

local ALERT_COLORS = {
	normal = Color3.fromRGB(40, 40, 40),
	warning = Color3.fromRGB(220, 180, 40),
	danger = Color3.fromRGB(220, 50, 50),
}

local StatBarModule = {}

local function createCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

function StatBarModule.create(parent: Instance, config: StatBarConfig): StatBar
	local root = Instance.new("Frame")
	root.Name = `{config.labelKey}Bar`
	root.Size = UDim2.new(1, 0, 0, 28)
	root.BackgroundColor3 = ALERT_COLORS.normal
	root.BorderSizePixel = 0
	root.Parent = parent
	createCorner(root, 6)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingRight = UDim.new(0, 4)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = root

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0, 52, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextColor3 = Color3.fromRGB(240, 240, 240)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = config.labelKey
	label.Parent = root

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(1, -56, 1, 0)
	track.Position = UDim2.new(0, 56, 0, 0)
	track.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	track.BorderSizePixel = 0
	track.Parent = root
	createCorner(track, 4)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = config.fillColor
	fill.BorderSizePixel = 0
	fill.Parent = track
	createCorner(fill, 4)

	local alertLabel = Instance.new("TextLabel")
	alertLabel.Name = "Alert"
	alertLabel.Size = UDim2.new(1, 0, 1, 0)
	alertLabel.BackgroundTransparency = 1
	alertLabel.Font = Enum.Font.GothamBold
	alertLabel.TextSize = 11
	alertLabel.TextColor3 = Color3.fromRGB(255, 220, 220)
	alertLabel.Text = ""
	alertLabel.Visible = false
	alertLabel.Parent = track

	local self: StatBar = {} :: StatBar
	self.root = root

	function self.setValue(_self: StatBar, value: number)
		local clamped = math.clamp(value, 0, config.maxValue)
		local ratio = clamped / config.maxValue
		fill.Size = UDim2.new(ratio, 0, 1, 0)
	end

	function self.setLabel(_self: StatBar, text: string)
		label.Text = text
	end

	function self.setAlertLevel(_self: StatBar, level: AlertLevel)
		root.BackgroundColor3 = ALERT_COLORS[level]
	end

	function self.setAlertMessage(_self: StatBar, message: string?)
		if message == nil or message == "" then
			alertLabel.Visible = false
			alertLabel.Text = ""
			return
		end

		alertLabel.Visible = true
		alertLabel.Text = message
	end

	function self.destroy(_self: StatBar)
		root:Destroy()
	end

	self:setValue(config.maxValue)

	return self
end

return StatBarModule
