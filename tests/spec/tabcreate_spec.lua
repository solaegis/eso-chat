describe("TabCreate", function()
    it("parses bare tab label", function()
        local spec, err = EsoChat.TabCreate.Parse("LFG")
        assertNil(err)
        assertEqual(spec.kind, "bare")
        assertEqual(spec.tabLabel, "LFG")
    end)

    it("parses whispers with @target and defaults label later", function()
        local spec, err = EsoChat.TabCreate.Parse("whispers @solaegis")
        assertNil(err)
        assertEqual(spec.kind, "special")
        assertEqual(spec.mode, "whispers")
        assertEqual(spec.target, "@solaegis")
        assertNil(spec.tabLabel)
    end)

    it("parses whispers with label and target", function()
        local spec, err = EsoChat.TabCreate.Parse("whispers Mail @solaegis")
        assertNil(err)
        assertEqual(spec.tabLabel, "Mail")
        assertEqual(spec.target, "@solaegis")
    end)

    it("parses --to character target", function()
        local spec, err = EsoChat.TabCreate.Parse("whispers --to Hadrian")
        assertNil(err)
        assertEqual(spec.target, "Hadrian")
        assertNil(spec.tabLabel)
    end)

    it("parses group with optional label", function()
        local spec, err = EsoChat.TabCreate.Parse("group Dungeon")
        assertNil(err)
        assertEqual(spec.kind, "group")
        assertEqual(spec.tabLabel, "Dungeon")
    end)

    it("parses profile social", function()
        local spec, err = EsoChat.TabCreate.Parse("social")
        assertNil(err)
        assertEqual(spec.kind, "profile")
        assertEqual(spec.profile, "Social")
    end)

    it("maps combat and system to Combat profile", function()
        local c = EsoChat.TabCreate.Parse("combat")
        assertEqual(c.kind, "profile")
        assertEqual(c.profile, "Combat")
        local s = EsoChat.TabCreate.Parse("system")
        assertEqual(s.kind, "profile")
        assertEqual(s.profile, "Combat")
        local short = EsoChat.TabCreate.Parse("s")
        assertEqual(short.profile, "Combat")
    end)

    it("parses notes special type", function()
        local spec, err = EsoChat.TabCreate.Parse("notes Journal")
        assertNil(err)
        assertEqual(spec.kind, "special")
        assertEqual(spec.mode, "notes")
        assertEqual(spec.tabLabel, "Journal")
        local n = EsoChat.TabCreate.Parse("n")
        assertEqual(n.mode, "notes")
    end)

    it("rejects @target without whispers type", function()
        local spec, err = EsoChat.TabCreate.Parse("@solaegis")
        assertNil(spec)
        assertTrue(err ~= nil)
    end)

    it("rejects target on mentions", function()
        local spec, err = EsoChat.TabCreate.Parse("mentions @solaegis")
        assertNil(spec)
        assertTrue(err ~= nil)
    end)

    it("maps short aliases w m f", function()
        local w = EsoChat.TabCreate.Parse("w")
        assertEqual(w.mode, "whispers")
        local m = EsoChat.TabCreate.Parse("m")
        assertEqual(m.mode, "mentions")
        local f = EsoChat.TabCreate.Parse("f")
        assertEqual(f.mode, "friends")
    end)

    it("builds target candidates with and without @", function()
        local c = EsoChat.TabCreate.TargetCandidates("@solaegis")
        assertEqual(c[1], "@solaegis")
        assertEqual(c[2], "solaegis")
    end)

    it("verify fails when not friend/group/guild", function()
        IsFriend = function()
            return false
        end
        IsPlayerInGroup = function()
            return false
        end
        GetNumGuilds = function()
            return 0
        end
        assertNil(EsoChat.TabCreate.VerifyTarget("@nobody"))
    end)

    it("verify succeeds for friend", function()
        IsFriend = function(name)
            return string.lower(name) == "@buddy" or string.lower(name) == "buddy"
        end
        local v = EsoChat.TabCreate.VerifyTarget("@buddy")
        assertEqual(v, "@buddy")
        IsFriend = function()
            return false
        end
    end)
end)
