--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)

export type LoadedController = {
	Name: string,
	Init: (self: LoadedController) -> (),
	Start: (self: LoadedController) -> (),
	Destroy: (self: LoadedController) -> ()?,
}

local ClientKernel = {}

local INIT_ORDER = {
	"ClientSyncController",
	"LocalizationController",
	"SurvivalHUDController",
	"InventoryHUDController",
	"CraftingHUDController",
	"BuildingController",
	"ChestController",
	"UIController",
}

local loadedControllers: { LoadedController } = {}
local started = false
local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts") :: PlayerScripts

local function getInitPriority(controllerName: string): number
	for index, name in INIT_ORDER do
		if name == controllerName then
			return index
		end
	end

	return #INIT_ORDER + 1
end

local function getControllerModules(): { ModuleScript }
	local controllersFolder = playerScripts:WaitForChild("Controllers") :: Folder
	local modules: { ModuleScript } = {}

	for _, child in controllersFolder:GetChildren() do
		if child:IsA("ModuleScript") then
			table.insert(modules, child)
		end
	end

	table.sort(modules, function(left, right)
		return left.Name < right.Name
	end)

	return modules
end

function ClientKernel.loadControllers(): { LoadedController }
	if #loadedControllers > 0 then
		return loadedControllers
	end

	for _, moduleScript in getControllerModules() do
		local loadOk, controllerModule = pcall(require, moduleScript)

		if not loadOk then
			Logger.error("ClientKernel", `Failed to load controller "{moduleScript.Name}": {controllerModule}`)
			continue
		end

		if type(controllerModule) ~= "table" or type(controllerModule.Name) ~= "string" then
			Logger.error("ClientKernel", `Controller module "{moduleScript.Name}" must export a table with Name`)
			continue
		end

		local alreadyLoaded = false

		for _, existing in loadedControllers do
			if existing.Name == controllerModule.Name then
				alreadyLoaded = true
				Logger.warn("ClientKernel", `Skipping duplicate controller module: {controllerModule.Name}`)
				break
			end
		end

		if alreadyLoaded then
			continue
		end

		table.insert(loadedControllers, controllerModule :: LoadedController)
		Logger.info("ClientKernel", `Loaded controller: {controllerModule.Name}`)
	end

	return loadedControllers
end

function ClientKernel.initControllers(controllers: { LoadedController })
	local orderedControllers = table.clone(controllers)

	table.sort(orderedControllers, function(left, right)
		local leftPriority = getInitPriority(left.Name)
		local rightPriority = getInitPriority(right.Name)

		if leftPriority ~= rightPriority then
			return leftPriority < rightPriority
		end

		return left.Name < right.Name
	end)

	for _, controller in orderedControllers do
		local initOk, initError = pcall(function()
			controller:Init()
		end)

		if initOk then
			Logger.info("ClientKernel", `Initialized controller: {controller.Name}`)
		else
			Logger.error("ClientKernel", `Failed to init controller "{controller.Name}": {initError}`)
		end
	end
end

function ClientKernel.startControllers(controllers: { LoadedController })
	if started then
		return
	end

	started = true

	for _, controller in controllers do
		controller:Start()
		Logger.info("ClientKernel", `Started controller: {controller.Name}`)
	end
end

function ClientKernel.destroyControllers(controllers: { LoadedController })
	for index = #controllers, 1, -1 do
		local controller = controllers[index]
		local destroy = controller.Destroy

		if destroy ~= nil then
			destroy(controller)
			Logger.info("ClientKernel", `Destroyed controller: {controller.Name}`)
		end
	end

	table.clear(loadedControllers)
	started = false
end

function ClientKernel.getController(name: string): LoadedController?
	for _, controller in loadedControllers do
		if controller.Name == name then
			return controller
		end
	end

	return nil
end

return ClientKernel
