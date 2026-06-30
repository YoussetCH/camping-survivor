--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local GameEvents = require(script.Parent.GameEvents)
local ChestBehavior = require(script.Parent.Behaviors.ChestBehavior)
local CraftingService = require(ServerScriptService.Services.CraftingService)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)

export type FeatureBootstrapModule = {
	init: () -> (),
	bindCampSync: (syncCamp: (player: Player, data: any) -> ()) -> (),
	bindRemotes: (connect: (signal: RBXScriptSignal, handler: (Player, ...any) -> ()) -> ()) -> (),
	wireCampEvents: (teleportToPlot: (player: Player, plotId: string) -> ()) -> (),
}

local initialized = false

local FeatureBootstrap: FeatureBootstrapModule = {
	init = function()
		if initialized then
			return
		end

		initialized = true

		require(script.Parent.Behaviors.CampfireBehavior)
		require(script.Parent.Behaviors.CraftTableBehavior)
		require(script.Parent.Behaviors.ChestBehavior)

		require(script.Parent.FaunaBootstrap).init()
		require(script.Parent.HelperBootstrap).init()
	end,
	bindCampSync = function(syncCamp)
		ChestBehavior.setSyncCamp(syncCamp)
	end,
	bindRemotes = function(connect)
		ChestBehavior.bindRemotes(connect)
	end,
	wireCampEvents = function(teleportToPlot)
		GameEvents.CampPlotAssigned.Event:Connect(function(player: Player, plotId: string)
			teleportToPlot(player, plotId)
		end)

		GameEvents.RequestPlotTeleport.Event:Connect(function(player: Player, plotId: string)
			teleportToPlot(player, plotId)
		end)

		GameEvents.CampLevelChanged.Event:Connect(function(player: Player, newLevel: number, oldLevel: number)
			if newLevel >= 1 and oldLevel < 1 then
				local data = PlayerDataService:GetData(player)

				if data ~= nil then
					CraftingService.ensureStarterRecipesUnlocked(player, data)
				end
			end
		end)
	end,
}

return FeatureBootstrap
