-- EsoChat - English strings (i18n table)

local EC = EsoChat

EC.i18n = EC.i18n or {}
EC.i18n.en = {
    settings_reset = "Settings reset to defaults",
    loaded = "%s v%s loaded — /ech help",
    gamepad_disabled = "Keyboard chat required; EsoChat formatter/tabs disabled on gamepad chat.",
    unknown_command = "Unknown command. Try /ech help",
    unknown_command_arg = "Unknown command: %q - try /ech help",
    debug_on = "Debug ON",
    debug_off = "Debug OFF",
    history_empty = "Chat history is empty.",
    history_header = "History (last %d):",
    mentions_none = "No mention keywords configured.",
    mentions_list = "Mention keywords:",
    compat_warning = "Another chat formatter addon detected. EsoChat will chain formatters; enable Force overlaps in Compat if needed.",
    filter_blocked = "Message blocked by filter.",
    export_ready = "Settings export copied to chat window text (select and copy).",
    import_ok = "Settings imported.",
    import_fail = "Settings import failed.",
    tab_list_header = "Chat tabs:",
    tab_not_found = "Tab not found: %s",
    tab_created = "Created tab: %s",
    tab_renamed = "Renamed tab to: %s",
    profile_saved = "Profile saved: %s",
    profile_applied = "Profile applied: %s",
    profile_missing = "Profile not found: %s",
    sv_size_warn = "Chat history is large (%d entries). Consider lowering History max entries or exporting a backup.",
    backup_reminder = "Reminder: export EsoChat settings backup (/ech export).",
    automation_sent = "Automation sent on %s",
}

--- Localize a key; English fallback.
--- @param key string
--- @param ... any format args
function EC.L(key, ...)
    local lang = "en"
    if GetCVar then
        local ok, cvar = pcall(GetCVar, "language.2")
        if ok and type(cvar) == "string" and cvar ~= "" then
            lang = cvar
        end
    end
    local pack = EC.i18n[lang] or EC.i18n.en
    local text = (pack and pack[key]) or (EC.i18n.en and EC.i18n.en[key]) or key
    if select("#", ...) > 0 then
        return string.format(text, ...)
    end
    return text
end
