--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

export type ItemTooltipModule = {
	bind: (target: GuiObject, getText: () -> string?) -> () -> (),
	hide: () -> (),
}

local HOVER_DELAY_SECONDS = 0.3
local TOOLTIP_DISPLAY_ORDER = 200

local ItemTooltip = {}

local tooltipGui: ScreenGui? = nil
local tooltipFrame: Frame? = nil
local tooltipLabel: TextLabel? = nil
local showThread: thread? = nil

local function isAltHeld(): boolean
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)
end

local function ensureTooltipGui()
	if tooltipGui ~= nil then
		return
	end

	if not RunService:IsClient() then
		return
	end

	local player = Players.LocalPlayer
	local playerGui = player:FindFirstChildOfClass("PlayerGui")

	if playerGui == nil then
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "ItemTooltipGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = TOOLTIP_DISPLAY_ORDER
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	tooltipGui = gui

	local frame = Instance.new("Frame")
	frame.Name = "Tooltip"
	frame.AutomaticSize = Enum.AutomaticSize.XY
	frame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 74, 88)
	stroke.Thickness = 1
	stroke.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextColor3 = Color3.fromRGB(240, 240, 240)
	label.TextWrapped = true
	label.Text = ""
	label.Parent = frame

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(220, 80)
	sizeConstraint.Parent = label

	tooltipFrame = frame
	tooltipLabel = label
end

function ItemTooltip.hide()
	if showThread ~= nil then
		task.cancel(showThread)
		showThread = nil
	end

	if tooltipFrame ~= nil then
		tooltipFrame.Visible = false
	end
end

local function showAt(text: string, screenPosition: Vector2)
	ensureTooltipGui()

	if tooltipFrame == nil or tooltipLabel == nil then
		return
	end

	tooltipLabel.Text = text
	tooltipFrame.Visible = true

	local frameSize = tooltipFrame.AbsoluteSize
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local x = screenPosition.X + 16
	local y = screenPosition.Y + 20

	if x + frameSize.X > viewport.X - 8 then
		x = screenPosition.X - frameSize.X - 12
	end

	if y + frameSize.Y > viewport.Y - 8 then
		y = screenPosition.Y - frameSize.Y - 12
	end

	tooltipFrame.Position = UDim2.fromOffset(x, y)
end

function ItemTooltip.bind(target: GuiObject, getText: () -> string?): () -> ()
	if not RunService:IsClient() then
		return function() end
	end

	ensureTooltipGui()

	local hovering = false
	local connections: { RBXScriptConnection } = {}

	local function cancelShowTimer()
		if showThread ~= nil then
			task.cancel(showThread)
			showThread = nil
		end
	end

	local function tryShow()
		cancelShowTimer()

		local text = getText()

		if not hovering or text == nil or text == "" then
			ItemTooltip.hide()
			return
		end

		local mouseLocation = UserInputService:GetMouseLocation()
		showAt(text, mouseLocation)
	end

	local function scheduleShow()
		cancelShowTimer()

		if isAltHeld() then
			tryShow()
			return
		end

		showThread = task.delay(HOVER_DELAY_SECONDS, tryShow)
	end

	local function onEnter()
		hovering = true
		scheduleShow()
	end

	local function onLeave()
		hovering = false
		cancelShowTimer()
		ItemTooltip.hide()
	end

	table.insert(connections, target.MouseEnter:Connect(onEnter))
	table.insert(connections, target.MouseLeave:Connect(onLeave))

	table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end

		if input.KeyCode ~= Enum.KeyCode.LeftAlt and input.KeyCode ~= Enum.KeyCode.RightAlt then
			return
		end

		if hovering then
			tryShow()
		end
	end))

	table.insert(connections, UserInputService.InputEnded:Connect(function(input, _processed)
		if input.KeyCode ~= Enum.KeyCode.LeftAlt and input.KeyCode ~= Enum.KeyCode.RightAlt then
			return
		end

		if hovering and not isAltHeld() then
			cancelShowTimer()
			ItemTooltip.hide()
		end
	end))

	return function()
		for _, connection in connections do
			connection:Disconnect()
		end

		if hovering then
			ItemTooltip.hide()
		end
	end
end

return ItemTooltip
