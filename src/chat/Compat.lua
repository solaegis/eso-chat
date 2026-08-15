-- EsoChat - Coexistence with other chat formatter addons

local EC = EsoChat

EC.Compat = EC.Compat or {}
local Compat = EC.Compat

local KNOWN = {
    { global = "pChat", label = "pChat" },
    { global = "rChat", label = "rChat" },
    { global = "FCOCTB", label = "FCOChatTabBrain" },
    { global = "FCOChatTabBrain", label = "FCOChatTabBrain" },
}

function Compat.DetectOthers()
    local found = {}
    for _, entry in ipairs(KNOWN) do
        if _G[entry.global] ~= nil then
            table.insert(found, entry.label)
        end
    end
    return found
end

function Compat.WarnIfNeeded()
    local cfg = EC.db and EC.db.compat
    if not cfg then
        return
    end
    local found = Compat.DetectOthers()
    if #found == 0 then
        return
    end
    if cfg.warnedThisSession then
        return
    end
    cfg.warnedThisSession = true
    EC.Warn(EC.L("compat_warning") .. " (" .. table.concat(found, ", ") .. ")")
end

--- Soft-disable overlapping display features unless forceEnableOverlaps.
function Compat.ShouldRunDisplay()
    local cfg = EC.db and EC.db.compat
    if cfg and cfg.forceEnableOverlaps then
        return true
    end
    local found = Compat.DetectOthers()
    -- Still run, but user was warned; EsoChat chains formatters
    return true, found
end

function Compat.Start()
    Compat.WarnIfNeeded()
end

return Compat
