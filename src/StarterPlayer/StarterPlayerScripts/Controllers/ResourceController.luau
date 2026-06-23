--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseController = require(script.Parent.Parent.Kernel.BaseController)
local Localization = require(ReplicatedStorage.Shared.Localization.Localization)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local WorldConstants = require(ReplicatedStorage.Shared.Constants.WorldConstants)
local WorldTypes = require(ReplicatedStorage.Shared.Types.World)

local ResourceController = BaseController.new("ResourceController")

local toastLabel: TextLabel? = nil
local toastToken = 0

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

local function getPromptKey(nodeType: string): string
	if nodeType == "chop" then
		return "resource.prompt.chop"
	end

	return "resource.prompt.gather"
end

local function getNodeContainer(instance: Instance): Instance?
	if instance:IsA("Model") or instance:IsA("BasePart") then
		return instance
	end

	return nil
end

local function bindResourceNode(instance: Instance, trove: any)
	local container = getNodeContainer(instance)

	if container == nil then
		return
	end

	local nodeId = container:GetAttribute(WorldConstants.NODE_ID_ATTRIBUTE)
	local nodeType = container:GetAttribute(WorldConstants.NODE_TYPE_ATTRIBUTE)

	if type(nodeId) ~= "string" or type(nodeType) ~= "string" then
		return
	end

	local prompt = container:FindFirstChild("HarvestPrompt", true)

	if prompt == nil or not prompt:IsA("ProximityPrompt") then
		return
	end

	prompt.ActionText = Localization.get(getPromptKey(nodeType))
	prompt.ObjectText = Localization.get("resource.prompt.node")

	trove:Connect(prompt.Triggered, function()
		local harvestResourceEvent = Networking.getEvent("HarvestResourceEvent")
		harvestResourceEvent:FireServer({
			nodeId = nodeId,
		})
	end)
end

local function refreshPromptLabels()
	for _, instance in CollectionService:GetTagged(WorldConstants.RESOURCE_NODE_TAG) do
		local container = getNodeContainer(instance)

		if container == nil then
			continue
		end

		local nodeType = container:GetAttribute(WorldConstants.NODE_TYPE_ATTRIBUTE)
		local prompt = container:FindFirstChild("HarvestPrompt", true)

		if type(nodeType) == "string" and prompt ~= nil and prompt:IsA("ProximityPrompt") then
			prompt.ActionText = Localization.get(getPromptKey(nodeType))
			prompt.ObjectText = Localization.get("resource.prompt.node")
		end
	end
end

function ResourceController:Init()
	local trove = self:GetTrove()
	local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ResourceHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 95
	screenGui.Parent = playerGui
	trove:Add(screenGui)

	toastLabel = Instance.new("TextLabel")
	toastLabel.AnchorPoint = Vector2.new(0.5, 1)
	toastLabel.Position = UDim2.new(0.5, 0, 1, -200)
	toastLabel.Size = UDim2.fromOffset(300, 32)
	toastLabel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	toastLabel.BackgroundTransparency = 0.15
	toastLabel.BorderSizePixel = 0
	toastLabel.Font = Enum.Font.Gotham
	toastLabel.TextSize = 13
	toastLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	toastLabel.Visible = false
	toastLabel.Parent = screenGui

	local toastCorner = Instance.new("UICorner")
	toastCorner.CornerRadius = UDim.new(0, 8)
	toastCorner.Parent = toastLabel

	for _, instance in CollectionService:GetTagged(WorldConstants.RESOURCE_NODE_TAG) do
		bindResourceNode(instance, trove)
	end

	trove:Connect(CollectionService:GetInstanceAddedSignal(WorldConstants.RESOURCE_NODE_TAG), function(instance: Instance)
		bindResourceNode(instance, trove)
	end)

	local harvestResultEvent = Networking.getEvent("HarvestResourceResultEvent")

	trove:Connect(harvestResultEvent.OnClientEvent, function(payload: WorldTypes.HarvestResultPayload)
		if type(payload) ~= "table" then
			return
		end

		if payload.success then
			showToast(payload.reasonKey or "resource.success.harvest")
			return
		end

		showToast(payload.reasonKey or "resource.error.invalid_node")
	end)

	trove:Connect(Localization.LocaleChanged, refreshPromptLabels)

	refreshPromptLabels()
end

return ResourceController
