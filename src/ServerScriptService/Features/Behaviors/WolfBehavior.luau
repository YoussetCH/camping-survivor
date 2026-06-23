--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FaunaRegistry = require(ServerScriptService.Features.FaunaRegistry)
local WolfDefinition = require(ReplicatedStorage.Shared.Features.Wolf.WolfDefinition)
local WolfModel = require(ReplicatedStorage.Shared.Features.Wolf.WolfModel)

FaunaRegistry.register({
	speciesId = WolfDefinition.speciesId,
	definition = WolfDefinition,
	buildModel = WolfModel.build,
})

return {}
