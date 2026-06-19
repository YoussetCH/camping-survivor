--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseService = require(script.Parent.BaseService)
local RemoteNames = require(ReplicatedStorage.Shared.Constants.Remotes)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)

local NetworkingService = BaseService.new("NetworkingService")

local function ensureRemoteEvent(parent: Folder, name: string): RemoteEvent
	local existing = parent:FindFirstChild(name)

	if existing ~= nil then
		return existing :: RemoteEvent
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent

	return remote
end

local function ensureRemoteFunction(parent: Folder, name: string): RemoteFunction
	local existing = parent:FindFirstChild(name)

	if existing ~= nil then
		return existing :: RemoteFunction
	end

	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = parent

	return remote
end

function NetworkingService:Init()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	local eventsFolder = remotesFolder:WaitForChild("Events") :: Folder
	local functionsFolder = remotesFolder:WaitForChild("Functions") :: Folder

	for _, eventName in RemoteNames.Events do
		ensureRemoteEvent(eventsFolder, eventName)
		Logger.debug("NetworkingService", `Registered RemoteEvent: {eventName}`)
	end

	for _, functionName in RemoteNames.Functions do
		ensureRemoteFunction(functionsFolder, functionName)
		Logger.debug("NetworkingService", `Registered RemoteFunction: {functionName}`)
	end
end

return NetworkingService
