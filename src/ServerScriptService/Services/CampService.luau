--!strict

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local BaseService = require(ServerScriptService.Kernel.BaseService)
local CampConstants = require(ReplicatedStorage.Shared.Constants.CampConstants)
local CampRepository = require(ServerScriptService.Repositories.CampRepository)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local Recipes = require(ReplicatedStorage.Shared.Constants.Recipes)
local StructuresConstants = require(ReplicatedStorage.Shared.Constants.StructuresConstants)
local StructureModelFactory = require(ReplicatedStorage.Shared.Structures.StructureModelFactory)
local CampTypes = require(ReplicatedStorage.Shared.Types.Camp)
local CampProximity = require(ReplicatedStorage.Shared.Utilities.CampProximity)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)
local InventoryService = require(ServerScriptService.Services.InventoryService)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local PlayerSyncService = require(ServerScriptService.Services.PlayerSyncService)
local FeatureBootstrap = require(ServerScriptService.Features.FeatureBootstrap)
local GameEvents = require(ServerScriptService.Features.GameEvents)
local StructureBehaviorRegistry = require(ServerScriptService.Features.StructureBehaviorRegistry)

local CampService = BaseService.new("CampService")

local plotParts: { [string]: BasePart } = {}
local plotOccupants: { [string]: number } = {}
local assignedPlotThisSession: { [number]: boolean } = {}

local function getCampHubFolder(): Folder
	local existing = workspace:FindFirstChild("CampHub")

	if existing ~= nil and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = "CampHub"
	folder.Parent = workspace
	return folder
end

local function createPlotPart(plotId: string, position: Vector3): BasePart
	local plotsFolder = getCampHubFolder():FindFirstChild("Plots")

	if plotsFolder == nil then
		plotsFolder = Instance.new("Folder")
		plotsFolder.Name = "Plots"
		plotsFolder.Parent = getCampHubFolder()
	end

	local part = Instance.new("Part")
	part.Name = plotId
	part.Anchored = true
	part.Size = Vector3.new(CampConstants.PLOT_SIZE_STUDS, 1, CampConstants.PLOT_SIZE_STUDS)
	part.Position = position
	part.Material = Enum.Material.Grass
	part.Color = Color3.fromRGB(70, 130, 70)
	part.Transparency = 0.35
	part.CanCollide = true
	part:SetAttribute("PlotId", plotId)
	part.Parent = plotsFolder
	CollectionService:AddTag(part, CampConstants.PLOT_TAG)
	return part
end

local function createStructureTemplate(blueprintId: string, definition: any): Model
	local templatesFolder = ServerStorage:FindFirstChild("StructureTemplates")

	if templatesFolder == nil then
		templatesFolder = Instance.new("Folder")
		templatesFolder.Name = "StructureTemplates"
		templatesFolder.Parent = ServerStorage
	end

	local existing = templatesFolder:FindFirstChild(blueprintId)

	if existing ~= nil and existing:IsA("Model") then
		if existing:GetAttribute("ModelVersion") == StructureModelFactory.MODEL_VERSION then
			return existing
		end

		existing:Destroy()
	end

	local model = StructureModelFactory.build(blueprintId)

	if model == nil then
		model = Instance.new("Model")
		model.Name = blueprintId

		local root = Instance.new("Part")
		root.Name = "Root"
		root.Anchored = true
		root.Size = definition.modelSize
		root.Color = definition.modelColor
		root.Material = Enum.Material.Wood
		root.Parent = model
		model.PrimaryPart = root
	end

	model.Parent = templatesFolder
	return model
end

local function ensureCampHub()
	local plotLayout = {
		{ id = "plot_01", position = Vector3.new(30, 0.5, 40) },
		{ id = "plot_02", position = Vector3.new(78, 0.5, 40) },
		{ id = "plot_03", position = Vector3.new(126, 0.5, 40) },
		{ id = "plot_04", position = Vector3.new(174, 0.5, 40) },
		{ id = "plot_05", position = Vector3.new(30, 0.5, 88) },
		{ id = "plot_06", position = Vector3.new(78, 0.5, 88) },
		{ id = "plot_07", position = Vector3.new(126, 0.5, 88) },
		{ id = "plot_08", position = Vector3.new(174, 0.5, 88) },
	}

	for _, plotInfo in plotLayout do
		if plotParts[plotInfo.id] == nil then
			local tagged = CollectionService:GetTagged(CampConstants.PLOT_TAG)
			local found: BasePart? = nil

			for _, instance in tagged do
				if instance:IsA("BasePart") and instance:GetAttribute("PlotId") == plotInfo.id then
					found = instance
					break
				end
			end

			plotParts[plotInfo.id] = found or createPlotPart(plotInfo.id, plotInfo.position)
		end

		local definition = StructuresConstants.get("bp_campfire")

		if definition ~= nil then
			createStructureTemplate("bp_campfire", definition)
		end
	end

	for _, definition in StructuresConstants.getAll() do
		createStructureTemplate(definition.id, definition)
	end

	Logger.info("CampService", `Camp hub ready with {#plotLayout} plots`)
end

local function getStructuresFolder(plotId: string): Folder
	local structuresRoot = getCampHubFolder():FindFirstChild("Structures")

	if structuresRoot == nil then
		structuresRoot = Instance.new("Folder")
		structuresRoot.Name = "Structures"
		structuresRoot.Parent = getCampHubFolder()
	end

	local plotFolder = structuresRoot:FindFirstChild(plotId)

	if plotFolder == nil then
		plotFolder = Instance.new("Folder")
		plotFolder.Name = plotId
		plotFolder.Parent = structuresRoot
	end

	return plotFolder :: Folder
end

local function snapScalar(value: number): number
	return math.round(value / CampConstants.GRID_CELL_SIZE) * CampConstants.GRID_CELL_SIZE
end

local function getFootprintSize(definition: StructuresConstants.StructureDefinition, rotation: number): (number, number)
	if rotation == 90 or rotation == 270 then
		return definition.gridDepth * CampConstants.GRID_CELL_SIZE, definition.gridWidth * CampConstants.GRID_CELL_SIZE
	end

	return definition.gridWidth * CampConstants.GRID_CELL_SIZE, definition.gridDepth * CampConstants.GRID_CELL_SIZE
end

local function getFootprintBounds(position: Vector3, widthStuds: number, depthStuds: number): (number, number, number, number)
	local halfWidth = widthStuds / 2
	local halfDepth = depthStuds / 2

	return position.X - halfWidth, position.X + halfWidth, position.Z - halfDepth, position.Z + halfDepth
end

local function isWithinPlot(
	plotPart: BasePart,
	positionY: number,
	minX: number,
	maxX: number,
	minZ: number,
	maxZ: number
): boolean
	local plotMinX = plotPart.Position.X - CampConstants.PLOT_SIZE_STUDS / 2
	local plotMaxX = plotPart.Position.X + CampConstants.PLOT_SIZE_STUDS / 2
	local plotMinZ = plotPart.Position.Z - CampConstants.PLOT_SIZE_STUDS / 2
	local plotMaxZ = plotPart.Position.Z + CampConstants.PLOT_SIZE_STUDS / 2
	local groundY = plotPart.Position.Y + plotPart.Size.Y / 2

	return minX >= plotMinX
		and maxX <= plotMaxX
		and minZ >= plotMinZ
		and maxZ <= plotMaxZ
		and positionY >= groundY
		and positionY <= groundY + CampConstants.MAX_BUILD_HEIGHT
end

local function footprintsOverlap(
	leftMinX: number,
	leftMaxX: number,
	leftMinZ: number,
	leftMaxZ: number,
	rightMinX: number,
	rightMaxX: number,
	rightMinZ: number,
	rightMaxZ: number
): boolean
	return leftMinX < rightMaxX and leftMaxX > rightMinX and leftMinZ < rightMaxZ and leftMaxZ > rightMinZ
end

local function computeSnappedPosition(plotPart: BasePart, definition: any, position: Vector3): Vector3
	return Vector3.new(
		snapScalar(position.X),
		plotPart.Position.Y + plotPart.Size.Y / 2 + definition.modelSize.Y / 2,
		snapScalar(position.Z)
	)
end

local function validateStructureFootprint(
	data: PlayerProfileTypes.PlayerProfile,
	plotPart: BasePart,
	blueprintId: string,
	position: Vector3,
	rotation: number,
	ignoreStructureId: string?
): (boolean, string?, Vector3?)
	local definition = StructuresConstants.get(blueprintId)

	if definition == nil then
		return false, "camp.error.invalid_blueprint", nil
	end

	local snappedPosition = computeSnappedPosition(plotPart, definition, position)
	local widthStuds, depthStuds = getFootprintSize(definition, rotation)
	local minX, maxX, minZ, maxZ = getFootprintBounds(snappedPosition, widthStuds, depthStuds)

	if not isWithinPlot(plotPart, snappedPosition.Y, minX, maxX, minZ, maxZ) then
		return false, "camp.error.out_of_bounds", nil
	end

	for _, existing in data.camp.structures do
		if ignoreStructureId ~= nil and existing.structureId == ignoreStructureId then
			continue
		end

		local existingDefinition = StructuresConstants.get(existing.blueprintId)

		if existingDefinition ~= nil then
			local existingPosition = CampProximity.toVector3(existing.position)

			if existingPosition == nil then
				continue
			end

			local existingWidth, existingDepth = getFootprintSize(existingDefinition, existing.rotation)
			local eMinX, eMaxX, eMinZ, eMaxZ = getFootprintBounds(existingPosition, existingWidth, existingDepth)

			if footprintsOverlap(minX, maxX, minZ, maxZ, eMinX, eMaxX, eMinZ, eMaxZ) then
				return false, "camp.error.overlap", nil
			end
		end
	end

	return true, nil, snappedPosition
end

local function findStructure(data: PlayerProfileTypes.PlayerProfile, structureId: string): CampTypes.CampStructure?
	for _, structure in data.camp.structures do
		if structure.structureId == structureId then
			return structure
		end
	end

	return nil
end

local function countBlueprintPlaced(structures: { CampTypes.CampStructure }, blueprintId: string): number
	local count = 0

	for _, structure in structures do
		if structure.blueprintId == blueprintId then
			count += 1
		end
	end

	return count
end

local function syncCamp(player: Player, data: PlayerProfileTypes.PlayerProfile)
	PlayerSyncService.syncCampToClient(player, data)
	PlayerDataService:SaveProfile(player)
end

local function firePlaceResult(player: Player, payload: CampTypes.PlaceStructureResult)
	Networking.getEvent("PlaceStructureResultEvent"):FireClient(player, payload)
end

local function fireDemolishResult(player: Player, payload: CampTypes.DemolishStructureResult)
	Networking.getEvent("DemolishStructureResultEvent"):FireClient(player, payload)
end

local function fireMoveResult(player: Player, payload: CampTypes.MoveStructureResult)
	Networking.getEvent("MoveStructureResultEvent"):FireClient(player, payload)
end

function CampService.getPlotPart(plotId: string): BasePart?
	return plotParts[plotId]
end

function CampService.teleportPlayerToPlot(player: Player, plotId: string)
	local plotPart = plotParts[plotId]

	if plotPart == nil then
		return
	end

	local character = player.Character

	if character == nil then
		return
	end

	character:PivotTo(CFrame.new(plotPart.Position + Vector3.new(0, 4, 0)))
end

local function tagStructureForInteraction(model: Model, structureId: string, blueprintId: string, ownerUserId: number)
	model:SetAttribute("StructureId", structureId)
	model:SetAttribute("BlueprintId", blueprintId)
	model:SetAttribute("OwnerUserId", ownerUserId)

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant:SetAttribute("StructureId", structureId)
			descendant:SetAttribute("OwnerUserId", ownerUserId)
			descendant.CanQuery = true
		end
	end
end

local function spawnStructureWorld(player: Player, plotId: string, structure: CampTypes.CampStructure)
	local definition = StructuresConstants.get(structure.blueprintId)

	if definition == nil then
		return
	end

	local position = CampProximity.toVector3(structure.position)

	if position == nil then
		Logger.warn("CampService", `Cannot spawn structure {structure.structureId} — invalid position`)
		return
	end

	local template = createStructureTemplate(structure.blueprintId, definition)
	local clone = template:Clone()
	tagStructureForInteraction(clone, structure.structureId, structure.blueprintId, player.UserId)

	clone:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.rad(structure.rotation), 0))
	clone.Parent = getStructuresFolder(plotId)
end

local function removeStructureWorld(plotId: string, structureId: string)
	local plotFolder = getCampHubFolder():FindFirstChild("Structures")

	if plotFolder == nil then
		return
	end

	local structureFolder = plotFolder:FindFirstChild(plotId)

	if structureFolder == nil then
		return
	end

	for _, child in structureFolder:GetChildren() do
		if child:GetAttribute("StructureId") == structureId then
			child:Destroy()
			return
		end
	end
end

local function clearPlayerStructuresOnPlot(plotId: string, ownerUserId: number)
	local plotFolder = getStructuresFolder(plotId)

	for _, child in plotFolder:GetChildren() do
		if child:GetAttribute("OwnerUserId") == ownerUserId then
			child:Destroy()
		end
	end
end

local function respawnStructures(player: Player, data: PlayerProfileTypes.PlayerProfile)
	if data.camp.plotId == nil then
		return
	end

	local plotId = data.camp.plotId :: string
	clearPlayerStructuresOnPlot(plotId, player.UserId)

	for _, structure in data.camp.structures do
		spawnStructureWorld(player, plotId, structure)
	end
end

local function assignPlot(player: Player, data: PlayerProfileTypes.PlayerProfile): boolean
	local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation")
	local origin = if spawnLocation ~= nil then spawnLocation.Position else Vector3.zero

	local bestPlotId: string? = nil
	local bestDistance = math.huge

	for plotId, plotPart in plotParts do
		if plotOccupants[plotId] == nil then
			local distance = (plotPart.Position - origin).Magnitude

			if distance < bestDistance then
				bestDistance = distance
				bestPlotId = plotId
			end
		end
	end

	if bestPlotId == nil then
		Logger.warn("CampService", `No free plots for {player.Name}`)
		return false
	end

	data.camp.plotId = bestPlotId
	plotOccupants[bestPlotId] = player.UserId
	assignedPlotThisSession[player.UserId] = true
	GameEvents.fireCampPlotAssigned(player, bestPlotId)
	Logger.info("CampService", `Assigned {bestPlotId} to {player.Name}`)
	return true
end

local function recalculateCampLevel(player: Player, data: PlayerProfileTypes.PlayerProfile)
	local oldLevel = data.camp.level
	local hasCampfire = countBlueprintPlaced(data.camp.structures, "bp_campfire") >= 1
	local hasChest = countBlueprintPlaced(data.camp.structures, "bp_chest") >= 1
	local hasCraftTable = countBlueprintPlaced(data.camp.structures, "bp_craft_table") >= 1

	if hasCampfire and hasChest and hasCraftTable and data.camp.level < 1 then
		data.camp.level = 1
	end

	if data.camp.level ~= oldLevel then
		GameEvents.fireCampLevelChanged(player, data.camp.level, oldLevel)
	end
end

local function invokeBehaviorHook(hook: ((...any) -> ())?, ...: any): boolean
	if hook == nil then
		return true
	end

	local ok, hookError = pcall(hook, ...)

	if not ok then
		Logger.warn("CampService", `Structure behavior hook failed: {hookError}`)
		return false
	end

	return true
end

local function grantRefund(player: Player, data: PlayerProfileTypes.PlayerProfile, blueprintId: string)
	local definition = StructuresConstants.get(blueprintId)

	if definition == nil or definition.recipeId == nil then
		return
	end

	local recipe = Recipes.get(definition.recipeId)

	if recipe == nil then
		return
	end

	for _, input in recipe.inputs do
		local refundQuantity = math.ceil(input.quantity * 0.5)

		if refundQuantity > 0 then
			local granted = InventoryService.grantItem(player, input.itemId, refundQuantity)

			if not granted then
				Logger.warn("CampService", `Refund skipped for {input.itemId} — bag full`)
			end
		end
	end
end

local function placeStructure(player: Player, request: unknown)
	if type(request) ~= "table" then
		return
	end

	local payload = request :: { [string]: unknown }
	local blueprintId = payload.blueprintId
	local position = payload.position
	local rotation = payload.rotation

	if type(blueprintId) ~= "string" or typeof(position) ~= "Vector3" or type(rotation) ~= "number" then
		return
	end

	if not CampConstants.isValidRotation(rotation) then
		firePlaceResult(player, { success = false, reasonKey = "camp.error.invalid_rotation" })
		return
	end

	local definition = StructuresConstants.get(blueprintId)

	if definition == nil then
		firePlaceResult(player, { success = false, reasonKey = "camp.error.invalid_blueprint" })
		return
	end

	local data = PlayerDataService:GetData(player)

	if data == nil or data.camp.plotId == nil then
		firePlaceResult(player, { success = false, reasonKey = "camp.error.no_plot" })
		return
	end

	if #data.camp.structures >= CampConstants.MAX_STRUCTURES_LEVEL_0_1 then
		firePlaceResult(player, { success = false, reasonKey = "camp.error.structure_cap" })
		return
	end

	if InventoryService.countItem(data, blueprintId) < 1 then
		firePlaceResult(player, { success = false, reasonKey = "camp.error.missing_blueprint" })
		return
	end

	local plotPart = plotParts[data.camp.plotId]

	if plotPart == nil then
		firePlaceResult(player, { success = false, reasonKey = "camp.error.no_plot" })
		return
	end

	local isValid, reasonKey, snappedPosition = validateStructureFootprint(
		data,
		plotPart,
		blueprintId,
		position,
		rotation,
		nil
	)

	if not isValid or snappedPosition == nil then
		firePlaceResult(player, { success = false, reasonKey = reasonKey or "camp.error.out_of_bounds" })
		return
	end

	local plotId = data.camp.plotId :: string
	local behavior = StructureBehaviorRegistry.get(blueprintId)

	if behavior ~= nil and behavior.validatePlacement ~= nil then
		local structureIdPreview = "pending"
		local previewStructure: CampTypes.CampStructure = {
			structureId = structureIdPreview,
			blueprintId = blueprintId,
			position = CampProximity.serializeVector3(snappedPosition),
			rotation = rotation,
			hp = definition.maxHp,
		}
		local placementOk, placementReason = behavior.validatePlacement({
			player = player,
			data = data,
			structure = previewStructure,
			plotId = plotId,
			position = snappedPosition,
			rotation = rotation,
		})

		if not placementOk then
			firePlaceResult(player, { success = false, reasonKey = placementReason or "camp.error.out_of_bounds" })
			return
		end
	end

	if not InventoryService.removeItems(player, data, { { itemId = blueprintId, quantity = 1 } }) then
		firePlaceResult(player, { success = false, reasonKey = "camp.error.missing_blueprint" })
		return
	end

	local structureId = HttpService:GenerateGUID(false)
	local structure: CampTypes.CampStructure = {
		structureId = structureId,
		blueprintId = blueprintId,
		position = CampProximity.serializeVector3(snappedPosition),
		rotation = rotation,
		hp = definition.maxHp,
	}

	table.insert(data.camp.structures, structure)

	if behavior ~= nil then
		if not invokeBehaviorHook(behavior.onPlace, {
			player = player,
			data = data,
			structure = structure,
			plotId = plotId,
		}) then
			table.remove(data.camp.structures, #data.camp.structures)
			InventoryService.grantItem(player, blueprintId, 1)
			firePlaceResult(player, { success = false, reasonKey = "camp.error.place_failed" })
			return
		end
	end

	spawnStructureWorld(player, plotId, structure)
	recalculateCampLevel(player, data)
	syncCamp(player, data)

	firePlaceResult(player, {
		success = true,
		reasonKey = "camp.success.placed",
		structureId = structureId,
	})
end

local function demolishStructure(player: Player, structureId: unknown)
	if type(structureId) ~= "string" then
		return
	end

	local data = PlayerDataService:GetData(player)

	if data == nil or data.camp.plotId == nil then
		fireDemolishResult(player, { success = false, reasonKey = "camp.error.no_plot" })
		return
	end

	local removedIndex: number? = nil
	local removedStructure: CampTypes.CampStructure? = nil

	for index, structure in data.camp.structures do
		if structure.structureId == structureId then
			removedIndex = index
			removedStructure = structure
			break
		end
	end

	if removedStructure == nil or removedIndex == nil then
		fireDemolishResult(player, { success = false, reasonKey = "camp.error.not_found" })
		return
	end

	local plotId = data.camp.plotId :: string
	local behavior = StructureBehaviorRegistry.get(removedStructure.blueprintId)

	if behavior ~= nil then
		invokeBehaviorHook(behavior.onDemolish, {
			player = player,
			data = data,
			structure = removedStructure,
			plotId = plotId,
		})
	end

	table.remove(data.camp.structures, removedIndex)
	removeStructureWorld(plotId, structureId)
	grantRefund(player, data, removedStructure.blueprintId)
	syncCamp(player, data)

	fireDemolishResult(player, { success = true, reasonKey = "camp.success.demolished" })
end

local function moveStructure(player: Player, request: unknown)
	if type(request) ~= "table" then
		return
	end

	local payload = request :: { [string]: unknown }
	local structureId = payload.structureId
	local position = payload.position
	local rotation = payload.rotation

	if type(structureId) ~= "string" or typeof(position) ~= "Vector3" or type(rotation) ~= "number" then
		return
	end

	if not CampConstants.isValidRotation(rotation) then
		fireMoveResult(player, { success = false, reasonKey = "camp.error.invalid_rotation" })
		return
	end

	local data = PlayerDataService:GetData(player)

	if data == nil or data.camp.plotId == nil then
		fireMoveResult(player, { success = false, reasonKey = "camp.error.no_plot" })
		return
	end

	local structure = findStructure(data, structureId)

	if structure == nil then
		fireMoveResult(player, { success = false, reasonKey = "camp.error.not_found" })
		return
	end

	local plotPart = plotParts[data.camp.plotId]

	if plotPart == nil then
		fireMoveResult(player, { success = false, reasonKey = "camp.error.no_plot" })
		return
	end

	local isValid, reasonKey, snappedPosition = validateStructureFootprint(
		data,
		plotPart,
		structure.blueprintId,
		position,
		rotation,
		structureId
	)

	if not isValid or snappedPosition == nil then
		fireMoveResult(player, { success = false, reasonKey = reasonKey or "camp.error.overlap" })
		return
	end

	structure.position = CampProximity.serializeVector3(snappedPosition)
	structure.rotation = rotation

	removeStructureWorld(data.camp.plotId, structureId)
	spawnStructureWorld(player, data.camp.plotId, structure)
	syncCamp(player, data)

	fireMoveResult(player, { success = true, reasonKey = "camp.success.moved" })
end

local function releasePlot(player: Player)
	local data = PlayerDataService:GetData(player)

	if data == nil or data.camp.plotId == nil then
		return
	end

	local plotId = data.camp.plotId

	if plotOccupants[plotId] == player.UserId then
		plotOccupants[plotId] = nil
	end
end

local function onPlayerCampReady(player: Player)
	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	CampRepository.normalize(data.camp)

	if data.camp.plotId ~= nil then
		plotOccupants[data.camp.plotId] = player.UserId
	end

	if data.camp.plotId == nil then
		assignPlot(player, data)
	end

	respawnStructures(player, data)
	syncCamp(player, data)
end

function CampService:Init()
	local trove = self:GetTrove()

	FeatureBootstrap.bindCampSync(syncCamp)
	FeatureBootstrap.bindRemotes(function(signal, handler)
		trove:Connect(signal, handler)
	end)
	FeatureBootstrap.wireCampEvents(function(player: Player, plotId: string)
		CampService.teleportPlayerToPlot(player, plotId)
	end)

	trove:Connect(Networking.getEvent("PlaceStructureEvent").OnServerEvent, placeStructure)
	trove:Connect(Networking.getEvent("DemolishStructureEvent").OnServerEvent, demolishStructure)
	trove:Connect(Networking.getEvent("MoveStructureEvent").OnServerEvent, moveStructure)
	trove:Connect(Players.PlayerRemoving, releasePlot)
end

function CampService:Start()
	ensureCampHub()

	local trove = self:GetTrove()

	trove:Connect(Players.PlayerAdded, function(player: Player)
		task.spawn(function()
			for _ = 1, 20 do
				if PlayerDataService:GetData(player) ~= nil then
					onPlayerCampReady(player)
					return
				end

				task.wait(0.25)
			end
		end)
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerCampReady, player)
	end

	Logger.info("CampService", "Camp is active")
end

return CampService
