--!strict

export type GameEventsModule = {
	CampPlotAssigned: BindableEvent,
	CampLevelChanged: BindableEvent,
	RequestPlotTeleport: BindableEvent,
	fireCampPlotAssigned: (player: Player, plotId: string) -> (),
	fireCampLevelChanged: (player: Player, newLevel: number, oldLevel: number) -> (),
	fireRequestPlotTeleport: (player: Player, plotId: string) -> (),
}

local campPlotAssigned = Instance.new("BindableEvent")
local campLevelChanged = Instance.new("BindableEvent")
local requestPlotTeleport = Instance.new("BindableEvent")

local GameEvents: GameEventsModule = {
	CampPlotAssigned = campPlotAssigned,
	CampLevelChanged = campLevelChanged,
	RequestPlotTeleport = requestPlotTeleport,
	fireCampPlotAssigned = function(player: Player, plotId: string)
		campPlotAssigned:Fire(player, plotId)
	end,
	fireCampLevelChanged = function(player: Player, newLevel: number, oldLevel: number)
		campLevelChanged:Fire(player, newLevel, oldLevel)
	end,
	fireRequestPlotTeleport = function(player: Player, plotId: string)
		requestPlotTeleport:Fire(player, plotId)
	end,
}

return GameEvents
