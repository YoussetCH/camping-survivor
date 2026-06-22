--!strict

local InventoryTypes = require(script.Parent.Inventory)

export type SerializedVector3 = {
	x: number,
	y: number,
	z: number,
}

export type CampStructure = {
	structureId: string,
	blueprintId: string,
	position: SerializedVector3,
	rotation: number,
	hp: number?,
}

export type CampChestSlots = InventoryTypes.BagSlots

export type CampData = {
	plotId: string?,
	level: number,
	structures: { CampStructure },
	chests: { [string]: CampChestSlots },
}

export type CampSnapshot = CampData

export type PlaceStructureRequest = {
	blueprintId: string,
	position: Vector3,
	rotation: number,
}

export type PlaceStructureResult = {
	success: boolean,
	reasonKey: string?,
	structureId: string?,
}

export type DemolishStructureResult = {
	success: boolean,
	reasonKey: string?,
}

export type MoveStructureRequest = {
	structureId: string,
	position: Vector3,
	rotation: number,
}

export type MoveStructureResult = {
	success: boolean,
	reasonKey: string?,
}

export type TransferDirection = "toChest" | "toBag"

export type TransferItemRequest = {
	direction: TransferDirection,
	chestStructureId: string,
	bagSlotKey: string?,
	chestSlotKey: string?,
}

return {}
