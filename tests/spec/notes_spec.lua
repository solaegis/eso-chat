describe("Notes", function()
    local function resetNotes()
        EsoChat.db.notes = {
            enabled = true,
            tabName = "Notes",
            perCharacter = false,
            text = "",
            maxChars = 20000,
        }
        EsoChat.db.perCharacterData = {}
        EsoChat.charData = nil
    end

    it("stores account-wide text by default", function()
        resetNotes()
        EsoChat.Notes.SetStore("hello account")
        assertEqual(EsoChat.Notes.GetStore(), "hello account")
        assertEqual(EsoChat.db.notes.text, "hello account")
    end)

    it("stores per-character text when enabled", function()
        resetNotes()
        EsoChat.Notes.SetPerCharacter(true)
        EsoChat.Notes.SetStore("char note")
        assertEqual(EsoChat.Notes.GetStore(), "char note")
        assertEqual(EsoChat.charData.notesText, "char note")
        assertEqual(EsoChat.db.notes.text, "")
    end)

    it("switching scope does not copy text", function()
        resetNotes()
        EsoChat.Notes.SetStore("account body")
        EsoChat.Notes.SetPerCharacter(true)
        assertEqual(EsoChat.Notes.GetStore(), "")
        EsoChat.Notes.SetStore("char body")
        EsoChat.Notes.SetPerCharacter(false)
        assertEqual(EsoChat.Notes.GetStore(), "account body")
    end)

    it("Clear empties active scope only", function()
        resetNotes()
        EsoChat.Notes.SetStore("keep me")
        EsoChat.Notes.SetPerCharacter(true)
        EsoChat.Notes.SetStore("wipe me")
        EsoChat.Notes.Clear()
        assertEqual(EsoChat.Notes.GetStore(), "")
        EsoChat.Notes.SetPerCharacter(false)
        assertEqual(EsoChat.Notes.GetStore(), "keep me")
    end)

    it("accepts notes as a valid filter mode", function()
        assertTrue(EsoChat.TabFilters.IsValidMode("notes"))
    end)
end)
