-- EsoChat - Tab inventory, CRUD, layout restore, alert routing

local EC = EsoChat

EC.Tabs = EC.Tabs or {}
local Tabs = EC.Tabs

local CATEGORIES = {
    "CHAT_CATEGORY_SAY",
    "CHAT_CATEGORY_YELL",
    "CHAT_CATEGORY_WHISPER_INCOMING",
    "CHAT_CATEGORY_WHISPER_OUTGOING",
    "CHAT_CATEGORY_ZONE",
    "CHAT_CATEGORY_PARTY",
    "CHAT_CATEGORY_EMOTE",
    "CHAT_CATEGORY_SYSTEM",
    "CHAT_CATEGORY_GUILD_1",
    "CHAT_CATEGORY_GUILD_2",
    "CHAT_CATEGORY_GUILD_3",
    "CHAT_CATEGORY_GUILD_4",
    "CHAT_CATEGORY_GUILD_5",
    "CHAT_CATEGORY_OFFICER_1",
    "CHAT_CATEGORY_OFFICER_2",
    "CHAT_CATEGORY_OFFICER_3",
    "CHAT_CATEGORY_OFFICER_4",
    "CHAT_CATEGORY_OFFICER_5",
    "CHAT_CATEGORY_ZONE_ENGLISH",
    "CHAT_CATEGORY_ZONE_FRENCH",
    "CHAT_CATEGORY_ZONE_GERMAN",
    "CHAT_CATEGORY_ZONE_JAPANESE",
}

local function getCfg()
    return EC.db and EC.db.tabs or EC.defaults.tabs
end

local function catValue(name)
    return _G[name]
end

local lastChannels = {} -- tabKey -> { channel, target }

-- Combat pin session state (group tab visible in combat)
local groupPin = {
    active = false,
    previousTabName = nil,
    swapped = false,
    groupTabName = nil,
    otherTabName = nil,
}

function Tabs.ListCategories()
    local out = {}
    for _, name in ipairs(CATEGORIES) do
        local v = catValue(name)
        if v ~= nil then
            table.insert(out, { name = name, id = v })
        end
    end
    return out
end

function Tabs.Enumerate()
    local tabs = {}
    if not GetNumChatContainers then
        return tabs
    end
    local numContainers = GetNumChatContainers() or 0
    for c = 1, numContainers do
        local numTabs = GetNumChatContainerTabs(c) or 0
        for t = 1, numTabs do
            local name, isLocked, isInteractable, isCombatLog, areTimestampsEnabled =
                GetChatContainerTabInfo(c, t)
            local categories = {}
            for _, cat in ipairs(Tabs.ListCategories()) do
                local enabled = IsChatContainerTabCategoryEnabled(c, t, cat.id)
                categories[cat.name] = enabled and true or false
            end
            table.insert(tabs, {
                containerIndex = c,
                tabIndex = t,
                key = string.format("%d:%d", c, t),
                name = name or string.format("Tab %d", t),
                isLocked = isLocked,
                isInteractable = isInteractable,
                isCombatLog = isCombatLog,
                areTimestampsEnabled = areTimestampsEnabled,
                categories = categories,
                overrides = {},
            })
        end
    end
    return tabs
end

function Tabs.FindByName(name)
    if not name then
        return nil
    end
    name = string.lower(name)
    for _, tab in ipairs(Tabs.Enumerate()) do
        if string.lower(tab.name) == name then
            return tab
        end
    end
    return nil
end

function Tabs.SnapshotLayout()
    local cfg = getCfg()
    local prevModes = {}
    local prevGroup = {}
    for _, entry in ipairs(cfg.layout or {}) do
        if entry.name then
            if entry.filterMode then
                prevModes[entry.name] = entry.filterMode
            end
            if entry.groupChannel then
                prevGroup[entry.name] = true
            end
        end
    end
    local layout = {}
    for _, tab in ipairs(Tabs.Enumerate()) do
        local colors = nil
        if GetChatContainerColors then
            local ok, r, g, b, minA, maxA = pcall(GetChatContainerColors, tab.containerIndex)
            if ok then
                colors = { r = r, g = g, b = b, minA = minA, maxA = maxA }
            end
        end
        table.insert(layout, {
            name = tab.name,
            containerIndex = tab.containerIndex,
            isLocked = tab.isLocked,
            areTimestampsEnabled = tab.areTimestampsEnabled,
            categories = tab.categories,
            overrides = tab.overrides or {},
            filterMode = prevModes[tab.name] or "none",
            groupChannel = prevGroup[tab.name] == true,
            colors = colors,
            fontSize = GetChatFontSize and GetChatFontSize() or nil,
        })
    end
    cfg.layout = layout
    if EC.ContainerLayout and EC.ContainerLayout.Snapshot then
        EC.ContainerLayout.Snapshot()
    end
end

function Tabs.ApplyCategories(containerIndex, tabIndex, categories)
    if not categories or not SetChatContainerTabCategoryEnabled then
        return
    end
    for name, enabled in pairs(categories) do
        local id = catValue(name)
        if id ~= nil then
            pcall(SetChatContainerTabCategoryEnabled, containerIndex, tabIndex, id, enabled and true or false)
        end
    end
end

function Tabs.RestoreLayout()
    local cfg = getCfg()
    if not cfg.enabled or not cfg.restoreLayout then
        return
    end
    if not cfg.layout or #cfg.layout == 0 then
        return
    end
    if EC.Formatter and EC.Formatter.UsesGamepadChat and EC.Formatter.UsesGamepadChat() then
        return
    end

    for _, saved in ipairs(cfg.layout) do
        local live = Tabs.FindByName(saved.name)
        if not live then
            Tabs.Create(saved.name)
            live = Tabs.FindByName(saved.name)
        end
        if live then
            if SetChatContainerTabInfo then
                pcall(
                    SetChatContainerTabInfo,
                    live.containerIndex,
                    live.tabIndex,
                    saved.name,
                    saved.isLocked and true or false,
                    true,
                    saved.areTimestampsEnabled and true or false
                )
            end
            Tabs.ApplyCategories(live.containerIndex, live.tabIndex, saved.categories)
            if saved.filterMode and saved.filterMode ~= "none" and EC.TabFilters and EC.TabFilters.ApplyMode then
                EC.TabFilters.ApplyMode(live, saved.filterMode)
            elseif saved.filterMode then
                -- Persist none on layout entry
                if EC.TabFilters and EC.TabFilters.SetLayoutFilterMode then
                    EC.TabFilters.SetLayoutFilterMode(live.name, saved.filterMode)
                end
            end
            if saved.groupChannel and EC.Tabs.SetGroupChannelFlag then
                EC.Tabs.SetGroupChannelFlag(live.name, true)
            end
            if saved.colors and SetChatContainerColors then
                pcall(
                    SetChatContainerColors,
                    live.containerIndex,
                    saved.colors.r,
                    saved.colors.g,
                    saved.colors.b,
                    saved.colors.minA,
                    saved.colors.maxA
                )
            end
            if saved.fontSize and SetChatFontSize then
                pcall(SetChatFontSize, saved.fontSize)
            end
            -- Keep overrides on the saved layout entry
            saved.overrides = saved.overrides or {}
        end
    end
    -- groupChannel SoT: party on only while grouped (override snapshot categories)
    if Tabs.SyncGroupTabCategories then
        Tabs.SyncGroupTabCategories()
    end
    if EC.ContainerLayout and EC.ContainerLayout.Restore then
        EC.ContainerLayout.Restore()
    end
end

function Tabs.Create(name, opts)
    opts = opts or {}
    name = name or "EsoChat"
    if CHAT_SYSTEM and CHAT_SYSTEM.primaryContainer and CHAT_SYSTEM.primaryContainer.AddWindow then
        local ok = pcall(function()
            CHAT_SYSTEM.primaryContainer:AddWindow(name)
        end)
        if ok then
            if not opts.silent then
                EC.Chat(EC.L("tab_created", name))
            end
            return true
        end
    end
    if AddChatContainerTab then
        local ok = pcall(AddChatContainerTab, 1, name, false)
        if ok then
            if not opts.silent then
                EC.Chat(EC.L("tab_created", name))
            end
            return true
        end
    end
    return false
end

--- Create if missing; returns tab or nil.
function Tabs.Ensure(name, opts)
    opts = opts or {}
    local tab = Tabs.FindByName(name)
    if tab then
        return tab
    end
    if not Tabs.Create(name, { silent = opts.silent ~= false }) then
        return nil
    end
    return Tabs.FindByName(name)
end

function Tabs.GetLayoutEntry(tabName)
    local cfg = getCfg()
    cfg.layout = cfg.layout or {}
    if not tabName then
        return nil
    end
    for _, entry in ipairs(cfg.layout) do
        if entry.name and string.lower(entry.name) == string.lower(tabName) then
            return entry
        end
    end
    return nil
end

function Tabs.SetGroupChannelFlag(tabName, enabled)
    local cfg = getCfg()
    cfg.layout = cfg.layout or {}
    local entry = Tabs.GetLayoutEntry(tabName)
    if not entry then
        entry = {
            name = tabName,
            filterMode = "none",
            overrides = {},
            categories = {},
            groupChannel = enabled and true or false,
        }
        table.insert(cfg.layout, entry)
    else
        entry.groupChannel = enabled and true or false
    end
    return entry
end

function Tabs.FindGroupTab()
    local cfg = getCfg()
    for _, entry in ipairs(cfg.layout or {}) do
        if entry.groupChannel and entry.name then
            local tab = Tabs.FindByName(entry.name)
            if tab then
                return tab
            end
        end
    end
    return nil
end

function Tabs.PartyOnlyCategories()
    local cats = {}
    for _, cat in ipairs(Tabs.ListCategories()) do
        cats[cat.name] = false
    end
    cats.CHAT_CATEGORY_PARTY = true
    return cats
end

function Tabs.AllCategoriesDisabled()
    local cats = {}
    for _, cat in ipairs(Tabs.ListCategories()) do
        cats[cat.name] = false
    end
    return cats
end

--- Enable party category on the groupChannel tab only while grouped; otherwise all off.
function Tabs.SyncGroupTabCategories()
    local tab = Tabs.FindGroupTab()
    if not tab then
        return false
    end
    if Tabs.IsPlayerGrouped() then
        Tabs.ApplyCategories(tab.containerIndex, tab.tabIndex, Tabs.PartyOnlyCategories())
    else
        Tabs.ApplyCategories(tab.containerIndex, tab.tabIndex, Tabs.AllCategoriesDisabled())
    end
    return true
end

function Tabs.Focus(tab)
    if not tab then
        return false
    end
    local cfg = getCfg()
    cfg.selectedTabKey = tab.name
    if CHAT_SYSTEM and CHAT_SYSTEM.containers then
        local container = CHAT_SYSTEM.containers[tab.containerIndex]
        if container and container.SetCurrentWindow then
            pcall(function()
                container:SetCurrentWindow(tab.tabIndex)
            end)
        elseif container and container.windows and container.windows[tab.tabIndex] and container.windows[tab.tabIndex].tab then
            pcall(function()
                container.windows[tab.tabIndex].tab:OnMouseUp(nil, true)
            end)
        end
    end
    if EC.TabFilters and EC.TabFilters.OnTabFocused then
        EC.TabFilters.OnTabFocused(tab)
    elseif Tabs.RestoreRememberedChannel then
        Tabs.RestoreRememberedChannel(tab.key)
    end
    return true
end

function Tabs.SeedInputChannel(tab, channel, target)
    if not tab then
        return
    end
    lastChannels[tab.key] = { channel = channel, target = target }
    if CHAT_SYSTEM and CHAT_SYSTEM.SwitchToChannelAndTarget then
        pcall(function()
            CHAT_SYSTEM:SwitchToChannelAndTarget(channel, target)
        end)
    end
end

--- Move tab to front (index 1). Prefer TransferChatContainerTab; else swap metadata with tab 1.
function Tabs.MoveToFront(tab)
    if not tab or tab.tabIndex == 1 then
        return tab
    end
    if TransferChatContainerTab then
        local ok = pcall(TransferChatContainerTab, tab.containerIndex, tab.tabIndex, tab.containerIndex, 1)
        if ok then
            return Tabs.FindByName(tab.name)
        end
    end
    local container = CHAT_SYSTEM and CHAT_SYSTEM.containers and CHAT_SYSTEM.containers[tab.containerIndex]
    if container and container.TransferWindow then
        local ok = pcall(function()
            container:TransferWindow(tab.tabIndex, 1)
        end)
        if ok then
            return Tabs.FindByName(tab.name)
        end
    end
    if Tabs.SwapTabIndices(tab.containerIndex, tab.tabIndex, 1) then
        return Tabs.FindByName(tab.name)
    end
    return tab
end

function Tabs.SwapTabIndices(containerIndex, indexA, indexB)
    if not containerIndex or not indexA or not indexB or indexA == indexB then
        return false
    end
    if not GetChatContainerTabInfo or not SetChatContainerTabInfo then
        return false
    end
    local nameA, lockA, _, _, tsA = GetChatContainerTabInfo(containerIndex, indexA)
    local nameB, lockB, _, _, tsB = GetChatContainerTabInfo(containerIndex, indexB)
    if not nameA or not nameB then
        return false
    end
    local catsA = {}
    local catsB = {}
    for _, cat in ipairs(Tabs.ListCategories()) do
        catsA[cat.name] = IsChatContainerTabCategoryEnabled
            and IsChatContainerTabCategoryEnabled(containerIndex, indexA, cat.id)
        catsB[cat.name] = IsChatContainerTabCategoryEnabled
            and IsChatContainerTabCategoryEnabled(containerIndex, indexB, cat.id)
    end
    local modeA = EC.TabFilters and EC.TabFilters.GetModeForTab and EC.TabFilters.GetModeForTab(nameA) or "none"
    local modeB = EC.TabFilters and EC.TabFilters.GetModeForTab and EC.TabFilters.GetModeForTab(nameB) or "none"
    local entryA = Tabs.GetLayoutEntry(nameA)
    local entryB = Tabs.GetLayoutEntry(nameB)
    local groupA = entryA and entryA.groupChannel
    local groupB = entryB and entryB.groupChannel

    pcall(SetChatContainerTabInfo, containerIndex, indexA, nameB, lockB and true or false, true, tsB and true or false)
    pcall(SetChatContainerTabInfo, containerIndex, indexB, nameA, lockA and true or false, true, tsA and true or false)
    Tabs.ApplyCategories(containerIndex, indexA, catsB)
    Tabs.ApplyCategories(containerIndex, indexB, catsA)

    if EC.TabFilters and EC.TabFilters.SetLayoutFilterMode then
        EC.TabFilters.SetLayoutFilterMode(nameB, modeB)
        EC.TabFilters.SetLayoutFilterMode(nameA, modeA)
    end
    if groupA then
        Tabs.SetGroupChannelFlag(nameA, true)
    end
    if groupB then
        Tabs.SetGroupChannelFlag(nameB, true)
    end
    return true
end

function Tabs.Rename(oldName, newName)
    local tab = Tabs.FindByName(oldName)
    if not tab then
        EC.Chat(EC.L("tab_not_found", tostring(oldName)))
        return false
    end
    if SetChatContainerTabInfo then
        pcall(
            SetChatContainerTabInfo,
            tab.containerIndex,
            tab.tabIndex,
            newName,
            tab.isLocked and true or false,
            true,
            tab.areTimestampsEnabled and true or false
        )
        if EC.TabUnread and EC.TabUnread.OnTabRenamed then
            EC.TabUnread.OnTabRenamed(tab.containerIndex, tab.tabIndex, newName)
        end
        EC.Chat(EC.L("tab_renamed", newName))
        return true
    end
    return false
end

function Tabs.GetActiveOverrides()
    local cfg = getCfg()
    if not cfg.layout then
        return nil
    end
    -- Prefer selected tab key / current tab name if known
    local selected = cfg.selectedTabKey
    for _, entry in ipairs(cfg.layout) do
        if selected ~= "" and entry.name == selected and entry.overrides then
            return entry.overrides
        end
    end
    -- Fall back to first layout entry with overrides
    for _, entry in ipairs(cfg.layout) do
        if entry.overrides and next(entry.overrides) then
            return entry.overrides
        end
    end
    return nil
end

function Tabs.CopyCategories(fromName, toName)
    local from = Tabs.FindByName(fromName)
    local to = Tabs.FindByName(toName)
    if not from or not to then
        return false
    end
    Tabs.ApplyCategories(to.containerIndex, to.tabIndex, from.categories)
    return true
end

function Tabs.SignalAlert(kind, detail)
    local cfg = getCfg()
    if not cfg.enabled then
        return
    end
    local prefer = cfg.alertTabPrefer
    local target = nil
    if prefer and prefer ~= "" then
        target = Tabs.FindByName(prefer)
    end
    if not target then
        -- Find first tab that includes whisper/party categories
        for _, tab in ipairs(Tabs.Enumerate()) do
            if kind == "whisper" and (tab.categories.CHAT_CATEGORY_WHISPER_INCOMING or tab.categories.CHAT_CATEGORY_WHISPER_OUTGOING) then
                target = tab
                break
            end
            if kind == "party" and tab.categories.CHAT_CATEGORY_PARTY then
                target = tab
                break
            end
            if kind == "mention" then
                target = tab
                break
            end
        end
    end
    if not target then
        return
    end
    local unreadOwnsFlash = EC.TabUnread and EC.TabUnread.OwnsFlash and EC.TabUnread.OwnsFlash()
    if cfg.flashInactiveOnAlert and not unreadOwnsFlash and CHAT_SYSTEM and CHAT_SYSTEM.containers then
        local container = CHAT_SYSTEM.containers[target.containerIndex]
        if container and container.windows and container.windows[target.tabIndex] then
            local win = container.windows[target.tabIndex]
            if win and win.tab and win.tab.Flash then
                pcall(function()
                    win.tab:Flash()
                end)
            end
        end
    end
    local shouldSwitch = (kind == "whisper" and cfg.switchOnWhisper)
        or (kind == "mention" and cfg.switchOnMention)
        or (kind == "party" and cfg.switchOnParty)
    if shouldSwitch and CHAT_SYSTEM and CHAT_SYSTEM.containers then
        local container = CHAT_SYSTEM.containers[target.containerIndex]
        if container and container.SetCurrentWindow then
            pcall(function()
                container:SetCurrentWindow(target.tabIndex)
            end)
        elseif container and container.windows and container.windows[target.tabIndex] and container.windows[target.tabIndex].tab then
            pcall(function()
                container.windows[target.tabIndex].tab:OnMouseUp(nil, true)
            end)
        end
    end
    EC.DebugPrint("TABS", function()
        return string.format("Alert %s detail=%s tab=%s", tostring(kind), tostring(detail), target.name)
    end)
end

function Tabs.ListToChat()
    EC.Chat(EC.L("tab_list_header"))
    for _, tab in ipairs(Tabs.Enumerate()) do
        local mode = "none"
        if EC.TabFilters and EC.TabFilters.GetModeForTab then
            mode = EC.TabFilters.GetModeForTab(tab.name) or "none"
        end
        EC.Chat(string.format(
            "  [%s] %s (c%d t%d) mode=%s%s",
            tab.key,
            tab.name,
            tab.containerIndex,
            tab.tabIndex,
            mode,
            tab.isCombatLog and " combat" or ""
        ))
    end
end

function Tabs.DumpCategories(name)
    local tab = Tabs.FindByName(name)
    if not tab then
        EC.Chat(EC.L("tab_not_found", tostring(name)))
        return
    end
    EC.Chat("Categories for " .. tab.name .. ":")
    for catName, enabled in pairs(tab.categories) do
        if enabled then
            EC.Chat("  " .. catName)
        end
    end
end

function Tabs.RememberChannel(tabKey, channel, target)
    if not getCfg().rememberChannelPerTab then
        return
    end
    lastChannels[tabKey] = { channel = channel, target = target }
end

function Tabs.GetRememberedChannel(tabKey)
    return lastChannels[tabKey]
end

function Tabs.RestoreRememberedChannel(tabKey)
    local saved = lastChannels[tabKey]
    if not saved or not CHAT_SYSTEM then
        return
    end
    if CHAT_SYSTEM.SwitchToChannelAndTarget then
        pcall(function()
            CHAT_SYSTEM:SwitchToChannelAndTarget(saved.channel, saved.target)
        end)
    end
end

local function isPlayerGrouped()
    if IsUnitGrouped then
        local ok, grouped = pcall(IsUnitGrouped, "player")
        if ok and grouped then
            return true
        end
    end
    if GetGroupSize then
        local ok, size = pcall(GetGroupSize)
        if ok and size and size > 0 then
            return true
        end
    end
    return false
end

function Tabs.IsPlayerGrouped()
    return isPlayerGrouped()
end

local function currentFocusedTabName()
    local cfg = getCfg()
    if cfg.selectedTabKey and cfg.selectedTabKey ~= "" then
        return cfg.selectedTabKey
    end
    local tabs = Tabs.Enumerate()
    if tabs[1] then
        return tabs[1].name
    end
    return nil
end

function Tabs.ReleaseGroupCombatPin()
    if not groupPin.active then
        return
    end
    if groupPin.swapped and groupPin.groupTabName and groupPin.otherTabName then
        local groupTab = Tabs.FindByName(groupPin.groupTabName)
        local otherTab = Tabs.FindByName(groupPin.otherTabName)
        if groupTab and otherTab and groupTab.containerIndex == otherTab.containerIndex then
            Tabs.SwapTabIndices(groupTab.containerIndex, groupTab.tabIndex, otherTab.tabIndex)
        end
    end
    if groupPin.previousTabName then
        local prev = Tabs.FindByName(groupPin.previousTabName)
        if prev then
            Tabs.Focus(prev)
        end
    end
    groupPin.active = false
    groupPin.previousTabName = nil
    groupPin.swapped = false
    groupPin.groupTabName = nil
    groupPin.otherTabName = nil
end

function Tabs.ApplyGroupCombatPin()
    local cfg = getCfg()
    if not cfg.keepGroupTabVisibleInCombat then
        return
    end
    if not isPlayerGrouped() then
        Tabs.ReleaseGroupCombatPin()
        return
    end
    local groupTab = Tabs.FindGroupTab()
    if not groupTab then
        return
    end
    if not groupPin.active then
        groupPin.previousTabName = currentFocusedTabName()
        groupPin.groupTabName = groupTab.name
        groupPin.active = true
        if groupTab.tabIndex ~= 1 then
            local frontName = nil
            if GetChatContainerTabInfo then
                frontName = GetChatContainerTabInfo(groupTab.containerIndex, 1)
            end
            groupPin.otherTabName = frontName
            local moved = Tabs.MoveToFront(groupTab)
            groupPin.swapped = moved ~= nil and (groupPin.otherTabName ~= nil)
            groupTab = Tabs.FindByName(groupPin.groupTabName) or moved or groupTab
        end
    else
        groupTab = Tabs.FindByName(groupPin.groupTabName) or groupTab
        if groupTab.tabIndex ~= 1 then
            Tabs.MoveToFront(groupTab)
            groupTab = Tabs.FindByName(groupPin.groupTabName) or groupTab
        end
    end
    Tabs.Focus(groupTab)
end

function Tabs.OnPlayerCombatState(_, inCombat)
    local cfg = getCfg()
    if not cfg.keepGroupTabVisibleInCombat then
        if groupPin.active then
            Tabs.ReleaseGroupCombatPin()
        end
        return
    end
    if inCombat then
        Tabs.ApplyGroupCombatPin()
    else
        Tabs.ReleaseGroupCombatPin()
    end
end

function Tabs.OnGroupMembershipChanged(_, memberCharacterName, reasonOrDisplayName, isLocalPlayer)
    -- JOINED: (memberCharacterName, memberDisplayName, isLocalPlayer)
    -- LEFT: (memberCharacterName, reason, isLocalPlayer, ...)
    -- UPDATE has no useful local-player flag — always sync
    if isLocalPlayer == false then
        return
    end
    Tabs.SyncGroupTabCategories()
end

function Tabs.OnGroupUpdate()
    Tabs.SyncGroupTabCategories()
end

function Tabs.Start()
    local cfg = getCfg()
    if EC.Formatter and EC.Formatter.UsesGamepadChat and EC.Formatter.UsesGamepadChat() then
        return
    end
    -- Always raise max size (independent of tab feature master toggle)
    if EC.ContainerLayout and EC.ContainerLayout.RaiseMaxSize then
        EC.ContainerLayout.RaiseMaxSize()
    end
    if EVENT_MANAGER then
        if EVENT_PLAYER_COMBAT_STATE then
            EVENT_MANAGER:UnregisterForEvent(EC.NAME .. "GroupTabPin", EVENT_PLAYER_COMBAT_STATE)
            EVENT_MANAGER:RegisterForEvent(EC.NAME .. "GroupTabPin", EVENT_PLAYER_COMBAT_STATE, Tabs.OnPlayerCombatState)
        end
        if EVENT_GROUP_MEMBER_JOINED then
            EVENT_MANAGER:UnregisterForEvent(EC.NAME .. "GroupTabJoin", EVENT_GROUP_MEMBER_JOINED)
            EVENT_MANAGER:RegisterForEvent(EC.NAME .. "GroupTabJoin", EVENT_GROUP_MEMBER_JOINED, Tabs.OnGroupMembershipChanged)
        end
        if EVENT_GROUP_MEMBER_LEFT then
            EVENT_MANAGER:UnregisterForEvent(EC.NAME .. "GroupTabLeft", EVENT_GROUP_MEMBER_LEFT)
            EVENT_MANAGER:RegisterForEvent(EC.NAME .. "GroupTabLeft", EVENT_GROUP_MEMBER_LEFT, Tabs.OnGroupMembershipChanged)
        end
        if EVENT_GROUP_UPDATE then
            EVENT_MANAGER:UnregisterForEvent(EC.NAME .. "GroupTabUpdate", EVENT_GROUP_UPDATE)
            EVENT_MANAGER:RegisterForEvent(EC.NAME .. "GroupTabUpdate", EVENT_GROUP_UPDATE, Tabs.OnGroupUpdate)
        end
    end
    if not cfg.enabled then
        return
    end
    Tabs.RestoreLayout()
    if EC.TabProfiles and EC.TabProfiles.EnsureSeeds then
        EC.TabProfiles.EnsureSeeds()
    end
    if EC.TabFilters and EC.TabFilters.Start then
        EC.TabFilters.Start()
    end
    Tabs.SyncGroupTabCategories()
end

return Tabs
