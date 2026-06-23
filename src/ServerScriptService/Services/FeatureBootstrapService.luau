--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local BaseService = require(ServerScriptService.Kernel.BaseService)
local FeatureBootstrap = require(ServerScriptService.Features.FeatureBootstrap)
local Logger = require(game:GetService("ReplicatedStorage").Shared.Utilities.Logger)

local FeatureBootstrapService = BaseService.new("FeatureBootstrapService")

function FeatureBootstrapService:Init()
	FeatureBootstrap.init()
	Logger.info("FeatureBootstrapService", "Feature modules registered")
end

function FeatureBootstrapService:Start()
end

return FeatureBootstrapService
