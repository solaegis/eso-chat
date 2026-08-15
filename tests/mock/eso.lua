-- Minimal ESO stubs for EsoChat headless tests

local function findRoot()
    local info = debug.getinfo(1, "S")
    local src = info and info.source or ""
    src = src:gsub("^@", "")
    -- tests/mock/eso.lua -> repo root
    local dir = src:match("^(.*)/tests/mock/")
    return dir or "."
end

local ROOT = findRoot()

CHAT_CHANNEL_SAY = 0
CHAT_CHANNEL_ZONE = 1
CHAT_CHANNEL_WHISPER = 2
CHAT_CHANNEL_WHISPER_SENT = 3
CHAT_CHANNEL_PARTY = 4
CHAT_CHANNEL_SYSTEM = 5
CHAT_CHANNEL_GUILD_1 = 6
CHAT_CHANNEL_ZONE_LANGUAGE_1 = 7

CHAT_CATEGORY_SAY = 1
CHAT_CATEGORY_SYSTEM = 2
CHAT_CATEGORY_WHISPER_INCOMING = 3
CHAT_CATEGORY_WHISPER_OUTGOING = 4
CHAT_CATEGORY_PARTY = 5
CHAT_CATEGORY_YELL = 6
CHAT_CATEGORY_EMOTE = 7
CHAT_CATEGORY_ZONE = 8
CHAT_CATEGORY_GUILD_1 = 9
CHAT_CATEGORY_GUILD_2 = 10
CHAT_CATEGORY_GUILD_3 = 11
CHAT_CATEGORY_GUILD_4 = 12
CHAT_CATEGORY_GUILD_5 = 13
CHAT_CATEGORY_OFFICER_1 = 14
CHAT_CATEGORY_OFFICER_2 = 15
CHAT_CATEGORY_OFFICER_3 = 16
CHAT_CATEGORY_OFFICER_4 = 17
CHAT_CATEGORY_OFFICER_5 = 18
CHAT_CATEGORY_ZONE_ENGLISH = 19
CHAT_CATEGORY_ZONE_FRENCH = 20
CHAT_CATEGORY_ZONE_GERMAN = 21
CHAT_CATEGORY_ZONE_JAPANESE = 22

function GetTimeStamp()
    return os.time()
end

function GetCVar()
    return "en"
end

EVENT_MANAGER = {
    RegisterForEvent = function() end,
    UnregisterForEvent = function() end,
    RegisterForUpdate = function() end,
    UnregisterForUpdate = function() end,
}

zo_callLater = function(fn)
    fn()
end

EsoChat = EsoChat or {}
local EC = EsoChat
EC.NAME = "EsoChat"
EC.VERSION = "test"
EC.Chat = function() end
EC.Info = function() end
EC.Warn = function() end
EC.Error = function() end
EC.DebugPrint = function() end

local function loadMod(rel)
    assert(loadfile(ROOT .. "/" .. rel))()
end

loadMod("src/i18n/en.lua")
loadMod("src/settings/Defaults.lua")
loadMod("src/settings/Initializer.lua")
EC.db = {}
for k, v in pairs(EC.defaults) do
    if type(v) == "table" then
        local copy = {}
        for sk, sv in pairs(v) do
            if type(sv) == "table" then
                local inner = {}
                for ik, iv in pairs(sv) do
                    inner[ik] = iv
                end
                copy[sk] = inner
            else
                copy[sk] = sv
            end
        end
        EC.db[k] = copy
    else
        EC.db[k] = v
    end
end

loadMod("src/chat/Display.lua")
loadMod("src/chat/Mentions.lua")
loadMod("src/chat/Filtering.lua")
loadMod("src/chat/TabProfiles.lua")
loadMod("src/chat/SettingsIO.lua")
loadMod("src/chat/Sounds.lua")
loadMod("src/chat/TabFilters.lua")
loadMod("src/chat/Notes.lua")
loadMod("src/chat/Tabs.lua")
loadMod("src/chat/TabUnread.lua")
loadMod("src/chat/TabCreate.lua")
loadMod("src/chat/InputEnhance.lua")

SOUNDS = SOUNDS
    or {
        NONE = "No_Sound",
        NEW_NOTIFICATION = "New_Notification",
        QUEST_ACCEPTED = "Quest_Accepted",
        MAIL_NEW = "New_Mail",
    }
PlaySound = PlaySound or function() end
IsFriend = IsFriend or function()
    return false
end
IsPlayerInGroup = IsPlayerInGroup or function()
    return false
end
IsUnitGrouped = IsUnitGrouped or function()
    return false
end
GetGroupSize = GetGroupSize or function()
    return 0
end
GetNumGuilds = GetNumGuilds or function()
    return 0
end
GetDisplayName = GetDisplayName or function()
    return "@test"
end
GetUnitName = GetUnitName or function()
    return "TestChar"
end
GetCurrentCharacterId = GetCurrentCharacterId or function()
    return 1001
end
KEY_UPARROW = KEY_UPARROW or 1
KEY_DOWNARROW = KEY_DOWNARROW or 2
CHAT_CHANNEL_WHISPER_SENT = CHAT_CHANNEL_WHISPER_SENT or 3
EVENT_PLAYER_COMBAT_STATE = EVENT_PLAYER_COMBAT_STATE or 12345


