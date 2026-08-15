describe("Sounds", function()
    it("builds catalog with matched choices and values", function()
        SOUNDS = {
            NONE = "No_Sound",
            NEW_NOTIFICATION = "New_Notification",
            QUEST_ACCEPTED = "Quest_Accepted",
            MAIL_NEW = "New_Mail",
            DEATH = "Death",
        }
        LibMediaProvider = nil
        EsoChat.Sounds.RebuildCatalog()
        local choices, values = EsoChat.Sounds.GetAll()
        assertTrue(#choices == #values)
        assertTrue(#choices >= 4)
    end)

    it("default filter returns shortlist not full catalog", function()
        SOUNDS = {
            NONE = "No_Sound",
            NEW_NOTIFICATION = "New_Notification",
            QUEST_ACCEPTED = "Quest_Accepted",
            MAIL_NEW = "New_Mail",
            DEATH = "Death",
            OBSCURE_ONE = "Obscure_One",
            OBSCURE_TWO = "Obscure_Two",
        }
        EsoChat.Sounds.RebuildCatalog()
        local allChoices = EsoChat.Sounds.GetAll()
        local shortChoices, shortValues, mode = EsoChat.Sounds.GetFiltered("")
        assertEqual(mode, "shortlist")
        assertTrue(#shortChoices == #shortValues)
        assertTrue(#shortChoices < #allChoices)
        -- Obscure sounds should not be on the shortlist
        local foundObscure = false
        for i = 1, #shortValues do
            if shortValues[i] == "Obscure_One" then
                foundObscure = true
            end
        end
        assertFalse(foundObscure)
    end)

    it("filters full catalog after min chars", function()
        SOUNDS = {
            NONE = "No_Sound",
            NEW_NOTIFICATION = "New_Notification",
            MAIL_NEW = "New_Mail",
            DEATH = "Death",
        }
        EsoChat.Sounds.RebuildCatalog()
        local choices, values, mode = EsoChat.Sounds.GetFiltered("ma")
        assertEqual(mode, "search")
        assertTrue(#choices == #values)
        assertTrue(#choices >= 1)
        local found = false
        for i = 1, #choices do
            if string.find(string.lower(choices[i]), "mail", 1, true)
                or string.find(string.lower(tostring(values[i])), "mail", 1, true)
            then
                found = true
            end
        end
        assertTrue(found)
    end)

    it("falls back to NONE when search matches nothing", function()
        EsoChat.Sounds.RebuildCatalog()
        local choices, values, mode = EsoChat.Sounds.GetFiltered("zzznomatchzzz")
        assertEqual(mode, "none")
        assertEqual(#choices, 1)
        assertEqual(values[1], "NONE")
    end)

    it("normalizes SOUNDS keys to PlaySound values", function()
        SOUNDS = {
            NONE = "No_Sound",
            NEW_NOTIFICATION = "New_Notification",
        }
        EsoChat.Sounds.RebuildCatalog()
        assertEqual(EsoChat.Sounds.Normalize("NEW_NOTIFICATION"), "New_Notification")
        assertEqual(EsoChat.Sounds.Normalize("NONE"), "NONE")
    end)
end)
