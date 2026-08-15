-- EsoChat - Named tab category profiles

local EC = EsoChat

EC.TabProfiles = EC.TabProfiles or {}
local TabProfiles = EC.TabProfiles

local function getCfg()
    return EC.db and EC.db.tabs or EC.defaults.tabs
end

local SEEDS = {
    Social = {
        CHAT_CATEGORY_SAY = true,
        CHAT_CATEGORY_YELL = true,
        CHAT_CATEGORY_EMOTE = true,
        CHAT_CATEGORY_ZONE = true,
        CHAT_CATEGORY_PARTY = true,
        CHAT_CATEGORY_SYSTEM = false,
    },
    Guild = {
        CHAT_CATEGORY_GUILD_1 = true,
        CHAT_CATEGORY_GUILD_2 = true,
        CHAT_CATEGORY_GUILD_3 = true,
        CHAT_CATEGORY_GUILD_4 = true,
        CHAT_CATEGORY_GUILD_5 = true,
        CHAT_CATEGORY_OFFICER_1 = true,
        CHAT_CATEGORY_OFFICER_2 = true,
        CHAT_CATEGORY_OFFICER_3 = true,
        CHAT_CATEGORY_OFFICER_4 = true,
        CHAT_CATEGORY_OFFICER_5 = true,
        CHAT_CATEGORY_SYSTEM = false,
    },
    Combat = {
        CHAT_CATEGORY_SYSTEM = true,
    },
    Whispers = {
        CHAT_CATEGORY_WHISPER_INCOMING = true,
        CHAT_CATEGORY_WHISPER_OUTGOING = true,
        CHAT_CATEGORY_SYSTEM = false,
    },
}

function TabProfiles.EnsureSeeds()
    local cfg = getCfg()
    cfg.profiles = cfg.profiles or {}
    for name, cats in pairs(SEEDS) do
        if not cfg.profiles[name] then
            cfg.profiles[name] = { categories = cats }
        end
    end
end

function TabProfiles.Save(name, categories)
    if not name or name == "" then
        return false
    end
    local cfg = getCfg()
    cfg.profiles = cfg.profiles or {}
    if not categories and EC.Tabs then
        local tabs = EC.Tabs.Enumerate()
        if tabs[1] then
            categories = tabs[1].categories
        end
    end
    cfg.profiles[name] = { categories = categories or {} }
    cfg.activeProfile = name
    EC.Chat(EC.L("profile_saved", name))
    return true
end

--- Disable every known category, then apply seed keys (avoids leftover enables).
function TabProfiles.CategoriesForApply(seed)
    local cats = {}
    if EC.Tabs and EC.Tabs.AllCategoriesDisabled then
        local disabled = EC.Tabs.AllCategoriesDisabled()
        for k, v in pairs(disabled) do
            cats[k] = v
        end
    end
    for k, v in pairs(seed or {}) do
        cats[k] = v and true or false
    end
    return cats
end

function TabProfiles.Apply(name, tabName)
    local cfg = getCfg()
    local profile = cfg.profiles and cfg.profiles[name]
    if not profile then
        EC.Chat(EC.L("profile_missing", tostring(name)))
        return false
    end
    local tab = nil
    if tabName and EC.Tabs then
        tab = EC.Tabs.FindByName(tabName)
    elseif EC.Tabs then
        local tabs = EC.Tabs.Enumerate()
        tab = tabs[1]
    end
    if not tab then
        EC.Chat(EC.L("tab_not_found", tostring(tabName or "?")))
        return false
    end
    EC.Tabs.ApplyCategories(tab.containerIndex, tab.tabIndex, TabProfiles.CategoriesForApply(profile.categories))
    cfg.activeProfile = name
    EC.Chat(EC.L("profile_applied", name))
    return true
end

function TabProfiles.List()
    local cfg = getCfg()
    EC.Chat("Profiles:")
    for name, _ in pairs(cfg.profiles or {}) do
        EC.Chat("  " .. name)
    end
end

function TabProfiles.Delete(name)
    local cfg = getCfg()
    if cfg.profiles then
        cfg.profiles[name] = nil
    end
end

return TabProfiles
