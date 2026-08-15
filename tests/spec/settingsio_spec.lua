describe("SettingsIO", function()
    it("exports scrubbed settings without history entries", function()
        EsoChat.db.history.entries = { { ts = 1, text = "secret" } }
        local text = nil
        local oldCopy = CopyToClipboard
        CopyToClipboard = function(t)
            text = t
        end
        EsoChat.SettingsIO.Export()
        CopyToClipboard = oldCopy
        assertTrue(text ~= nil)
        assertTrue(string.find(text, "_esoChatExport", 1, true) ~= nil)
        assertTrue(string.find(text, "secret", 1, true) == nil)
    end)

    it("imports settings tables", function()
        local ok = EsoChat.SettingsIO.Import('return { _esoChatExport = true, display = { nameMode = "account" } }')
        assertTrue(ok)
        assertEqual(EsoChat.db.display.nameMode, "account")
    end)
end)
