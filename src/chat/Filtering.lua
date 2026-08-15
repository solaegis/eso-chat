-- EsoChat - Message filtering (spam presets, keywords, flood)

local EC = EsoChat

EC.Filtering = EC.Filtering or {}
local Filtering = EC.Filtering

local lastBySender = {} -- key -> { text, ts }

local LFG_PATTERNS = { "lfg", "lfm", "lf ", "looking for" }
local TRADE_PATTERNS = { "wtb", "wts", "wtt", "wtt ", "selling ", "buying " }
local RECRUIT_PATTERNS = { "recruiting", "guild recruit", "join our guild", "looking for members" }

local function getCfg()
    return EC.db and EC.db.filtering or EC.defaults.filtering
end

local function now()
    if GetTimeStamp then
        return GetTimeStamp()
    end
    return os.time()
end

local function matchesAny(lower, patterns)
    for _, p in ipairs(patterns) do
        if string.find(lower, p, 1, true) then
            return true
        end
    end
    return false
end

local function channelAllowed(channelType, cfg)
    if channelType == CHAT_CHANNEL_ZONE or channelType == CHAT_CHANNEL_ZONE_LANGUAGE_1 then
        return cfg.applyToZone ~= false
    end
    if channelType == CHAT_CHANNEL_SAY then
        return cfg.applyToSay == true
    end
    if channelType == CHAT_CHANNEL_GUILD_1
        or channelType == CHAT_CHANNEL_GUILD_2
        or channelType == CHAT_CHANNEL_GUILD_3
        or channelType == CHAT_CHANNEL_GUILD_4
        or channelType == CHAT_CHANNEL_GUILD_5
    then
        return cfg.applyToGuild == true
    end
    return false
end

function Filtering.ShouldBlock(channelType, fromName, text)
    local cfg = getCfg()
    if not cfg.enabled then
        return false
    end
    if not channelAllowed(channelType, cfg) then
        return false
    end
    text = text or ""
    local lower = string.lower(text)

    if cfg.blockLFG and matchesAny(lower, LFG_PATTERNS) then
        return true
    end
    if cfg.blockTrade and matchesAny(lower, TRADE_PATTERNS) then
        return true
    end
    if cfg.blockRecruit and matchesAny(lower, RECRUIT_PATTERNS) then
        return true
    end

    local custom = cfg.customKeywords or ""
    for line in string.gmatch(custom .. "\n", "(.-)\n") do
        line = string.gsub(line, "^%s+", "")
        line = string.gsub(line, "%s+$", "")
        if line ~= "" and string.find(lower, string.lower(line), 1, true) then
            return true
        end
    end

    if cfg.floodProtect then
        local key = tostring(fromName or "")
        local prev = lastBySender[key]
        local t = now()
        local window = tonumber(cfg.floodSeconds) or 5
        if prev and prev.text == text and (t - (prev.ts or 0)) <= window then
            return true
        end
        lastBySender[key] = { text = text, ts = t }
    end

    return false
end

return Filtering
