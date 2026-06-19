--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)

local function getPlayerScripts(): PlayerScripts
	local parent = script.Parent

	if parent:IsA("PlayerScripts") then
		return parent
	end

	return parent.Parent :: PlayerScripts
end

local playerScripts = getPlayerScripts()
local ClientKernel = require(playerScripts:WaitForChild("Kernel").ClientKernel)

local controllers = ClientKernel.loadControllers()

ClientKernel.initControllers(controllers)
ClientKernel.startControllers(controllers)

Players.LocalPlayer.AncestryChanged:Connect(function(_, parent)
	if parent == nil then
		ClientKernel.destroyControllers(controllers)
	end
end)

Logger.info("Bootstrap", "Client bootstrap complete")
