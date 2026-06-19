--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)

local LifecycleTypes = require(ReplicatedStorage.Shared.Types.Lifecycle)

export type Service = LifecycleTypes.ServiceLifecycle & {
	_trove: Trove.Trove,
	GetTrove: (self: Service) -> Trove.Trove,
}

local BaseService = {}
BaseService.__index = BaseService

function BaseService.new(name: string): Service
	local self = setmetatable({
		Name = name,
		_trove = Trove.new(),
	}, BaseService)

	return self :: Service
end

function BaseService:GetTrove(): Trove.Trove
	return self._trove
end

function BaseService:Init()
end

function BaseService:Start()
end

function BaseService:Destroy()
	self._trove:Destroy()
end

return BaseService
