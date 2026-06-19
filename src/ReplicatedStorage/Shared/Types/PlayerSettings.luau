--!strict

local LocaleTypes = require(script.Parent.Locale)

export type PlayerSettings = {
	locale: LocaleTypes.LocaleCode,
}

local PlayerSettings = {}

function PlayerSettings.readLocale(settings: PlayerSettings | { [string]: unknown }): LocaleTypes.LocaleCode
	local locale = settings.locale

	if type(locale) == "string" and (locale == "en" or locale == "es") then
		return locale :: LocaleTypes.LocaleCode
	end

	return "en"
end

return PlayerSettings
