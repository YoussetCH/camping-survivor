--!strict

export type ServiceLifecycle = {
	Name: string,
	Init: (self: ServiceLifecycle) -> (),
	Start: (self: ServiceLifecycle) -> (),
	Destroy: (self: ServiceLifecycle) -> ()?,
}

export type ControllerLifecycle = {
	Name: string,
	Init: (self: ControllerLifecycle) -> (),
	Start: (self: ControllerLifecycle) -> (),
	Destroy: (self: ControllerLifecycle) -> ()?,
}

return {}
