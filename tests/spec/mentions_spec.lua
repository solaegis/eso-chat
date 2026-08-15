describe("Mentions", function()
    it("matches case-insensitive substring", function()
        EsoChat.db.mentions.enabled = true
        EsoChat.db.mentions.keywords = "solaegis\nalert"
        EsoChat.db.mentions.useRegex = false
        EsoChat.db.mentions.excludeWhispers = true
        local matched, text = EsoChat.Mentions.Match("Hello Solaegis there", CHAT_CHANNEL_SAY)
        assertEqual(matched, "solaegis")
        assertTrue(string.find(text, "|c", 1, true) ~= nil)
    end)

    it("excludes whispers when configured", function()
        EsoChat.db.mentions.keywords = "ping"
        EsoChat.db.mentions.excludeWhispers = true
        local matched = EsoChat.Mentions.Match("ping me", CHAT_CHANNEL_WHISPER)
        assertNil(matched)
    end)

    it("parses keyword list", function()
        EsoChat.db.mentions.keywords = "one\n\ntwo\n"
        local list = EsoChat.Mentions.GetKeywords()
        assertEqual(#list, 2)
        assertEqual(list[1], "one")
        assertEqual(list[2], "two")
    end)
end)
