--!strict

local Logger = {}

export type LogLevel = "Debug" | "Info" | "Warn" | "Error"

local function formatMessage(scope: string, message: string): string
	return `[{scope}] {message}`
end

function Logger.debug(scope: string, message: string)
	print(formatMessage(scope, message))
end

function Logger.info(scope: string, message: string)
	print(formatMessage(scope, message))
end

function Logger.warn(scope: string, message: string)
	warn(formatMessage(scope, message))
end

function Logger.error(scope: string, message: string)
	warn(formatMessage(scope, message))
end

return Logger
