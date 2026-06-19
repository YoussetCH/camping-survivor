--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseController = require(script.Parent.BaseController)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local PlayerProfileTypes = require(ReplicatedStorage.Shared.Types.PlayerProfile)

local UIController = BaseController.new("UIController")

local currentProfile: PlayerProfileTypes.PlayerProfile? = nil

function UIController:GetProfile(): PlayerProfileTypes.PlayerProfile?
	return currentProfile
end

function UIController:Init()
	local trove = self:GetTrove()
	local playerDataLoadedEvent = Networking.getEvent("PlayerDataLoadedEvent")

	trove:Connect(playerDataLoadedEvent.OnClientEvent, function(profileData: PlayerProfileTypes.PlayerProfile)
		currentProfile = profileData
		Logger.info("UIController", `Received player profile with {profileData.currency} currency`)
	end)
end

return UIController
