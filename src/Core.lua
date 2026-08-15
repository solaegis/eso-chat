-- EsoChat - Core namespace, helpers, and branding constants

EsoChat = EsoChat or {}
local EC = EsoChat

EC.NAME = "EsoChat"
EC.DISPLAY_NAME = "ESO Chat"
EC.VERSION = "@project-version@"
EC.AUTHOR = "solaegis"

EC.WEBSITE_URL = "https://github.com/solaegis/eso-chat"
EC.FEEDBACK_URL = "https://github.com/solaegis/eso-chat/issues"
EC.DONATION_URL = "https://www.buymeacoffee.com/lewisvavasw"
EC.DONATION_ACCOUNT = "@solaegis"
EC.DONATION_GOLD_DEFAULT = 5000

EC.SV_NAME = "EsoChatSettings"
EC.SV_VERSION = 2

EC.db = nil
EC.defaults = nil
EC.debug = false

-- Filled by src/i18n/en.lua (and optional language packs)
EC.i18n = EC.i18n or {}

------------------------------------------------------------
-- Optional LibDebugLogger
------------------------------------------------------------

local logger = nil
if LibDebugLogger and LibDebugLogger.Create then
    logger = LibDebugLogger.Create(EC.NAME)
end

local function chatPrefix()
    return "|c7EC8E3[EC]|r "
end

local function printToChat(message)
    d(chatPrefix() .. tostring(message))
end

------------------------------------------------------------
-- Logging
------------------------------------------------------------

--- Debug category log (silent unless LibDebugLogger or EC.debug).
--- @param category string
--- @param ... any message parts, or a single function for lazy evaluation
function EC.DebugPrint(category, ...)
    if not logger and not EC.debug then
        return
    end

    local args = { ... }
    local parts = {}

    if #args == 1 and type(args[1]) == "function" then
        local ok, result = pcall(args[1])
        if ok then
            parts[1] = tostring(result)
        else
            parts[1] = "Error in debug function: " .. tostring(result)
        end
    else
        for i, v in ipairs(args) do
            parts[i] = tostring(v)
        end
    end

    local message = table.concat(parts, " ")
    if logger then
        logger:Debug(string.format("[%s] %s", category or "CORE", message))
    elseif EC.debug then
        printToChat(string.format("|cAAAAAA[%s] %s|r", category or "CORE", message))
    end
end

function EC.Info(message)
    local text = tostring(message)
    if logger then
        logger:Info(text)
    end
    printToChat(text)
end

function EC.Warn(message)
    local text = tostring(message)
    if logger then
        logger:Warn(text)
    end
    printToChat("|cE6B800" .. text .. "|r")
end

function EC.Error(message)
    local text = tostring(message)
    if logger then
        logger:Error(text)
    end
    printToChat("|cFF6666" .. text .. "|r")
end

--- Chat helper used by SupportFooter and Commands (always visible).
function EC.Chat(message)
    printToChat(message)
end

--- Debug line gated by settings.debug (and always via DebugPrint when logger present).
function EC.Debug(message)
    EC.DebugPrint("DEBUG", tostring(message))
    if EC.db and EC.db.debug then
        printToChat("|cAAAAAA" .. tostring(message) .. "|r")
    end
end

------------------------------------------------------------
-- SafeCall helpers (ESO API wrappers)
------------------------------------------------------------

--- Call func with pcall; return first result or nil on failure.
function EC.SafeCall(func, ...)
    local success, result = EC.SafeCallMulti(func, ...)
    if success then
        return result
    end
    return nil
end

--- Call func with pcall preserving multiple return values.
--- Returns success, then the function returns (or error message on failure).
function EC.SafeCallMulti(func, ...)
    if not func or type(func) ~= "function" then
        local errorMsg = string.format("SafeCallMulti: function is nil or not a function (type=%s)", type(func))
        EC.DebugPrint("SAFECALL", errorMsg)
        return false, errorMsg
    end

    local function capture(ok, ...)
        return ok, select("#", ...), { ... }
    end

    local pcallOk, count, results = capture(pcall(func, ...))
    if not pcallOk then
        local errorMsg = results[1]
        EC.DebugPrint("SAFECALL", function()
            return string.format("Error in SafeCallMulti: %s", tostring(errorMsg))
        end)
        return false, errorMsg
    end

    return true, unpack(results, 1, count)
end

------------------------------------------------------------
-- Settings accessors
------------------------------------------------------------

function EC.GetSettings()
    return EC.db
end

function EC.IsDebugEnabled()
    return EC.db ~= nil and EC.db.debug == true
end
