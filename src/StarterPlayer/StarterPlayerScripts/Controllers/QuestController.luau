--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BaseController = require(script.Parent.Parent.Kernel.BaseController)
local ClientKernel = require(script.Parent.Parent.Kernel.ClientKernel)
local Localization = require(ReplicatedStorage.Shared.Localization.Localization)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local Quests = require(ReplicatedStorage.Shared.Constants.Quests)
local QuestJournalModule = require(ReplicatedStorage.Shared.UI.Components.QuestJournal)
local QuestTrackerModule = require(ReplicatedStorage.Shared.UI.Components.QuestTracker)
local TutorialOverlayModule = require(ReplicatedStorage.Shared.UI.Components.TutorialOverlay)
local QuestTypes = require(ReplicatedStorage.Shared.Types.Quest)

local QuestController = BaseController.new("QuestController")

local screenGui: ScreenGui? = nil
local tracker: QuestTrackerModule.QuestTracker? = nil
local journal: QuestJournalModule.QuestJournal? = nil
local tutorialOverlay: TutorialOverlayModule.TutorialOverlay? = nil
local toastLabel: TextLabel? = nil

local latestSnapshot: QuestTypes.QuestSnapshot? = nil
local journalVisible = false
local lastLevel = 1
local toastToken = 0

local function getTrackedQuestId(snapshot: QuestTypes.QuestSnapshot): string?
	if snapshot.trackedQuestId ~= nil then
		return snapshot.trackedQuestId
	end

	for _, questId in snapshot.activeQuestIds do
		local definition = Quests.get(questId)

		if definition ~= nil and definition.questType == "main" then
			return questId
		end
	end

	return snapshot.activeQuestIds[1]
end

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

local function refreshUi()
	if latestSnapshot == nil or tracker == nil or journal == nil or tutorialOverlay == nil then
		return
	end

	local trackedQuestId = getTrackedQuestId(latestSnapshot)
	local questState = if trackedQuestId ~= nil then latestSnapshot.progress[trackedQuestId] else nil

	tracker:updateWithState(
		trackedQuestId,
		questState,
		latestSnapshot.stats.level,
		latestSnapshot.stats.xp
	)

	journal:refresh(latestSnapshot)

	if not latestSnapshot.tutorialCompleted and trackedQuestId ~= nil then
		local definition = Quests.get(trackedQuestId)

		if definition ~= nil and definition.questType == "tutorial" then
			tutorialOverlay:setQuestId(trackedQuestId)
		else
			tutorialOverlay:setQuestId(nil)
		end
	else
		tutorialOverlay:setQuestId(nil)
	end
end

local function applySnapshot(snapshot: QuestTypes.QuestSnapshot)
	if latestSnapshot ~= nil and snapshot.stats.level > lastLevel then
		showToast(Localization.format("quest.level_up", {
			level = snapshot.stats.level,
		}))
	end

	lastLevel = snapshot.stats.level

	if snapshot.lastCompletedQuestId ~= nil then
		local definition = Quests.get(snapshot.lastCompletedQuestId)

		if definition ~= nil then
			showToast(Localization.format("quest.completed_toast", {
				title = Localization.get(definition.titleKey),
			}))
		end
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
	screenGui.Name = "QuestUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	tracker = QuestTrackerModule.create(screenGui)
	journal = QuestJournalModule.create(screenGui, {
		onTrackQuest = function(questId: string)
			Networking.getEvent("QuestTrackEvent"):FireServer(questId)
		end,
	})
	tutorialOverlay = TutorialOverlayModule.create(screenGui)

	toastLabel = Instance.new("TextLabel")
	toastLabel.Name = "QuestToast"
	toastLabel.AnchorPoint = Vector2.new(0.5, 1)
	toastLabel.Position = UDim2.new(0.5, 0, 1, -120)
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

function QuestController:Init()
	local trove = self:GetTrove()

	ensureUi()

	trove:Connect(Networking.getEvent("QuestProgressEvent").OnClientEvent, function(snapshot: QuestTypes.QuestSnapshot)
		applySnapshot(snapshot)
	end)

	trove:Connect(Localization.LocaleChanged, function()
		refreshUi()
	end)

	trove:Connect(UserInputService.InputBegan, function(input, processed)
		if processed or input.KeyCode ~= Enum.KeyCode.J then
			return
		end

		journalVisible = not journalVisible

		if journal ~= nil then
			journal:setVisible(journalVisible)
		end
	end)

	local syncController = ClientKernel.getController("ClientSyncController")

	if syncController ~= nil then
		local cached = syncController:GetQuest()

		if cached ~= nil then
			applySnapshot(cached)
		end
	end
end

function QuestController:Start()
	Networking.getEvent("QuestUiOpenedEvent"):FireServer("stats")
end

return QuestController
