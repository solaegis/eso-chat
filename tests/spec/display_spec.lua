describe("Display", function()
    it("strips color codes", function()
        local out = EsoChat.Display.StripColors("|cFF0000Hello|r world")
        assertEqual(out, "Hello world")
    end)

    it("strips says phrasing", function()
        local out = EsoChat.Display.StripSays("Bob says, hello")
        assertTrue(string.find(out, "hello", 1, true) ~= nil)
        assertTrue(string.find(out, "says") == nil)
    end)

    it("formats character names", function()
        EsoChat.db.display.nameMode = "character"
        EsoChat.db.display.nicknames = {}
        local name = EsoChat.Display.FormatName("Hero", "@account")
        assertEqual(name, "Hero")
    end)

    it("formats both names", function()
        EsoChat.db.display.nameMode = "both"
        local name = EsoChat.Display.FormatName("Hero", "@account")
        assertEqual(name, "Hero(@account)")
    end)

    it("applies nicknames", function()
        EsoChat.db.display.nicknames = { ["@account"] = "Buddy" }
        local name = EsoChat.Display.FormatName("Hero", "@account")
        assertEqual(name, "Buddy")
    end)
end)
