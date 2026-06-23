--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FaunaRegistry = require(ServerScriptService.Features.FaunaRegistry)
local SnakeDefinition = require(ReplicatedStorage.Shared.Features.Snake.SnakeDefinition)
local SnakeModel = require(ReplicatedStorage.Shared.Features.Snake.SnakeModel)

FaunaRegistry.register({
	speciesId = SnakeDefinition.speciesId,
	definition = SnakeDefinition,
	buildModel = SnakeModel.build,
	onReveal = SnakeModel.reveal,
})

return {}
