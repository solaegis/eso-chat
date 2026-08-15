-- EsoChat - Chat history persistence

local EC = EsoChat

EC.History = EC.History or {}
local History = EC.History

local flushPending = false
local FLUSH_MS = 5000

local function getCfg()
    return EC.db and EC.db.history or EC.defaults.history
end

local function now()
    if GetTimeStamp then
        return GetTimeStamp()
    end
    return os.time()
end

function History.Prune()
    local cfg = getCfg()
    if not cfg.entries then
        cfg.entries = {}
        return
    end
    local maxEntries = tonumber(cfg.maxEntries) or 200
    if maxEntries > 1000 then
        maxEntries = 1000
    end
    if maxEntries < 10 then
        maxEntries = 10
    end
    local retention = tonumber(cfg.retentionHours) or 24
    local cutoff = nil
    if retention > 0 then
        cutoff = now() - (retention * 3600)
    end
    local kept = {}
    for i = 1, #cfg.entries do
        local e = cfg.entries[i]
        if e and (not cutoff or (e.ts or 0) >= cutoff) then
            table.insert(kept, e)
        end
    end
    while #kept > maxEntries do
        table.remove(kept, 1)
    end
    cfg.entries = kept
end

local function scheduleFlush()
    if flushPending then
        return
    end
    flushPending = true
    if zo_callLater then
        zo_callLater(function()
            flushPending = false
            History.Prune()
            if EC.SettingsIO and EC.SettingsIO.CheckSvWarning then
                EC.SettingsIO.CheckSvWarning()
            end
        end, FLUSH_MS)
    else
        flushPending = false
        History.Prune()
    end
end

function History.Capture(channelType, fromName, text, fromDisplayName)
    local cfg = getCfg()
    if not cfg.enabled then
        return
    end
    if not EC.db or EC.db.enabled == false then
        return
    end
    cfg.entries = cfg.entries or {}
    table.insert(cfg.entries, {
        ts = now(),
        channel = channelType,
        from = fromName,
        account = fromDisplayName,
        text = text,
    })
    scheduleFlush()
end

function History.Dump(n)
    local cfg = getCfg()
    local entries = cfg.entries or {}
    n = tonumber(n) or 20
    if n < 1 then
        n = 20
    end
    if #entries == 0 then
        EC.Chat(EC.L("history_empty"))
        return
    end
    local start = math.max(1, #entries - n + 1)
    EC.Chat(EC.L("history_header", math.min(n, #entries)))
    for i = start, #entries do
        local e = entries[i]
        EC.Chat(string.format("[%s] %s: %s", tostring(e.channel), tostring(e.from), tostring(e.text)))
    end
end

function History.Start()
    EVENT_MANAGER:RegisterForEvent(EC.NAME .. "History", EVENT_CHAT_MESSAGE_CHANNEL, function(_, channelType, fromName, text, isCustomerService, fromDisplayName)
        local blocked = EC.Filtering and EC.Filtering.ShouldBlock and EC.Filtering.ShouldBlock(channelType, fromName, text)
        if blocked then
            local fcfg = EC.db and EC.db.filtering
            if fcfg and fcfg.hideFromHistory then
                return
            end
            -- Still capture if hideFromHistory is false, but skip notifications
            History.Capture(channelType, fromName, text, fromDisplayName)
            return
        end
        History.Capture(channelType, fromName, text, fromDisplayName)
        if EC.Notifications and EC.Notifications.OnChatMessage then
            EC.Notifications.OnChatMessage(channelType, fromName, text, fromDisplayName)
        end
        if EC.TabFilters and EC.TabFilters.OnChatMessage then
            EC.TabFilters.OnChatMessage(channelType, fromName, text, fromDisplayName)
        end
        if EC.TabUnread and EC.TabUnread.OnMessage then
            EC.TabUnread.OnMessage(channelType)
        end
    end)
    EVENT_MANAGER:RegisterForEvent(EC.NAME .. "HistoryDeact", EVENT_PLAYER_DEACTIVATED, function()
        History.Prune()
    end)
end

return History
