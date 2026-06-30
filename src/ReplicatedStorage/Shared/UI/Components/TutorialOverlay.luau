--!strict

local Localization = require(script.Parent.Parent.Parent.Localization.Localization)

export type TutorialOverlay = {
	root: Frame,
	setQuestId: (self: TutorialOverlay, questId: string?) -> (),
	destroy: (self: TutorialOverlay) -> (),
}

local HINT_KEYS: { [string]: string } = {
	t02_gather = "quest.tutorial.hint.t02_gather",
	t03_sparks = "quest.tutorial.hint.t03_sparks",
	t05_campfire = "quest.tutorial.hint.t05_campfire",
	t06_cold = "quest.tutorial.hint.t06_cold",
	t08_complete = "quest.tutorial.hint.t08_complete",
}

local TutorialOverlayModule = {}

local function createCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

function TutorialOverlayModule.create(parent: Instance): TutorialOverlay
	local root = Instance.new("Frame")
	root.Name = "TutorialOverlay"
	root.AnchorPoint = Vector2.new(0.5, 0)
	root.Position = UDim2.new(0.5, 0, 0, 12)
	root.Size = UDim2.new(0, 520, 0, 48)
	root.BackgroundColor3 = Color3.fromRGB(35, 55, 90)
	root.BackgroundTransparency = 0.05
	root.BorderSizePixel = 0
	root.Visible = false
	root.Parent = parent
	createCorner(root, 8)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextWrapped = true
	label.TextColor3 = Color3.fromRGB(235, 240, 255)
	label.Parent = root

	return {
		root = root,
		setQuestId = function(_self, questId)
			local hintKey = if questId ~= nil then HINT_KEYS[questId] else nil

			if hintKey == nil then
				root.Visible = false
				label.Text = ""
				return
			end

			root.Visible = true
			label.Text = Localization.get(hintKey)
		end,
		destroy = function(_self)
			root:Destroy()
		end,
	}
end

return TutorialOverlayModule
