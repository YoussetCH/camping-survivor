--!strict

export type WorldPhase = "dawn" | "day" | "dusk" | "night"

export type WorldSnapshot = {
	phase: WorldPhase,
	cycleProgress: number,
	serverTime: number,
}

export type HarvestOutput = {
	itemId: string,
	quantity: number,
}

export type HarvestResultPayload = {
	success: boolean,
	reasonKey: string?,
	granted: { HarvestOutput }?,
}

return {}
