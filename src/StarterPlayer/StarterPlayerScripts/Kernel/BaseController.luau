--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)

local LifecycleTypes = require(ReplicatedStorage.Shared.Types.Lifecycle)

export type Controller = LifecycleTypes.ControllerLifecycle & {
	_trove: Trove.Trove,
	GetTrove: (self: Controller) -> Trove.Trove,
}

local BaseController = {}
BaseController.__index = BaseController

function BaseController.new(name: string): Controller
	local self = setmetatable({
		Name = name,
		_trove = Trove.new(),
	}, BaseController)

	return self :: Controller
end

function BaseController:GetTrove(): Trove.Trove
	return self._trove
end

function BaseController:Init()
end

function BaseController:Start()
end

function BaseController:Destroy()
	self._trove:Destroy()
end

return BaseController
