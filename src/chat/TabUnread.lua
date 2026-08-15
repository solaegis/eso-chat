-- EsoChat - Per-tab unread flash, pulse, and counter (session-only)

local EC = EsoChat

EC.TabUnread = EC.TabUnread or {}
local TabUnread = EC.TabUnread

local SUFFIX_PATTERN = " %(%d+%+?%)$"
local UPDATE_NAME = "EsoChatTabUnreadPulse"
local PULSE_PERIOD_MS = 1600
local MAX_DISPLAY = 99

-- key "c:t" -> { count, baseName, flashed, pulsing }
local state = {}
local hooksInstalled = false
local scrollBound = {}

local function getCfg()
    return EC.db and EC.db.tabs or EC.defaults.tabs
end

local function pulseEnabled()
    local cfg = getCfg()
    return cfg and cfg.unreadPulseEnabled ~= false
end

local function counterEnabled()
    local cfg = getCfg()
    return cfg and cfg.unreadCounterEnabled ~= false
end

local function tabKey(containerIndex, tabIndex)
    return string.format("%d:%d", containerIndex, tabIndex)
end

function TabUnread.StripSuffix(name)
    if not name or type(name) ~= "string" then
        return name
    end
    return (string.gsub(name, SUFFIX_PATTERN, ""))
end

function TabUnread.FormatLabel(baseName, count)
    if not count or count < 1 then
        return baseName
    end
    if count > MAX_DISPLAY then
        return string.format("%s (%d+)", baseName, MAX_DISPLAY)
    end
    return string.format("%s (%d)", baseName, count)
end

--- Prefer containers[index]; fall back to primaryContainer for index 1 (TabFilters pattern).
function TabUnread.ResolveContainer(containerIndex)
    if not CHAT_SYSTEM or not containerIndex then
        return nil
    end
    local container = CHAT_SYSTEM.containers and CHAT_SYSTEM.containers[containerIndex]
    if not container and containerIndex == 1 and CHAT_SYSTEM.primaryContainer then
        container = CHAT_SYSTEM.primaryContainer
    end
    return container
end

local function getWindow(containerIndex, tabIndex)
    local container = TabUnread.ResolveContainer(containerIndex)
    if not container or not container.windows then
        return nil, nil
    end
    return container, container.windows[tabIndex]
end

local function getBaseName(containerIndex, tabIndex, window)
    local entry = state[tabKey(containerIndex, tabIndex)]
    if entry and entry.baseName and entry.baseName ~= "" then
        return entry.baseName
    end
    if GetChatContainerTabInfo then
        local ok, name = pcall(GetChatContainerTabInfo, containerIndex, tabIndex)
        if ok and name and name ~= "" then
            return TabUnread.StripSuffix(name)
        end
    end
    if window and window.tab and ZO_TabButton_Text_GetText then
        local ok, text = pcall(ZO_TabButton_Text_GetText, window.tab)
        if ok and text and text ~= "" then
            return TabUnread.StripSuffix(text)
        end
    end
    return string.format("Tab %d", tabIndex)
end

local function setDisplayText(container, window, text)
    if not window or not window.tab or not text then
        return false
    end
    local ok = false
    if ZO_TabButton_Text_SetText then
        ok = pcall(ZO_TabButton_Text_SetText, window.tab, text)
    end
    local textCtrl = window.tab.GetNamedChild and window.tab:GetNamedChild("Text")
    if textCtrl and textCtrl.SetText then
        local okChild = pcall(function()
            textCtrl:SetText(text)
        end)
        ok = ok or okChild
    end
    if ok and container and container.PerformLayout then
        pcall(function()
            container:PerformLayout()
        end)
    end
    return ok
end

local function restoreColors(window)
    if not window or not window.tab then
        return
    end
    if ZO_TabButton_Text_RestoreDefaultColors then
        pcall(ZO_TabButton_Text_RestoreDefaultColors, window.tab)
    end
    if ZO_TabButton_Text_AllowColorChanges then
        pcall(ZO_TabButton_Text_AllowColorChanges, window.tab, true)
    end
end

local function applyAlertColor(window, alpha)
    if not window or not window.tab then
        return
    end
    local color = TAB_ALERT_TEXT_COLOR or ZO_SECOND_CONTRAST_TEXT
    alpha = alpha or 1
    if ZO_TabButton_Text_AllowColorChanges then
        pcall(ZO_TabButton_Text_AllowColorChanges, window.tab, false)
    end
    if color and ZO_TabButton_Text_SetTextColor then
        pcall(ZO_TabButton_Text_SetTextColor, window.tab, color)
    end
    local textCtrl = window.tab.GetNamedChild and window.tab:GetNamedChild("Text")
    if textCtrl and textCtrl.SetAlpha then
        pcall(function()
            textCtrl:SetAlpha(alpha)
        end)
    elseif window.tab.SetAlpha then
        pcall(function()
            window.tab:SetAlpha(alpha)
        end)
    end
end

local function anyUnread()
    for _, entry in pairs(state) do
        if entry.count and entry.count > 0 then
            return true
        end
    end
    return false
end

local function anyPulsing()
    for _, entry in pairs(state) do
        if entry.pulsing then
            return true
        end
    end
    return false
end

local function stopUpdate()
    if EVENT_MANAGER and EVENT_MANAGER.UnregisterForUpdate then
        EVENT_MANAGER:UnregisterForUpdate(UPDATE_NAME)
    end
end

local function updateLabel(containerIndex, tabIndex)
    local key = tabKey(containerIndex, tabIndex)
    local entry = state[key]
    local container, window = getWindow(containerIndex, tabIndex)
    if not window then
        return
    end
    local base = getBaseName(containerIndex, tabIndex, window)
    if entry then
        entry.baseName = base
    end
    if counterEnabled() and entry and entry.count and entry.count > 0 then
        setDisplayText(container, window, TabUnread.FormatLabel(base, entry.count))
    else
        setDisplayText(container, window, base)
    end
end

local function reapplyUnreadLabels()
    for key, entry in pairs(state) do
        if entry.count and entry.count > 0 then
            local c, ti = key:match("^(%d+):(%d+)$")
            c, ti = tonumber(c), tonumber(ti)
            if c and ti then
                updateLabel(c, ti)
            end
        end
    end
end

local function pulseTick()
    local needPulse = pulseEnabled() and anyPulsing()
    local needLabels = counterEnabled() and anyUnread()
    if not needPulse and not needLabels then
        stopUpdate()
        return
    end
    if needLabels then
        reapplyUnreadLabels()
    end
    if not needPulse then
        return
    end
    local t = GetFrameTimeMilliseconds and GetFrameTimeMilliseconds() or (os.clock() * 1000)
    local phase = (t % PULSE_PERIOD_MS) / PULSE_PERIOD_MS
    local alpha = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi))
    local still = false
    for key, entry in pairs(state) do
        if entry.pulsing and entry.count and entry.count > 0 then
            local c, ti = key:match("^(%d+):(%d+)$")
            c, ti = tonumber(c), tonumber(ti)
            local _, window = getWindow(c, ti)
            if window then
                applyAlertColor(window, alpha)
                still = true
            end
        end
    end
    if not still and not needLabels then
        stopUpdate()
    end
end

local function ensureUpdate()
    local need = (pulseEnabled() and anyPulsing()) or (counterEnabled() and anyUnread())
    if not need then
        return
    end
    if not EVENT_MANAGER or not EVENT_MANAGER.RegisterForUpdate then
        return
    end
    EVENT_MANAGER:UnregisterForUpdate(UPDATE_NAME)
    EVENT_MANAGER:RegisterForUpdate(UPDATE_NAME, 50, pulseTick)
end

--- True when the player can currently see new messages on this tab.
function TabUnread.IsViewable(container, tabIndex)
    if not container or not tabIndex then
        return false
    end
    local window = container.windows and container.windows[tabIndex]
    if not window or not window.buffer then
        return false
    end
    if container.currentBuffer ~= window.buffer then
        return false
    end
    if container.IsScrolledUp then
        local ok, scrolledUp = pcall(function()
            return container:IsScrolledUp()
        end)
        if ok and scrolledUp then
            return false
        end
    end
    return true
end

local function flashOnce(window)
    if not window or not window.tab or not window.tab.Flash then
        return
    end
    pcall(function()
        window.tab:Flash()
    end)
end

local function startPulse(containerIndex, tabIndex)
    local key = tabKey(containerIndex, tabIndex)
    local entry = state[key]
    if not entry then
        return
    end
    if not pulseEnabled() then
        entry.pulsing = false
        ensureUpdate()
        return
    end
    entry.pulsing = true
    local _, window = getWindow(containerIndex, tabIndex)
    if window then
        applyAlertColor(window, 1)
    end
    ensureUpdate()
end

local function stopPulse(containerIndex, tabIndex)
    local key = tabKey(containerIndex, tabIndex)
    local entry = state[key]
    if entry then
        entry.pulsing = false
    end
    local _, window = getWindow(containerIndex, tabIndex)
    if window then
        local textCtrl = window.tab and window.tab.GetNamedChild and window.tab:GetNamedChild("Text")
        if textCtrl and textCtrl.SetAlpha then
            pcall(function()
                textCtrl:SetAlpha(1)
            end)
        end
        restoreColors(window)
    end
    if not anyPulsing() and not (counterEnabled() and anyUnread()) then
        stopUpdate()
    end
end

function TabUnread.GetCount(containerIndex, tabIndex)
    local entry = state[tabKey(containerIndex, tabIndex)]
    return entry and entry.count or 0
end

function TabUnread.Clear(containerIndex, tabIndex)
    local key = tabKey(containerIndex, tabIndex)
    local container, window = getWindow(containerIndex, tabIndex)
    local base = getBaseName(containerIndex, tabIndex, window)
    stopPulse(containerIndex, tabIndex)
    state[key] = nil
    if window then
        setDisplayText(container, window, base)
        restoreColors(window)
    end
end

local function resolveContainerIndex(container)
    if not container then
        return nil
    end
    if container.id and type(container.id) == "number" then
        return container.id
    end
    if CHAT_SYSTEM and CHAT_SYSTEM.containers then
        for i, c in pairs(CHAT_SYSTEM.containers) do
            if c == container and type(i) == "number" then
                return i
            end
        end
    end
    if CHAT_SYSTEM and container == CHAT_SYSTEM.primaryContainer then
        return 1
    end
    return nil
end

function TabUnread.MaybeClearContainer(container)
    if not container or not container.windows then
        return
    end
    local cIndex = resolveContainerIndex(container)
    if not cIndex then
        return
    end
    for tabIndex, window in ipairs(container.windows) do
        if window and TabUnread.IsViewable(container, tabIndex) and TabUnread.GetCount(cIndex, tabIndex) > 0 then
            TabUnread.Clear(cIndex, tabIndex)
        end
    end
end

function TabUnread.MaybeClearAll()
    if not GetNumChatContainers then
        return
    end
    local numContainers = GetNumChatContainers() or 0
    for cIndex = 1, numContainers do
        local container = TabUnread.ResolveContainer(cIndex)
        if container and container.windows then
            for tabIndex, _ in ipairs(container.windows) do
                if TabUnread.IsViewable(container, tabIndex) and TabUnread.GetCount(cIndex, tabIndex) > 0 then
                    TabUnread.Clear(cIndex, tabIndex)
                end
            end
        end
    end
end

local function bumpTab(containerIndex, tabIndex)
    local key = tabKey(containerIndex, tabIndex)
    local _, window = getWindow(containerIndex, tabIndex)
    local entry = state[key]
    if not entry then
        entry = {
            count = 0,
            baseName = getBaseName(containerIndex, tabIndex, window),
            flashed = false,
            pulsing = false,
        }
        state[key] = entry
    elseif not entry.baseName or entry.baseName == "" then
        entry.baseName = getBaseName(containerIndex, tabIndex, window)
    end
    entry.count = (entry.count or 0) + 1
    if pulseEnabled() and not entry.flashed then
        flashOnce(window)
        entry.flashed = true
    end
    if pulseEnabled() then
        startPulse(containerIndex, tabIndex)
    else
        ensureUpdate()
    end
    updateLabel(containerIndex, tabIndex)
end

function TabUnread.OnMessage(channelType)
    if not EC.db or EC.db.enabled == false then
        return
    end
    -- Intentionally not gated on tabs.enabled (unread works independently)
    if not pulseEnabled() and not counterEnabled() then
        return
    end
    if not GetChannelCategoryFromChannel then
        return
    end
    local ok, category = pcall(GetChannelCategoryFromChannel, channelType)
    if not ok or category == nil then
        return
    end
    if not GetNumChatContainers or not IsChatContainerTabCategoryEnabled then
        return
    end
    local numContainers = GetNumChatContainers() or 0
    for c = 1, numContainers do
        local numTabs = GetNumChatContainerTabs and (GetNumChatContainerTabs(c) or 0) or 0
        for t = 1, numTabs do
            local enabled = IsChatContainerTabCategoryEnabled(c, t, category)
            if enabled then
                local container = TabUnread.ResolveContainer(c)
                if not container or not TabUnread.IsViewable(container, t) then
                    bumpTab(c, t)
                end
            end
        end
    end
end

function TabUnread.RefreshLabels()
    for key, _ in pairs(state) do
        local c, t = key:match("^(%d+):(%d+)$")
        c, t = tonumber(c), tonumber(t)
        if c and t then
            updateLabel(c, t)
        end
    end
end

function TabUnread.OnTabRenamed(containerIndex, tabIndex, newName)
    local key = tabKey(containerIndex, tabIndex)
    local entry = state[key]
    if entry then
        entry.baseName = TabUnread.StripSuffix(newName or entry.baseName)
        updateLabel(containerIndex, tabIndex)
    end
end

--- Whether SignalAlert should skip its own Flash (unread owns it).
function TabUnread.OwnsFlash()
    return pulseEnabled()
end

--- Dump session unread state to chat (diagnostic).
function TabUnread.DumpToChat()
    EC.Chat("EsoChat unread (session):")
    EC.Chat(string.format(
        "  pulse=%s counter=%s",
        tostring(pulseEnabled()),
        tostring(counterEnabled())
    ))
    local numContainers = GetNumChatContainers and (GetNumChatContainers() or 0) or 0
    if numContainers == 0 then
        EC.Chat("  (no chat containers)")
        return
    end
    for c = 1, numContainers do
        local numTabs = GetNumChatContainerTabs and (GetNumChatContainerTabs(c) or 0) or 0
        for t = 1, numTabs do
            local count = TabUnread.GetCount(c, t)
            local _, window = getWindow(c, t)
            local base = getBaseName(c, t, window)
            local display = "?"
            if window and window.tab and ZO_TabButton_Text_GetText then
                local ok, text = pcall(ZO_TabButton_Text_GetText, window.tab)
                if ok then
                    display = tostring(text)
                end
            end
            EC.Chat(string.format(
                "  [%d:%d] base=%s count=%d display=%s window=%s",
                c,
                t,
                tostring(base),
                count,
                display,
                window and "yes" or "NO"
            ))
        end
    end
end

local function bindScrollbar(container, cIndex)
    if not container or not container.scrollbar then
        return
    end
    local id = tostring(cIndex)
    if scrollBound[id] then
        return
    end
    scrollBound[id] = true
    local bar = container.scrollbar
    local prev = bar.SetHandler and bar:GetHandler("OnValueChanged")
    if bar.SetHandler then
        bar:SetHandler("OnValueChanged", function(...)
            if prev then
                prev(...)
            end
            TabUnread.MaybeClearAll()
        end)
    end
end

function TabUnread.BindContainers()
    if not GetNumChatContainers then
        return
    end
    local numContainers = GetNumChatContainers() or 0
    for cIndex = 1, numContainers do
        local container = TabUnread.ResolveContainer(cIndex)
        if container then
            bindScrollbar(container, cIndex)
        end
    end
end

local function installHooks()
    if hooksInstalled then
        return
    end
    hooksInstalled = true

    local function postHandleTabClick(self)
        TabUnread.MaybeClearContainer(self)
        TabUnread.MaybeClearAll()
    end

    if SecurePostHook and SharedChatContainer and SharedChatContainer.HandleTabClick then
        pcall(SecurePostHook, SharedChatContainer, "HandleTabClick", postHandleTabClick)
    elseif SharedChatContainer and SharedChatContainer.HandleTabClick then
        local orig = SharedChatContainer.HandleTabClick
        SharedChatContainer.HandleTabClick = function(self, ...)
            orig(self, ...)
            postHandleTabClick(self)
        end
    end
end

function TabUnread.Start()
    if EC.Formatter and EC.Formatter.UsesGamepadChat and EC.Formatter.UsesGamepadChat() then
        return
    end
    installHooks()
    TabUnread.BindContainers()
    if zo_callLater then
        zo_callLater(function()
            TabUnread.BindContainers()
        end, 2000)
    end
end

--- Test helpers (session reset).
function TabUnread._ResetForTests()
    stopUpdate()
    state = {}
    scrollBound = {}
    hooksInstalled = false
end

function TabUnread._GetStateForTests()
    return state
end

return TabUnread
