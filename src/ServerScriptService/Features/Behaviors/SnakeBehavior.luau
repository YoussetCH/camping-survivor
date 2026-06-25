--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FaunaConstants = require(ReplicatedStorage.Shared.Constants.FaunaConstants)
local FaunaRegistry = require(ServerScriptService.Features.FaunaRegistry)
local SnakeBehaviorBridge = require(script.Parent.SnakeBehaviorBridge)
local SnakeDefinition = require(ReplicatedStorage.Shared.Features.Snake.SnakeDefinition)
local SnakeModel = require(ReplicatedStorage.Shared.Features.Snake.SnakeModel)

local function onAttackTelegraphStart(model: Model, definition)
	model:SetAttribute(FaunaConstants.SNAKE_ATTACK_STARTED_AT_ATTRIBUTE, workspace:GetServerTimeNow())
	model:SetAttribute(
		FaunaConstants.SNAKE_ATTACK_DURATION_ATTRIBUTE,
		definition.attackAnimationSeconds or FaunaConstants.SNAKE_ATTACK_TOTAL_SECONDS
	)
	SnakeModel.playAttackSound(model)
end

local function onAttackTelegraphEnd(model: Model)
	model:SetAttribute(FaunaConstants.SNAKE_ATTACK_STARTED_AT_ATTRIBUTE, nil)
	model:SetAttribute(FaunaConstants.SNAKE_ATTACK_DURATION_ATTRIBUTE, nil)
end

FaunaRegistry.register({
	speciesId = SnakeDefinition.speciesId,
	definition = SnakeDefinition,
	buildModel = SnakeModel.build,
	onReveal = SnakeModel.reveal,
	onAttackTelegraphStart = onAttackTelegraphStart,
	onAttackTelegraphEnd = onAttackTelegraphEnd,
})

SnakeBehaviorBridge.init()

return {}
