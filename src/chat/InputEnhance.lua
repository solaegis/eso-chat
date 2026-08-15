-- EsoChat - Chat input character counter and history

local EC = EsoChat

EC.InputEnhance = EC.InputEnhance or {}
local InputEnhance = EC.InputEnhance

local MAX_CHAT_CHARS = 350
local counterControl = nil
local historyIndex = 0
local keysHooked = false

local function getCfg()
    return EC.db and EC.db.input or EC.defaults.input
end

local function colorForRatio(ratio)
    if ratio >= 1 then
        return 1, 0.2, 0.2
    elseif ratio >= 0.9 then
        return 1, 0.55, 0.1
    elseif ratio >= 0.8 then
        return 1, 0.9, 0.2
    end
    return 0.8, 0.8, 0.8
end

function InputEnhance.UpdateCounter()
    local cfg = getCfg()
    if not cfg.counterEnabled then
        if counterControl then
            counterControl:SetHidden(true)
        end
        return
    end
    if not CHAT_SYSTEM or not CHAT_SYSTEM.textEntry or not CHAT_SYSTEM.textEntry.editControl then
        return
    end
    local edit = CHAT_SYSTEM.textEntry.editControl
    local text = ""
    if edit.GetText then
        text = edit:GetText() or ""
    end
    local len = string.len(text)
    local ratio = len / MAX_CHAT_CHARS
    local r, g, b = colorForRatio(ratio)

    if not counterControl and GuiRoot and CreateControl then
        counterControl = CreateControl("EsoChatInputCounter", GuiRoot, CT_LABEL)
        if counterControl then
            counterControl:SetFont("ZoFontGameSmall")
            counterControl:SetAnchor(BOTTOMLEFT, CHAT_SYSTEM.control or GuiRoot, BOTTOMLEFT, 8, -4)
            counterControl:SetDrawTier(DT_HIGH)
        end
    end
    if counterControl then
        counterControl:SetColor(r, g, b, 1)
        counterControl:SetText(string.format("%d / %d", len, MAX_CHAT_CHARS))
        counterControl:SetHidden(false)
    end
end

function InputEnhance.PushHistory(text)
    local cfg = getCfg()
    if not cfg.historyEnabled or not text or text == "" then
        return
    end
    cfg.historyEntries = cfg.historyEntries or {}
    -- Skip consecutive duplicate
    local last = cfg.historyEntries[#cfg.historyEntries]
    if last == text then
        historyIndex = #cfg.historyEntries + 1
        return
    end
    table.insert(cfg.historyEntries, text)
    local maxN = tonumber(cfg.historyMax) or 50
    while #cfg.historyEntries > maxN do
        table.remove(cfg.historyEntries, 1)
    end
    historyIndex = #cfg.historyEntries + 1
end

function InputEnhance.HistoryUp()
    local cfg = getCfg()
    if not cfg.historyEnabled then
        return false
    end
    local entries = cfg.historyEntries or {}
    if #entries == 0 then
        return false
    end
    historyIndex = math.max(1, (historyIndex or (#entries + 1)) - 1)
    local text = entries[historyIndex]
    if CHAT_SYSTEM and CHAT_SYSTEM.textEntry and CHAT_SYSTEM.textEntry.editControl and text then
        CHAT_SYSTEM.textEntry.editControl:SetText(text)
    end
    return true
end

function InputEnhance.HistoryDown()
    local cfg = getCfg()
    if not cfg.historyEnabled then
        return false
    end
    local entries = cfg.historyEntries or {}
    historyIndex = math.min(#entries + 1, (historyIndex or 1) + 1)
    local text = entries[historyIndex] or ""
    if CHAT_SYSTEM and CHAT_SYSTEM.textEntry and CHAT_SYSTEM.textEntry.editControl then
        CHAT_SYSTEM.textEntry.editControl:SetText(text)
    end
    return true
end

--- Test helper: current browse index (1-based into entries, or #entries+1 for blank).
function InputEnhance.GetHistoryIndex()
    return historyIndex
end

function InputEnhance.SetHistoryIndex(idx)
    historyIndex = tonumber(idx) or 0
end

local function installKeyHandlers()
    if keysHooked then
        return
    end
    if not CHAT_SYSTEM or not CHAT_SYSTEM.textEntry or not CHAT_SYSTEM.textEntry.editControl then
        return
    end
    local edit = CHAT_SYSTEM.textEntry.editControl
    if not edit.SetHandler then
        return
    end
    keysHooked = true
    local previous = edit.GetHandler and edit:GetHandler("OnKeyDown") or nil
    edit:SetHandler("OnKeyDown", function(self, key, ctrl, alt, shift, command)
        local cfg = getCfg()
        if cfg.historyEnabled then
            if key == KEY_UPARROW then
                InputEnhance.HistoryUp()
                return true
            end
            if key == KEY_DOWNARROW then
                InputEnhance.HistoryDown()
                return true
            end
        end
        if previous then
            return previous(self, key, ctrl, alt, shift, command)
        end
    end)
end

function InputEnhance.Start()
    if EC.Formatter and EC.Formatter.UsesGamepadChat and EC.Formatter.UsesGamepadChat() then
        return
    end
    EVENT_MANAGER:RegisterForUpdate(EC.NAME .. "InputCounter", 200, function()
        InputEnhance.UpdateCounter()
    end)
    -- Hook send to capture history when possible
    if CHAT_SYSTEM and CHAT_SYSTEM.textEntry then
        local te = CHAT_SYSTEM.textEntry
        if te.Send and not te._esoChatHooked then
            local original = te.Send
            te.Send = function(self, ...)
                local text = ""
                if self.editControl and self.editControl.GetText then
                    text = self.editControl:GetText() or ""
                end
                InputEnhance.PushHistory(text)
                return original(self, ...)
            end
            te._esoChatHooked = true
        end
    end
    installKeyHandlers()
    if zo_callLater then
        zo_callLater(installKeyHandlers, 1000)
    end
end

return InputEnhance
