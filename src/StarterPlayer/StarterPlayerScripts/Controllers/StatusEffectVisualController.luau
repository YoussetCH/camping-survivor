--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BaseController = require(script.Parent.Parent.Kernel.BaseController)
local ClientKernel = require(script.Parent.Parent.Kernel.ClientKernel)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local SurvivalTypes = require(ReplicatedStorage.Shared.Types.Survival)

local StatusEffectVisualController = BaseController.new("StatusEffectVisualController")

local HIGHLIGHT_NAME = "StatusEffectHighlight"

type StatusVisualStyle = {
	fillColor: Color3,
	outlineColor: Color3,
}

local STATUS_VISUALS: { [string]: StatusVisualStyle } = {
	poison = {
		fillColor = Color3.fromRGB(70, 210, 90),
		outlineColor = Color3.fromRGB(35, 150, 55),
	},
	bleeding = {
		fillColor = Color3.fromRGB(220, 60, 60),
		outlineColor = Color3.fromRGB(160, 30, 30),
	},
	infection = {
		fillColor = Color3.fromRGB(230, 140, 50),
		outlineColor = Color3.fromRGB(180, 90, 20),
	},
}

local EFFECT_PRIORITY = { "poison", "bleeding", "infection" }

local boundCharacter: Model? = nil
local highlight: Highlight? = nil
local activeEffectId: string? = nil
local pulsePhase = 0

local function hasEffect(statusEffects: { SurvivalTypes.StatusEffect }, effectId: string): boolean
	for _, effect in statusEffects do
		if effect.id == effectId then
			return true
		end
	end

	return false
end

local function resolvePrimaryEffect(statusEffects: { SurvivalTypes.StatusEffect }): string?
	for _, effectId in EFFECT_PRIORITY do
		if hasEffect(statusEffects, effectId) then
			return effectId
		end
	end

	return nil
end

local function clearHighlight()
	if boundCharacter ~= nil then
		local existing = boundCharacter:FindFirstChild(HIGHLIGHT_NAME)

		if existing ~= nil then
			existing:Destroy()
		end
	end

	highlight = nil
	activeEffectId = nil
end

local function ensureHighlight(character: Model): Highlight
	local existing = character:FindFirstChild(HIGHLIGHT_NAME)

	if existing ~= nil and existing:IsA("Highlight") then
		return existing
	end

	if existing ~= nil then
		existing:Destroy()
	end

	local nextHighlight = Instance.new("Highlight")
	nextHighlight.Name = HIGHLIGHT_NAME
	nextHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	nextHighlight.Parent = character

	return nextHighlight
end

local function applyEffectVisual(character: Model, effectId: string?)
	if effectId == nil then
		clearHighlight()
		return
	end

	local style = STATUS_VISUALS[effectId]

	if style == nil then
		clearHighlight()
		return
	end

	highlight = ensureHighlight(character)
	highlight.FillColor = style.fillColor
	highlight.OutlineColor = style.outlineColor
	highlight.FillTransparency = 0.55
	highlight.OutlineTransparency = 0.15
	activeEffectId = effectId
end

local function refreshFromSnapshot(snapshot: SurvivalTypes.SurvivalSnapshot?)
	local character = boundCharacter

	if character == nil or snapshot == nil then
		clearHighlight()
		return
	end

	applyEffectVisual(character, resolvePrimaryEffect(snapshot.statusEffects))
end

local function bindCharacter(character: Model)
	boundCharacter = character
	pulsePhase = 0

	local syncController = ClientKernel.getController("ClientSyncController")
	local snapshot: SurvivalTypes.SurvivalSnapshot? = nil

	if syncController ~= nil then
		snapshot = (syncController :: any):GetSurvival()
	end

	refreshFromSnapshot(snapshot)
end

function StatusEffectVisualController:Init()
	local trove = self:GetTrove()
	local player = Players.LocalPlayer

	trove:Connect(Networking.getEvent("SurvivalUpdatedEvent").OnClientEvent, function(snapshot: SurvivalTypes.SurvivalSnapshot)
		refreshFromSnapshot(snapshot)
	end)

	trove:Connect(player.CharacterAdded, bindCharacter)

	trove:Connect(player.CharacterRemoving, function()
		clearHighlight()
		boundCharacter = nil
	end)

	if player.Character ~= nil then
		task.defer(bindCharacter, player.Character)
	end
end

function StatusEffectVisualController:Start()
	local trove = self:GetTrove()

	trove:Connect(RunService.Heartbeat, function(deltaTime: number)
		if highlight == nil or activeEffectId == nil then
			return
		end

		pulsePhase += deltaTime * 3
		highlight.FillTransparency = 0.45 + math.sin(pulsePhase) * 0.12
	end)
end

return StatusEffectVisualController
