-- EsoChat - Settings export/import and SV size warnings

local EC = EsoChat

EC.SettingsIO = EC.SettingsIO or {}
local SettingsIO = EC.SettingsIO

local function getCfg()
    return EC.db and EC.db.settingsIO or EC.defaults.settingsIO
end

local function serialize(value, indent)
    indent = indent or ""
    local t = type(value)
    if t == "nil" then
        return "nil"
    elseif t == "boolean" then
        return value and "true" or "false"
    elseif t == "number" then
        return tostring(value)
    elseif t == "string" then
        return string.format("%q", value)
    elseif t == "table" then
        local parts = { "{" }
        local nextIndent = indent .. "  "
        for k, v in pairs(value) do
            local key
            if type(k) == "string" and string.match(k, "^[%a_][%w_]*$") then
                key = k
            else
                key = "[" .. serialize(k, "") .. "]"
            end
            table.insert(parts, nextIndent .. key .. " = " .. serialize(v, nextIndent) .. ",")
        end
        table.insert(parts, indent .. "}")
        return table.concat(parts, "\n")
    end
    return "nil"
end

local EXPORT_SKIP = {
    entries = true,
    historyEntries = true,
    perCharacterData = true,
}

local function scrubForExport(tbl)
    local out = {}
    for k, v in pairs(tbl) do
        if not EXPORT_SKIP[k] then
            if type(v) == "table" then
                out[k] = scrubForExport(v)
            else
                out[k] = v
            end
        end
    end
    return out
end

function SettingsIO.Export()
    if not EC.db then
        return
    end
    local payload = scrubForExport(EC.db)
    payload._esoChatExport = true
    payload._version = EC.VERSION
    local text = "return " .. serialize(payload)
    if CopyToClipboard then
        pcall(CopyToClipboard, text)
        EC.Chat("Settings export copied to clipboard.")
    else
        EC.Chat(EC.L("export_ready"))
        EC.Chat(text)
    end
    local cfg = getCfg()
    cfg.lastBackupReminder = GetTimeStamp and GetTimeStamp() or os.time()
end

function SettingsIO.Import(luaChunk)
    if not luaChunk or luaChunk == "" then
        EC.Chat(EC.L("import_fail"))
        return false
    end
    local chunk, err = loadstring(luaChunk)
    if not chunk then
        EC.Error(tostring(err))
        EC.Chat(EC.L("import_fail"))
        return false
    end
    local ok, data = pcall(chunk)
    if not ok or type(data) ~= "table" then
        EC.Chat(EC.L("import_fail"))
        return false
    end
    for k, v in pairs(data) do
        if k ~= "_esoChatExport" and k ~= "_version" and k ~= "perCharacterData" and k ~= "entries" then
            if type(v) == "table" and type(EC.db[k]) == "table" then
                for sk, sv in pairs(v) do
                    if sk ~= "entries" and sk ~= "historyEntries" then
                        EC.db[k][sk] = sv
                    end
                end
            else
                EC.db[k] = v
            end
        end
    end
    EC.Chat(EC.L("import_ok"))
    return true
end

function SettingsIO.CheckSvWarning()
    local cfg = getCfg()
    local hist = EC.db and EC.db.history and EC.db.history.entries
    local count = hist and #hist or 0
    local warnAt = tonumber(cfg.svWarnEntries) or 500
    if count >= warnAt then
        EC.Warn(EC.L("sv_size_warn", count))
    end
end

function SettingsIO.MaybeRemindBackup()
    local cfg = getCfg()
    local days = tonumber(cfg.backupReminderDays) or 14
    if days <= 0 then
        return
    end
    local now = GetTimeStamp and GetTimeStamp() or os.time()
    local last = tonumber(cfg.lastBackupReminder) or 0
    if (now - last) >= (days * 86400) then
        EC.Chat(EC.L("backup_reminder"))
        cfg.lastBackupReminder = now
    end
end

return SettingsIO
