--!strict

export type FaunaBootstrapModule = {
	init: () -> (),
}

local initialized = false

local FaunaBootstrap: FaunaBootstrapModule = {
	init = function()
		if initialized then
			return
		end

		initialized = true

		require(script.Parent.Behaviors.WolfBehavior)
		require(script.Parent.Behaviors.SnakeBehavior)
	end,
}

return FaunaBootstrap
