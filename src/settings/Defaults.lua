-- EsoChat - default SavedVariables

local EC = EsoChat

EC.SCHEMA_VERSION = 1

EC.defaults = {
    enabled = true,
    debug = false,
    settingsSchemaVersion = EC.SCHEMA_VERSION,
    perCharacterData = {},

    display = {
        nameMode = "character", -- character | account | both
        stripSays = true,
        stripZoneTags = true,
        stripColors = false,
        timestampEnabled = true,
        timestamp24h = true,
        timestampColorR = 0.6,
        timestampColorG = 0.6,
        timestampColorB = 0.6,
        preventFade = false,
        guildChannelNames = {},
        nicknames = {},
    },

    mentions = {
        enabled = true,
        keywords = "",
        highlightColorR = 1,
        highlightColorG = 0.85,
        highlightColorB = 0.2,
        soundEnabled = true,
        soundName = "New_Notification",
        excludeWhispers = true,
        excludeSystem = true,
        useRegex = false,
    },

    notifications = {
        whisperSoundEnabled = true,
        whisperVisualEnabled = true,
        whisperSoundName = "New_Notification",
        mentionSoundEnabled = true,
        partySoundEnabled = false,
        partySoundName = "New_Notification",
        partySwitchEnabled = false,
    },

    history = {
        enabled = true,
        maxEntries = 200,
        retentionHours = 24,
        entries = {},
    },

    notes = {
        enabled = true,
        tabName = "Notes",
        perCharacter = false,
        text = "",
        maxChars = 20000,
    },

    tabs = {
        enabled = true,
        restoreLayout = true,
        flashInactiveOnAlert = true,
        unreadPulseEnabled = true,
        unreadCounterEnabled = true,
        switchOnWhisper = false,
        switchOnMention = false,
        switchOnParty = false,
        rememberChannelPerTab = true,
        rememberSize = true,
        raiseMaxSize = true,
        rememberPosition = true,
        alertTabPrefer = "",
        specialTabsEnabled = true,
        whispersTabName = "Whispers",
        mentionsTabName = "Mentions",
        friendsTabName = "Friends",
        notesTabName = "Notes",
        conversationStickyMinutes = 5,
        keepGroupTabVisibleInCombat = false,
        layout = {},
        containers = {},
        profiles = {},
        activeProfile = "",
        selectedTabKey = "",
    },

    filtering = {
        enabled = false,
        blockLFG = false,
        blockTrade = false,
        blockRecruit = false,
        floodProtect = true,
        floodSeconds = 5,
        customKeywords = "",
        applyToZone = true,
        applyToSay = false,
        applyToGuild = false,
        hideFromHistory = true,
    },

    input = {
        counterEnabled = true,
        historyEnabled = true,
        historyMax = 50,
        historyEntries = {},
    },

    copy = {
        stripFormatting = true,
        includeMeta = true,
    },

    settingsIO = {
        backupReminderDays = 14,
        lastBackupReminder = 0,
        svWarnEntries = 500,
    },

    automation = {
        enabled = false,
        loginGreeting = "",
        loginGreetingEnabled = false,
        zoneWelcome = "",
        zoneWelcomeEnabled = false,
        guildGreeting = "",
        guildGreetingEnabled = false,
        recruitment = "",
        recruitmentEnabled = false,
        quickWhispers = { "", "", "" },
        restoreChannelAfterSend = false,
    },

    compat = {
        forceEnableOverlaps = false,
        warnedThisSession = false,
    },

    loot = {
        enabled = false,
        showPrices = false,
    },

    emoji = {
        enabled = false,
    },
}

--- Deep-copy a defaults table value for reset.
local function copyValue(value)
    if type(value) ~= "table" then
        return value
    end
    if ZO_DeepTableCopy then
        return ZO_DeepTableCopy(value)
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = copyValue(v)
    end
    return out
end

--- Reset account settings to defaults, preserving perCharacterData and history entries optionally cleared.
function EC.ResetSettings()
    if not EC.db then
        return
    end

    local preserved = EC.db.perCharacterData
    local preservedHistory = EC.db.history and EC.db.history.entries
    local preservedNotesText = EC.db.notes and EC.db.notes.text
    for key, value in pairs(EC.defaults) do
        if key ~= "perCharacterData" then
            EC.db[key] = copyValue(value)
        end
    end
    EC.db.perCharacterData = preserved or {}
    if preservedHistory and EC.db.history then
        EC.db.history.entries = preservedHistory
    end
    if preservedNotesText ~= nil and EC.db.notes then
        EC.db.notes.text = preservedNotesText
    end
    EC.db.settingsSchemaVersion = EC.SCHEMA_VERSION
    EC.Info(EC.L("settings_reset"))
end

--- Ensure nested default keys exist after upgrades (non-destructive).
function EC.EnsureDefaultsFilled()
    if not EC.db then
        return
    end
    local function fill(target, source)
        for k, v in pairs(source) do
            if target[k] == nil then
                target[k] = copyValue(v)
            elseif type(v) == "table" and type(target[k]) == "table" and k ~= "entries" and k ~= "layout" and k ~= "profiles" and k ~= "containers" and k ~= "historyEntries" and k ~= "nicknames" and k ~= "guildChannelNames" then
                fill(target[k], v)
            end
        end
    end
    fill(EC.db, EC.defaults)
end
