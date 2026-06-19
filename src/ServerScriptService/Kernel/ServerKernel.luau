--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Logger = require(game:GetService("ReplicatedStorage").Shared.Utilities.Logger)

export type LoadedService = {
	Name: string,
	Init: (self: LoadedService) -> (),
	Start: (self: LoadedService) -> (),
	Destroy: (self: LoadedService) -> ()?,
}

local ServerKernel = {}

local loadedServices: { LoadedService } = {}
local started = false

local function getServiceModules(): { ModuleScript }
	local servicesFolder = ServerScriptService:WaitForChild("Services") :: Folder
	local modules: { ModuleScript } = {}

	for _, child in servicesFolder:GetChildren() do
		if child:IsA("ModuleScript") then
			table.insert(modules, child)
		end
	end

	table.sort(modules, function(left, right)
		return left.Name < right.Name
	end)

	return modules
end

function ServerKernel.loadServices(): { LoadedService }
	if #loadedServices > 0 then
		return loadedServices
	end

	for _, moduleScript in getServiceModules() do
		local serviceModule = require(moduleScript)

		if type(serviceModule) ~= "table" or type(serviceModule.Name) ~= "string" then
			error(`Service module "{moduleScript.Name}" must export a table with Name`, 2)
		end

		table.insert(loadedServices, serviceModule :: LoadedService)
		Logger.info("ServerKernel", `Loaded service: {serviceModule.Name}`)
	end

	return loadedServices
end

function ServerKernel.initServices(services: { LoadedService })
	for _, service in services do
		service:Init()
		Logger.info("ServerKernel", `Initialized service: {service.Name}`)
	end
end

function ServerKernel.startServices(services: { LoadedService })
	if started then
		return
	end

	started = true

	for _, service in services do
		service:Start()
		Logger.info("ServerKernel", `Started service: {service.Name}`)
	end
end

function ServerKernel.destroyServices(services: { LoadedService })
	for index = #services, 1, -1 do
		local service = services[index]
		local destroy = service.Destroy

		if destroy ~= nil then
			destroy(service)
			Logger.info("ServerKernel", `Destroyed service: {service.Name}`)
		end
	end

	table.clear(loadedServices)
	started = false
end

function ServerKernel.getService(name: string): LoadedService?
	for _, service in loadedServices do
		if service.Name == name then
			return service
		end
	end

	return nil
end

return ServerKernel
