-- Luacheck for EsoChat (ESO Lua 5.1)

std = "lua51"

ignore = {
    "212", -- unused argument (ESO event callbacks)
    "631", -- line too long
}

globals = {
    EsoChat = {
        other_fields = true,
    },
    EsoChatSettings = {
        other_fields = true,
    },
    SLASH_COMMANDS = {
        other_fields = true,
    },
}

read_globals = {
    "EVENT_MANAGER",
    "SLASH_COMMANDS",
    "d",
    "zo_callLater",
    "zo_strformat",
    "RequestOpenURL",
    "ZO_SavedVars",
    "ZO_ShallowTableCopy",
    "ZO_DeepTableCopy",
    "GetWorldName",
    "GetDisplayName",
    "GetCurrentCharacterId",
    "GetUnitName",
    "GetAddOnMetadata",
    "SOUNDS",
    "CALLBACK_MANAGER",
    "LibAddonMenu2",
    "LibDebugLogger",
    "_G",
    "EVENT_ADD_ON_LOADED",
    "EVENT_PLAYER_ACTIVATED",
    "MAIL_SEND",
    "CallSecureProtected",
    "GetCurrentMoney",
    "IsInGamepadPreferredMode",
}
