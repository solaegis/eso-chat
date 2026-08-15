-- EsoChat - Automation (greetings / templates) — default off

local EC = EsoChat

EC.Automation = EC.Automation or {}
local Automation = EC.Automation

local zoneWelcomed = {}
local sessionGreeted = false

local function getCfg()
    return EC.db and EC.db.automation or EC.defaults.automation
end

local function sendChat(message, channel, target)
    if not message or message == "" or not SendChatMessage then
        return
    end
    pcall(SendChatMessage, message, channel or CHAT_CHANNEL_SAY, target)
end

function Automation.OnPlayerActivated()
    local cfg = getCfg()
    if not cfg.enabled then
        return
    end
    if cfg.loginGreetingEnabled and not sessionGreeted and cfg.loginGreeting ~= "" then
        sessionGreeted = true
        sendChat(cfg.loginGreeting, CHAT_CHANNEL_SAY)
        EC.DebugPrint("AUTO", EC.L("automation_sent", "login"))
    end
    if cfg.guildGreetingEnabled and cfg.guildGreeting ~= "" then
        sendChat(cfg.guildGreeting, CHAT_CHANNEL_GUILD_1)
    end
    if cfg.zoneWelcomeEnabled and cfg.zoneWelcome ~= "" then
        local zone = GetUnitZone and GetUnitZone("player") or "zone"
        if not zoneWelcomed[zone] then
            zoneWelcomed[zone] = true
            sendChat(cfg.zoneWelcome, CHAT_CHANNEL_ZONE)
            if cfg.recruitmentEnabled and cfg.recruitment ~= "" then
                sendChat(cfg.recruitment, CHAT_CHANNEL_ZONE)
            end
        end
    end
end

function Automation.SendQuickWhisper(index, target)
    local cfg = getCfg()
    local msg = cfg.quickWhispers and cfg.quickWhispers[index]
    if msg and msg ~= "" and target then
        sendChat(msg, CHAT_CHANNEL_WHISPER, target)
    end
end

function Automation.Start()
    -- Player activated handled from ChatModules
end

return Automation
