-- EsoChat - slash commands

local EC = EsoChat

local function trim(s)
    s = tostring(s or "")
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

local function printHelp()
    EC.Chat("Commands:")
    EC.Chat("  /ech            - status")
    EC.Chat("  /ech help       - this help")
    EC.Chat("  /ech create …  - create tabs (see /ech create help)")
    EC.Chat("  /ech notes [clear] - focus Notes notepad, or clear active scope")
    EC.Chat("  /ech settings   - open settings (LibAddonMenu)")
    EC.Chat("  /ech debug      - toggle debug logging")
    EC.Chat("  /ech reset      - reset settings to defaults")
    EC.Chat("  /ech history [n] - show last n history lines")
    EC.Chat("  /ech mentions   - list mention keywords")
    EC.Chat("  /ech tab list|create|rename|focus|categories|ensure|mode")
    EC.Chat("  /ech profile list|save|apply|delete")
    EC.Chat("  /ech copy [n]   - copy history to clipboard")
    EC.Chat("  /ech export     - export settings")
    EC.Chat("  /ech resize     - chat window resize status (aliases: size, window)")
    EC.Chat("  /ech unread     - dump tab unread counts / label state")
    EC.Chat("  /ech filter     - filter status")
end

local function printStatus()
    local gamepad = EC.Formatter and EC.Formatter.UsesGamepadChat and EC.Formatter.UsesGamepadChat()
    EC.Chat(
        string.format(
            "%s v%s | enabled=%s debug=%s gamepadChat=%s formatter=%s",
            EC.DISPLAY_NAME,
            EC.VERSION,
            tostring(EC.db and EC.db.enabled ~= false),
            tostring(EC.IsDebugEnabled()),
            tostring(gamepad),
            tostring(EC.Formatter and EC.Formatter.IsInstalled and EC.Formatter.IsInstalled())
        )
    )
end

local function handleTab(rest)
    rest = rest or ""
    local cmd, a, b = string.match(rest, "^(%S+)%s*(%S*)%s*(.*)$")
    cmd = cmd or "list"
    if cmd == "list" then
        EC.Tabs.ListToChat()
    elseif cmd == "create" and a ~= "" then
        EC.Tabs.Create(a)
    elseif cmd == "rename" and a ~= "" and b ~= "" then
        EC.Tabs.Rename(a, b)
    elseif cmd == "focus" and a ~= "" then
        local tab = EC.Tabs.FindByName(a)
        if tab then
            EC.db.tabs.selectedTabKey = tab.name
            if EC.TabFilters and EC.TabFilters.OnTabFocused then
                EC.TabFilters.OnTabFocused(tab)
            end
            EC.Chat("Selected tab " .. tab.name)
        else
            EC.Chat(EC.L("tab_not_found", a))
        end
    elseif cmd == "categories" and a ~= "" then
        EC.Tabs.DumpCategories(a)
    elseif cmd == "ensure" and a ~= "" then
        local mode = string.lower(a)
        if EC.TabFilters and EC.TabFilters.EnsureTab then
            EC.TabFilters.EnsureTab(mode)
        else
            EC.Chat("TabFilters module not loaded.")
        end
    elseif cmd == "mode" and a ~= "" and b ~= "" then
        local mode = string.lower(b)
        if EC.TabFilters and EC.TabFilters.SetMode then
            EC.TabFilters.SetMode(a, mode)
        else
            EC.Chat("TabFilters module not loaded.")
        end
    else
        EC.Chat("Usage: /ech tab list|create <name>|rename <old> <new>|focus <name>|categories <name>|ensure whispers|mentions|friends|notes|mode <tab> <mode>")
    end
end

local function handleProfile(rest)
    rest = rest or ""
    local cmd, a, b = string.match(rest, "^(%S+)%s*(%S*)%s*(.*)$")
    cmd = cmd or "list"
    if cmd == "list" then
        EC.TabProfiles.List()
    elseif cmd == "save" and a ~= "" then
        EC.TabProfiles.Save(a)
    elseif cmd == "apply" and a ~= "" then
        EC.TabProfiles.Apply(a, b ~= "" and b or nil)
    elseif cmd == "delete" and a ~= "" then
        EC.TabProfiles.Delete(a)
        EC.Chat("Deleted profile " .. a)
    else
        EC.Chat("Usage: /ech profile list|save <name>|apply <name> [tab]|delete <name>")
    end
end

local function handleResize()
    if not EC.ContainerLayout then
        EC.Chat("ContainerLayout module not loaded.")
        return
    end
    if EC.ContainerLayout.RaiseMaxSize then
        EC.ContainerLayout.RaiseMaxSize()
    end
    if EC.ContainerLayout.StatusToChat then
        EC.ContainerLayout.StatusToChat()
    end
end

local function handleCommand(args)
    -- Do not use zo_strformat for routing — it can mangle unexpected input.
    local raw = trim(args)
    local lower = string.lower(raw)

    if lower == "" or lower == "status" then
        printStatus()
        return
    end

    if lower == "help" or lower == "?" then
        printHelp()
        return
    end

    if lower == "settings" or lower == "options" then
        if EC.OpenSettings then
            EC.OpenSettings()
        else
            EC.Chat("Open Settings > Addons > " .. EC.DISPLAY_NAME)
        end
        return
    end

    if lower == "debug" then
        if not EC.db then
            return
        end
        EC.db.debug = not EC.db.debug
        EC.debug = EC.db.debug
        EC.Chat(EC.db.debug and EC.L("debug_on") or EC.L("debug_off"))
        return
    end

    if lower == "reset" then
        EC.ResetSettings()
        return
    end

    local histN = string.match(lower, "^history%s*(%d*)$")
    if histN ~= nil or lower == "history" then
        EC.History.Dump(histN ~= "" and histN or 20)
        return
    end

    if lower == "mentions" then
        local kws = EC.Mentions.GetKeywords()
        if #kws == 0 then
            EC.Chat(EC.L("mentions_none"))
        else
            EC.Chat(EC.L("mentions_list"))
            for _, kw in ipairs(kws) do
                EC.Chat("  " .. kw)
            end
        end
        return
    end

    if string.sub(lower, 1, 4) == "tab " or lower == "tab" then
        handleTab(string.sub(raw, 5))
        return
    end

    if string.sub(lower, 1, 7) == "create " or lower == "create" then
        if EC.TabCreate and EC.TabCreate.Run then
            EC.TabCreate.Run(string.sub(raw, 8))
        else
            EC.Chat("TabCreate module not loaded.")
        end
        return
    end

    if string.sub(lower, 1, 6) == "notes " or lower == "notes" then
        local rest = trim(string.sub(raw, 7))
        local sub = string.lower(rest)
        if sub == "clear" then
            if EC.Notes and EC.Notes.Clear then
                EC.Notes.Clear()
            else
                EC.Chat("Notes module not loaded.")
            end
        elseif sub == "" or sub == "focus" or sub == "open" then
            if EC.Notes and EC.Notes.Focus then
                if not EC.Notes.Focus() then
                    EC.Chat("Could not open Notes tab.")
                end
            else
                EC.Chat("Notes module not loaded.")
            end
        else
            EC.Chat("Usage: /ech notes [clear]")
        end
        return
    end

    if string.sub(lower, 1, 8) == "profile " or lower == "profile" then
        handleProfile(string.sub(raw, 9))
        return
    end

    local copyN = string.match(lower, "^copy%s*(%d*)$")
    if copyN ~= nil or lower == "copy" then
        EC.CopyPaste.CopyHistory(copyN ~= "" and copyN or 20)
        return
    end

    if lower == "export" then
        EC.SettingsIO.Export()
        return
    end

    if string.sub(lower, 1, 7) == "import " then
        EC.SettingsIO.Import(string.sub(raw, 8))
        return
    end

    if lower == "resize" or lower == "size" or lower == "window" then
        handleResize()
        return
    end

    if lower == "unread" then
        if EC.TabUnread and EC.TabUnread.DumpToChat then
            EC.TabUnread.DumpToChat()
        else
            EC.Chat("TabUnread module not loaded.")
        end
        return
    end

    if lower == "filter" then
        local f = EC.db and EC.db.filtering
        EC.Chat(string.format(
            "Filter enabled=%s LFG=%s trade=%s recruit=%s flood=%s",
            tostring(f and f.enabled),
            tostring(f and f.blockLFG),
            tostring(f and f.blockTrade),
            tostring(f and f.blockRecruit),
            tostring(f and f.floodProtect)
        ))
        return
    end

    EC.Chat(string.format("Unknown command: %q - try /ech help", raw))
end

function EC.RegisterCommands()
    SLASH_COMMANDS["/ech"] = handleCommand
    SLASH_COMMANDS["/esochat"] = handleCommand
end
