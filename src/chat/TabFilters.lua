-- EsoChat - Special filter tabs (Whispers / Mentions / Friends)
-- Mentions and Friends inject conversation-complete copies; Whispers uses categories.

local EC = EsoChat

EC.TabFilters = EC.TabFilters or {}
local TabFilters = EC.TabFilters

local MODES = {
    none = true,
    whispers = true,
    mentions = true,
    friends = true,
    notes = true,
}

-- Session-only sticky maps: key -> { channelType = n, expiresAt = ts }
local mentionSticky = {}
local friendSticky = {}
local started = false
local focusHooked = false

local function getCfg()
    return EC.db and EC.db.tabs or (EC.defaults and EC.defaults.tabs) or {}
end

local function now()
    if GetTimeStamp then
        return GetTimeStamp()
    end
    return os.time()
end

function TabFilters.ClampStickyMinutes(v)
    v = tonumber(v) or 5
    if v < 1 then
        v = 1
    end
    if v > 60 then
        v = 60
    end
    return v
end

function TabFilters.GetStickySeconds()
    local cfg = getCfg()
    return TabFilters.ClampStickyMinutes(cfg.conversationStickyMinutes) * 60
end

function TabFilters.IsValidMode(mode)
    return mode ~= nil and MODES[mode] == true
end

local function stripName(name)
    name = tostring(name or "")
    name = string.gsub(name, "|c%x%x%x%x%x%x%x%x", "")
    name = string.gsub(name, "|r", "")
    name = string.gsub(name, "%^%w+", "")
    name = string.gsub(name, "^%s+", "")
    name = string.gsub(name, "%s+$", "")
    return name
end

function TabFilters.NormalizeKey(name)
    local s = stripName(name)
    if s == "" then
        return nil
    end
    return string.lower(s)
end

local function isWhisperChannel(channelType)
    return channelType == CHAT_CHANNEL_WHISPER or channelType == CHAT_CHANNEL_WHISPER_SENT
end

local function isLocalPlayer(fromName, fromDisplayName)
    local dn = TabFilters.NormalizeKey(fromDisplayName)
    local cn = TabFilters.NormalizeKey(fromName)
    local selfAccount = GetDisplayName and TabFilters.NormalizeKey(GetDisplayName()) or nil
    local selfChar = GetUnitName and TabFilters.NormalizeKey(GetUnitName("player")) or nil
    if selfAccount and dn and dn == selfAccount then
        return true
    end
    if selfChar and cn and cn == selfChar then
        return true
    end
    return false
end

local function partnerKey(channelType, fromName, fromDisplayName)
    return TabFilters.NormalizeKey(fromDisplayName) or TabFilters.NormalizeKey(fromName)
end

local function pruneSticky(map)
    local t = now()
    for k, entry in pairs(map) do
        if not entry or (entry.expiresAt or 0) < t then
            map[k] = nil
        end
    end
end

function TabFilters.TouchSticky(map, key, channelType)
    if not key then
        return
    end
    pruneSticky(map)
    map[key] = {
        channelType = channelType,
        expiresAt = now() + TabFilters.GetStickySeconds(),
    }
end

function TabFilters.IsSticky(map, key, channelType)
    if not key then
        return false
    end
    pruneSticky(map)
    local entry = map[key]
    if not entry then
        return false
    end
    if channelType ~= nil and entry.channelType ~= nil and entry.channelType ~= channelType then
        if not (isWhisperChannel(channelType) and isWhisperChannel(entry.channelType)) then
            return false
        end
    end
    return true
end

function TabFilters.ClearSessionSticky()
    mentionSticky = {}
    friendSticky = {}
end

function TabFilters.GetMentionSticky()
    return mentionSticky
end

function TabFilters.GetFriendSticky()
    return friendSticky
end

local function playerNameMatchesText(text)
    text = string.lower(tostring(text or ""))
    if text == "" then
        return false
    end
    local selfAccount = GetDisplayName and TabFilters.NormalizeKey(GetDisplayName()) or nil
    local selfChar = GetUnitName and TabFilters.NormalizeKey(GetUnitName("player")) or nil
    if selfAccount and selfAccount ~= "" and string.find(text, selfAccount, 1, true) then
        return true
    end
    if selfChar and selfChar ~= "" and string.find(text, selfChar, 1, true) then
        return true
    end
    return false
end

function TabFilters.IsFriendName(fromName, fromDisplayName)
    if not IsFriend then
        return false
    end
    local dn = stripName(fromDisplayName)
    local cn = stripName(fromName)
    if dn ~= "" then
        local ok, result = pcall(IsFriend, dn)
        if ok and result then
            return true
        end
    end
    if cn ~= "" and cn ~= dn then
        local ok, result = pcall(IsFriend, cn)
        if ok and result then
            return true
        end
    end
    return false
end

function TabFilters.ShouldInjectMentions(channelType, fromName, text, fromDisplayName, opts)
    opts = opts or {}
    local stickyMap = opts.stickyMap or mentionSticky
    local localPlayer = opts.isLocalPlayer
    if localPlayer == nil then
        localPlayer = isLocalPlayer(fromName, fromDisplayName)
    end
    local key = partnerKey(channelType, fromName, fromDisplayName)

    local mentionHit = false
    if opts.mentionHit ~= nil then
        mentionHit = opts.mentionHit
    else
        if EC.Mentions and EC.Mentions.Match then
            local matched = EC.Mentions.Match(text, channelType)
            if matched then
                mentionHit = true
            end
        end
        if not mentionHit and playerNameMatchesText(text) then
            mentionHit = true
        end
    end

    if mentionHit and not localPlayer then
        return true, key, "hit"
    end

    if localPlayer then
        pruneSticky(stickyMap)
        for stickyKey, entry in pairs(stickyMap) do
            if entry and (entry.expiresAt or 0) >= now() then
                if entry.channelType == channelType
                    or (isWhisperChannel(channelType) and isWhisperChannel(entry.channelType))
                then
                    return true, stickyKey, "self_sticky"
                end
            end
        end
        return false, nil, nil
    end

    if key and TabFilters.IsSticky(stickyMap, key, channelType) then
        return true, key, "partner_sticky"
    end

    return false, nil, nil
end

function TabFilters.ShouldInjectFriends(channelType, fromName, text, fromDisplayName, opts)
    opts = opts or {}
    local stickyMap = opts.stickyMap or friendSticky
    local localPlayer = opts.isLocalPlayer
    if localPlayer == nil then
        localPlayer = isLocalPlayer(fromName, fromDisplayName)
    end
    local key = partnerKey(channelType, fromName, fromDisplayName)

    local fromFriend = opts.fromFriend
    if fromFriend == nil then
        fromFriend = TabFilters.IsFriendName(fromName, fromDisplayName)
    end

    if not localPlayer and fromFriend then
        return true, key, "from_friend"
    end

    if localPlayer and isWhisperChannel(channelType) then
        local toFriend = opts.toFriend
        if toFriend == nil then
            toFriend = TabFilters.IsFriendName(fromName, fromDisplayName)
        end
        if toFriend then
            return true, key, "to_friend"
        end
    end

    if localPlayer then
        pruneSticky(stickyMap)
        for stickyKey, entry in pairs(stickyMap) do
            if entry and (entry.expiresAt or 0) >= now() then
                if entry.channelType == channelType
                    or (isWhisperChannel(channelType) and isWhisperChannel(entry.channelType))
                then
                    return true, stickyKey, "self_sticky"
                end
            end
        end
    end

    return false, nil, nil
end

local function allCategoriesDisabled()
    local cats = {}
    if EC.Tabs and EC.Tabs.ListCategories then
        for _, cat in ipairs(EC.Tabs.ListCategories()) do
            cats[cat.name] = false
        end
    end
    return cats
end

local function whisperOnlyCategories()
    local cats = allCategoriesDisabled()
    cats.CHAT_CATEGORY_WHISPER_INCOMING = true
    cats.CHAT_CATEGORY_WHISPER_OUTGOING = true
    return cats
end

function TabFilters.GetLayoutEntry(tabName)
    local cfg = getCfg()
    cfg.layout = cfg.layout or {}
    for _, entry in ipairs(cfg.layout) do
        if entry.name and tabName and string.lower(entry.name) == string.lower(tabName) then
            return entry
        end
    end
    return nil
end

function TabFilters.SetLayoutFilterMode(tabName, mode)
    local cfg = getCfg()
    cfg.layout = cfg.layout or {}
    local entry = TabFilters.GetLayoutEntry(tabName)
    if not entry then
        entry = { name = tabName, filterMode = mode, overrides = {}, categories = {} }
        table.insert(cfg.layout, entry)
    else
        entry.filterMode = mode
    end
    return entry
end

function TabFilters.GetModeForTab(tabName)
    local entry = TabFilters.GetLayoutEntry(tabName)
    if entry and entry.filterMode then
        return entry.filterMode
    end
    return "none"
end

function TabFilters.FindTabByMode(mode)
    local cfg = getCfg()
    local preferred = nil
    if mode == "whispers" then
        preferred = cfg.whispersTabName or "Whispers"
    elseif mode == "mentions" then
        preferred = cfg.mentionsTabName or "Mentions"
    elseif mode == "friends" then
        preferred = cfg.friendsTabName or "Friends"
    elseif mode == "notes" then
        preferred = cfg.notesTabName or "Notes"
        if EC.db and EC.db.notes and EC.db.notes.tabName and EC.db.notes.tabName ~= "" then
            preferred = EC.db.notes.tabName
        end
    end
    if preferred and EC.Tabs then
        local tab = EC.Tabs.FindByName(preferred)
        if tab then
            return tab
        end
    end
    for _, entry in ipairs(cfg.layout or {}) do
        if entry.filterMode == mode and entry.name and EC.Tabs then
            local tab = EC.Tabs.FindByName(entry.name)
            if tab then
                return tab
            end
        end
    end
    return nil
end

function TabFilters.ApplyMode(tab, mode)
    if not tab or not TabFilters.IsValidMode(mode) or not EC.Tabs then
        return false
    end
    if mode == "whispers" then
        EC.Tabs.ApplyCategories(tab.containerIndex, tab.tabIndex, whisperOnlyCategories())
    elseif mode == "mentions" or mode == "friends" or mode == "notes" then
        EC.Tabs.ApplyCategories(tab.containerIndex, tab.tabIndex, allCategoriesDisabled())
    end
    TabFilters.SetLayoutFilterMode(tab.name, mode)
    return true
end

function TabFilters.EnsureTab(mode, nameOverride, opts)
    opts = opts or {}
    if not TabFilters.IsValidMode(mode) or mode == "none" then
        return false
    end
    local cfg = getCfg()
    if cfg.specialTabsEnabled == false then
        EC.Chat("Special filter tabs are disabled in settings.")
        return false
    end
    if not EC.Tabs then
        return false
    end
    local name = nameOverride
    if not name or name == "" then
        name = cfg.whispersTabName or "Whispers"
        if mode == "mentions" then
            name = cfg.mentionsTabName or "Mentions"
        elseif mode == "friends" then
            name = cfg.friendsTabName or "Friends"
        elseif mode == "notes" then
            name = cfg.notesTabName or "Notes"
            if EC.db and EC.db.notes and EC.db.notes.tabName and EC.db.notes.tabName ~= "" then
                name = EC.db.notes.tabName
            end
        end
    end
    if mode == "notes" then
        cfg.notesTabName = name
        if EC.db and EC.db.notes then
            EC.db.notes.tabName = name
        end
    end
    local tab = EC.Tabs.FindByName(name)
    if not tab then
        local createOpts = { silent = opts.silent == true }
        if not EC.Tabs.Create(name, createOpts) then
            return false
        end
        tab = EC.Tabs.FindByName(name)
    end
    if not tab then
        return false
    end
    TabFilters.ApplyMode(tab, mode)
    if not opts.silent then
        EC.Chat(string.format("Special tab ready: %s (%s)", name, mode))
    end
    return true
end

function TabFilters.SetMode(tabName, mode)
    if not TabFilters.IsValidMode(mode) then
        EC.Chat("Unknown mode. Use none|whispers|mentions|friends|notes")
        return false
    end
    local tab = EC.Tabs and EC.Tabs.FindByName(tabName)
    if not tab then
        EC.Chat(EC.L("tab_not_found", tostring(tabName)))
        return false
    end
    if mode == "none" then
        TabFilters.SetLayoutFilterMode(tab.name, "none")
        EC.Chat(string.format("Cleared filter mode on %s", tab.name))
        return true
    end
    TabFilters.ApplyMode(tab, mode)
    EC.Chat(string.format("Set %s to mode %s", tab.name, mode))
    return true
end

function TabFilters.ApplyAllModes()
    local cfg = getCfg()
    if not cfg.layout or not EC.Tabs then
        return
    end
    for _, entry in ipairs(cfg.layout) do
        local mode = entry.filterMode or "none"
        if mode ~= "none" and entry.name then
            local tab = EC.Tabs.FindByName(entry.name)
            if tab then
                TabFilters.ApplyMode(tab, mode)
            end
        end
    end
end

local function formatInjectLine(channelType, fromName, text, fromDisplayName)
    local body = text or ""
    if EC.Display and EC.Display.FormatMessageText then
        body = EC.Display.FormatMessageText(body)
    end
    if EC.Mentions and EC.Mentions.Match then
        local _, highlighted = EC.Mentions.Match(body, channelType)
        if highlighted then
            body = highlighted
        end
    end
    local ts = ""
    if EC.Display and EC.Display.FormatTimestamp then
        ts = EC.Display.FormatTimestamp() or ""
    end
    local name = fromName
    if EC.Display and EC.Display.FormatName then
        name = EC.Display.FormatName(fromName, fromDisplayName)
    end
    if name and name ~= "" then
        return string.format("%s%s: %s", ts, name, body or "")
    end
    return ts .. (body or "")
end

function TabFilters.Inject(mode, line)
    local tab = TabFilters.FindTabByMode(mode)
    if not tab or not line or line == "" then
        return false
    end
    local container = nil
    if CHAT_SYSTEM then
        if CHAT_SYSTEM.containers then
            container = CHAT_SYSTEM.containers[tab.containerIndex]
        end
        if not container and CHAT_SYSTEM.primaryContainer and tab.containerIndex == 1 then
            container = CHAT_SYSTEM.primaryContainer
        end
    end
    if not container or not container.windows then
        return false
    end
    local window = container.windows[tab.tabIndex]
    if not window then
        return false
    end
    local ok = false
    if window.buffer and window.buffer.AddMessage then
        ok = pcall(function()
            window.buffer:AddMessage(line)
        end)
    end
    if not ok and container.AddEventMessageToWindow then
        ok = pcall(function()
            container:AddEventMessageToWindow(window, line, CHAT_CATEGORY_SAY)
        end)
    end
    if ok and EC.Tabs and EC.Tabs.SignalAlert then
        local cfg = getCfg()
        local prev = cfg.alertTabPrefer
        cfg.alertTabPrefer = tab.name
        local kind = mode == "whispers" and "whisper" or "mention"
        EC.Tabs.SignalAlert(kind, mode)
        cfg.alertTabPrefer = prev
    end
    return ok
end

function TabFilters.OnTabFocused(tab)
    if not tab then
        return
    end
    if EC.Notes and EC.Notes.OnTabFocused then
        EC.Notes.OnTabFocused(tab)
    end
    local mode = TabFilters.GetModeForTab(tab.name)
    if mode == "none" then
        return
    end
    local cfg = getCfg()
    cfg.selectedTabKey = tab.name
    if EC.Tabs and EC.Tabs.RestoreRememberedChannel then
        EC.Tabs.RestoreRememberedChannel(tab.key)
    end
end

function TabFilters.OnChatMessage(channelType, fromName, text, fromDisplayName)
    local cfg = getCfg()
    if cfg.specialTabsEnabled == false or cfg.enabled == false then
        return
    end
    if EC.db and EC.db.enabled == false then
        return
    end
    if EC.Formatter and EC.Formatter.UsesGamepadChat and EC.Formatter.UsesGamepadChat() then
        return
    end
    if EC.Filtering and EC.Filtering.ShouldBlock and EC.Filtering.ShouldBlock(channelType, fromName, text) then
        return
    end

    local line = formatInjectLine(channelType, fromName, text, fromDisplayName)
    local localPlayer = isLocalPlayer(fromName, fromDisplayName)
    local key = partnerKey(channelType, fromName, fromDisplayName)

    local injectMen, stickyKeyMen, reasonMen = TabFilters.ShouldInjectMentions(
        channelType,
        fromName,
        text,
        fromDisplayName,
        { isLocalPlayer = localPlayer }
    )
    if injectMen then
        if stickyKeyMen then
            TabFilters.TouchSticky(mentionSticky, stickyKeyMen, channelType)
        end
        TabFilters.Inject("mentions", line)
        EC.DebugPrint("TABFILTERS", function()
            return "mentions inject reason=" .. tostring(reasonMen)
        end)
    end

    local injectFr, stickyKeyFr, reasonFr = TabFilters.ShouldInjectFriends(
        channelType,
        fromName,
        text,
        fromDisplayName,
        { isLocalPlayer = localPlayer }
    )
    if injectFr then
        local touchKey = stickyKeyFr or key
        if touchKey then
            TabFilters.TouchSticky(friendSticky, touchKey, channelType)
        end
        TabFilters.Inject("friends", line)
        EC.DebugPrint("TABFILTERS", function()
            return "friends inject reason=" .. tostring(reasonFr)
        end)
    end

    if cfg.rememberChannelPerTab and EC.Tabs and EC.Tabs.RememberChannel then
        local selected = cfg.selectedTabKey
        if selected and selected ~= "" then
            local mode = TabFilters.GetModeForTab(selected)
            if mode ~= "none" then
                local tab = EC.Tabs.FindByName(selected)
                if tab then
                    local target = nil
                    if isWhisperChannel(channelType) then
                        local dn = stripName(fromDisplayName)
                        local cn = stripName(fromName)
                        target = dn ~= "" and dn or cn
                    end
                    EC.Tabs.RememberChannel(tab.key, channelType, target)
                end
            end
        end
    end
end

local function installFocusHook()
    if focusHooked or not CHAT_SYSTEM then
        return
    end
    local container = CHAT_SYSTEM.primaryContainer
    if not container or not container.HandleTabClick then
        return
    end
    focusHooked = true
    local original = container.HandleTabClick
    container.HandleTabClick = function(self, tabControl, ...)
        local result = original(self, tabControl, ...)
        local tabIndex = tabControl and tabControl.index
        if tabIndex and EC.Tabs then
            for _, tab in ipairs(EC.Tabs.Enumerate()) do
                if tab.containerIndex == 1 and tab.tabIndex == tabIndex then
                    TabFilters.OnTabFocused(tab)
                    break
                end
            end
        end
        return result
    end
end

function TabFilters.Start()
    if started then
        TabFilters.ApplyAllModes()
        installFocusHook()
        return
    end
    started = true
    TabFilters.ApplyAllModes()
    installFocusHook()
    if zo_callLater then
        zo_callLater(installFocusHook, 1000)
        zo_callLater(function()
            TabFilters.ApplyAllModes()
        end, 1500)
    end
end

return TabFilters
