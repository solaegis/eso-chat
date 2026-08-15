-- EsoChat - initialization

local EC = EsoChat

local ADDON_NAME = EC.NAME
local loaded = false

local function onAddOnLoaded(_, name)
    if name ~= ADDON_NAME then
        return
    end
    if loaded then
        return
    end
    loaded = true
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    local defaults = EC.defaults or {}

    -- Namespace by server so NA / EU / PTS account settings do not overwrite each other.
    EC.db = ZO_SavedVars:NewAccountWide(EC.SV_NAME, EC.SV_VERSION, GetWorldName(), defaults)
    EC.debug = EC.db.debug == true

    if EC.EnsureCharacterData then
        EC.EnsureCharacterData()
    end

    EC.RegisterCommands()
    EC.RegisterSettingsPanel()

    EC.Info(string.format("%s v%s loaded — /ech help", EC.DISPLAY_NAME, EC.VERSION))
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, onAddOnLoaded)
