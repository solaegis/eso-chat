-- EsoChat - Copy chat history / lines to clipboard helpers

local EC = EsoChat

EC.CopyPaste = EC.CopyPaste or {}
local CopyPaste = EC.CopyPaste

local function getCfg()
    return EC.db and EC.db.copy or EC.defaults.copy
end

local function strip(text)
    if EC.Display and EC.Display.StripColors then
        return EC.Display.StripColors(text)
    end
    return text
end

--- Build copy text from last N history entries.
function CopyPaste.FormatHistory(n)
    local cfg = getCfg()
    local hist = EC.db and EC.db.history and EC.db.history.entries or {}
    n = tonumber(n) or 20
    local start = math.max(1, #hist - n + 1)
    local lines = {}
    for i = start, #hist do
        local e = hist[i]
        local text = e.text or ""
        if cfg.stripFormatting then
            text = strip(text)
        end
        if cfg.includeMeta then
            table.insert(lines, string.format("[%s] %s: %s", tostring(e.channel), tostring(e.from), text))
        else
            table.insert(lines, text)
        end
    end
    return table.concat(lines, "\n")
end

function CopyPaste.CopyHistory(n)
    local text = CopyPaste.FormatHistory(n)
    if text == "" then
        EC.Chat(EC.L("history_empty"))
        return
    end
    if CopyToClipboard then
        pcall(CopyToClipboard, text)
        EC.Chat("Copied " .. tostring(n or 20) .. " history lines to clipboard.")
    else
        -- Fallback: dump to chat for manual select
        EC.Chat("--- COPY START ---")
        for line in string.gmatch(text .. "\n", "(.-)\n") do
            EC.Chat(line)
        end
        EC.Chat("--- COPY END ---")
    end
end

return CopyPaste
