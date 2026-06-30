--!strict

local Localization = require(script.Parent.Parent.Parent.Localization.Localization)
local Quests = require(script.Parent.Parent.Parent.Constants.Quests)
local QuestTypes = require(script.Parent.Parent.Parent.Types.Quest)

export type QuestJournal = {
	root: Frame,
	setVisible: (self: QuestJournal, visible: boolean) -> (),
	destroy: (self: QuestJournal) -> (),
}

export type QuestJournalConfig = {
	onTrackQuest: ((questId: string) -> ())?,
}

local QuestJournalModule = {}

local function createCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

function QuestJournalModule.create(parent: Instance, config: QuestJournalConfig?): QuestJournal
	local root = Instance.new("Frame")
	root.Name = "QuestJournal"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.new(0, 420, 0, 360)
	root.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	root.BorderSizePixel = 0
	root.Visible = false
	root.Parent = parent
	createCorner(root, 10)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 32)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(245, 245, 250)
	title.Text = Localization.get("quest.journal.title")
	title.Parent = root

	local activeHeader = Instance.new("TextLabel")
	activeHeader.Size = UDim2.new(1, -20, 0, 20)
	activeHeader.Position = UDim2.new(0, 10, 0, 44)
	activeHeader.BackgroundTransparency = 1
	activeHeader.Font = Enum.Font.GothamBold
	activeHeader.TextSize = 13
	activeHeader.TextXAlignment = Enum.TextXAlignment.Left
	activeHeader.TextColor3 = Color3.fromRGB(180, 220, 255)
	activeHeader.Text = Localization.get("quest.journal.active")
	activeHeader.Parent = root

	local activeList = Instance.new("ScrollingFrame")
	activeList.Name = "ActiveList"
	activeList.Size = UDim2.new(1, -20, 0, 130)
	activeList.Position = UDim2.new(0, 10, 0, 68)
	activeList.BackgroundTransparency = 1
	activeList.BorderSizePixel = 0
	activeList.ScrollBarThickness = 4
	activeList.CanvasSize = UDim2.new()
	activeList.Parent = root

	local activeLayout = Instance.new("UIListLayout")
	activeLayout.Padding = UDim.new(0, 6)
	activeLayout.Parent = activeList

	local completedHeader = Instance.new("TextLabel")
	completedHeader.Size = UDim2.new(1, -20, 0, 20)
	completedHeader.Position = UDim2.new(0, 10, 0, 206)
	completedHeader.BackgroundTransparency = 1
	completedHeader.Font = Enum.Font.GothamBold
	completedHeader.TextSize = 13
	completedHeader.TextXAlignment = Enum.TextXAlignment.Left
	completedHeader.TextColor3 = Color3.fromRGB(170, 210, 150)
	completedHeader.Text = Localization.get("quest.journal.completed")
	completedHeader.Parent = root

	local completedList = Instance.new("ScrollingFrame")
	completedList.Name = "CompletedList"
	completedList.Size = UDim2.new(1, -20, 0, 110)
	completedList.Position = UDim2.new(0, 10, 0, 230)
	completedList.BackgroundTransparency = 1
	completedList.BorderSizePixel = 0
	completedList.ScrollBarThickness = 4
	completedList.CanvasSize = UDim2.new()
	completedList.Parent = root

	local completedLayout = Instance.new("UIListLayout")
	completedLayout.Padding = UDim.new(0, 6)
	completedLayout.Parent = completedList

	local function clearList(list: ScrollingFrame)
		for _, child in list:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
	end

	local function createRow(parentList: ScrollingFrame, questId: string, trackedQuestId: string?, showTrack: boolean)
		local definition = Quests.get(questId)

		if definition == nil then
			return
		end

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -4, 0, 34)
		row.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
		row.BorderSizePixel = 0
		row.Parent = parentList
		createCorner(row, 6)

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, if showTrack then -72 else -8, 1, 0)
		label.Position = UDim2.new(0, 8, 0, 0)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.Gotham
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = if trackedQuestId == questId
			then Color3.fromRGB(255, 230, 140)
			else Color3.fromRGB(230, 230, 235)
		label.Text = Localization.get(definition.titleKey)
		label.Parent = row

		if showTrack then
			local trackButton = Instance.new("TextButton")
			trackButton.Size = UDim2.new(0, 60, 0, 24)
			trackButton.Position = UDim2.new(1, -64, 0.5, -12)
			trackButton.BackgroundColor3 = Color3.fromRGB(55, 95, 140)
			trackButton.Font = Enum.Font.GothamBold
			trackButton.TextSize = 11
			trackButton.TextColor3 = Color3.fromRGB(240, 240, 245)
			trackButton.Text = Localization.get("quest.journal.track")
			trackButton.Parent = row
			createCorner(trackButton, 5)

			trackButton.MouseButton1Click:Connect(function()
				if config ~= nil and config.onTrackQuest ~= nil then
					config.onTrackQuest(questId)
				end
			end)
		end
	end

	local journal: QuestJournal = {
		root = root,
		setVisible = function(_self, visible)
			root.Visible = visible
		end,
		destroy = function(_self)
			root:Destroy()
		end,
	}

	function journal:refresh(snapshot: QuestTypes.QuestSnapshot)
		title.Text = Localization.get("quest.journal.title")
		activeHeader.Text = Localization.get("quest.journal.active")
		completedHeader.Text = Localization.get("quest.journal.completed")

		clearList(activeList)
		clearList(completedList)

		local activeCount = 0
		local completedCount = 0

		for questId, state in snapshot.progress do
			if state.status == "active" then
				activeCount += 1
				createRow(activeList, questId, snapshot.trackedQuestId, true)
			elseif state.status == "completed" then
				completedCount += 1
				createRow(completedList, questId, snapshot.trackedQuestId, false)
			end
		end

		if activeCount == 0 then
			local empty = Instance.new("TextLabel")
			empty.Size = UDim2.new(1, 0, 0, 24)
			empty.BackgroundTransparency = 1
			empty.Font = Enum.Font.Gotham
			empty.TextSize = 12
			empty.TextXAlignment = Enum.TextXAlignment.Left
			empty.TextColor3 = Color3.fromRGB(150, 150, 160)
			empty.Text = Localization.get("quest.journal.empty_active")
			empty.Parent = activeList
		end

		if completedCount == 0 then
			local empty = Instance.new("TextLabel")
			empty.Size = UDim2.new(1, 0, 0, 24)
			empty.BackgroundTransparency = 1
			empty.Font = Enum.Font.Gotham
			empty.TextSize = 12
			empty.TextXAlignment = Enum.TextXAlignment.Left
			empty.TextColor3 = Color3.fromRGB(150, 150, 160)
			empty.Text = Localization.get("quest.journal.empty_completed")
			empty.Parent = completedList
		end

		activeList.CanvasSize = UDim2.new(0, 0, 0, activeLayout.AbsoluteContentSize.Y)
		completedList.CanvasSize = UDim2.new(0, 0, 0, completedLayout.AbsoluteContentSize.Y)
	end

	return journal :: any
end

return QuestJournalModule
