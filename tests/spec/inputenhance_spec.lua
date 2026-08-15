describe("InputEnhance history", function()
    local function resetInput()
        EsoChat.db.input = {
            counterEnabled = true,
            historyEnabled = true,
            historyMax = 50,
            historyEntries = {},
        }
        EsoChat.InputEnhance.SetHistoryIndex(0)
        CHAT_SYSTEM = {
            textEntry = {
                editControl = {
                    text = "",
                    SetText = function(self, t)
                        self.text = t
                    end,
                    GetText = function(self)
                        return self.text
                    end,
                },
            },
        }
    end

    it("PushHistory and Up/Down walk entries", function()
        resetInput()
        EsoChat.InputEnhance.PushHistory("/ech help")
        EsoChat.InputEnhance.PushHistory("/ech notes")
        EsoChat.InputEnhance.PushHistory("/ech create system")
        assertEqual(#EsoChat.db.input.historyEntries, 3)

        EsoChat.InputEnhance.HistoryUp()
        assertEqual(CHAT_SYSTEM.textEntry.editControl.text, "/ech create system")
        EsoChat.InputEnhance.HistoryUp()
        assertEqual(CHAT_SYSTEM.textEntry.editControl.text, "/ech notes")
        EsoChat.InputEnhance.HistoryUp()
        assertEqual(CHAT_SYSTEM.textEntry.editControl.text, "/ech help")
        EsoChat.InputEnhance.HistoryDown()
        assertEqual(CHAT_SYSTEM.textEntry.editControl.text, "/ech notes")
        EsoChat.InputEnhance.HistoryDown()
        assertEqual(CHAT_SYSTEM.textEntry.editControl.text, "/ech create system")
        EsoChat.InputEnhance.HistoryDown()
        assertEqual(CHAT_SYSTEM.textEntry.editControl.text, "")
    end)

    it("skips consecutive duplicate pushes", function()
        resetInput()
        EsoChat.InputEnhance.PushHistory("same")
        EsoChat.InputEnhance.PushHistory("same")
        assertEqual(#EsoChat.db.input.historyEntries, 1)
    end)

    it("does not navigate when history disabled", function()
        resetInput()
        EsoChat.InputEnhance.PushHistory("one")
        EsoChat.db.input.historyEnabled = false
        assertEqual(EsoChat.InputEnhance.HistoryUp(), false)
    end)
end)
