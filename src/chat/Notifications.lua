-- EsoChat - Sound and visual notifications

local EC = EsoChat

EC.Notifications = EC.Notifications or {}
local Notifications = EC.Notifications

local function getCfg()
    return EC.db and EC.db.notifications or EC.defaults.notifications
end

local function playNamedSound(soundName)
    if EC.Sounds and EC.Sounds.Play then
        EC.Sounds.Play(soundName)
        return
    end
    if not soundName or soundName == "" or soundName == "NONE" then
        return
    end
    if PlaySound then
        pcall(PlaySound, soundName)
    end
end

--- Resolve sound name from a notifications settings field (LMP-aware).
function Notifications.ResolveSound(settingName, fallback)
    local cfg = getCfg()
    local name = cfg[settingName] or fallback or "New_Notification"
    if EC.Sounds and EC.Sounds.Normalize then
        name = EC.Sounds.Normalize(name)
    end
    if name == "NONE" then
        return name
    end
    if LibMediaProvider and LibMediaProvider.Fetch then
        local ok, media = pcall(function()
            return LibMediaProvider:Fetch("sound", name)
        end)
        if ok and media then
            return media
        end
    end
    return name
end

function Notifications.OnWhisper()
    local cfg = getCfg()
    if cfg.whisperSoundEnabled then
        playNamedSound(cfg.whisperSoundName or "New_Notification")
    end
    if cfg.whisperVisualEnabled and CENTER_SCREEN_ANNOUNCE and CENTER_SCREEN_ANNOUNCE.CreateMessage then
        pcall(function()
            CENTER_SCREEN_ANNOUNCE:CreateMessage(1, CSA_CATEGORY_SMALL_TEXT, "Whisper", "")
        end)
    end
    if EC.Tabs and EC.Tabs.SignalAlert then
        EC.Tabs.SignalAlert("whisper")
    end
end

function Notifications.OnMention(keyword)
    local cfg = getCfg()
    local mentions = EC.db and EC.db.mentions
    if mentions and mentions.soundEnabled == false then
        return
    end
    if cfg.mentionSoundEnabled ~= false then
        local sound = (mentions and mentions.soundName) or "New_Notification"
        playNamedSound(sound)
    end
    if EC.Tabs and EC.Tabs.SignalAlert then
        EC.Tabs.SignalAlert("mention", keyword)
    end
end

function Notifications.OnParty()
    local cfg = getCfg()
    if cfg.partySoundEnabled then
        playNamedSound(cfg.partySoundName or "New_Notification")
    end
    if EC.Tabs and EC.Tabs.SignalAlert then
        EC.Tabs.SignalAlert("party")
    end
end

--- Handle raw chat event for notification side effects.
function Notifications.OnChatMessage(channelType, fromName, text, fromDisplayName)
    if not EC.db or EC.db.enabled == false then
        return
    end
    if channelType == CHAT_CHANNEL_WHISPER then
        Notifications.OnWhisper()
    end
    if channelType == CHAT_CHANNEL_PARTY and getCfg().partySoundEnabled then
        Notifications.OnParty()
    end
    local matched = nil
    if EC.Mentions and EC.Mentions.Match then
        matched = EC.Mentions.Match(text, channelType)
    end
    if matched then
        Notifications.OnMention(matched)
    end
end

return Notifications
