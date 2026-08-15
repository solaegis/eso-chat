-- EsoChat - Sound catalog for LAM dropdowns
--
-- Never dump the full SOUNDS table into a LAM dropdown: ESO has thousands of
-- entries and three full lists freeze the UI long enough for the client to
-- time out / disconnect. Shortlist only until the user searches.

local EC = EsoChat

EC.Sounds = EC.Sounds or {}
local Sounds = EC.Sounds

local catalogChoices = nil
local catalogValues = nil
local catalogBuilt = false

local shortChoices = nil
local shortValues = nil
local shortBuilt = false

local DEFAULT_SOUND = "New_Notification"
local NONE_LABEL = "(None)"
local NONE_VALUE = "NONE"
local MIN_FILTER_CHARS = 2
local MAX_FILTER_RESULTS = 80

-- Curated keys (SOUNDS table keys). Missing keys are skipped at build time.
local SHORTLIST_KEYS = {
    "NEW_NOTIFICATION",
    "NEW_MAIL",
    "DEFAULT_CLICK",
    "POSITIVE_CLICK",
    "NEGATIVE_CLICK",
    "QUEST_ACCEPTED",
    "QUEST_COMPLETED",
    "QUEST_OBJECTIVE_STARTED",
    "QUEST_STEP_FAILED",
    "ACHIEVEMENT_AWARDED",
    "LEVEL_UP",
    "SKILL_GAINED",
    "SKILL_LINE_LEVELED_UP",
    "BOOK_ACQUIRED",
    "CODEX_ENTRY_UNLOCKED",
    "TELVAR_GAINED",
    "ALLIANCE_POINT_GAINED",
    "INVENTORY_ITEM_APPLY_CHARGED",
    "DUEL_START",
    "DUEL_FORFEIT",
    "GROUP_ELECTION_REQUESTED",
    "GROUP_DISBAND",
    "GUILD_SELF_JOINED",
    "GUILD_SELF_LEFT",
    "FRIEND_INVITE_RECEIVED",
    "VOICE_CHAT_ALERT_CHANNEL_MADE_ACTIVE",
    "OBJECTIVE_DISCOVERED",
    "LOCKPICKING_SUCCESS",
    "LOCKPICKING_FAILED",
    "DEATH",
    "PLAYER_TELEPORTING",
}

local function addUnique(seen, choices, values, label, value)
    if value == nil or value == "" then
        return
    end
    if seen[value] then
        return
    end
    seen[value] = true
    table.insert(choices, label)
    table.insert(values, value)
end

local function storeForKey(key)
    if not SOUNDS then
        return key
    end
    local playValue = SOUNDS[key]
    if type(playValue) == "string" and playValue ~= "" then
        return playValue
    end
    return key
end

--- Cheap: ~30 curated entries. Safe to call when opening settings.
function Sounds.EnsureShortlist()
    if shortBuilt and shortChoices and #shortChoices > 0 then
        return
    end
    local choices = {}
    local values = {}
    local seen = {}
    addUnique(seen, choices, values, NONE_LABEL, NONE_VALUE)
    if SOUNDS then
        for i = 1, #SHORTLIST_KEYS do
            local key = SHORTLIST_KEYS[i]
            if SOUNDS[key] ~= nil then
                addUnique(seen, choices, values, key, storeForKey(key))
            end
        end
    end
    addUnique(seen, choices, values, "NEW_NOTIFICATION", DEFAULT_SOUND)
    shortChoices = choices
    shortValues = values
    shortBuilt = true
end

--- Expensive: full SOUNDS + LMP. Only for filter search (deferred).
local function ensureFullCatalog()
    if catalogBuilt and catalogChoices and #catalogChoices > 0 then
        return
    end
    local choices = {}
    local values = {}
    local seen = {}

    addUnique(seen, choices, values, NONE_LABEL, NONE_VALUE)

    if SOUNDS then
        local keys = {}
        for key, _ in pairs(SOUNDS) do
            if type(key) == "string" and key ~= "NONE" then
                table.insert(keys, key)
            end
        end
        table.sort(keys)
        for i = 1, #keys do
            local key = keys[i]
            addUnique(seen, choices, values, key, storeForKey(key))
        end
    end

    if LibMediaProvider then
        local ok, list = pcall(function()
            if LibMediaProvider.List then
                return LibMediaProvider:List("sound")
            end
            return nil
        end)
        if ok and type(list) == "table" then
            local lmpKeys = {}
            for i = 1, #list do
                if type(list[i]) == "string" then
                    table.insert(lmpKeys, list[i])
                end
            end
            if #lmpKeys == 0 then
                for k, _ in pairs(list) do
                    if type(k) == "string" then
                        table.insert(lmpKeys, k)
                    end
                end
            end
            table.sort(lmpKeys)
            for i = 1, #lmpKeys do
                local key = lmpKeys[i]
                addUnique(seen, choices, values, "LMP: " .. key, key)
            end
        end
    end

    addUnique(seen, choices, values, "NEW_NOTIFICATION", DEFAULT_SOUND)
    catalogChoices = choices
    catalogValues = values
    catalogBuilt = true
end

--- Reset caches (tests / optional rebuild).
function Sounds.RebuildCatalog()
    catalogBuilt = false
    catalogChoices = nil
    catalogValues = nil
    shortBuilt = false
    shortChoices = nil
    shortValues = nil
    Sounds.EnsureShortlist()
end

function Sounds.GetAll()
    ensureFullCatalog()
    return catalogChoices, catalogValues
end

function Sounds.GetShortlist()
    Sounds.EnsureShortlist()
    return shortChoices, shortValues
end

function Sounds.MinFilterChars()
    return MIN_FILTER_CHARS
end

--- Dropdown choices: shortlist when filter is empty/short; capped search otherwise.
function Sounds.GetFiltered(filter)
    Sounds.EnsureShortlist()
    filter = filter or ""
    if #filter < MIN_FILTER_CHARS then
        return shortChoices, shortValues, "shortlist"
    end

    ensureFullCatalog()
    local needle = string.lower(filter)
    local choices = {}
    local values = {}
    for i = 1, #catalogChoices do
        local label = catalogChoices[i]
        local value = catalogValues[i]
        if string.find(string.lower(label), needle, 1, true)
            or string.find(string.lower(tostring(value)), needle, 1, true)
        then
            table.insert(choices, label)
            table.insert(values, value)
            if #choices >= MAX_FILTER_RESULTS then
                break
            end
        end
    end
    if #choices == 0 then
        table.insert(choices, NONE_LABEL)
        table.insert(values, NONE_VALUE)
        return choices, values, "none"
    end
    return choices, values, "search"
end

function Sounds.Normalize(stored)
    if not stored or stored == "" then
        return DEFAULT_SOUND
    end
    if stored == NONE_VALUE or stored == "No_Sound" then
        return NONE_VALUE
    end
    if SOUNDS and type(SOUNDS[stored]) == "string" and SOUNDS[stored] ~= "" then
        return SOUNDS[stored]
    end
    return stored
end

function Sounds.Play(stored)
    local name = Sounds.Normalize(stored)
    if name == NONE_VALUE or name == "" then
        return
    end
    if LibMediaProvider and LibMediaProvider.Fetch then
        local ok, media = pcall(function()
            return LibMediaProvider:Fetch("sound", name)
        end)
        if ok and media then
            name = media
        end
    end
    if PlaySound then
        pcall(PlaySound, name)
    end
end

function Sounds.Default()
    return DEFAULT_SOUND
end

function Sounds.NoneValue()
    return NONE_VALUE
end

local function labelForValue(selected)
    Sounds.EnsureShortlist()
    for i = 1, #shortValues do
        if shortValues[i] == selected then
            return shortChoices[i]
        end
    end
    if catalogBuilt then
        for i = 1, #catalogValues do
            if catalogValues[i] == selected then
                return catalogChoices[i]
            end
        end
    end
    return selected
end

function Sounds.EnsureSelectionVisible(choices, values, selected)
    selected = Sounds.Normalize(selected)
    for i = 1, #values do
        if values[i] == selected then
            return choices, values
        end
    end
    local label = labelForValue(selected)
    local outChoices = { label }
    local outValues = { selected }
    for i = 1, #choices do
        table.insert(outChoices, choices[i])
        table.insert(outValues, values[i])
    end
    return outChoices, outValues
end

return Sounds
