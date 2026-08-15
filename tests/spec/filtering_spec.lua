describe("Filtering", function()
    it("blocks LFG in zone when enabled", function()
        EsoChat.db.filtering.enabled = true
        EsoChat.db.filtering.blockLFG = true
        EsoChat.db.filtering.applyToZone = true
        EsoChat.db.filtering.floodProtect = false
        assertTrue(EsoChat.Filtering.ShouldBlock(CHAT_CHANNEL_ZONE, "Bob", "LFG dungeon"))
    end)

    it("allows LFG when filter disabled", function()
        EsoChat.db.filtering.enabled = false
        assertFalse(EsoChat.Filtering.ShouldBlock(CHAT_CHANNEL_ZONE, "Bob", "LFG dungeon"))
    end)

    it("blocks custom keywords", function()
        EsoChat.db.filtering.enabled = true
        EsoChat.db.filtering.blockLFG = false
        EsoChat.db.filtering.blockTrade = false
        EsoChat.db.filtering.blockRecruit = false
        EsoChat.db.filtering.customKeywords = "goldspam"
        EsoChat.db.filtering.applyToZone = true
        EsoChat.db.filtering.floodProtect = false
        assertTrue(EsoChat.Filtering.ShouldBlock(CHAT_CHANNEL_ZONE, "Bob", "buy my goldspam now"))
    end)
end)
