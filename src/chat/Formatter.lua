-- EsoChat - CHAT_ROUTER message formatter chain

local EC = EsoChat

EC.Formatter = EC.Formatter or {}
local Formatter = EC.Formatter

local installed = false
local previousFormatter = nil

--- True only when the gamepad chat UI is what the player is using.
--- PC gamepad-preferred mode can still show keyboard chat via
--- GAMEPAD_SETTING_USE_KEYBOARD_CHAT; ZO_ChatSystem_DoesPlatformUseGamepadChatSystem
--- alone is a false positive in that case (blocks resize/formatter/tabs).
local function usesGamepadChat()
    if GetSetting_Bool and SETTING_TYPE_GAMEPAD and GAMEPAD_SETTING_USE_KEYBOARD_CHAT then
        local ok, useKeyboard = pcall(GetSetting_Bool, SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_USE_KEYBOARD_CHAT)
        if ok and useKeyboard then
            return false
        end
    end
    if CHAT_SYSTEM and CHAT_SYSTEM.primaryContainer then
        return false
    end
    if ZO_ChatSystem_DoesPlatformUseGamepadChatSystem then
        local ok, result = pcall(ZO_ChatSystem_DoesPlatformUseGamepadChatSystem)
        if ok and result then
            return true
        end
    end
    return false
end

local function formatEvent(messageType, ...)
    -- Typical EVENT_CHAT_MESSAGE_CHANNEL formatter receives channel-related args.
    -- Preserve unknown shapes by calling previous formatter when present.
    local args = { ... }
    local channelType = args[1]
    local fromName = args[2]
    local text = args[3]
    local fromDisplayName = args[5] or args[4]

    if EC.Filtering and EC.Filtering.ShouldBlock and EC.Filtering.ShouldBlock(channelType, fromName, text) then
        return "" -- suppress
    end

    local overrides = nil
    if EC.Tabs and EC.Tabs.GetActiveOverrides then
        overrides = EC.Tabs.GetActiveOverrides()
    end

    local body = text
    if EC.Display and EC.Display.FormatMessageText then
        body = EC.Display.FormatMessageText(text, overrides)
    end

    if EC.Mentions and EC.Mentions.Match then
        local mentionKw, highlighted = EC.Mentions.Match(body, channelType)
        if highlighted then
            body = highlighted
        end
        if mentionKw then
            EC.DebugPrint("FORMATTER", "mention:" .. tostring(mentionKw))
        end
    end
    local ts = ""
    local showTs = true
    if overrides and overrides.timestampEnabled ~= nil then
        showTs = overrides.timestampEnabled
    end
    if showTs and EC.Display and EC.Display.FormatTimestamp then
        ts = EC.Display.FormatTimestamp()
    end

    local name = fromName
    if EC.Display and EC.Display.FormatName then
        local modeOverride = overrides and overrides.nameMode
        if modeOverride then
            local saved = EC.db.display.nameMode
            EC.db.display.nameMode = modeOverride
            name = EC.Display.FormatName(fromName, fromDisplayName)
            EC.db.display.nameMode = saved
        else
            name = EC.Display.FormatName(fromName, fromDisplayName)
        end
    end

    -- If we have a previous formatter, prefer letting it build the final string
    -- after we mutate the text arg in-place when possible.
    if previousFormatter then
        args[3] = body
        local ok, result = pcall(previousFormatter, messageType, unpack(args))
        if ok and result ~= nil then
            if ts ~= "" and type(result) == "string" then
                return ts .. result
            end
            return result
        end
    end

    -- Fallback simple format
    if name and name ~= "" then
        return string.format("%s%s: %s", ts, name, body or "")
    end
    return ts .. (body or "")
end

function Formatter.Install()
    if installed then
        return
    end
    if usesGamepadChat() then
        EC.Warn(EC.L("gamepad_disabled"))
        -- Retry: CHAT_SYSTEM / Use Keyboard Chat may land after first activated tick
        if zo_callLater then
            zo_callLater(function()
                if not installed and not usesGamepadChat() then
                    Formatter.Install()
                end
            end, 1500)
        end
        return
    end
    if not CHAT_ROUTER or not CHAT_ROUTER.RegisterMessageFormatter then
        EC.DebugPrint("FORMATTER", "CHAT_ROUTER unavailable")
        return
    end

    -- Capture existing formatter if the router stores it
    if CHAT_ROUTER.GetMessageFormatter then
        local ok, existing = pcall(function()
            return CHAT_ROUTER:GetMessageFormatter(EVENT_CHAT_MESSAGE_CHANNEL)
        end)
        if ok and existing then
            previousFormatter = existing
        end
    end
    -- Also try common internal tables
    if not previousFormatter and CHAT_ROUTER.messageFormatters then
        previousFormatter = CHAT_ROUTER.messageFormatters[EVENT_CHAT_MESSAGE_CHANNEL]
    end
    if not previousFormatter and CHAT_ROUTER.formatters then
        previousFormatter = CHAT_ROUTER.formatters[EVENT_CHAT_MESSAGE_CHANNEL]
    end

    CHAT_ROUTER:RegisterMessageFormatter(EVENT_CHAT_MESSAGE_CHANNEL, formatEvent)
    installed = true
    EC.DebugPrint("FORMATTER", "Installed message formatter chain")

    if EC.Display and EC.Display.ApplyPreventFade then
        EC.Display.ApplyPreventFade()
    end
end

function Formatter.IsInstalled()
    return installed
end

function Formatter.UsesGamepadChat()
    return usesGamepadChat()
end

return Formatter
