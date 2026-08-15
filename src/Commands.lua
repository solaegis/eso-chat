-- EsoChat - slash commands

local EC = EsoChat

local function printHelp()
    EC.Chat("Commands:")
    EC.Chat("  /ech            — status")
    EC.Chat("  /ech help       — this help")
    EC.Chat("  /ech settings   — open settings (LibAddonMenu)")
    EC.Chat("  /ech debug      — toggle debug logging")
    EC.Chat("  /ech reset      — reset settings to defaults")
end

local function printStatus()
    EC.Chat(
        string.format(
            "%s v%s | enabled=%s debug=%s",
            EC.DISPLAY_NAME,
            EC.VERSION,
            tostring(EC.db and EC.db.enabled ~= false),
            tostring(EC.IsDebugEnabled())
        )
    )
end

local function handleCommand(args)
    args = zo_strformat("<<1>>", args or "") or ""
    args = string.lower(string.gsub(args, "^%s+", ""))
    args = string.gsub(args, "%s+$", "")

    if args == "" or args == "status" then
        printStatus()
        return
    end

    if args == "help" or args == "?" then
        printHelp()
        return
    end

    if args == "settings" or args == "options" then
        if EC.OpenSettings then
            EC.OpenSettings()
        else
            EC.Chat("Open Settings > Addons > " .. EC.DISPLAY_NAME)
        end
        return
    end

    if args == "debug" then
        if not EC.db then
            return
        end
        EC.db.debug = not EC.db.debug
        EC.debug = EC.db.debug
        EC.Chat("Debug " .. (EC.db.debug and "ON" or "OFF"))
        return
    end

    if args == "reset" then
        EC.ResetSettings()
        return
    end

    EC.Chat("Unknown command. Try /ech help")
end

function EC.RegisterCommands()
    SLASH_COMMANDS["/ech"] = handleCommand
    SLASH_COMMANDS["/esochat"] = handleCommand
end
