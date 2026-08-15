describe("TabFilters", function()
    local function resetSticky()
        EsoChat.TabFilters.ClearSessionSticky()
    end

    it("clamps conversation sticky minutes", function()
        assertEqual(EsoChat.TabFilters.ClampStickyMinutes(0), 1)
        assertEqual(EsoChat.TabFilters.ClampStickyMinutes(5), 5)
        assertEqual(EsoChat.TabFilters.ClampStickyMinutes(99), 60)
    end)

    it("injects mention hits from others", function()
        resetSticky()
        local ok, key, reason = EsoChat.TabFilters.ShouldInjectMentions(
            CHAT_CHANNEL_SAY,
            "OtherChar",
            "hey there",
            "@other",
            { isLocalPlayer = false, mentionHit = true }
        )
        assertTrue(ok)
        assertEqual(reason, "hit")
        assertEqual(key, "@other")
    end)

    it("injects self reply when mention partner is sticky", function()
        resetSticky()
        local map = {}
        EsoChat.TabFilters.TouchSticky(map, "@other", CHAT_CHANNEL_SAY)
        local ok, key, reason = EsoChat.TabFilters.ShouldInjectMentions(
            CHAT_CHANNEL_SAY,
            "Me",
            "replying",
            "@me",
            { isLocalPlayer = true, stickyMap = map, mentionHit = false }
        )
        assertTrue(ok)
        assertEqual(reason, "self_sticky")
        assertEqual(key, "@other")
    end)

    it("injects partner follow-up via sticky without mention", function()
        resetSticky()
        local map = {}
        EsoChat.TabFilters.TouchSticky(map, "@other", CHAT_CHANNEL_ZONE)
        local ok, key, reason = EsoChat.TabFilters.ShouldInjectMentions(
            CHAT_CHANNEL_ZONE,
            "OtherChar",
            "still here",
            "@other",
            { isLocalPlayer = false, stickyMap = map, mentionHit = false }
        )
        assertTrue(ok)
        assertEqual(reason, "partner_sticky")
        assertEqual(key, "@other")
    end)

    it("injects messages from friends", function()
        resetSticky()
        local ok, _, reason = EsoChat.TabFilters.ShouldInjectFriends(
            CHAT_CHANNEL_SAY,
            "Buddy",
            "hi",
            "@buddy",
            { isLocalPlayer = false, fromFriend = true }
        )
        assertTrue(ok)
        assertEqual(reason, "from_friend")
    end)

    it("injects outgoing whisper to a friend", function()
        resetSticky()
        local ok, _, reason = EsoChat.TabFilters.ShouldInjectFriends(
            CHAT_CHANNEL_WHISPER_SENT,
            "Buddy",
            "secret",
            "@buddy",
            { isLocalPlayer = true, toFriend = true }
        )
        assertTrue(ok)
        assertEqual(reason, "to_friend")
    end)

    it("injects self sticky reply after friend traffic", function()
        resetSticky()
        local map = {}
        EsoChat.TabFilters.TouchSticky(map, "@buddy", CHAT_CHANNEL_SAY)
        local ok, key, reason = EsoChat.TabFilters.ShouldInjectFriends(
            CHAT_CHANNEL_SAY,
            "Me",
            "my reply",
            "@me",
            { isLocalPlayer = true, stickyMap = map, fromFriend = false }
        )
        assertTrue(ok)
        assertEqual(reason, "self_sticky")
        assertEqual(key, "@buddy")
    end)
end)
