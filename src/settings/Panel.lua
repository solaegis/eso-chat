-- EsoChat - LibAddonMenu-2.0 settings panel

local EC = EsoChat

local PANEL_NAME = "EsoChatPanel"
local lamPanel = nil

local function db()
    return EC.db
end

local function display()
    return EC.db.display
end

local function mentions()
    return EC.db.mentions
end

local function notifications()
    return EC.db.notifications
end

local function history()
    return EC.db.history
end

local function tabs()
    return EC.db.tabs
end

local function filtering()
    return EC.db.filtering
end

local function input()
    return EC.db.input
end

local function automation()
    return EC.db.automation
end

function EC.OpenSettings()
    if LibAddonMenu2 and LibAddonMenu2.OpenToPanel and lamPanel then
        LibAddonMenu2:OpenToPanel(lamPanel)
    else
        EC.Chat("Open Settings > Addons > " .. EC.DISPLAY_NAME)
    end
end

function EC.RegisterSettingsPanel()
    if not LibAddonMenu2 then
        EC.Chat("LibAddonMenu-2.0 not found — use /ech for status; settings UI unavailable")
        return
    end

    local LAM = LibAddonMenu2

    if EC.Sounds and EC.Sounds.EnsureShortlist then
        EC.Sounds.EnsureShortlist()
    end

    local panelData = {
        type = "panel",
        name = EC.DISPLAY_NAME,
        displayName = EC.DISPLAY_NAME,
        author = EC.AUTHOR,
        version = EC.VERSION,
        slashCommand = "/echsettings",
        registerForRefresh = true,
        registerForDefaults = true,
        website = EC.WEBSITE_URL,
        feedback = EC.FEEDBACK_URL,
        donation = EC.OpenGoldDonationMail,
        defaultsFunc = function()
            EC.ResetSettings()
        end,
    }

    local nameModeChoices = { "Character", "Account", "Both" }
    local nameModeValues = { "character", "account", "both" }

    -- Curated shortlist only (full SOUNDS in a dropdown freezes the UI).
    local soundChoices, soundValues = { "(None)", "NEW_NOTIFICATION" }, { "NONE", "New_Notification" }
    if EC.Sounds and EC.Sounds.GetShortlist then
        soundChoices, soundValues = EC.Sounds.GetShortlist()
    end

    local function soundDropdown(name, tooltip, getStored, setStored, reference, disabledFn)
        local choices = soundChoices
        local values = soundValues
        if EC.Sounds and EC.Sounds.EnsureSelectionVisible then
            choices, values = EC.Sounds.EnsureSelectionVisible(soundChoices, soundValues, getStored())
        end
        return {
            type = "dropdown",
            name = name,
            tooltip = tooltip,
            choices = choices,
            choicesValues = values,
            getFunc = function()
                local v = getStored()
                if EC.Sounds and EC.Sounds.Normalize then
                    return EC.Sounds.Normalize(v)
                end
                return v or "New_Notification"
            end,
            setFunc = function(v)
                setStored(v)
                if EC.Sounds and EC.Sounds.Play then
                    EC.Sounds.Play(v)
                end
            end,
            scrollable = 12,
            default = "New_Notification",
            width = "full",
            reference = reference,
            disabled = disabledFn,
        }
    end

    local optionsTable = {
        { type = "header", name = "General", width = "full" },
        {
            type = "checkbox",
            name = "Enabled",
            tooltip = "Master toggle for EsoChat features.",
            getFunc = function()
                return db() == nil or db().enabled ~= false
            end,
            setFunc = function(value)
                if db() then
                    db().enabled = value
                end
            end,
            default = true,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Debug logging",
            getFunc = function()
                return db() and db().debug == true
            end,
            setFunc = function(value)
                if db() then
                    db().debug = value
                end
                EC.debug = value
            end,
            default = false,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Force feature overlaps",
            tooltip = "Keep EsoChat display features on even when pChat/rChat is detected.",
            getFunc = function()
                return db() and db().compat and db().compat.forceEnableOverlaps
            end,
            setFunc = function(value)
                if db() and db().compat then
                    db().compat.forceEnableOverlaps = value
                end
            end,
            default = false,
            width = "full",
        },

        { type = "header", name = "Display", width = "full" },
        {
            type = "dropdown",
            name = "Name mode",
            choices = nameModeChoices,
            choicesValues = nameModeValues,
            getFunc = function()
                return display() and display().nameMode or "character"
            end,
            setFunc = function(value)
                display().nameMode = value
            end,
            default = "character",
            width = "full",
        },
        {
            type = "checkbox",
            name = "Strip says/yells",
            getFunc = function()
                return display().stripSays
            end,
            setFunc = function(v)
                display().stripSays = v
            end,
            default = true,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Strip zone tags",
            getFunc = function()
                return display().stripZoneTags
            end,
            setFunc = function(v)
                display().stripZoneTags = v
            end,
            default = true,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Strip colors",
            getFunc = function()
                return display().stripColors
            end,
            setFunc = function(v)
                display().stripColors = v
            end,
            default = false,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Timestamps",
            getFunc = function()
                return display().timestampEnabled
            end,
            setFunc = function(v)
                display().timestampEnabled = v
            end,
            default = true,
            width = "half",
        },
        {
            type = "checkbox",
            name = "24-hour timestamps",
            getFunc = function()
                return display().timestamp24h
            end,
            setFunc = function(v)
                display().timestamp24h = v
            end,
            default = true,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Prevent chat fade",
            tooltip = "Best-effort; keyboard chat only.",
            getFunc = function()
                return display().preventFade
            end,
            setFunc = function(v)
                display().preventFade = v
                if v and EC.Display then
                    EC.Display.ApplyPreventFade()
                end
            end,
            default = false,
            width = "half",
        },
        {
            type = "colorpicker",
            name = "Timestamp color",
            getFunc = function()
                return display().timestampColorR, display().timestampColorG, display().timestampColorB
            end,
            setFunc = function(r, g, b)
                display().timestampColorR = r
                display().timestampColorG = g
                display().timestampColorB = b
            end,
            default = { r = 0.6, g = 0.6, b = 0.6 },
            width = "full",
        },

        { type = "header", name = "Mentions", width = "full" },
        {
            type = "checkbox",
            name = "Enable mentions",
            getFunc = function()
                return mentions().enabled
            end,
            setFunc = function(v)
                mentions().enabled = v
            end,
            default = true,
            width = "full",
        },
        {
            type = "editbox",
            name = "Keywords (one per line)",
            isMultiline = true,
            getFunc = function()
                return mentions().keywords or ""
            end,
            setFunc = function(v)
                mentions().keywords = v
            end,
            default = "",
            width = "full",
        },
        {
            type = "checkbox",
            name = "Regex keywords",
            tooltip = "Treat each keyword as a Lua pattern. Invalid patterns are ignored.",
            getFunc = function()
                return mentions().useRegex == true
            end,
            setFunc = function(v)
                mentions().useRegex = v
            end,
            default = false,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Mention sound",
            getFunc = function()
                return mentions().soundEnabled
            end,
            setFunc = function(v)
                mentions().soundEnabled = v
            end,
            default = true,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Exclude whispers",
            getFunc = function()
                return mentions().excludeWhispers
            end,
            setFunc = function(v)
                mentions().excludeWhispers = v
            end,
            default = true,
            width = "half",
        },
        {
            type = "colorpicker",
            name = "Highlight color",
            getFunc = function()
                return mentions().highlightColorR, mentions().highlightColorG, mentions().highlightColorB
            end,
            setFunc = function(r, g, b)
                mentions().highlightColorR = r
                mentions().highlightColorG = g
                mentions().highlightColorB = b
            end,
            default = { r = 1, g = 0.85, b = 0.2 },
            width = "full",
        },

        { type = "header", name = "Notifications", width = "full" },
        {
            type = "checkbox",
            name = "Whisper sound",
            getFunc = function()
                return notifications().whisperSoundEnabled
            end,
            setFunc = function(v)
                notifications().whisperSoundEnabled = v
            end,
            default = true,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Whisper visual",
            getFunc = function()
                return notifications().whisperVisualEnabled
            end,
            setFunc = function(v)
                notifications().whisperVisualEnabled = v
            end,
            default = true,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Party sound",
            getFunc = function()
                return notifications().partySoundEnabled
            end,
            setFunc = function(v)
                notifications().partySoundEnabled = v
            end,
            default = false,
            width = "full",
        },
        soundDropdown(
            "Mention alert sound",
            "Common game sounds. Selecting previews the sound.",
            function()
                return mentions().soundName
            end,
            function(v)
                mentions().soundName = v
            end,
            "EsoChat_MentionSoundDropdown",
            function()
                return not mentions().soundEnabled
            end
        ),
        soundDropdown(
            "Whisper alert sound",
            "Common game sounds. Selecting previews the sound.",
            function()
                return notifications().whisperSoundName
            end,
            function(v)
                notifications().whisperSoundName = v
            end,
            "EsoChat_WhisperSoundDropdown",
            function()
                return not notifications().whisperSoundEnabled
            end
        ),
        soundDropdown(
            "Party alert sound",
            "Common game sounds. Selecting previews the sound.",
            function()
                return notifications().partySoundName
            end,
            function(v)
                notifications().partySoundName = v
            end,
            "EsoChat_PartySoundDropdown",
            function()
                return not notifications().partySoundEnabled
            end
        ),

        { type = "header", name = "History", width = "full" },
        {
            type = "checkbox",
            name = "Save chat history",
            tooltip = "Survives /reloadui. Large history increases SavedVariables size.",
            getFunc = function()
                return history().enabled
            end,
            setFunc = function(v)
                history().enabled = v
            end,
            default = true,
            width = "full",
        },
        {
            type = "slider",
            name = "Max entries",
            min = 10,
            max = 1000,
            step = 10,
            getFunc = function()
                return history().maxEntries or 200
            end,
            setFunc = function(v)
                history().maxEntries = v
            end,
            default = 200,
            width = "full",
        },
        {
            type = "slider",
            name = "Retention hours (0 = entries only)",
            min = 0,
            max = 168,
            step = 1,
            getFunc = function()
                return history().retentionHours or 24
            end,
            setFunc = function(v)
                history().retentionHours = v
            end,
            default = 24,
            width = "full",
        },

        { type = "header", name = "Tabs", width = "full" },
        {
            type = "checkbox",
            name = "Enable tab features",
            tooltip = "Keyboard chat only.",
            getFunc = function()
                return tabs().enabled
            end,
            setFunc = function(v)
                tabs().enabled = v
            end,
            default = true,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Restore layout on login",
            getFunc = function()
                return tabs().restoreLayout
            end,
            setFunc = function(v)
                tabs().restoreLayout = v
            end,
            default = true,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Remember window size across logins",
            tooltip = "Saves each chat container width and height to SavedVariables.",
            getFunc = function()
                return tabs().rememberSize ~= false
            end,
            setFunc = function(v)
                tabs().rememberSize = v
            end,
            default = true,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Allow larger than default chat size",
            tooltip = "Raises max chat size to the screen. Drag the chat corner to resize. Use /ech resize to diagnose.",
            getFunc = function()
                return tabs().raiseMaxSize ~= false
            end,
            setFunc = function(v)
                tabs().raiseMaxSize = v
                if v and EC.ContainerLayout and EC.ContainerLayout.RaiseMaxSize then
                    EC.ContainerLayout.RaiseMaxSize()
                end
            end,
            default = true,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Remember window position",
            tooltip = "Saves and restores chat container screen position.",
            getFunc = function()
                return tabs().rememberPosition ~= false
            end,
            setFunc = function(v)
                tabs().rememberPosition = v
            end,
            default = true,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Flash inactive tab on alert",
            tooltip = "One-shot flash for whisper/mention/party when Unread pulse is off. When Unread pulse is on, unread owns the flash.",
            getFunc = function()
                return tabs().flashInactiveOnAlert
            end,
            setFunc = function(v)
                tabs().flashInactiveOnAlert = v
            end,
            default = true,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Unread pulse until read",
            tooltip = "Flash once on the first unread message, then slowly pulse until the tab is focused and scrolled to the bottom. Counts any message on inactive or scrolled-up tabs.",
            getFunc = function()
                return tabs().unreadPulseEnabled ~= false
            end,
            setFunc = function(v)
                tabs().unreadPulseEnabled = v
            end,
            default = true,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Unread message counter",
            tooltip = "Show a display-only (N) suffix on tab labels for unread messages. Not saved into the tab name.",
            getFunc = function()
                return tabs().unreadCounterEnabled ~= false
            end,
            setFunc = function(v)
                tabs().unreadCounterEnabled = v
                if EC.TabUnread and EC.TabUnread.RefreshLabels then
                    EC.TabUnread.RefreshLabels()
                end
            end,
            default = true,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Switch tab on whisper",
            getFunc = function()
                return tabs().switchOnWhisper
            end,
            setFunc = function(v)
                tabs().switchOnWhisper = v
            end,
            default = false,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Switch tab on mention",
            getFunc = function()
                return tabs().switchOnMention
            end,
            setFunc = function(v)
                tabs().switchOnMention = v
            end,
            default = false,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Switch tab on party",
            getFunc = function()
                return tabs().switchOnParty
            end,
            setFunc = function(v)
                tabs().switchOnParty = v
            end,
            default = false,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Keep group tab visible in combat",
            tooltip = "While grouped and in combat, move the EsoChat group tab (/ech create group) to first position and keep it focused. Restores prior focus and order when combat ends. Default off.",
            getFunc = function()
                return tabs().keepGroupTabVisibleInCombat == true
            end,
            setFunc = function(v)
                tabs().keepGroupTabVisibleInCombat = v and true or false
            end,
            default = false,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Remember channel per tab",
            getFunc = function()
                return tabs().rememberChannelPerTab
            end,
            setFunc = function(v)
                tabs().rememberChannelPerTab = v
            end,
            default = true,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Enable special filter tabs",
            tooltip = "Whispers / Mentions / Friends / Notes. Mentions and Friends receive copies; Whispers uses whisper categories; Notes is a persistent notepad.",
            getFunc = function()
                return tabs().specialTabsEnabled ~= false
            end,
            setFunc = function(v)
                tabs().specialTabsEnabled = v
            end,
            default = true,
            width = "full",
        },
        {
            type = "slider",
            name = "Conversation sticky (minutes)",
            tooltip = "After a Mentions or Friends hit, keep your replies and their follow-ups in that tab for this many minutes (1-60).",
            min = 1,
            max = 60,
            step = 1,
            getFunc = function()
                local v = tabs().conversationStickyMinutes
                if EC.TabFilters and EC.TabFilters.ClampStickyMinutes then
                    return EC.TabFilters.ClampStickyMinutes(v)
                end
                return tonumber(v) or 5
            end,
            setFunc = function(v)
                if EC.TabFilters and EC.TabFilters.ClampStickyMinutes then
                    tabs().conversationStickyMinutes = EC.TabFilters.ClampStickyMinutes(v)
                else
                    tabs().conversationStickyMinutes = v
                end
            end,
            default = 5,
            width = "full",
        },
        {
            type = "button",
            name = "Create/Update Whispers tab",
            func = function()
                if EC.TabFilters and EC.TabFilters.EnsureTab then
                    EC.TabFilters.EnsureTab("whispers")
                end
            end,
            width = "half",
        },
        {
            type = "button",
            name = "Create/Update Mentions tab",
            func = function()
                if EC.TabFilters and EC.TabFilters.EnsureTab then
                    EC.TabFilters.EnsureTab("mentions")
                end
            end,
            width = "half",
        },
        {
            type = "button",
            name = "Create/Update Friends tab",
            func = function()
                if EC.TabFilters and EC.TabFilters.EnsureTab then
                    EC.TabFilters.EnsureTab("friends")
                end
            end,
            width = "half",
        },
        {
            type = "button",
            name = "Create/Update Notes tab",
            func = function()
                if EC.TabFilters and EC.TabFilters.EnsureTab then
                    EC.TabFilters.EnsureTab("notes")
                end
            end,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Keep Notes per character",
            tooltip = "Off: one notepad shared across characters on this server. On: each character has its own notepad. Switching does not copy text between stores.",
            getFunc = function()
                return EC.db.notes and EC.db.notes.perCharacter == true
            end,
            setFunc = function(v)
                if EC.Notes and EC.Notes.SetPerCharacter then
                    EC.Notes.SetPerCharacter(v)
                elseif EC.db.notes then
                    EC.db.notes.perCharacter = v and true or false
                end
            end,
            default = false,
            width = "half",
        },
        {
            type = "button",
            name = "Clear Notes (active scope)",
            func = function()
                if EC.Notes and EC.Notes.Clear then
                    EC.Notes.Clear()
                end
            end,
            width = "half",
        },
        {
            type = "editbox",
            name = "Preferred alert tab name",
            getFunc = function()
                return tabs().alertTabPrefer or ""
            end,
            setFunc = function(v)
                tabs().alertTabPrefer = v
            end,
            default = "",
            width = "full",
        },
        {
            type = "button",
            name = "Snapshot tab layout now",
            func = function()
                if EC.Tabs then
                    EC.Tabs.SnapshotLayout()
                    EC.Chat("Tab layout and window size saved.")
                end
            end,
            width = "half",
        },
        {
            type = "button",
            name = "Restore tab layout now",
            func = function()
                if EC.ContainerLayout and EC.ContainerLayout.RaiseMaxSize then
                    EC.ContainerLayout.RaiseMaxSize()
                end
                if EC.Tabs then
                    EC.Tabs.RestoreLayout()
                    EC.Chat("Tab layout and window size restore attempted.")
                end
            end,
            width = "half",
        },

        { type = "header", name = "Filtering", width = "full" },
        {
            type = "checkbox",
            name = "Enable filtering",
            getFunc = function()
                return filtering().enabled
            end,
            setFunc = function(v)
                filtering().enabled = v
            end,
            default = false,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Block LFG/LFM",
            getFunc = function()
                return filtering().blockLFG
            end,
            setFunc = function(v)
                filtering().blockLFG = v
            end,
            default = false,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Block WTB/WTS/WTT",
            getFunc = function()
                return filtering().blockTrade
            end,
            setFunc = function(v)
                filtering().blockTrade = v
            end,
            default = false,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Block guild recruit spam",
            getFunc = function()
                return filtering().blockRecruit
            end,
            setFunc = function(v)
                filtering().blockRecruit = v
            end,
            default = false,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Flood protection",
            getFunc = function()
                return filtering().floodProtect
            end,
            setFunc = function(v)
                filtering().floodProtect = v
            end,
            default = true,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Apply to zone",
            getFunc = function()
                return filtering().applyToZone
            end,
            setFunc = function(v)
                filtering().applyToZone = v
            end,
            default = true,
            width = "half",
        },
        {
            type = "editbox",
            name = "Custom block keywords",
            isMultiline = true,
            getFunc = function()
                return filtering().customKeywords or ""
            end,
            setFunc = function(v)
                filtering().customKeywords = v
            end,
            default = "",
            width = "full",
        },

        { type = "header", name = "Input", width = "full" },
        {
            type = "checkbox",
            name = "Character counter",
            getFunc = function()
                return input().counterEnabled
            end,
            setFunc = function(v)
                input().counterEnabled = v
            end,
            default = true,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Input history",
            getFunc = function()
                return input().historyEnabled
            end,
            setFunc = function(v)
                input().historyEnabled = v
            end,
            default = true,
            width = "half",
        },

        { type = "header", name = "Copy and backup", width = "full" },
        {
            type = "checkbox",
            name = "Strip formatting on copy",
            getFunc = function()
                return db().copy.stripFormatting
            end,
            setFunc = function(v)
                db().copy.stripFormatting = v
            end,
            default = true,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Include channel/sender on copy",
            getFunc = function()
                return db().copy.includeMeta
            end,
            setFunc = function(v)
                db().copy.includeMeta = v
            end,
            default = true,
            width = "half",
        },
        {
            type = "button",
            name = "Export settings",
            func = function()
                EC.SettingsIO.Export()
            end,
            width = "half",
        },
        {
            type = "button",
            name = "Copy last 20 history lines",
            func = function()
                EC.CopyPaste.CopyHistory(20)
            end,
            width = "half",
        },

        { type = "header", name = "Automation (default off)", width = "full" },
        {
            type = "checkbox",
            name = "Enable automation",
            tooltip = "Sends greetings/templates. Keep off unless you intend to auto-post.",
            getFunc = function()
                return automation().enabled
            end,
            setFunc = function(v)
                automation().enabled = v
            end,
            default = false,
            width = "full",
            isDangerous = true,
            warning = "Can spam chat channels if misconfigured.",
        },
        {
            type = "checkbox",
            name = "Login greeting",
            getFunc = function()
                return automation().loginGreetingEnabled
            end,
            setFunc = function(v)
                automation().loginGreetingEnabled = v
            end,
            default = false,
            width = "half",
        },
        {
            type = "editbox",
            name = "Login greeting text",
            getFunc = function()
                return automation().loginGreeting or ""
            end,
            setFunc = function(v)
                automation().loginGreeting = v
            end,
            default = "",
            width = "full",
        },
        {
            type = "checkbox",
            name = "Zone welcome",
            getFunc = function()
                return automation().zoneWelcomeEnabled
            end,
            setFunc = function(v)
                automation().zoneWelcomeEnabled = v
            end,
            default = false,
            width = "half",
        },
        {
            type = "editbox",
            name = "Zone welcome text",
            getFunc = function()
                return automation().zoneWelcome or ""
            end,
            setFunc = function(v)
                automation().zoneWelcome = v
            end,
            default = "",
            width = "full",
        },

        { type = "header", name = "Loot / emoji (experimental)", width = "full" },
        {
            type = "checkbox",
            name = "Show loot in chat",
            getFunc = function()
                return db().loot.enabled
            end,
            setFunc = function(v)
                db().loot.enabled = v
            end,
            default = false,
            width = "half",
        },
        {
            type = "checkbox",
            name = "Emoji mode (LMP font)",
            getFunc = function()
                return db().emoji.enabled
            end,
            setFunc = function(v)
                db().emoji.enabled = v
            end,
            default = false,
            width = "half",
        },

        { type = "header", name = "Credits", width = "full" },
        {
            type = "description",
            text = "Inspired by ideas from pChat, rChat, FCOChatTabBrain, Chat Window Manager, Chat2Clipboard, SmartChatMsg, HelloTamriel!, TOM, Chat Input Viewer, ShowLootChat, and CopyTextESO. EsoChat is an independent implementation and does not include their code. Optional libraries: LibAddonMenu-2.0, LibDebugLogger, LibChatMessage, LibMediaProvider.",
            width = "full",
        },
    }

    EC.AppendSupportFooter(optionsTable)

    lamPanel = LAM:RegisterAddonPanel(PANEL_NAME, panelData)
    LAM:RegisterOptionControls(PANEL_NAME, optionsTable)
end
