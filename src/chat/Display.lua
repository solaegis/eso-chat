-- EsoChat - Display formatting helpers

local EC = EsoChat

EC.Display = EC.Display or {}
local Display = EC.Display

local function getDisplay()
    return EC.db and EC.db.display or EC.defaults.display
end

--- Strip ESO color codes from text.
function Display.StripColors(text)
    if not text then
        return ""
    end
    text = string.gsub(text, "|c%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    return text
end

--- Remove redundant says/yells phrasing.
function Display.StripSays(text)
    if not text then
        return ""
    end
    text = string.gsub(text, "%s+says[,:]?%s*", " ")
    text = string.gsub(text, "%s+yells[,:]?%s*", " ")
    return text
end

--- Remove simple zone tags like [Zone].
function Display.StripZoneTags(text)
    if not text then
        return ""
    end
    return string.gsub(text, "%[%w[^%]]*%]", "")
end

--- Format a timestamp prefix.
function Display.FormatTimestamp(now)
    local cfg = getDisplay()
    if not cfg.timestampEnabled then
        return ""
    end
    now = now or (GetTimeStamp and GetTimeStamp()) or os.time()
    if GetTimeString then
        -- Prefer game clock when available; fall back to os.date
        local ok, s = pcall(GetTimeString)
        if ok and s then
            local r = cfg.timestampColorR or 0.6
            local g = cfg.timestampColorG or 0.6
            local b = cfg.timestampColorB or 0.6
            local hex = string.format("%02X%02X%02X", r * 255, g * 255, b * 255)
            return string.format("|c%s[%s]|r ", hex, s)
        end
    end
    local fmt = cfg.timestamp24h and "%H:%M:%S" or "%I:%M:%S"
    local stamp = os.date(fmt, now)
    local r = cfg.timestampColorR or 0.6
    local g = cfg.timestampColorG or 0.6
    local b = cfg.timestampColorB or 0.6
    local hex = string.format("%02X%02X%02X", r * 255, g * 255, b * 255)
    return string.format("|c%s[%s]|r ", hex, stamp)
end

--- Resolve display name from character / account / both + nicknames.
function Display.FormatName(fromName, fromDisplayName)
    local cfg = getDisplay()
    local charName = fromName or ""
    local account = fromDisplayName or ""
    -- Strip links/control codes lightly
    charName = string.gsub(charName, "|H.-|h(.-)|h", "%1")
    account = string.gsub(account, "|H.-|h(.-)|h", "%1")

    local nickKey = account ~= "" and account or charName
    if cfg.nicknames and nickKey ~= "" and cfg.nicknames[nickKey] then
        return cfg.nicknames[nickKey]
    end

    local mode = cfg.nameMode or "character"
    if mode == "account" then
        return account ~= "" and account or charName
    elseif mode == "both" then
        if charName ~= "" and account ~= "" and charName ~= account then
            return string.format("%s(%s)", charName, account)
        end
        return charName ~= "" and charName or account
    end
    return charName ~= "" and charName or account
end

--- Apply display transforms to message body text.
function Display.FormatMessageText(text, overrides)
    local cfg = getDisplay()
    local stripSays = cfg.stripSays
    local stripZone = cfg.stripZoneTags
    local stripColors = cfg.stripColors
    if overrides then
        if overrides.stripColors ~= nil then
            stripColors = overrides.stripColors
        end
    end
    text = text or ""
    if stripColors then
        text = Display.StripColors(text)
    end
    if stripSays then
        text = Display.StripSays(text)
    end
    if stripZone then
        text = Display.StripZoneTags(text)
    end
    return text
end

--- Guild channel rename lookup.
function Display.GuildChannelLabel(channelId, fallback)
    local cfg = getDisplay()
    if cfg.guildChannelNames and channelId and cfg.guildChannelNames[tostring(channelId)] then
        return cfg.guildChannelNames[tostring(channelId)]
    end
    return fallback
end

--- Best-effort prevent chat text fade on keyboard buffers.
function Display.ApplyPreventFade()
    local cfg = getDisplay()
    if not cfg.preventFade or not CHAT_SYSTEM or not CHAT_SYSTEM.containers then
        return
    end
    for _, container in pairs(CHAT_SYSTEM.containers) do
        if container and container.windows then
            for _, window in pairs(container.windows) do
                if window and window.buffer and window.buffer.SetLineFade then
                    pcall(function()
                        window.buffer:SetLineFade(0, 0)
                    end)
                end
            end
        end
    end
end

return Display
