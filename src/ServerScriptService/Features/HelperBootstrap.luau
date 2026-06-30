--!strict

export type HelperBootstrapModule = {
	init: () -> (),
}

local initialized = false

local HelperBootstrap: HelperBootstrapModule = {
	init = function()
		if initialized then
			return
		end

		initialized = true
		require(script.Parent.Behaviors.LumberjackBehavior)
	end,
}

return HelperBootstrap
