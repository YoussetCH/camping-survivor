--!strict

local Helpers = require(script.Parent.Parent.Parent.Constants.Helpers)

local typeDefinition = Helpers.getType("lumberjack")

if typeDefinition == nil then
	error("Lumberjack helper type missing from Helpers registry", 0)
end

return typeDefinition
