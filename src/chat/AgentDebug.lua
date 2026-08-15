-- EsoChat - debug session logger (agent instrumentation)
-- Persists NDJSON-like entries to SavedVariables; also tries filesystem append.

local EC = EsoChat

EC.AgentDebug = EC.AgentDebug or {}
local AgentDebug = EC.AgentDebug

local LOG_PATH = "/Users/lvavasour/git/solaegis/eso-addon-template/.cursor/debug-8e42b1.log"
local SESSION = "8e42b1"
local MAX_ENTRIES = 80

local function nowMs()
    if GetTimeStamp then
        return GetTimeStamp() * 1000
    end
    return os.time() * 1000
end

local function ensureStore()
    if not EC.db then
        return nil
    end
    if type(EC.db._agentDebugLog) ~= "table" then
        EC.db._agentDebugLog = {}
    end
    return EC.db._agentDebugLog
end

local function encodeSimple(value)
    local t = type(value)
    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return value and "true" or "false"
    elseif t == "number" then
        return tostring(value)
    elseif t == "string" then
        return string.format("%q", value)
    elseif t == "table" then
        local parts = {}
        for k, v in pairs(value) do
            table.insert(parts, string.format("%q:%s", tostring(k), encodeSimple(v)))
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return string.format("%q", tostring(value))
end

--- @param hypothesisId string
--- @param location string
--- @param message string
--- @param data table|nil
function AgentDebug.Log(hypothesisId, location, message, data)
    local entry = {
        sessionId = SESSION,
        hypothesisId = hypothesisId,
        location = location,
        message = message,
        data = data or {},
        timestamp = nowMs(),
        runId = "post-fix",
    }

    local store = ensureStore()
    if store then
        -- Drop pre-fix noise once we start a post-fix run
        if #store > 0 and store[1].runId == "pre-fix" then
            for i = #store, 1, -1 do
                if store[i].runId == "pre-fix" then
                    table.remove(store, i)
                end
            end
        end
        table.insert(store, entry)
        while #store > MAX_ENTRIES do
            table.remove(store, 1)
        end
    end

    -- #region agent log
    if io and io.open then
        local ok, f = pcall(io.open, LOG_PATH, "a")
        if ok and f then
            local line = string.format(
                '{"sessionId":"%s","hypothesisId":%s,"location":%s,"message":%s,"data":%s,"timestamp":%s,"runId":"post-fix"}\n',
                SESSION,
                encodeSimple(hypothesisId),
                encodeSimple(location),
                encodeSimple(message),
                encodeSimple(data or {}),
                tostring(entry.timestamp)
            )
            f:write(line)
            f:close()
        end
    end
    -- #endregion
end

function AgentDebug.DumpConstraints(tag, hypothesisId)
    local data = {
        tag = tag,
        chatSystem = CHAT_SYSTEM ~= nil,
        gamepad = EC.Formatter and EC.Formatter.UsesGamepadChat and EC.Formatter.UsesGamepadChat() or false,
        raiseMax = EC.db and EC.db.tabs and EC.db.tabs.raiseMaxSize,
        tabsEnabled = EC.db and EC.db.tabs and EC.db.tabs.enabled,
        systemMaxW = CHAT_SYSTEM and CHAT_SYSTEM.maxContainerWidth,
        systemMaxH = CHAT_SYSTEM and CHAT_SYSTEM.maxContainerHeight,
        hasPrimary = CHAT_SYSTEM and CHAT_SYSTEM.primaryContainer ~= nil,
        hasZOChatWindow = ZO_ChatWindow ~= nil,
        hasPChat = _G.pChat ~= nil,
        hasSharedChatContainer = SharedChatContainer ~= nil,
    }
    if GuiRoot and GuiRoot.GetDimensions then
        local ok, gw, gh = pcall(function()
            return GuiRoot:GetDimensions()
        end)
        if ok then
            data.guiW = gw
            data.guiH = gh
        end
    end
    local function grab(name, control)
        if not control or not control.GetDimensionConstraints then
            data[name] = "missing"
            return
        end
        local ok, minW, minH, maxW, maxH = pcall(function()
            return control:GetDimensionConstraints()
        end)
        if ok then
            data[name .. "MinW"] = minW
            data[name .. "MinH"] = minH
            data[name .. "MaxW"] = maxW
            data[name .. "MaxH"] = maxH
            if control.GetWidth then
                data[name .. "W"] = control:GetWidth()
            end
            if control.GetHeight then
                data[name .. "H"] = control:GetHeight()
            end
        else
            data[name] = "error"
        end
    end
    if CHAT_SYSTEM and CHAT_SYSTEM.primaryContainer then
        grab("primary", CHAT_SYSTEM.primaryContainer.control)
    end
    grab("zoChatWindow", ZO_ChatWindow)
    if CHAT_SYSTEM then
        grab("chatSystemControl", CHAT_SYSTEM.control)
    end
    AgentDebug.Log(hypothesisId or "H2", "AgentDebug.DumpConstraints", tag or "constraints", data)
    return data
end

return AgentDebug
