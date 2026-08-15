-- EsoChat - Persistent Notes notepad (EditBox overlay on notes filter tab)

local EC = EsoChat

EC.Notes = EC.Notes or {}
local Notes = EC.Notes

local editControl = nil
local bgControl = nil
local started = false
local persistPending = false
local visible = false
local lastFocusedIsNotes = false

local function getNotesCfg()
    return EC.db and EC.db.notes or (EC.defaults and EC.defaults.notes) or {}
end

local function maxChars()
    local n = tonumber(getNotesCfg().maxChars) or 20000
    if n < 1000 then
        n = 1000
    end
    if n > 50000 then
        n = 50000
    end
    return n
end

function Notes.IsEnabled()
    local cfg = getNotesCfg()
    return cfg.enabled ~= false
end

function Notes.IsPerCharacter()
    return getNotesCfg().perCharacter == true
end

function Notes.GetStore()
    if Notes.IsPerCharacter() then
        if EC.EnsureCharacterData then
            EC.EnsureCharacterData()
        end
        if EC.charData then
            if EC.charData.notesText == nil then
                EC.charData.notesText = ""
            end
            return EC.charData.notesText or ""
        end
        return ""
    end
    local cfg = getNotesCfg()
    return cfg.text or ""
end

function Notes.SetStore(text)
    text = tostring(text or "")
    local limit = maxChars()
    if string.len(text) > limit then
        text = string.sub(text, 1, limit)
    end
    if Notes.IsPerCharacter() then
        if EC.EnsureCharacterData then
            EC.EnsureCharacterData()
        end
        if EC.charData then
            EC.charData.notesText = text
        end
        return
    end
    if EC.db and EC.db.notes then
        EC.db.notes.text = text
    end
end

function Notes.Persist()
    persistPending = false
    if not editControl or not editControl.GetText then
        return
    end
    Notes.SetStore(editControl:GetText() or "")
end

local function schedulePersist()
    if persistPending then
        return
    end
    persistPending = true
    if zo_callLater then
        zo_callLater(function()
            Notes.Persist()
        end, 400)
    else
        Notes.Persist()
    end
end

function Notes.LoadFromDb()
    local text = Notes.GetStore()
    if editControl and editControl.SetText then
        editControl:SetText(text)
    end
end

function Notes.Clear()
    Notes.SetStore("")
    if editControl and editControl.SetText then
        editControl:SetText("")
    end
    EC.Chat("Notes cleared.")
end

function Notes.SetPerCharacter(perChar)
    Notes.Persist()
    local cfg = getNotesCfg()
    cfg.perCharacter = perChar and true or false
    Notes.LoadFromDb()
end

local function findNotesTab()
    if EC.TabFilters and EC.TabFilters.FindTabByMode then
        return EC.TabFilters.FindTabByMode("notes")
    end
    return nil
end

local function isNotesTab(tab)
    if not tab or not tab.name then
        return false
    end
    if EC.TabFilters and EC.TabFilters.GetModeForTab then
        return EC.TabFilters.GetModeForTab(tab.name) == "notes"
    end
    return false
end

local function getChatAnchorParent()
    if not CHAT_SYSTEM then
        return nil
    end
    local container = CHAT_SYSTEM.primaryContainer
    if container and container.control then
        return container.control
    end
    if CHAT_SYSTEM.control then
        return CHAT_SYSTEM.control
    end
    return nil
end

local function setBufferHiddenForNotesTab(hidden)
    local tab = findNotesTab()
    if not tab or not CHAT_SYSTEM then
        return
    end
    local container = nil
    if CHAT_SYSTEM.containers then
        container = CHAT_SYSTEM.containers[tab.containerIndex]
    end
    if not container and CHAT_SYSTEM.primaryContainer and tab.containerIndex == 1 then
        container = CHAT_SYSTEM.primaryContainer
    end
    if not container or not container.windows then
        return
    end
    local window = container.windows[tab.tabIndex]
    if not window then
        return
    end
    if window.buffer and window.buffer.SetHidden then
        pcall(function()
            window.buffer:SetHidden(hidden and true or false)
        end)
    end
end

function Notes.CreateUi()
    if editControl or not CreateControl or not GuiRoot then
        return editControl ~= nil
    end
    -- Top-level so it renders; re-anchor to chat when shown
    bgControl = CreateControl("EsoChatNotesBg", GuiRoot, CT_BACKDROP)
    if not bgControl then
        return false
    end
    bgControl:SetCenterColor(0, 0, 0, 0.85)
    bgControl:SetEdgeColor(0.4, 0.4, 0.4, 1)
    bgControl:SetEdgeTexture("", 1, 1, 1)
    bgControl:SetDrawTier(DT_HIGH)
    bgControl:SetDrawLayer(DL_OVERLAY)
    bgControl:SetHidden(true)
    bgControl:SetMouseEnabled(true)

    editControl = CreateControl("EsoChatNotesEdit", bgControl, CT_EDITBOX)
    if not editControl then
        return false
    end
    editControl:SetFont("ZoFontChat")
    editControl:SetColor(0.9, 0.9, 0.9, 1)
    editControl:SetMultiLine(true)
    editControl:SetNewLineEnabled(true)
    editControl:SetMaxInputChars(maxChars())
    editControl:SetEditEnabled(true)
    editControl:SetMouseEnabled(true)
    editControl:SetKeyboardEnabled(true)
    editControl:SetAnchorFill(bgControl)
    editControl:SetHandler("OnTextChanged", function()
        schedulePersist()
    end)
    editControl:SetHandler("OnFocusLost", function()
        Notes.Persist()
    end)

    return true
end

local function anchorToChat()
    if not bgControl then
        return
    end
    local parent = getChatAnchorParent()
    if not parent then
        return
    end
    bgControl:ClearAnchors()
    -- Cover message area above the text entry
    local bottomPad = 40
    if CHAT_SYSTEM and CHAT_SYSTEM.textEntry and CHAT_SYSTEM.textEntry.control then
        bottomPad = 48
    end
    bgControl:SetAnchor(TOPLEFT, parent, TOPLEFT, 4, 28)
    bgControl:SetAnchor(BOTTOMRIGHT, parent, BOTTOMRIGHT, -4, -bottomPad)
end

function Notes.Show()
    if not Notes.IsEnabled() then
        return
    end
    if not editControl then
        Notes.CreateUi()
    end
    if not bgControl then
        return
    end
    Notes.LoadFromDb()
    anchorToChat()
    setBufferHiddenForNotesTab(true)
    bgControl:SetHidden(false)
    visible = true
    lastFocusedIsNotes = true
    if editControl and editControl.TakeFocus then
        pcall(function()
            editControl:TakeFocus()
        end)
    end
end

function Notes.Hide()
    if visible then
        Notes.Persist()
    end
    if bgControl then
        bgControl:SetHidden(true)
    end
    setBufferHiddenForNotesTab(false)
    visible = false
    lastFocusedIsNotes = false
end

function Notes.OnTabFocused(tab)
    if isNotesTab(tab) then
        Notes.Show()
    else
        if lastFocusedIsNotes or visible then
            Notes.Hide()
        end
    end
end

function Notes.EnsureTab(label)
    if EC.TabFilters and EC.TabFilters.EnsureTab then
        return EC.TabFilters.EnsureTab("notes", label)
    end
    return false
end

function Notes.Focus()
    Notes.EnsureTab(nil)
    local tab = findNotesTab()
    if tab and EC.Tabs and EC.Tabs.Focus then
        EC.Tabs.Focus(tab)
        return true
    end
    return false
end

function Notes.Start()
    if started then
        if findNotesTab() and EC.db and EC.db.tabs and EC.db.tabs.selectedTabKey then
            local selected = EC.Tabs and EC.Tabs.FindByName(EC.db.tabs.selectedTabKey)
            if selected and isNotesTab(selected) then
                Notes.Show()
            end
        end
        return
    end
    started = true
    if EC.Formatter and EC.Formatter.UsesGamepadChat and EC.Formatter.UsesGamepadChat() then
        return
    end
    Notes.CreateUi()
    if zo_callLater then
        zo_callLater(function()
            local tab = findNotesTab()
            if not tab then
                return
            end
            local cfg = EC.db and EC.db.tabs
            if cfg and cfg.selectedTabKey and string.lower(cfg.selectedTabKey) == string.lower(tab.name) then
                Notes.Show()
            end
        end, 1200)
    end
end

return Notes
