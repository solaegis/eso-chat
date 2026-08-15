-- EsoChat - Mention detection and highlighting

local EC = EsoChat

EC.Mentions = EC.Mentions or {}
local Mentions = EC.Mentions

local function getCfg()
    return EC.db and EC.db.mentions or EC.defaults.mentions
end

--- Parse newline-separated keywords.
function Mentions.GetKeywords()
    local cfg = getCfg()
    local raw = cfg.keywords or ""
    local list = {}
    for line in string.gmatch(raw .. "\n", "(.-)\n") do
        line = string.gsub(line, "^%s+", "")
        line = string.gsub(line, "%s+$", "")
        if line ~= "" then
            table.insert(list, line)
        end
    end
    return list
end

local function isWhisperChannel(channelType)
    return channelType == CHAT_CHANNEL_WHISPER
        or channelType == CHAT_CHANNEL_WHISPER_SENT
        or channelType == CHAT_CATEGORY_WHISPER_INCOMING
        or channelType == CHAT_CATEGORY_WHISPER_OUTGOING
end

local function isSystemChannel(channelType)
    return channelType == CHAT_CHANNEL_SYSTEM or channelType == CHAT_CATEGORY_SYSTEM
end

--- Returns matched keyword or nil, and optionally highlighted text.
function Mentions.Match(text, channelType)
    local cfg = getCfg()
    if not cfg.enabled then
        return nil, text
    end
    if cfg.excludeWhispers and isWhisperChannel(channelType) then
        return nil, text
    end
    if cfg.excludeSystem and isSystemChannel(channelType) then
        return nil, text
    end
    text = text or ""
    local keywords = Mentions.GetKeywords()
    if #keywords == 0 then
        return nil, text
    end

    local lower = string.lower(text)
    local matched = nil
    local useRegex = cfg.useRegex == true

    for _, kw in ipairs(keywords) do
        if useRegex then
            local ok, found = pcall(function()
                return string.find(text, kw)
            end)
            if ok and found then
                matched = kw
                break
            end
        else
            if string.find(lower, string.lower(kw), 1, true) then
                matched = kw
                break
            end
        end
    end

    if not matched then
        return nil, text
    end

    local r = cfg.highlightColorR or 1
    local g = cfg.highlightColorG or 0.85
    local b = cfg.highlightColorB or 0.2
    local hex = string.format("%02X%02X%02X", r * 255, g * 255, b * 255)
    local highlighted = text
    if not useRegex then
        -- Case-insensitive replace of first match occurrence
        local pattern = string.gsub(matched, "(%W)", "%%%1")
        highlighted = string.gsub(text, "([%w%p%s]*" .. pattern .. "[%w%p%s]*)", function(chunk)
            return string.format("|c%s%s|r", hex, chunk)
        end, 1)
        -- Simpler: wrap the keyword itself
        local idx = string.find(lower, string.lower(matched), 1, true)
        if idx then
            local before = string.sub(text, 1, idx - 1)
            local mid = string.sub(text, idx, idx + #matched - 1)
            local after = string.sub(text, idx + #matched)
            highlighted = before .. string.format("|c%s%s|r", hex, mid) .. after
        end
    end
    return matched, highlighted
end

return Mentions
