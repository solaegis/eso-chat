-- EsoChat - Chat container size/position raise, snapshot, restore
--
-- Vanilla CalculateConstraints clamps to CHAT_SYSTEM.maxContainerWidth/Height
-- (default ~550x380). Raising those fields alone is not enough unless we also
-- refresh control constraints and re-assert after layout recalculates.

local EC = EsoChat

EC.ContainerLayout = EC.ContainerLayout or {}
local ContainerLayout = EC.ContainerLayout

local SAVE_INTERVAL_MS = 1000
local MARGIN = 15
local watching = false
local started = false
local classConstraintHooked = false

local function getCfg()
    return EC.db and EC.db.tabs or (EC.defaults and EC.defaults.tabs) or {}
end

local function usesGamepadChat()
    return EC.Formatter and EC.Formatter.UsesGamepadChat and EC.Formatter.UsesGamepadChat()
end

local function containerKey(index, container)
    if CHAT_SYSTEM and CHAT_SYSTEM.primaryContainer and container == CHAT_SYSTEM.primaryContainer then
        return "primary"
    end
    if index == 1 then
        return "primary"
    end
    if GetChatContainerTabInfo then
        local ok, name = pcall(GetChatContainerTabInfo, index, 1)
        if ok and name and name ~= "" then
            return "tab:" .. name
        end
    end
    return "c" .. tostring(index)
end

local function eachContainer(fn)
    if not CHAT_SYSTEM then
        return
    end
    if CHAT_SYSTEM.primaryContainer then
        fn(CHAT_SYSTEM.primaryContainer, 1)
    end
    if CHAT_SYSTEM.containers then
        for index, container in pairs(CHAT_SYSTEM.containers) do
            if type(index) == "number" and container and container ~= CHAT_SYSTEM.primaryContainer then
                fn(container, index)
            end
        end
    end
end

local function guiRootSize()
    if not GuiRoot or not GuiRoot.GetDimensions then
        return nil, nil
    end
    local ok, gw, gh = pcall(function()
        return GuiRoot:GetDimensions()
    end)
    if not ok or not gw or not gh or gw < 100 or gh < 100 then
        return nil, nil
    end
    return gw, gh
end

local function applyConstraintsToControl(control, minW, minH, maxW, maxH)
    if not control or not control.SetDimensionConstraints then
        return
    end
    pcall(function()
        control:SetDimensionConstraints(minW, minH, maxW, maxH)
    end)
end

--- pChat-style class hook: raise system max *before* vanilla CalculateConstraints.
--- Instance SetDimensionConstraints alone is overwritten when unhooked CalculateConstraints runs.
local function installClassConstraintHook()
    if classConstraintHooked then
        return true
    end
    if not SharedChatContainer or not SharedChatContainer.CalculateConstraints then
        return false
    end
    local orgCalculateConstraints = SharedChatContainer.CalculateConstraints
    function SharedChatContainer.CalculateConstraints(...)
        local self = ...
        if getCfg().raiseMaxSize ~= false and not usesGamepadChat() then
            local gw, gh = guiRootSize()
            if gw and gh then
                if self and self.system then
                    self.system.maxContainerWidth = gw
                    self.system.maxContainerHeight = gh
                end
                if CHAT_SYSTEM then
                    CHAT_SYSTEM.maxContainerWidth = gw
                    CHAT_SYSTEM.maxContainerHeight = gh
                end
            end
        end
        return orgCalculateConstraints(...)
    end
    classConstraintHooked = true
    -- #region agent log
    if EC.AgentDebug then
        EC.AgentDebug.Log("H1", "ContainerLayout.installClassConstraintHook", "SharedChatContainer hooked", {
            hasPChat = _G.pChat ~= nil,
        })
    end
    -- #endregion
    return true
end

-- Try at file load (SharedChatContainer exists early; mirrors pChat LoadEarlyHooks)
installClassConstraintHook()

local function refreshContainerConstraints(container, maxW, maxH)
    if not container then
        return
    end
    -- Drive ZOS path so hooked CalculateConstraints applies raised max.
    -- Do not SetDimensionConstraints *before* an unhooked CalculateConstraints —
    -- that was resetting caps back to vanilla ~550x380.
    if container.CalculateConstraints then
        pcall(function()
            container:CalculateConstraints()
        end)
    else
        local minW = (CHAT_SYSTEM and CHAT_SYSTEM.minContainerWidth) or 300
        local minH = (CHAT_SYSTEM and CHAT_SYSTEM.minContainerHeight) or 170
        applyConstraintsToControl(container.control, minW, minH, maxW, maxH)
        if container.PerformLayout then
            pcall(function()
                container:PerformLayout()
            end)
        end
    end
end

--- Raise CHAT_SYSTEM max container dimensions toward GuiRoot (keyboard only).
function ContainerLayout.RaiseMaxSize()
    installClassConstraintHook()
    -- #region agent log
    if EC.AgentDebug then
        EC.AgentDebug.Log("H1", "ContainerLayout.RaiseMaxSize:entry", "RaiseMaxSize called", {
            gamepad = usesGamepadChat(),
            raiseMaxSize = getCfg().raiseMaxSize,
            hasChatSystem = CHAT_SYSTEM ~= nil,
            started = started,
            classHooked = classConstraintHooked,
            hasPChat = _G.pChat ~= nil,
        })
    end
    -- #endregion
    if usesGamepadChat() then
        -- #region agent log
        if EC.AgentDebug then
            EC.AgentDebug.Log("H1", "ContainerLayout.RaiseMaxSize:exit", "blocked gamepad", {})
        end
        -- #endregion
        return false
    end
    local cfg = getCfg()
    if cfg.raiseMaxSize == false then
        -- #region agent log
        if EC.AgentDebug then
            EC.AgentDebug.Log("H1", "ContainerLayout.RaiseMaxSize:exit", "blocked raiseMaxSize=false", {})
        end
        -- #endregion
        return false
    end
    if not CHAT_SYSTEM then
        -- #region agent log
        if EC.AgentDebug then
            EC.AgentDebug.Log("H1", "ContainerLayout.RaiseMaxSize:exit", "blocked no CHAT_SYSTEM", {})
        end
        -- #endregion
        return false
    end
    local gw, gh = guiRootSize()
    if not gw then
        -- #region agent log
        if EC.AgentDebug then
            EC.AgentDebug.Log("H1", "ContainerLayout.RaiseMaxSize:exit", "blocked GuiRoot size", {})
        end
        -- #endregion
        return false
    end

    CHAT_SYSTEM.maxContainerWidth = gw
    CHAT_SYSTEM.maxContainerHeight = gh

    local containerCount = 0
    eachContainer(function(container)
        containerCount = containerCount + 1
        refreshContainerConstraints(container, gw, gh)
    end)

    -- Legacy / alias controls some clients still expose
    if ZO_ChatWindow then
        applyConstraintsToControl(ZO_ChatWindow, CHAT_SYSTEM.minContainerWidth or 300, CHAT_SYSTEM.minContainerHeight or 170, gw, gh)
    end
    if CHAT_SYSTEM.control then
        applyConstraintsToControl(CHAT_SYSTEM.control, CHAT_SYSTEM.minContainerWidth or 300, CHAT_SYSTEM.minContainerHeight or 170, gw, gh)
    end

    -- #region agent log
    if EC.AgentDebug then
        EC.AgentDebug.Log("H2", "ContainerLayout.RaiseMaxSize:after", "raised and refreshed", {
            gw = gw,
            gh = gh,
            containerCount = containerCount,
            systemMaxW = CHAT_SYSTEM.maxContainerWidth,
            systemMaxH = CHAT_SYSTEM.maxContainerHeight,
            classHooked = classConstraintHooked,
        })
        EC.AgentDebug.DumpConstraints("after RaiseMaxSize", "H2")
    end
    -- #endregion

    EC.DebugPrint("CONTAINER", function()
        return string.format("Raised max size to %sx%s", tostring(gw), tostring(gh))
    end)
    return true
end

--- Instance hooks for resize lifecycle + logging (class hook owns max raise).
local function installLayoutHook()
    installClassConstraintHook()
    eachContainer(function(container)
        if container and container.OnResizeStop and not container._esoChatResizeStopHooked then
            local original = container.OnResizeStop
            container.OnResizeStop = function(self, ...)
                -- #region agent log
                if EC.AgentDebug then
                    EC.AgentDebug.Log("H3", "ContainerLayout.OnResizeStop", "resize stop fired", {
                        key = containerKey(1, self),
                    })
                    EC.AgentDebug.DumpConstraints("on resize stop", "H3")
                end
                -- #endregion
                local result = original(self, ...)
                ContainerLayout.Snapshot()
                return result
            end
            container._esoChatResizeStopHooked = true
        end
        if container and container.OnResizeStart and not container._esoChatResizeStartHooked then
            local original = container.OnResizeStart
            container.OnResizeStart = function(self, ...)
                -- #region agent log
                if EC.AgentDebug then
                    EC.AgentDebug.Log("H3", "ContainerLayout.OnResizeStart", "resize start fired", {})
                    EC.AgentDebug.DumpConstraints("on resize start", "H3")
                end
                -- #endregion
                -- Re-assert before drag in case layout reset caps
                ContainerLayout.RaiseMaxSize()
                return original(self, ...)
            end
            container._esoChatResizeStartHooked = true
        end
    end)
end

local function readAnchor(control)
    if not control or not control.GetAnchor then
        return nil
    end
    local ok, isValid, point, _, relativePoint, offsetX, offsetY = pcall(function()
        return control:GetAnchor(0)
    end)
    if not ok or isValid == false then
        return nil
    end
    return {
        point = point,
        relativePoint = relativePoint,
        offsetX = offsetX or 0,
        offsetY = offsetY or 0,
    }
end

local function readGeometry(container)
    if not container then
        return nil
    end
    local control = container.control
    local width, height
    if container.settings then
        width = container.settings.width
        height = container.settings.height
    end
    if control then
        if (not width or width == 0) and control.GetWidth then
            width = control:GetWidth()
        end
        if (not height or height == 0) and control.GetHeight then
            height = control:GetHeight()
        end
    end
    if not width or not height then
        return nil
    end
    local geo = {
        width = width,
        height = height,
    }
    local anchor = readAnchor(control)
    if anchor then
        geo.point = anchor.point
        geo.relativePoint = anchor.relativePoint
        geo.offsetX = anchor.offsetX
        geo.offsetY = anchor.offsetY
    end
    return geo
end

local function clampSize(width, height)
    local minW = (CHAT_SYSTEM and CHAT_SYSTEM.minContainerWidth) or 300
    local minH = (CHAT_SYSTEM and CHAT_SYSTEM.minContainerHeight) or 170
    local maxW = (CHAT_SYSTEM and CHAT_SYSTEM.maxContainerWidth) or 550
    local maxH = (CHAT_SYSTEM and CHAT_SYSTEM.maxContainerHeight) or 380
    if width > maxW - MARGIN then
        width = maxW - MARGIN
    end
    if height > maxH - MARGIN then
        height = maxH - MARGIN
    end
    if width < minW then
        width = minW
    end
    if height < minH then
        height = minH
    end
    return width, height
end

function ContainerLayout.Snapshot()
    local cfg = getCfg()
    if not cfg.rememberSize and not cfg.rememberPosition then
        return
    end
    if not CHAT_SYSTEM then
        return
    end
    cfg.containers = cfg.containers or {}
    eachContainer(function(container, index)
        local key = containerKey(index, container)
        local geo = readGeometry(container)
        if geo then
            local prev = cfg.containers[key] or {}
            if cfg.rememberSize then
                prev.width = geo.width
                prev.height = geo.height
            end
            if cfg.rememberPosition and geo.point ~= nil then
                prev.point = geo.point
                prev.relativePoint = geo.relativePoint
                prev.offsetX = geo.offsetX
                prev.offsetY = geo.offsetY
            end
            cfg.containers[key] = prev
        end
    end)
end

local function applyOne(container, saved)
    if not container or not saved then
        return
    end
    local control = container.control
    if not control then
        return
    end
    local cfg = getCfg()
    if cfg.rememberSize and saved.width and saved.height then
        local w, h = clampSize(saved.width, saved.height)
        if control.SetDimensions then
            pcall(function()
                control:SetDimensions(w, h)
            end)
        end
        if container.settings then
            container.settings.width = w
            container.settings.height = h
        end
        if container.PerformLayout then
            pcall(function()
                container:PerformLayout()
            end)
        end
    end
    if cfg.rememberPosition and saved.point ~= nil and control.ClearAnchors and control.SetAnchor then
        local relPoint = saved.relativePoint or saved.point
        local ox = saved.offsetX or 0
        local oy = saved.offsetY or 0
        pcall(function()
            control:ClearAnchors()
            control:SetAnchor(saved.point, GuiRoot, relPoint, ox, oy)
        end)
    end
end

function ContainerLayout.Restore()
    if usesGamepadChat() then
        return
    end
    local cfg = getCfg()
    if cfg.restoreLayout == false then
        return
    end
    if not cfg.rememberSize and not cfg.rememberPosition then
        return
    end
    if not cfg.containers or not CHAT_SYSTEM then
        return
    end
    ContainerLayout.RaiseMaxSize()
    installLayoutHook()
    eachContainer(function(container, index)
        local key = containerKey(index, container)
        local saved = cfg.containers[key]
        if saved then
            applyOne(container, saved)
        end
    end)
    EC.DebugPrint("CONTAINER", "Restored container layout")
end

local function geometryChanged(a, b)
    if not a or not b then
        return true
    end
    if a.width ~= b.width or a.height ~= b.height then
        return true
    end
    if a.offsetX ~= b.offsetX or a.offsetY ~= b.offsetY then
        return true
    end
    if a.point ~= b.point or a.relativePoint ~= b.relativePoint then
        return true
    end
    return false
end

local function pollAndSave()
    -- Re-assert raised max periodically (layout can reset constraints)
    ContainerLayout.RaiseMaxSize()
    installLayoutHook()

    local cfg = getCfg()
    if not cfg.rememberSize and not cfg.rememberPosition then
        return
    end
    if not CHAT_SYSTEM then
        return
    end
    cfg.containers = cfg.containers or {}
    local dirty = false
    eachContainer(function(container, index)
        if dirty then
            return
        end
        local key = containerKey(index, container)
        local geo = readGeometry(container)
        local prev = cfg.containers[key]
        if geo and geometryChanged(geo, prev) then
            dirty = true
        end
    end)
    if dirty then
        ContainerLayout.Snapshot()
    end
end

function ContainerLayout.StartWatching()
    if watching or usesGamepadChat() then
        return
    end
    watching = true
    EVENT_MANAGER:RegisterForUpdate(EC.NAME .. "ContainerLayout", SAVE_INTERVAL_MS, pollAndSave)
    EVENT_MANAGER:RegisterForEvent(EC.NAME .. "ContainerDeact", EVENT_PLAYER_DEACTIVATED, function()
        ContainerLayout.Snapshot()
    end)
end

function ContainerLayout.StatusToChat()
    -- #region agent log
    if EC.AgentDebug then
        EC.AgentDebug.Log("H4", "ContainerLayout.StatusToChat", "status requested", {
            started = started,
            watching = watching,
        })
        EC.AgentDebug.DumpConstraints("status command", "H4")
    end
    -- #endregion
    local gw, gh = guiRootSize()
    local maxW = CHAT_SYSTEM and CHAT_SYSTEM.maxContainerWidth
    local maxH = CHAT_SYSTEM and CHAT_SYSTEM.maxContainerHeight
    local useKbChat = nil
    if GetSetting_Bool and SETTING_TYPE_GAMEPAD and GAMEPAD_SETTING_USE_KEYBOARD_CHAT then
        local ok, v = pcall(GetSetting_Bool, SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_USE_KEYBOARD_CHAT)
        if ok then
            useKbChat = v
        end
    end
    local platformGamepad = nil
    if ZO_ChatSystem_DoesPlatformUseGamepadChatSystem then
        local ok, v = pcall(ZO_ChatSystem_DoesPlatformUseGamepadChatSystem)
        if ok then
            platformGamepad = v
        end
    end
    EC.Chat(string.format(
        "Resize: raiseMax=%s gui=%sx%s systemMax=%sx%s gamepad=%s started=%s classHook=%s pChat=%s",
        tostring(getCfg().raiseMaxSize ~= false),
        tostring(gw),
        tostring(gh),
        tostring(maxW),
        tostring(maxH),
        tostring(usesGamepadChat()),
        tostring(started),
        tostring(classConstraintHooked),
        tostring(_G.pChat ~= nil)
    ))
    EC.Chat(string.format(
        "  detect: platformGamepad=%s useKeyboardChat=%s hasPrimary=%s",
        tostring(platformGamepad),
        tostring(useKbChat),
        tostring(CHAT_SYSTEM and CHAT_SYSTEM.primaryContainer ~= nil)
    ))
    eachContainer(function(container, index)
        local geo = readGeometry(container)
        local cminW, cminH, cmaxW, cmaxH = nil, nil, nil, nil
        if container.control and container.control.GetDimensionConstraints then
            local ok, a, b, c, d = pcall(function()
                return container.control:GetDimensionConstraints()
            end)
            if ok then
                cminW, cminH, cmaxW, cmaxH = a, b, c, d
            end
        end
        EC.Chat(string.format(
            "  [%s] size=%sx%s constraints=%sx%s..%sx%s",
            containerKey(index, container),
            tostring(geo and geo.width),
            tostring(geo and geo.height),
            tostring(cminW),
            tostring(cminH),
            tostring(cmaxW),
            tostring(cmaxH)
        ))
    end)
    if ZO_ChatWindow and ZO_ChatWindow.GetDimensionConstraints then
        local ok, a, b, c, d = pcall(function()
            return ZO_ChatWindow:GetDimensionConstraints()
        end)
        if ok then
            EC.Chat(string.format("  [ZO_ChatWindow] constraints=%sx%s..%sx%s", tostring(a), tostring(b), tostring(c), tostring(d)))
        end
    end
    local n = EC.db and EC.db._agentDebugLog and #EC.db._agentDebugLog or 0
    EC.Chat(string.format("Debug log entries: %d (saved on /reloadui)", n))
end

--- Start independently of tabs.enabled so resize works even if tab features are off.
function ContainerLayout.Start()
    -- #region agent log
    if EC.AgentDebug then
        local useKb = nil
        if GetSetting_Bool and SETTING_TYPE_GAMEPAD and GAMEPAD_SETTING_USE_KEYBOARD_CHAT then
            local ok, v = pcall(GetSetting_Bool, SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_USE_KEYBOARD_CHAT)
            if ok then
                useKb = v
            end
        end
        local platformGp = nil
        if ZO_ChatSystem_DoesPlatformUseGamepadChatSystem then
            local ok, v = pcall(ZO_ChatSystem_DoesPlatformUseGamepadChatSystem)
            if ok then
                platformGp = v
            end
        end
        EC.AgentDebug.Log("H5", "ContainerLayout.Start", "Start called", {
            alreadyStarted = started,
            gamepad = usesGamepadChat(),
            useKeyboardChat = useKb,
            platformGamepad = platformGp,
            hasPrimary = CHAT_SYSTEM and CHAT_SYSTEM.primaryContainer ~= nil,
        })
    end
    -- #endregion
    if started then
        ContainerLayout.RaiseMaxSize()
        return
    end
    if usesGamepadChat() then
        EC.Warn(EC.L("gamepad_disabled"))
        -- #region agent log
        if EC.AgentDebug then
            EC.AgentDebug.Log("H5", "ContainerLayout.Start", "deferred gamepad; will retry", {
                hasPrimary = CHAT_SYSTEM and CHAT_SYSTEM.primaryContainer ~= nil,
            })
        end
        -- #endregion
        -- Keyboard chat may appear shortly (CHAT_SYSTEM not ready yet, or
        -- gamepad-preferred + Use Keyboard Chat). Retry instead of aborting forever.
        if zo_callLater then
            local delays = { 500, 1500, 3000, 6000 }
            for i = 1, #delays do
                local delay = delays[i]
                zo_callLater(function()
                    if not started and not usesGamepadChat() then
                        ContainerLayout.Start()
                    end
                end, delay)
            end
        end
        return
    end
    started = true
    installClassConstraintHook()

    local function attempt(delay)
        if zo_callLater then
            zo_callLater(function()
                -- #region agent log
                if EC.AgentDebug then
                    EC.AgentDebug.Log("H5", "ContainerLayout.Start:attempt", "retry raise", { delay = delay })
                end
                -- #endregion
                ContainerLayout.RaiseMaxSize()
                installLayoutHook()
                ContainerLayout.Restore()
                ContainerLayout.StartWatching()
            end, delay)
        else
            ContainerLayout.RaiseMaxSize()
            installLayoutHook()
            ContainerLayout.Restore()
            ContainerLayout.StartWatching()
        end
    end

    -- Immediate + retries: chat containers may not exist on first tick
    ContainerLayout.RaiseMaxSize()
    attempt(100)
    attempt(500)
    attempt(1500)
    attempt(3000)
end

return ContainerLayout
