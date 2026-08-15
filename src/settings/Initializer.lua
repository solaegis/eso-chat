-- EsoChat - SavedVariables initializer helpers

local EC = EsoChat

--- Ensure the current character has a bucket under account-wide perCharacterData.
--- Product addons can store character-specific fields here; do not put these in Defaults.
function EC.EnsureCharacterData()
    if not EC.db then
        return nil
    end
    if not EC.db.perCharacterData then
        EC.db.perCharacterData = {}
    end

    local characterId = tostring(GetCurrentCharacterId())
    if not EC.db.perCharacterData[characterId] then
        EC.db.perCharacterData[characterId] = {
            _initialized = true,
            notesText = "",
        }
    end

    EC.charData = EC.db.perCharacterData[characterId]
    if EC.charData.notesText == nil then
        EC.charData.notesText = ""
    end
    return EC.charData
end
