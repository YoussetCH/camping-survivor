--!strict

export type QuestObjectiveKind =
	"gather"
	| "craft"
	| "place_structure"
	| "survive_cold"
	| "defeat_fauna"
	| "open_ui"

export type QuestObjectiveProgress = {
	kind: QuestObjectiveKind,
	current: number,
	target: number,
	itemId: string?,
	recipeId: string?,
	outputItemId: string?,
	blueprintId: string?,
	speciesId: string?,
	panelId: string?,
}

export type QuestState = {
	status: "active" | "completed",
	objectives: { QuestObjectiveProgress },
	startedAt: number,
	completedAt: number?,
}

export type QuestProgress = {
	[string]: QuestState,
}

export type QuestSnapshot = {
	progress: QuestProgress,
	tutorialCompleted: boolean,
	trackedQuestId: string?,
	activeQuestIds: { string },
	stats: {
		level: number,
		xp: number,
	},
	lastCompletedQuestId: string?,
}

return {}
