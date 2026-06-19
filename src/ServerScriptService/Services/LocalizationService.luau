--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseService = require(ServerScriptService.Kernel.BaseService)
local LocaleRegistry = require(ReplicatedStorage.Shared.Localization.LocaleRegistry)
local Logger = require(ReplicatedStorage.Shared.Utilities.Logger)
local Networking = require(ReplicatedStorage.Shared.Networking.Networking)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local LocaleTypes = require(ReplicatedStorage.Shared.Types.Locale)

local LocalizationService = BaseService.new("LocalizationService")

local function ensureSettingsLocale(data: { settings: { locale: string? } })
	if data.settings.locale == nil or not LocaleRegistry.isSupported(data.settings.locale) then
		data.settings.locale = LocaleRegistry.DEFAULT_LOCALE
	end
end

local function onSetLocale(player: Player, locale: unknown)
	if type(locale) ~= "string" or not LocaleRegistry.isSupported(locale) then
		Logger.warn("LocalizationService", `Rejected invalid locale from {player.Name}`)
		return
	end

	local data = PlayerDataService:GetData(player)

	if data == nil then
		return
	end

	ensureSettingsLocale(data)
	data.settings.locale = locale :: LocaleTypes.LocaleCode
	PlayerDataService:SaveProfile(player)
	Networking.getEvent("LocaleChangedEvent"):FireClient(player, locale)
	Logger.info("LocalizationService", `{player.Name} locale set to {locale}`)
end

function LocalizationService:Init()
	local trove = self:GetTrove()

	trove:Connect(Networking.getEvent("SetLocaleEvent").OnServerEvent, onSetLocale)
end

function LocalizationService:Start()
	Logger.info("LocalizationService", "Localization is active")
end

return LocalizationService
