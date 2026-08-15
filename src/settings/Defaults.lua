-- EsoChat - default SavedVariables

local EC = EsoChat

EC.defaults = {
    enabled = true,
    debug = false,
    -- Reserved for optional per-character buckets (do not wipe on reset).
    perCharacterData = {},
}

--- Reset account settings to defaults, preserving perCharacterData.
function EC.ResetSettings()
    if not EC.db then
        return
    end

    local preserved = EC.db.perCharacterData
    for key, value in pairs(EC.defaults) do
        if key ~= "perCharacterData" then
            if type(value) == "table" then
                if ZO_DeepTableCopy then
                    EC.db[key] = ZO_DeepTableCopy(value)
                else
                    EC.db[key] = ZO_ShallowTableCopy(value)
                end
            else
                EC.db[key] = value
            end
        end
    end
    EC.db.perCharacterData = preserved or {}
    EC.Info("Settings reset to defaults")
end
