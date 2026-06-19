--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.Constants.Remotes)

local Networking = {}

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local eventsFolder = remotesFolder:WaitForChild("Events") :: Folder
local functionsFolder = remotesFolder:WaitForChild("Functions") :: Folder

function Networking.getEventsFolder(): Folder
	return eventsFolder
end

function Networking.getFunctionsFolder(): Folder
	return functionsFolder
end

function Networking.getEvent(name: string): RemoteEvent
	local remote = eventsFolder:WaitForChild(name, 30)

	if remote == nil then
		error(`RemoteEvent "{name}" was not found after 30s`, 2)
	end

	return remote :: RemoteEvent
end

function Networking.getFunction(name: string): RemoteFunction
	local remote = functionsFolder:WaitForChild(name, 30)

	if remote == nil then
		error(`RemoteFunction "{name}" was not found after 30s`, 2)
	end

	return remote :: RemoteFunction
end

function Networking.getEventNames(): { string }
	return table.clone(RemoteNames.Events)
end

function Networking.getFunctionNames(): { string }
	return table.clone(RemoteNames.Functions)
end

return Networking
