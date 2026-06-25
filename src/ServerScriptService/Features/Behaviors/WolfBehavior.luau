--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FaunaConstants = require(ReplicatedStorage.Shared.Constants.FaunaConstants)
local FaunaRegistry = require(ServerScriptService.Features.FaunaRegistry)
local WolfDefinition = require(ReplicatedStorage.Shared.Features.Wolf.WolfDefinition)
local WolfModel = require(ReplicatedStorage.Shared.Features.Wolf.WolfModel)

local function onAttackTelegraphStart(model: Model, definition)
	model:SetAttribute(FaunaConstants.WOLF_ATTACK_STARTED_AT_ATTRIBUTE, workspace:GetServerTimeNow())
	model:SetAttribute(
		FaunaConstants.WOLF_ATTACK_DURATION_ATTRIBUTE,
		definition.attackAnimationSeconds or definition.attackWindupSeconds or 0.45
	)
	WolfModel.playGrowlSound(model)
end

local function onAttackTelegraphEnd(model: Model)
	model:SetAttribute(FaunaConstants.WOLF_ATTACK_STARTED_AT_ATTRIBUTE, nil)
	model:SetAttribute(FaunaConstants.WOLF_ATTACK_DURATION_ATTRIBUTE, nil)
end

FaunaRegistry.register({
	speciesId = WolfDefinition.speciesId,
	definition = WolfDefinition,
	buildModel = WolfModel.build,
	onAttackTelegraphStart = onAttackTelegraphStart,
	onAttackTelegraphEnd = onAttackTelegraphEnd,
})

return {}
