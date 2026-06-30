--!strict

local SurvivalTypes = require(script.Parent.Survival)

export type HelperMode = "work" | "shelter"

export type HelperState = {
	helperTypeId: string,
	nameKey: string,
	hunger: number,
	health: number,
	statusEffects: { SurvivalTypes.StatusEffect },
	mode: HelperMode,
	recruitedAt: number,
	weakSince: number?,
}

export type HelperProgress = {
	[string]: HelperState,
}

export type HelperSnapshot = {
	helpers: HelperProgress,
	lostHelpers: { string },
	maxHelpers: number,
	lastRemovedInstanceId: string?,
}

export type HelperWorkContext = {
	player: Player,
	data: any,
	helperInstanceId: string,
	helperState: HelperState,
}

export type HelperTypeDefinition = {
	helperTypeId: string,
	nameKey: string,
	workIntervalSeconds: number,
	biomeOrigin: string,
}

export type HelperBehaviorModule = {
	helperTypeId: string,
	definition: HelperTypeDefinition,
	buildModel: (groundPosition: Vector3, options: { escort: boolean }?) -> Model,
	canWork: (context: HelperWorkContext) -> boolean,
	onWorkTick: (context: HelperWorkContext) -> boolean,
}

return {}
