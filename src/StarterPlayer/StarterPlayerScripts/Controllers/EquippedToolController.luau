--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseController = require(script.Parent.Parent.Kernel.BaseController)
local ClientKernel = require(script.Parent.Parent.Kernel.ClientKernel)
local Items = require(ReplicatedStorage.Shared.Constants.Items)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local EquippedToolModelFactory = require(ReplicatedStorage.Shared.Tools.EquippedToolModelFactory)
local EquippedToolVisuals = require(ReplicatedStorage.Shared.Tools.EquippedToolVisuals)
local InventoryTypes = require(ReplicatedStorage.Shared.Types.Inventory)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)

local EquippedToolController = BaseController.new("EquippedToolController")

local currentToolItemId: string? = nil

local function getEquippedToolId(snapshot: PlayerProfileTypes.InventorySnapshot?): string?
	if snapshot == nil or type(snapshot.equipped) ~= "table" then
		return nil
	end

	return snapshot.equipped.toolItemId
end

local function shouldShowTool(toolItemId: string?): boolean
	if toolItemId == nil then
		return false
	end

	local definition = Items.get(toolItemId)

	return definition ~= nil and definition.category == "tool"
end

local function applyEquippedVisual(character: Model?, toolItemId: string?)
	if character == nil then
		return
	end

	EquippedToolVisuals.detachFromCharacter(character)

	if not shouldShowTool(toolItemId) or toolItemId == nil then
		currentToolItemId = nil
		return
	end

	local buildResult = EquippedToolModelFactory.build(toolItemId)

	if buildResult == nil then
		currentToolItemId = nil
		return
	end

	if EquippedToolVisuals.attachToHand(character, buildResult.model, buildResult.gripOffset) then
		currentToolItemId = toolItemId
	else
		currentToolItemId = nil
	end
end

local function refreshFromSnapshot(snapshot: PlayerProfileTypes.InventorySnapshot?)
	local toolItemId = getEquippedToolId(snapshot)
	local player = Players.LocalPlayer

	if player.Character == nil then
		currentToolItemId = nil
		return
	end

	if toolItemId == currentToolItemId then
		return
	end

	applyEquippedVisual(player.Character, toolItemId)
end

local function bindCharacter(character: Model)
	local syncController = ClientKernel.getController("ClientSyncController")
	local snapshot: PlayerProfileTypes.InventorySnapshot? = nil

	if syncController ~= nil then
		snapshot = (syncController :: any):GetInventory()
	end

	applyEquippedVisual(character, getEquippedToolId(snapshot))
end

function EquippedToolController:Init()
	local trove = self:GetTrove()
	local player = Players.LocalPlayer

	trove:Connect(Networking.getEvent("InventoryUpdatedEvent").OnClientEvent, function(snapshot: PlayerProfileTypes.InventorySnapshot)
		refreshFromSnapshot(snapshot)
	end)

	trove:Connect(Networking.getEvent("PlayerDataLoadedEvent").OnClientEvent, function(profileData: PlayerProfileTypes.PlayerProfile)
		if type(profileData.inventory) ~= "table" then
			return
		end

		refreshFromSnapshot({
			inventory = profileData.inventory,
			hotbar = if type(profileData.hotbar) == "table" then profileData.hotbar else InventoryTypes.createEmptyHotbar(),
			equipped = if type(profileData.equipped) == "table" then profileData.equipped else InventoryTypes.createEmptyEquipped(),
		})
	end)

	trove:Connect(player.CharacterAdded, bindCharacter)

	if player.Character ~= nil then
		task.defer(bindCharacter, player.Character)
	end
end

return EquippedToolController
