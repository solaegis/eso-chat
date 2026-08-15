-- EsoChat - /ech create dispatcher (typed tabs, whisper targets, group)

local EC = EsoChat

EC.TabCreate = EC.TabCreate or {}
local TabCreate = EC.TabCreate

local TYPE_MAP = {
    whispers = { kind = "special", mode = "whispers" },
    w = { kind = "special", mode = "whispers" },
    mentions = { kind = "special", mode = "mentions" },
    m = { kind = "special", mode = "mentions" },
    friends = { kind = "special", mode = "friends" },
    f = { kind = "special", mode = "friends" },
    notes = { kind = "special", mode = "notes" },
    n = { kind = "special", mode = "notes" },
    group = { kind = "group" },
    social = { kind = "profile", profile = "Social" },
    guild = { kind = "profile", profile = "Guild" },
    combat = { kind = "profile", profile = "Combat" },
    system = { kind = "profile", profile = "Combat" },
    s = { kind = "profile", profile = "Combat" },
}

local function trim(s)
    s = tostring(s or "")
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

local function getTabsCfg()
    return EC.db and EC.db.tabs or (EC.defaults and EC.defaults.tabs) or {}
end

function TabCreate.PrintHelp()
    -- ESO chat treats "|" as markup; use "||" so a literal pipe is shown.
    EC.Chat("NAME")
    EC.Chat("  /ech create - create a chat tab (optionally typed, with whisper target)")
    EC.Chat("SYNOPSIS")
    EC.Chat("  /ech create <tabLabel>")
    EC.Chat("  /ech create whispers [tabLabel] [@account || --to <Name>]")
    EC.Chat("  /ech create mentions [tabLabel]")
    EC.Chat("  /ech create friends [tabLabel]")
    EC.Chat("  /ech create notes [tabLabel]")
    EC.Chat("  /ech create group [tabLabel]")
    EC.Chat("  /ech create social||guild||combat||system [tabLabel]")
    EC.Chat("  /ech create help")
    EC.Chat("See docs/TABS.md for full behavior, settings, and examples.")
end

--- Build candidate strings for friend/group/guild APIs.
function TabCreate.TargetCandidates(raw)
    raw = trim(raw)
    if raw == "" then
        return {}
    end
    local out = { raw }
    if string.sub(raw, 1, 1) == "@" then
        local bare = string.sub(raw, 2)
        if bare ~= "" then
            table.insert(out, bare)
        end
    else
        table.insert(out, "@" .. raw)
    end
    -- de-dupe case-insensitively while preserving first form
    local seen = {}
    local uniq = {}
    for _, c in ipairs(out) do
        local k = string.lower(c)
        if not seen[k] then
            seen[k] = true
            table.insert(uniq, c)
        end
    end
    return uniq
end

local function namesMatch(a, b)
    if not a or not b then
        return false
    end
    return string.lower(tostring(a)) == string.lower(tostring(b))
end

--- Verify target exists (friend -> group -> guild). Returns canonical display string or nil.
function TabCreate.VerifyTarget(raw)
    local candidates = TabCreate.TargetCandidates(raw)
    if #candidates == 0 then
        return nil
    end

    for _, c in ipairs(candidates) do
        if IsFriend then
            local ok, result = pcall(IsFriend, c)
            if ok and result then
                return c
            end
        end
    end

    for _, c in ipairs(candidates) do
        if IsPlayerInGroup then
            local ok, result = pcall(IsPlayerInGroup, c)
            if ok and result then
                return c
            end
        end
    end

    if GetNumGuilds and GetGuildId and GetNumGuildMembers then
        local numGuilds = GetNumGuilds() or 0
        for gi = 1, numGuilds do
            local guildId = GetGuildId(gi)
            if guildId then
                for _, c in ipairs(candidates) do
                    if GetGuildMemberIndexFromDisplayName then
                        local ok, idx = pcall(GetGuildMemberIndexFromDisplayName, guildId, c)
                        if ok and idx then
                            return c
                        end
                    end
                end
                local n = GetNumGuildMembers(guildId) or 0
                for mi = 1, n do
                    local memberName = nil
                    if GetGuildMemberInfo then
                        local ok, name = pcall(GetGuildMemberInfo, guildId, mi)
                        if ok then
                            memberName = name
                        end
                    end
                    local charName = nil
                    if GetGuildMemberCharacterInfo then
                        local ok, hasChar, cname = pcall(GetGuildMemberCharacterInfo, guildId, mi)
                        if ok and hasChar then
                            charName = cname
                        end
                    end
                    for _, c in ipairs(candidates) do
                        if namesMatch(memberName, c) or namesMatch(charName, c) then
                            if memberName and memberName ~= "" then
                                return memberName
                            end
                            return c
                        end
                    end
                end
            end
        end
    end

    return nil
end

--- Parse create args. Returns table or nil + error message.
function TabCreate.Parse(rest)
    rest = trim(rest or "")
    if rest == "" or string.lower(rest) == "help" or rest == "?" then
        return { help = true }
    end

    local tokens = {}
    for token in string.gmatch(rest, "%S+") do
        table.insert(tokens, token)
    end

    local tabLabel = nil
    local target = nil
    local first = tokens[1]
    local firstLower = first and string.lower(first) or ""
    local typeInfo = TYPE_MAP[firstLower]
    local idx

    if typeInfo then
        idx = 2
    elseif first and string.sub(first, 1, 1) == "@" then
        return nil, "Use /ech create whispers @account (target requires whispers type)"
    else
        -- bare tab: entire first token is label; no further typed args
        return { kind = "bare", tabLabel = first }
    end

    while idx <= #tokens do
        local t = tokens[idx]
        local tl = string.lower(t)
        if tl == "--to" then
            idx = idx + 1
            if not tokens[idx] then
                return nil, "Missing name after --to"
            end
            target = tokens[idx]
        elseif string.sub(t, 1, 1) == "@" then
            target = t
        elseif not tabLabel then
            tabLabel = t
        else
            return nil, "Unexpected argument: " .. t
        end
        idx = idx + 1
    end

    if target and typeInfo.kind ~= "special" then
        return nil, "Whisper target is only valid with whispers"
    end
    if target and typeInfo.mode and typeInfo.mode ~= "whispers" then
        return nil, "Whisper target is only valid with whispers"
    end

    return {
        kind = typeInfo.kind,
        mode = typeInfo.mode,
        profile = typeInfo.profile,
        tabLabel = tabLabel,
        target = target,
    }
end

local function defaultSpecialName(mode)
    local cfg = getTabsCfg()
    if mode == "whispers" then
        return cfg.whispersTabName or "Whispers"
    elseif mode == "mentions" then
        return cfg.mentionsTabName or "Mentions"
    elseif mode == "friends" then
        return cfg.friendsTabName or "Friends"
    elseif mode == "notes" then
        local notes = EC.db and EC.db.notes
        return (notes and notes.tabName) or cfg.notesTabName or "Notes"
    end
    return mode
end

local function finishTab(tab, msg)
    if not tab then
        return false
    end
    if EC.Tabs.Focus then
        EC.Tabs.Focus(tab)
    end
    if EC.Tabs.SnapshotLayout then
        EC.Tabs.SnapshotLayout()
    end
    if msg then
        EC.Chat(msg)
    end
    return true
end

local function createSpecial(spec)
    local verified = nil
    if spec.target then
        verified = TabCreate.VerifyTarget(spec.target)
        if not verified then
            EC.Chat(string.format("Target not found: %s (friend, group, or guild)", tostring(spec.target)))
            return false
        end
    end

    local name = spec.tabLabel
    if not name or name == "" then
        if verified then
            name = verified
        else
            name = defaultSpecialName(spec.mode)
        end
    end

    if not EC.TabFilters or not EC.TabFilters.EnsureTab then
        EC.Chat("TabFilters module not loaded.")
        return false
    end

    local ok = EC.TabFilters.EnsureTab(spec.mode, name, { silent = true })
    if not ok then
        return false
    end
    local tab = EC.Tabs.FindByName(name)
    if not tab then
        return false
    end

    if verified and spec.mode == "whispers" then
        EC.Tabs.SeedInputChannel(tab, CHAT_CHANNEL_WHISPER, verified)
        EC.Tabs.Focus(tab)
        EC.Tabs.SnapshotLayout()
        EC.Chat(string.format("Created/ready: %s (whispers -> %s)", tab.name, verified))
        return true
    end

    return finishTab(tab, string.format("Created/ready: %s (%s)", tab.name, spec.mode))
end

local function createGroup(spec)
    if not EC.Tabs or not EC.Tabs.IsPlayerGrouped or not EC.Tabs.IsPlayerGrouped() then
        EC.Chat("Not in a group")
        return false
    end
    local name = spec.tabLabel
    if not name or name == "" then
        name = "Group"
    end
    local tab = EC.Tabs.Ensure(name, { silent = true })
    if not tab then
        EC.Chat("Failed to create group tab.")
        return false
    end
    EC.Tabs.ApplyCategories(tab.containerIndex, tab.tabIndex, EC.Tabs.PartyOnlyCategories())
    EC.Tabs.SetGroupChannelFlag(tab.name, true)
    EC.Tabs.SeedInputChannel(tab, CHAT_CHANNEL_PARTY, nil)
    if EC.Tabs.SyncGroupTabCategories then
        EC.Tabs.SyncGroupTabCategories()
    end
    return finishTab(tab, string.format("Created/ready: %s (group)", tab.name))
end

local function createProfile(spec)
    if EC.TabProfiles and EC.TabProfiles.EnsureSeeds then
        EC.TabProfiles.EnsureSeeds()
    end
    local name = spec.tabLabel
    if not name or name == "" then
        name = spec.profile
    end
    local tab = EC.Tabs.Ensure(name, { silent = true })
    if not tab then
        EC.Chat("Failed to create tab.")
        return false
    end
    if not EC.TabProfiles or not EC.TabProfiles.Apply then
        EC.Chat("TabProfiles module not loaded.")
        return false
    end
    EC.TabProfiles.Apply(spec.profile, tab.name)
    return finishTab(tab, string.format("Created/ready: %s (%s)", tab.name, string.lower(spec.profile)))
end

local function createBare(spec)
    if not spec.tabLabel or spec.tabLabel == "" then
        EC.Chat("Usage: /ech create <tabLabel>")
        return false
    end
    if not EC.Tabs.Create(spec.tabLabel) then
        EC.Chat("Failed to create tab.")
        return false
    end
    local tab = EC.Tabs.FindByName(spec.tabLabel)
    return finishTab(tab, nil)
end

function TabCreate.Run(rest)
    local spec, err = TabCreate.Parse(rest)
    if not spec then
        EC.Chat(err or "Invalid /ech create arguments")
        return false
    end
    if spec.help then
        TabCreate.PrintHelp()
        return true
    end
    if not EC.Tabs then
        EC.Chat("Tabs module not loaded.")
        return false
    end
    if EC.Formatter and EC.Formatter.UsesGamepadChat and EC.Formatter.UsesGamepadChat() then
        EC.Chat("Tab create requires keyboard chat.")
        return false
    end

    if spec.kind == "bare" then
        return createBare(spec)
    elseif spec.kind == "special" then
        return createSpecial(spec)
    elseif spec.kind == "group" then
        return createGroup(spec)
    elseif spec.kind == "profile" then
        return createProfile(spec)
    end
    EC.Chat("Unknown create kind.")
    return false
end

return TabCreate
