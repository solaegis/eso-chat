describe("GroupTabSync", function()
    local applied = nil
    local origApply
    local origFind
    local origGrouped

    local function reset()
        applied = nil
        origApply = EsoChat.Tabs.ApplyCategories
        origFind = EsoChat.Tabs.FindGroupTab
        origGrouped = EsoChat.Tabs.IsPlayerGrouped
        EsoChat.Tabs.ApplyCategories = function(c, t, cats)
            applied = {
                containerIndex = c,
                tabIndex = t,
                categories = cats,
            }
        end
    end

    local function restore()
        if origApply then
            EsoChat.Tabs.ApplyCategories = origApply
        end
        if origFind then
            EsoChat.Tabs.FindGroupTab = origFind
        end
        if origGrouped then
            EsoChat.Tabs.IsPlayerGrouped = origGrouped
        end
    end

    it("PartyOnlyCategories enables only party", function()
        local cats = EsoChat.Tabs.PartyOnlyCategories()
        assertTrue(cats.CHAT_CATEGORY_PARTY == true)
        assertTrue(cats.CHAT_CATEGORY_SAY == false)
        assertTrue(cats.CHAT_CATEGORY_ZONE == false)
    end)

    it("AllCategoriesDisabled turns every category off", function()
        local cats = EsoChat.Tabs.AllCategoriesDisabled()
        assertTrue(cats.CHAT_CATEGORY_PARTY == false)
        assertTrue(cats.CHAT_CATEGORY_SAY == false)
    end)

    it("SyncGroupTabCategories applies party-only when grouped", function()
        reset()
        EsoChat.Tabs.FindGroupTab = function()
            return { containerIndex = 1, tabIndex = 2, name = "Group" }
        end
        EsoChat.Tabs.IsPlayerGrouped = function()
            return true
        end
        assertTrue(EsoChat.Tabs.SyncGroupTabCategories())
        assertEqual(applied.containerIndex, 1)
        assertEqual(applied.tabIndex, 2)
        assertTrue(applied.categories.CHAT_CATEGORY_PARTY == true)
        assertTrue(applied.categories.CHAT_CATEGORY_SAY == false)
        restore()
    end)

    it("SyncGroupTabCategories disables all when solo", function()
        reset()
        EsoChat.Tabs.FindGroupTab = function()
            return { containerIndex = 1, tabIndex = 2, name = "Group" }
        end
        EsoChat.Tabs.IsPlayerGrouped = function()
            return false
        end
        assertTrue(EsoChat.Tabs.SyncGroupTabCategories())
        assertTrue(applied.categories.CHAT_CATEGORY_PARTY == false)
        assertTrue(applied.categories.CHAT_CATEGORY_SAY == false)
        restore()
    end)

    it("SyncGroupTabCategories no-ops without group tab", function()
        reset()
        EsoChat.Tabs.FindGroupTab = function()
            return nil
        end
        assertFalse(EsoChat.Tabs.SyncGroupTabCategories())
        assertNil(applied)
        restore()
    end)
end)
