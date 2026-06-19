--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientKernel = require(script.Parent.Parent.Kernel.ClientKernel)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)

local controllers = ClientKernel.loadControllers()

ClientKernel.initControllers(controllers)
ClientKernel.startControllers(controllers)

Players.LocalPlayer.AncestryChanged:Connect(function(_, parent)
	if parent == nil then
		ClientKernel.destroyControllers(controllers)
	end
end)

Logger.info("Bootstrap", "Client bootstrap complete")
