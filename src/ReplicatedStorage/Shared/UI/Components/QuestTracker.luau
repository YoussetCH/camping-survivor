--!strict

local Localization = require(script.Parent.Parent.Parent.Localization.Localization)
local Quests = require(script.Parent.Parent.Parent.Constants.Quests)
local QuestTypes = require(script.Parent.Parent.Parent.Types.Quest)

export type QuestTracker = {
	root: Frame,
	updateWithState: (
		self: QuestTracker,
		questId: string?,
		questState: QuestTypes.QuestState?,
		level: number,
		xp: number
	) -> (),
	setCollapsed: (self: QuestTracker, collapsed: boolean) -> (),
	destroy: (self: QuestTracker) -> (),
}

local QuestTrackerModule = {}

local function createCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function formatObjectiveText(questId: string, objectiveIndex: number, current: number, target: number): string
	local definition = Quests.get(questId)
	local key = if definition ~= nil then definition.objectiveKeys[objectiveIndex] else nil

	if key == nil then
		return `{current}/{target}`
	end

	return Localization.format(key, {
		current = current,
		target = target,
	})
end

function QuestTrackerModule.create(parent: Instance): QuestTracker
	local root = Instance.new("Frame")
	root.Name = "QuestTracker"
	root.AnchorPoint = Vector2.new(1, 0)
	root.Position = UDim2.new(1, -12, 0, 120)
	root.Size = UDim2.new(0, 260, 0, 88)
	root.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	root.BackgroundTransparency = 0.1
	root.BorderSizePixel = 0
	root.Parent = parent
	createCorner(root, 8)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = root

	local collapseButton = Instance.new("TextButton")
	collapseButton.Name = "CollapseButton"
	collapseButton.Size = UDim2.new(0, 72, 0, 22)
	collapseButton.Position = UDim2.new(1, -72, 0, 0)
	collapseButton.BackgroundTransparency = 1
	collapseButton.Font = Enum.Font.GothamBold
	collapseButton.TextSize = 11
	collapseButton.TextColor3 = Color3.fromRGB(180, 180, 190)
	collapseButton.Text = Localization.get("quest.tracker.collapse")
	collapseButton.Parent = root

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -76, 0, 20)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextColor3 = Color3.fromRGB(250, 220, 120)
	titleLabel.Parent = root

	local objectiveLabel = Instance.new("TextLabel")
	objectiveLabel.Name = "Objective"
	objectiveLabel.Size = UDim2.new(1, 0, 0, 36)
	objectiveLabel.Position = UDim2.new(0, 0, 0, 24)
	objectiveLabel.BackgroundTransparency = 1
	objectiveLabel.Font = Enum.Font.Gotham
	objectiveLabel.TextSize = 12
	objectiveLabel.TextXAlignment = Enum.TextXAlignment.Left
	objectiveLabel.TextYAlignment = Enum.TextYAlignment.Top
	objectiveLabel.TextWrapped = true
	objectiveLabel.TextColor3 = Color3.fromRGB(230, 230, 235)
	objectiveLabel.Parent = root

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "Level"
	levelLabel.Size = UDim2.new(1, 0, 0, 16)
	levelLabel.Position = UDim2.new(0, 0, 1, -16)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.TextSize = 11
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
	levelLabel.Parent = root

	local expanded = true

	local function setCollapsed(collapsed: boolean)
		expanded = not collapsed
		objectiveLabel.Visible = expanded
		levelLabel.Visible = expanded
		root.Size = if expanded then UDim2.new(0, 260, 0, 88) else UDim2.new(0, 110, 0, 30)
	end

	collapseButton.MouseButton1Click:Connect(function()
		setCollapsed(expanded)
	end)

	local tracker: QuestTracker = {
		root = root,
		updateWithState = function(_self, questId, questState, level, xp)
			if questId == nil then
				root.Visible = false
				return
			end

			local definition = Quests.get(questId)

			if definition == nil then
				root.Visible = false
				return
			end

			root.Visible = true
			titleLabel.Text = Localization.get(definition.titleKey)
			levelLabel.Text = `Lv {level} · {xp} XP`

			local objectiveText = ""

			for index, objectiveDef in definition.objectives do
				local current = 0
				local target = objectiveDef.target

				if questState ~= nil then
					local progress = questState.objectives[index]

					if progress ~= nil then
						current = progress.current
						target = progress.target
					end
				end

				local line = formatObjectiveText(questId, index, current, target)

				if objectiveText ~= "" then
					objectiveText ..= "\n"
				end

				objectiveText ..= line
			end

			objectiveLabel.Text = objectiveText
		end,
		setCollapsed = function(_self, collapsed)
			setCollapsed(collapsed)
		end,
		destroy = function(_self)
			root:Destroy()
		end,
	}

	return tracker
end

return QuestTrackerModule
