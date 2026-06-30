--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseService = require(ServerScriptService.Kernel.BaseService)
local GameEvents = require(ServerScriptService.Features.GameEvents)
local InventoryService = require(ServerScriptService.Services.InventoryService)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local ResourceNodesConstants = require(ReplicatedStorage.Shared.Constants.ResourceNodesConstants)
local ResourceNodeModelFactory = require(ReplicatedStorage.Shared.World.ResourceNodeModelFactory)
local WorldConstants = require(ReplicatedStorage.Shared.Constants.WorldConstants)
local WorldTypes = require(ReplicatedStorage.Shared.Types.World)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)

local ResourceService = BaseService.new("ResourceService")

type NodeDefinition = {
	nodeId: string,
	container: Instance,
	interactPart: BasePart,
	nodeType: ResourceNodesConstants.NodeType,
	outputsRaw: string,
}

type NodeRuntimeState = {
	depleted: boolean,
	respawnAt: number?,
	lastHarvestByPlayer: { [number]: number },
}

local nodeDefinitions: { [string]: NodeDefinition } = {}
local nodeStates: { [string]: NodeRuntimeState } = {}

local function getCharacterRoot(player: Player): BasePart?
	local character = player.Character

	if character == nil then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if rootPart ~= nil and rootPart:IsA("BasePart") then
		return rootPart
	end

	return nil
end

local function getResourceNodeContainer(instance: Instance): Instance?
	if instance:IsA("Model") or instance:IsA("BasePart") then
		return instance
	end

	return nil
end

local function getInteractPart(container: Instance): BasePart?
	if container:IsA("BasePart") then
		return container
	end

	if container:IsA("Model") then
		return container.PrimaryPart
	end

	return nil
end

local function getDistanceToNode(player: Player, interactPart: BasePart): number?
	local rootPart = getCharacterRoot(player)

	if rootPart == nil then
		return nil
	end

	return (rootPart.Position - interactPart.Position).Magnitude
end

local function setNodeDepletedVisual(container: Instance, depleted: boolean)
	ResourceNodeModelFactory.setDepletedVisual(container, depleted)
end

local function getNodeState(nodeId: string): NodeRuntimeState
	local state = nodeStates[nodeId]

	if state == nil then
		state = {
			depleted = false,
			respawnAt = nil,
			lastHarvestByPlayer = {},
		}
		nodeStates[nodeId] = state
	end

	return state
end

local function registerNode(instance: Instance)
	local container = getResourceNodeContainer(instance)

	if container == nil then
		return
	end

	local interactPart = getInteractPart(container)

	if interactPart == nil then
		Logger.warn("ResourceService", `Resource node missing interact part: {instance:GetFullName()}`)
		return
	end

	local nodeId = container:GetAttribute(WorldConstants.NODE_ID_ATTRIBUTE)
	local nodeTypeRaw = instance:GetAttribute(WorldConstants.NODE_TYPE_ATTRIBUTE)
	local outputsRaw = instance:GetAttribute(WorldConstants.NODE_OUTPUTS_ATTRIBUTE)

	if type(nodeId) ~= "string" or nodeId == "" then
		return
	end

	if type(nodeTypeRaw) ~= "string" then
		return
	end

	if type(outputsRaw) ~= "string" or outputsRaw == "" then
		return
	end

	local nodeType = ResourceNodesConstants.getNodeType(nodeTypeRaw)

	if nodeType == nil then
		Logger.warn("ResourceService", `Invalid node type for {nodeId}: {nodeTypeRaw}`)
		return
	end

	if nodeDefinitions[nodeId] ~= nil then
		Logger.warn("ResourceService", `Duplicate node id: {nodeId}`)
		return
	end

	nodeDefinitions[nodeId] = {
		nodeId = nodeId,
		container = container,
		interactPart = interactPart,
		nodeType = nodeType,
		outputsRaw = outputsRaw,
	}

	local depletedAttribute = container:GetAttribute(WorldConstants.NODE_DEPLETED_ATTRIBUTE)

	if depletedAttribute == true then
		local state = getNodeState(nodeId)
		state.depleted = true
		setNodeDepletedVisual(container, true)
	else
		setNodeDepletedVisual(container, false)
	end
end

local function scanResourceNodes()
	table.clear(nodeDefinitions)

	for _, instance in CollectionService:GetTagged(WorldConstants.RESOURCE_NODE_TAG) do
		registerNode(instance)
	end

	Logger.info("ResourceService", `Registered {#nodeDefinitions} resource nodes`)
end

local function scheduleRespawn(nodeId: string, nodeDefinition: NodeDefinition, state: NodeRuntimeState)
	local respawnDelay = ResourceNodesConstants.GLOBAL_RESPAWN_SECONDS
	state.respawnAt = os.clock() + respawnDelay

	task.delay(respawnDelay, function()
		local currentState = nodeStates[nodeId]

		if currentState == nil or currentState.respawnAt == nil then
			return
		end

		currentState.depleted = false
		currentState.respawnAt = nil
		setNodeDepletedVisual(nodeDefinition.container, false)
	end)
end

local function sendHarvestResult(player: Player, payload: WorldTypes.HarvestResultPayload)
	local harvestResultEvent = Networking.getEvent("HarvestResourceResultEvent")
	harvestResultEvent:FireClient(player, payload)
end

local function handleHarvest(player: Player, nodeId: string)
	if type(nodeId) ~= "string" or nodeId == "" then
		sendHarvestResult(player, {
			success = false,
			reasonKey = "resource.error.invalid_node",
		})
		return
	end

	local nodeDefinition = nodeDefinitions[nodeId]

	if nodeDefinition == nil then
		sendHarvestResult(player, {
			success = false,
			reasonKey = "resource.error.invalid_node",
		})
		return
	end

	local state = getNodeState(nodeId)

	if state.depleted then
		sendHarvestResult(player, {
			success = false,
			reasonKey = "resource.error.depleted",
		})
		return
	end

	local distance = getDistanceToNode(player, nodeDefinition.interactPart)

	if distance == nil or distance > WorldConstants.HARVEST_MAX_DISTANCE_STUDS then
		sendHarvestResult(player, {
			success = false,
			reasonKey = "resource.error.too_far",
		})
		return
	end

	local lastHarvestAt = state.lastHarvestByPlayer[player.UserId]

	if lastHarvestAt ~= nil and os.clock() - lastHarvestAt < ResourceNodesConstants.PLAYER_COOLDOWN_SECONDS then
		sendHarvestResult(player, {
			success = false,
			reasonKey = "resource.error.cooldown",
		})
		return
	end

	if nodeDefinition.nodeType == "chop" then
		local data = PlayerDataService:GetData(player)
		local equippedTool = if data ~= nil then data.equipped.toolItemId else nil

		if not ResourceNodesConstants.matchesAxeTool(equippedTool) then
			sendHarvestResult(player, {
				success = false,
				reasonKey = "resource.error.no_tool",
			})
			return
		end
	end

	local rolledOutputs = ResourceNodesConstants.rollOutputs(nodeDefinition.outputsRaw)

	if #rolledOutputs == 0 then
		sendHarvestResult(player, {
			success = false,
			reasonKey = "resource.error.invalid_node",
		})
		return
	end

	local granted = InventoryService.grantItems(player, rolledOutputs)

	if not granted then
		sendHarvestResult(player, {
			success = false,
			reasonKey = "resource.error.bag_full",
		})
		return
	end

	state.depleted = true
	state.lastHarvestByPlayer[player.UserId] = os.clock()
	setNodeDepletedVisual(nodeDefinition.container, true)
	scheduleRespawn(nodeId, nodeDefinition, state)

	sendHarvestResult(player, {
		success = true,
		reasonKey = "resource.success.harvest",
		granted = rolledOutputs,
	})

	for _, output in rolledOutputs do
		GameEvents.fireItemHarvested(player, output.itemId, output.quantity)
	end

	Logger.info("ResourceService", `{player.Name} harvested {nodeId}`)
end

function ResourceService:Init()
	scanResourceNodes()

	local trove = self:GetTrove()

	trove:Connect(CollectionService:GetInstanceAddedSignal(WorldConstants.RESOURCE_NODE_TAG), function(instance: Instance)
		registerNode(instance)
	end)

	local harvestResourceEvent = Networking.getEvent("HarvestResourceEvent")

	trove:Connect(harvestResourceEvent.OnServerEvent, function(player: Player, payload: { nodeId: string }?)
		if type(payload) ~= "table" or type(payload.nodeId) ~= "string" then
			sendHarvestResult(player, {
				success = false,
				reasonKey = "resource.error.invalid_node",
			})
			return
		end

		handleHarvest(player, payload.nodeId)
	end)
end

function ResourceService:Start()
end

return ResourceService
