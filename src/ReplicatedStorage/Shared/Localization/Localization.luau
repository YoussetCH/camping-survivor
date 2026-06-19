--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
local LocaleRegistry = require(script.Parent.LocaleRegistry)
local LocaleTypes = require(script.Parent.Parent.Types.Locale)

local EnglishLocale = require(script.Parent.Locales.en)
local SpanishLocale = require(script.Parent.Locales.es)

export type LocalizationModule = {
	LocaleChanged: Signal.Signal<LocaleTypes.LocaleCode>,
	get: (key: string) -> string,
	format: (key: string, params: { [string]: string | number }) -> string,
	getLocale: () -> LocaleTypes.LocaleCode,
	applyLocale: (locale: string) -> LocaleTypes.LocaleCode,
}

local localeTables: { [LocaleTypes.LocaleCode]: LocaleTypes.LocaleTable } = {
	en = EnglishLocale,
	es = SpanishLocale,
}

local currentLocale: LocaleTypes.LocaleCode = LocaleRegistry.DEFAULT_LOCALE

local Localization: LocalizationModule = {} :: LocalizationModule
Localization.LocaleChanged = Signal.new()

function Localization.get(key: string): string
	local activeTable = localeTables[currentLocale]
	local value = activeTable[key]

	if value ~= nil then
		return value
	end

	local fallback = localeTables.en[key]

	if fallback ~= nil then
		return fallback
	end

	return `[{key}]`
end

function Localization.format(key: string, params: { [string]: string | number }): string
	local text = Localization.get(key)

	for name, value in params do
		text = string.gsub(text, `{` .. name .. `}`, tostring(value))
	end

	return text
end

function Localization.getLocale(): LocaleTypes.LocaleCode
	return currentLocale
end

function Localization.applyLocale(locale: string): LocaleTypes.LocaleCode
	local normalized = LocaleRegistry.normalize(locale)

	if normalized == currentLocale then
		return currentLocale
	end

	currentLocale = normalized
	Localization.LocaleChanged:Fire(currentLocale)

	return currentLocale
end

return Localization
