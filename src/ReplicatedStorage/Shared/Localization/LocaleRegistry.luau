--!strict

local LocaleTypes = require(script.Parent.Parent.Types.Locale)

export type LocaleRegistryModule = {
	DEFAULT_LOCALE: LocaleTypes.LocaleCode,
	SUPPORTED_LOCALES: { LocaleTypes.LocaleCode },
	isSupported: (locale: string) -> boolean,
	normalize: (locale: string?) -> LocaleTypes.LocaleCode,
}

local SUPPORTED: { LocaleTypes.LocaleCode } = { "en", "es" }

local supportedSet: { [string]: boolean } = {
	en = true,
	es = true,
}

local LocaleRegistry: LocaleRegistryModule = {
	DEFAULT_LOCALE = "en",
	SUPPORTED_LOCALES = SUPPORTED,
	isSupported = function(locale: string): boolean
		return supportedSet[locale] == true
	end,
	normalize = function(locale: string?): LocaleTypes.LocaleCode
		if locale ~= nil and supportedSet[locale] then
			return locale :: LocaleTypes.LocaleCode
		end

		return "en"
	end,
}

return LocaleRegistry
