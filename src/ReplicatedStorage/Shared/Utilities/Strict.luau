--!strict

local Strict = {}

function Strict.isString(value: unknown): boolean
	return type(value) == "string"
end

function Strict.isNumber(value: unknown): boolean
	return type(value) == "number"
end

function Strict.isBoolean(value: unknown): boolean
	return type(value) == "boolean"
end

function Strict.isTable(value: unknown): boolean
	return type(value) == "table"
end

function Strict.assertString(value: unknown, fieldName: string): string
	if not Strict.isString(value) then
		error(`{fieldName} must be a string`, 3)
	end

	return value :: string
end

function Strict.assertNumber(value: unknown, fieldName: string): number
	if not Strict.isNumber(value) then
		error(`{fieldName} must be a number`, 3)
	end

	return value :: number
end

return Strict
