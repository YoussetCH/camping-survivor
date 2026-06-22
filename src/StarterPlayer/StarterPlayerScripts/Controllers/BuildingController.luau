--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local BaseController = require(script.Parent.Parent.Kernel.BaseController)
local ClientKernel = require(script.Parent.Parent.Kernel.ClientKernel)
local CampConstants = require(ReplicatedStorage.Shared.Constants.CampConstants)
local Items = require(ReplicatedStorage.Shared.Constants.Items)
local Localization = require(ReplicatedStorage.Shared.Localization.Localization)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local StructuresConstants = require(ReplicatedStorage.Shared.Constants.StructuresConstants)
local StructureModelFactory = require(ReplicatedStorage.Shared.Structures.StructureModelFactory)
local CampTypes = require(ReplicatedStorage.Shared.Types.Camp)
local CampProximity = require(ReplicatedStorage.Shared.Utilities.CampProximity)

local BuildingController = BaseController.new("BuildingController")

local panelFrame: Frame? = nil
local toastLabel: TextLabel? = nil
local titleLabel: TextLabel? = nil
local placeButton: TextButton? = nil
local moveButton: TextButton? = nil
local demolishButton: TextButton? = nil
local rotateHint: TextLabel? = nil
local blueprintButtons: { TextButton } = {}

local buildModeActive = false
local moveModeActive = false
local demolishModeActive = false
local selectedBlueprintId: string? = nil
local movingStructureId: string? = nil
local currentRotation = 0
local ghostModel: Model? = nil
local ghostBlueprintId: string? = nil
local toastToken = 0

local getGhostExcludeList: () -> { Instance }

local function showToast(messageKey: string)
	if toastLabel == nil then
		return
	end

	toastToken += 1
	local currentToken = toastToken
	toastLabel.Text = Localization.get(messageKey)
	toastLabel.Visible = true

	task.delay(2.5, function()
		if toastToken == currentToken and toastLabel ~= nil then
			toastLabel.Visible = false
		end
	end)
end

local function getInventoryBlueprints(): { string }
	local syncController = ClientKernel.getController("ClientSyncController")
	local inventory = if syncController ~= nil then syncController:GetInventory() else nil
	local blueprintIds: { string } = {}

	if inventory == nil then
		return blueprintIds
	end

	for _, item in inventory.inventory do
		if StructuresConstants.isBlueprint(item.itemId) and item.quantity > 0 then
			table.insert(blueprintIds, item.itemId)
		end
	end

	table.sort(blueprintIds)
	return blueprintIds
end

local function getCampSnapshot(): CampTypes.CampSnapshot?
	local syncController = ClientKernel.getController("ClientSyncController")

	if syncController == nil then
		return nil
	end

	return syncController:GetCamp()
end

local function hasCampPlot(): boolean
	local camp = getCampSnapshot()

	return camp ~= nil and camp.plotId ~= nil
end

local function countCampStructures(camp: CampTypes.CampSnapshot): number
	if type(camp.structures) ~= "table" then
		return 0
	end

	local count = 0

	for _ in camp.structures do
		count += 1
	end

	return count
end

local function hasWorldStructures(plotId: string?): boolean
	local campHub = workspace:FindFirstChild("CampHub")
	local structuresRoot = if campHub ~= nil then campHub:FindFirstChild("Structures") else nil

	if structuresRoot == nil then
		return false
	end

	local userId = Players.LocalPlayer.UserId
	local plotFolders: { Instance } = {}

	if plotId ~= nil then
		local plotFolder = structuresRoot:FindFirstChild(plotId)

		if plotFolder ~= nil then
			table.insert(plotFolders, plotFolder)
		end
	else
		for _, child in structuresRoot:GetChildren() do
			table.insert(plotFolders, child)
		end
	end

	for _, plotFolder in plotFolders do
		for _, child in plotFolder:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("OwnerUserId") == userId then
				return true
			end
		end
	end

	return false
end

local function hasPlacedStructures(): boolean
	local camp = getCampSnapshot()

	if camp ~= nil and countCampStructures(camp) > 0 then
		return true
	end

	local plotId = if camp ~= nil then camp.plotId else nil

	return hasWorldStructures(plotId)
end

local function canOpenBuildMode(): boolean
	if #getInventoryBlueprints() > 0 then
		return true
	end

	if hasCampPlot() then
		return true
	end

	return hasPlacedStructures()
end

local function resolveStructureIdFromInstance(start: Instance): string?
	local playerUserId = Players.LocalPlayer.UserId
	local current: Instance? = start

	while current ~= nil and current ~= workspace do
		local structureId = current:GetAttribute("StructureId")

		if type(structureId) == "string" then
			local ownerUserId = current:GetAttribute("OwnerUserId")

			if ownerUserId == playerUserId then
				return structureId
			end

			return nil
		end

		current = current.Parent
	end

	return nil
end

local function buildStructureRaycastExcludeList(): { Instance }
	local excludeList: { Instance } = {}

	for _, instance in getGhostExcludeList() do
		table.insert(excludeList, instance)
	end

	local character = Players.LocalPlayer.Character

	if character ~= nil then
		table.insert(excludeList, character)
	end

	for _, plotPart in CollectionService:GetTagged(CampConstants.PLOT_TAG) do
		table.insert(excludeList, plotPart)
	end

	local devBaseplate = workspace:FindFirstChild("DevBaseplate")

	if devBaseplate ~= nil then
		table.insert(excludeList, devBaseplate)
	end

	return excludeList
end

local function raycastForStructureId(maxDistance: number): string?
	local mouse = Players.LocalPlayer:GetMouse()
	local unitRay = mouse.UnitRay
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = buildStructureRaycastExcludeList()

	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * maxDistance, params)

	if result == nil then
		return nil
	end

	return resolveStructureIdFromInstance(result.Instance)
end

local function getStructureIdFromRay(): string?
	local mouse = Players.LocalPlayer:GetMouse()

	if mouse.Target ~= nil then
		local structureId = resolveStructureIdFromInstance(mouse.Target)

		if structureId ~= nil then
			return structureId
		end
	end

	return raycastForStructureId(500)
end

local function getActiveBlueprintId(): string?
	if movingStructureId ~= nil then
		local camp = getCampSnapshot()

		if camp ~= nil then
			for _, structure in camp.structures do
				if structure.structureId == movingStructureId then
					return structure.blueprintId
				end
			end
		end
	end

	return selectedBlueprintId
end

local function updateBuildPanelHints()
	if rotateHint == nil or placeButton == nil or moveButton == nil or demolishButton == nil then
		return
	end

	if moveModeActive then
		if movingStructureId == nil then
			rotateHint.Text = Localization.get("ui.build.select_structure")
		else
			rotateHint.Text = Localization.get("ui.build.rotate")
		end
		placeButton.Text = Localization.get("ui.build.confirm_move")
		moveButton.BackgroundColor3 = Color3.fromRGB(90, 72, 58)
		demolishButton.BackgroundColor3 = Color3.fromRGB(120, 58, 58)
	elseif demolishModeActive then
		rotateHint.Text = Localization.get("ui.build.demolish_hint")
		placeButton.Text = Localization.get("ui.build.place")
		moveButton.BackgroundColor3 = Color3.fromRGB(58, 72, 96)
		demolishButton.BackgroundColor3 = Color3.fromRGB(180, 72, 72)
	elseif selectedBlueprintId == "bp_chest" then
		rotateHint.Text = Localization.get("ui.build.placement_ground")
		placeButton.Text = Localization.get("ui.build.place")
		moveButton.BackgroundColor3 = Color3.fromRGB(58, 72, 96)
	else
		rotateHint.Text = Localization.get("ui.build.rotate")
		placeButton.Text = Localization.get("ui.build.place")
		moveButton.BackgroundColor3 = Color3.fromRGB(58, 72, 96)
		demolishButton.BackgroundColor3 = Color3.fromRGB(120, 58, 58)
	end
end

local function clearMoveSelection()
	movingStructureId = nil
	currentRotation = 0
end

local function getPlotPart(): BasePart?
	local camp = getCampSnapshot()

	if camp == nil or camp.plotId == nil then
		return nil
	end

	local campHub = workspace:FindFirstChild("CampHub")

	if campHub == nil then
		return nil
	end

	local plots = campHub:FindFirstChild("Plots")

	if plots == nil then
		return nil
	end

	local plotPart = plots:FindFirstChild(camp.plotId)

	if plotPart ~= nil and plotPart:IsA("BasePart") then
		return plotPart
	end

	return nil
end

local function snapScalar(value: number): number
	return math.round(value / CampConstants.GRID_CELL_SIZE) * CampConstants.GRID_CELL_SIZE
end

local function destroyGhostModel()
	if ghostModel ~= nil then
		ghostModel:Destroy()
		ghostModel = nil
		ghostBlueprintId = nil
	end
end

local function rebuildGhostModel(blueprintId: string)
	if ghostBlueprintId == blueprintId and ghostModel ~= nil then
		return
	end

	destroyGhostModel()

	local model = StructureModelFactory.build(blueprintId, { ghost = true })

	if model == nil then
		return
	end

	model.Name = "BuildGhost"
	model.Parent = workspace
	ghostModel = model
	ghostBlueprintId = blueprintId
end

local function setGhostVisible(visible: boolean)
	if ghostModel == nil then
		return
	end

	StructureModelFactory.setGhostVisible(ghostModel, visible)
end

local function pivotGhost(targetCFrame: CFrame)
	if ghostModel == nil or ghostModel.PrimaryPart == nil then
		return
	end

	ghostModel:PivotTo(targetCFrame)
end

local function getGhostPosition(): Vector3?
	if ghostModel == nil or ghostModel.PrimaryPart == nil then
		return nil
	end

	return ghostModel.PrimaryPart.Position
end

local function getGhostExcludeList(): { Instance }
	if ghostModel ~= nil then
		return { ghostModel }
	end

	return {}
end

local function updateGhostSize(blueprintId: string)
	rebuildGhostModel(blueprintId)
end

local function getMouseWorldPosition(): Vector3?
	local camera = workspace.CurrentCamera

	if camera == nil then
		return nil
	end

	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = getGhostExcludeList()

	local result = workspace:Raycast(ray.Origin, ray.Direction * 500, params)

	if result ~= nil then
		return result.Position
	end

	return nil
end

local function updateGhostTransform()
	local activeBlueprintId = getActiveBlueprintId()

	if ghostModel == nil or activeBlueprintId == nil or not buildModeActive then
		return
	end

	if moveModeActive and movingStructureId == nil then
		setGhostVisible(false)
		return
	end

	local plotPart = getPlotPart()
	local hitPosition = getMouseWorldPosition()

	if plotPart == nil or hitPosition == nil then
		setGhostVisible(false)
		return
	end

	local definition = StructuresConstants.get(activeBlueprintId)

	if definition == nil then
		return
	end

	local snapped = Vector3.new(
		snapScalar(hitPosition.X),
		plotPart.Position.Y + plotPart.Size.Y / 2 + definition.modelSize.Y / 2,
		snapScalar(hitPosition.Z)
	)

	pivotGhost(CFrame.new(snapped) * CFrame.Angles(0, math.rad(currentRotation), 0))
	setGhostVisible(true)
end

local function renderBlueprintList()
	for _, button in blueprintButtons do
		button:Destroy()
	end

	table.clear(blueprintButtons)

	if panelFrame == nil then
		return
	end

	local listFrame = panelFrame:FindFirstChild("BlueprintList")

	if listFrame == nil or not listFrame:IsA("ScrollingFrame") then
		return
	end

	for _, child in listFrame:GetChildren() do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	local blueprints = getInventoryBlueprints()

	if #blueprints == 0 then
		selectedBlueprintId = nil

		if ghostModel ~= nil then
			setGhostVisible(false)
		end

		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Name = "EmptyHint"
		emptyLabel.Size = UDim2.new(1, -8, 0, 48)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.TextSize = 12
		emptyLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		emptyLabel.TextWrapped = true
		emptyLabel.TextXAlignment = Enum.TextXAlignment.Left
		emptyLabel.TextYAlignment = Enum.TextYAlignment.Top
		emptyLabel.Text = Localization.get("ui.build.no_blueprints_use_move")
		emptyLabel.LayoutOrder = 1
		emptyLabel.Parent = listFrame

		updateBuildPanelHints()
		return
	end

	if selectedBlueprintId == nil or table.find(blueprints, selectedBlueprintId) == nil then
		selectedBlueprintId = blueprints[1]
	end

	if selectedBlueprintId ~= nil then
		updateGhostSize(selectedBlueprintId)
	end

	for index, blueprintId in blueprints do
		local button = Instance.new("TextButton")
		button.Name = blueprintId
		button.Size = UDim2.new(1, -8, 0, 36)
		button.BackgroundColor3 = if selectedBlueprintId == blueprintId
			then Color3.fromRGB(58, 72, 96)
			else Color3.fromRGB(45, 48, 58)
		button.BorderSizePixel = 0
		button.Font = Enum.Font.Gotham
		button.TextSize = 13
		button.TextColor3 = Color3.fromRGB(240, 240, 240)
		button.Text = Localization.get(Items.getNameKey(blueprintId))
		button.LayoutOrder = index
		button.Parent = listFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = button

		button.Activated:Connect(function()
			moveModeActive = false
			clearMoveSelection()
			selectedBlueprintId = blueprintId
			updateGhostSize(blueprintId)
			renderBlueprintList()
			updateBuildPanelHints()
		end)

		table.insert(blueprintButtons, button)
	end
end

local function setBuildMode(active: boolean)
	buildModeActive = active

	if not active then
		moveModeActive = false
		demolishModeActive = false
		clearMoveSelection()
	end

	if panelFrame ~= nil then
		panelFrame.Visible = active
	end

	if active then
		renderBlueprintList()

		if selectedBlueprintId ~= nil then
			rebuildGhostModel(selectedBlueprintId)
		elseif movingStructureId ~= nil then
			-- ghost rebuilt when structure selected for move
		else
			setGhostVisible(false)
		end
	else
		selectedBlueprintId = nil
		destroyGhostModel()
	end

	updateBuildPanelHints()
end

local function toggleMoveMode()
	if not buildModeActive then
		return
	end

	moveModeActive = not moveModeActive
	demolishModeActive = false
	clearMoveSelection()
	selectedBlueprintId = nil

	if moveModeActive then
		if ghostModel ~= nil then
			setGhostVisible(false)
		end
	else
		renderBlueprintList()
	end

	updateBuildPanelHints()
end

local function toggleDemolishMode()
	if not buildModeActive then
		return
	end

	demolishModeActive = not demolishModeActive
	moveModeActive = false
	clearMoveSelection()
	selectedBlueprintId = nil

	if demolishModeActive and ghostModel ~= nil then
		setGhostVisible(false)
	end

	updateBuildPanelHints()
end

local function requestDemolishStructure(structureId: string)
	Networking.getEvent("DemolishStructureEvent"):FireServer(structureId)
end

local function selectStructureForMove(structureId: string)
	local camp = getCampSnapshot()

	if camp == nil then
		return
	end

	for _, structure in camp.structures do
		if structure.structureId == structureId then
			movingStructureId = structureId
			currentRotation = structure.rotation
			updateGhostSize(structure.blueprintId)

			if ghostModel ~= nil then
				local position = CampProximity.toVector3(structure.position)

				if position ~= nil then
					pivotGhost(CFrame.new(position) * CFrame.Angles(0, math.rad(currentRotation), 0))
					setGhostVisible(true)
				end
			end

			updateBuildPanelHints()
			return
		end
	end
end

function BuildingController:ClosePanel()
	setBuildMode(false)
end

local function toggleBuildMode()
	if not buildModeActive and not canOpenBuildMode() then
		showToast("ui.build.no_camp")
		return
	end

	setBuildMode(not buildModeActive)
end

local function requestPlace()
	if moveModeActive and movingStructureId ~= nil then
		requestMove()
		return
	end

	if moveModeActive then
		showToast("ui.build.select_structure")
		return
	end

	local ghostPosition = getGhostPosition()

	if selectedBlueprintId == nil or ghostPosition == nil then
		showToast("ui.build.select_blueprint")
		return
	end

	Networking.getEvent("PlaceStructureEvent"):FireServer({
		blueprintId = selectedBlueprintId,
		position = ghostPosition,
		rotation = currentRotation,
	})
end

local function requestMove()
	local ghostPosition = getGhostPosition()

	if movingStructureId == nil or ghostPosition == nil then
		showToast("ui.build.select_structure")
		return
	end

	Networking.getEvent("MoveStructureEvent"):FireServer({
		structureId = movingStructureId,
		position = ghostPosition,
		rotation = currentRotation,
	})
end

function BuildingController:Init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local trove = self:GetTrove()

	trove:Add(destroyGhostModel)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BuildHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 107
	screenGui.Parent = playerGui
	trove:Add(screenGui)

	panelFrame = Instance.new("Frame")
	panelFrame.Name = "BuildPanel"
	panelFrame.AnchorPoint = Vector2.new(0, 0.5)
	panelFrame.Position = UDim2.new(0, 12, 0.5, 0)
	panelFrame.Size = UDim2.fromOffset(220, 340)
	panelFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	panelFrame.BackgroundTransparency = 0.1
	panelFrame.BorderSizePixel = 0
	panelFrame.Visible = false
	panelFrame.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 10)
	panelCorner.Parent = panelFrame

	local title = Instance.new("TextLabel")
	titleLabel = title
	title.Size = UDim2.new(1, -16, 0, 24)
	title.Position = UDim2.fromOffset(8, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextColor3 = Color3.fromRGB(240, 240, 240)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = Localization.get("ui.build.title")
	title.Parent = panelFrame

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Name = "BlueprintList"
	listFrame.Position = UDim2.fromOffset(8, 40)
	listFrame.Size = UDim2.fromOffset(204, 140)
	listFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
	listFrame.BackgroundTransparency = 0.2
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 6
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.CanvasSize = UDim2.fromOffset(0, 0)
	listFrame.Parent = panelFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 4)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = listFrame

	local placeBtn = Instance.new("TextButton")
	placeButton = placeBtn
	placeBtn.Size = UDim2.fromOffset(204, 32)
	placeBtn.Position = UDim2.fromOffset(8, 188)
	placeBtn.BackgroundColor3 = Color3.fromRGB(58, 120, 72)
	placeBtn.BorderSizePixel = 0
	placeBtn.Font = Enum.Font.GothamBold
	placeBtn.TextSize = 13
	placeBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
	placeBtn.Text = Localization.get("ui.build.place")
	placeBtn.Parent = panelFrame

	local moveBtn = Instance.new("TextButton")
	moveButton = moveBtn
	moveBtn.Size = UDim2.fromOffset(204, 32)
	moveBtn.Position = UDim2.fromOffset(8, 226)
	moveBtn.BackgroundColor3 = Color3.fromRGB(58, 72, 96)
	moveBtn.BorderSizePixel = 0
	moveBtn.Font = Enum.Font.GothamBold
	moveBtn.TextSize = 13
	moveBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
	moveBtn.Text = Localization.get("ui.build.move")
	moveBtn.Parent = panelFrame

	local demolishBtn = Instance.new("TextButton")
	demolishButton = demolishBtn
	demolishBtn.Size = UDim2.fromOffset(204, 32)
	demolishBtn.Position = UDim2.fromOffset(8, 264)
	demolishBtn.BackgroundColor3 = Color3.fromRGB(120, 58, 58)
	demolishBtn.BorderSizePixel = 0
	demolishBtn.Font = Enum.Font.GothamBold
	demolishBtn.TextSize = 13
	demolishBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
	demolishBtn.Text = Localization.get("ui.build.demolish")
	demolishBtn.Parent = panelFrame

	local hint = Instance.new("TextLabel")
	rotateHint = hint
	hint.Size = UDim2.fromOffset(204, 36)
	hint.Position = UDim2.fromOffset(8, 300)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 11
	hint.TextColor3 = Color3.fromRGB(180, 180, 180)
	hint.TextWrapped = true
	hint.Text = Localization.get("ui.build.rotate")
	hint.Parent = panelFrame

	placeBtn.Activated:Connect(requestPlace)
	moveBtn.Activated:Connect(toggleMoveMode)
	demolishBtn.Activated:Connect(toggleDemolishMode)

	toastLabel = Instance.new("TextLabel")
	toastLabel.AnchorPoint = Vector2.new(0.5, 1)
	toastLabel.Position = UDim2.new(0.5, 0, 1, -160)
	toastLabel.Size = UDim2.fromOffset(280, 32)
	toastLabel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	toastLabel.BackgroundTransparency = 0.15
	toastLabel.BorderSizePixel = 0
	toastLabel.Font = Enum.Font.Gotham
	toastLabel.TextSize = 13
	toastLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	toastLabel.Visible = false
	toastLabel.Parent = screenGui

	local toggleButton = Instance.new("TextButton")
	toggleButton.AnchorPoint = Vector2.new(1, 1)
	toggleButton.Position = UDim2.new(1, -108, 1, -80)
	toggleButton.Size = UDim2.fromOffset(40, 40)
	toggleButton.BackgroundColor3 = Color3.fromRGB(72, 58, 45)
	toggleButton.BorderSizePixel = 0
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextSize = 18
	toggleButton.TextColor3 = Color3.fromRGB(240, 240, 240)
	toggleButton.Text = "B"
	toggleButton.Parent = screenGui

	toggleButton.Activated:Connect(toggleBuildMode)

	trove:Connect(UserInputService.InputBegan, function(input, _processed)
		if UserInputService:GetFocusedTextBox() ~= nil then
			return
		end

		if input.KeyCode == Enum.KeyCode.B then
			toggleBuildMode()
			return
		end

		if not buildModeActive then
			return
		end

		if input.KeyCode == Enum.KeyCode.R then
			currentRotation = (currentRotation + 90) % 360
			updateGhostTransform()
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if demolishModeActive then
				local structureId = getStructureIdFromRay()

				if structureId ~= nil then
					requestDemolishStructure(structureId)
				else
					showToast("ui.build.select_structure")
				end

				return
			end

			if moveModeActive then
				if movingStructureId == nil then
					local structureId = getStructureIdFromRay()

					if structureId ~= nil then
						selectStructureForMove(structureId)
					else
						showToast("ui.build.select_structure")
					end
				else
					requestMove()
				end

				return
			end

			if selectedBlueprintId ~= nil then
				requestPlace()
			end
		end
	end)

	trove:Connect(RunService.RenderStepped, updateGhostTransform)

	trove:Connect(Networking.getEvent("PlaceStructureResultEvent").OnClientEvent, function(payload: CampTypes.PlaceStructureResult)
		if payload.reasonKey ~= nil then
			showToast(payload.reasonKey)
		end

		if payload.success then
			renderBlueprintList()
		end
	end)

	trove:Connect(Networking.getEvent("DemolishStructureResultEvent").OnClientEvent, function(payload: CampTypes.DemolishStructureResult)
		if payload.reasonKey ~= nil then
			showToast(payload.reasonKey)
		end

		if payload.success then
			demolishModeActive = false
			clearMoveSelection()
			renderBlueprintList()
			updateBuildPanelHints()
		end
	end)

	trove:Connect(Networking.getEvent("MoveStructureResultEvent").OnClientEvent, function(payload: CampTypes.MoveStructureResult)
		if payload.reasonKey ~= nil then
			showToast(payload.reasonKey)
		end

		if payload.success then
			moveModeActive = false
			clearMoveSelection()
			updateBuildPanelHints()
		end
	end)

	trove:Connect(Networking.getEvent("CampUpdatedEvent").OnClientEvent, function()
		if buildModeActive then
			updateGhostTransform()
		end
	end)

	trove:Connect(Networking.getEvent("InventoryUpdatedEvent").OnClientEvent, function()
		if buildModeActive then
			renderBlueprintList()
		end
	end)

	trove:Connect(Localization.LocaleChanged, function()
		if titleLabel ~= nil then
			titleLabel.Text = Localization.get("ui.build.title")
		end

		if demolishButton ~= nil then
			demolishButton.Text = Localization.get("ui.build.demolish")
		end

		if moveButton ~= nil then
			moveButton.Text = Localization.get("ui.build.move")
		end

		updateBuildPanelHints()
		renderBlueprintList()
	end)
end

return BuildingController
