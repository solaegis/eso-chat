describe("TabUnread", function()
    local function reset()
        EsoChat.TabUnread._ResetForTests()
        EsoChat.db.tabs.enabled = true
        EsoChat.db.tabs.unreadPulseEnabled = true
        EsoChat.db.tabs.unreadCounterEnabled = true
    end

    it("strips counter suffix from labels", function()
        assertEqual(EsoChat.TabUnread.StripSuffix("Guild (3)"), "Guild")
        assertEqual(EsoChat.TabUnread.StripSuffix("Guild (99+)"), "Guild")
        assertEqual(EsoChat.TabUnread.StripSuffix("Guild"), "Guild")
    end)

    it("formats labels with 99+ cap", function()
        assertEqual(EsoChat.TabUnread.FormatLabel("Guild", 0), "Guild")
        assertEqual(EsoChat.TabUnread.FormatLabel("Guild", 3), "Guild (3)")
        assertEqual(EsoChat.TabUnread.FormatLabel("Guild", 100), "Guild (99+)")
    end)

    it("IsViewable requires current buffer and not scrolled up", function()
        local bufferA = {}
        local bufferB = {}
        local container = {
            currentBuffer = bufferA,
            windows = {
                { buffer = bufferA },
                { buffer = bufferB },
            },
            IsScrolledUp = function()
                return false
            end,
        }
        assertTrue(EsoChat.TabUnread.IsViewable(container, 1))
        assertFalse(EsoChat.TabUnread.IsViewable(container, 2))
        container.IsScrolledUp = function()
            return true
        end
        assertFalse(EsoChat.TabUnread.IsViewable(container, 1))
    end)

    it("increments unread when tab is not viewable", function()
        reset()
        local labels = {}
        local bufferMain = {}
        local bufferGuild = {}
        local tabMain = {
            Flash = function() end,
            GetNamedChild = function()
                return nil
            end,
        }
        local tabGuild = {
            Flash = function() end,
            GetNamedChild = function()
                return nil
            end,
        }
        CHAT_SYSTEM = {
            containers = {
                [1] = {
                    id = 1,
                    currentBuffer = bufferMain,
                    windows = {
                        [1] = { buffer = bufferMain, tab = tabMain },
                        [2] = { buffer = bufferGuild, tab = tabGuild },
                    },
                    IsScrolledUp = function()
                        return false
                    end,
                },
            },
        }
        GetNumChatContainers = function()
            return 1
        end
        GetNumChatContainerTabs = function()
            return 2
        end
        GetChannelCategoryFromChannel = function(ch)
            if ch == CHAT_CHANNEL_GUILD_1 then
                return CHAT_CATEGORY_GUILD_1
            end
            return CHAT_CATEGORY_ZONE
        end
        IsChatContainerTabCategoryEnabled = function(c, t, cat)
            if t == 1 then
                return cat == CHAT_CATEGORY_ZONE
            end
            if t == 2 then
                return cat == CHAT_CATEGORY_GUILD_1
            end
            return false
        end
        GetChatContainerTabInfo = function(c, t)
            if t == 1 then
                return "General", false, true, false, false
            end
            return "Guild", false, true, false, false
        end
        ZO_TabButton_Text_SetText = function(ctrl, text)
            labels[ctrl] = text
        end
        ZO_TabButton_Text_GetText = function(ctrl)
            return labels[ctrl]
        end
        ZO_TabButton_Text_RestoreDefaultColors = function() end
        ZO_TabButton_Text_AllowColorChanges = function() end
        ZO_TabButton_Text_SetTextColor = function() end

        EsoChat.TabUnread.OnMessage(CHAT_CHANNEL_GUILD_1)
        assertEqual(EsoChat.TabUnread.GetCount(1, 2), 1)
        assertEqual(EsoChat.TabUnread.GetCount(1, 1), 0)
        assertEqual(labels[tabGuild], "Guild (1)")

        EsoChat.TabUnread.OnMessage(CHAT_CHANNEL_GUILD_1)
        assertEqual(EsoChat.TabUnread.GetCount(1, 2), 2)
        assertEqual(labels[tabGuild], "Guild (2)")
    end)

    it("does not increment when tab is viewable at bottom", function()
        reset()
        local bufferGuild = {}
        CHAT_SYSTEM = {
            containers = {
                [1] = {
                    id = 1,
                    currentBuffer = bufferGuild,
                    windows = {
                        [1] = { buffer = bufferGuild, tab = { Flash = function() end } },
                    },
                    IsScrolledUp = function()
                        return false
                    end,
                },
            },
        }
        GetNumChatContainers = function()
            return 1
        end
        GetNumChatContainerTabs = function()
            return 1
        end
        GetChannelCategoryFromChannel = function()
            return CHAT_CATEGORY_GUILD_1
        end
        IsChatContainerTabCategoryEnabled = function()
            return true
        end
        GetChatContainerTabInfo = function()
            return "Guild", false, true, false, false
        end
        ZO_TabButton_Text_SetText = function() end

        EsoChat.TabUnread.OnMessage(CHAT_CHANNEL_GUILD_1)
        assertEqual(EsoChat.TabUnread.GetCount(1, 1), 0)
    end)

    it("clears when focused and at bottom", function()
        reset()
        local labels = {}
        local bufferGuild = {}
        local tabGuild = {
            Flash = function() end,
            GetNamedChild = function()
                return nil
            end,
        }
        local container = {
            id = 1,
            currentBuffer = {}, -- inactive initially
            windows = {
                [1] = { buffer = bufferGuild, tab = tabGuild },
            },
            IsScrolledUp = function()
                return false
            end,
        }
        CHAT_SYSTEM = { containers = { [1] = container } }
        GetNumChatContainers = function()
            return 1
        end
        GetNumChatContainerTabs = function()
            return 1
        end
        GetChannelCategoryFromChannel = function()
            return CHAT_CATEGORY_GUILD_1
        end
        IsChatContainerTabCategoryEnabled = function()
            return true
        end
        GetChatContainerTabInfo = function()
            return "Guild", false, true, false, false
        end
        ZO_TabButton_Text_SetText = function(ctrl, text)
            labels[ctrl] = text
        end
        ZO_TabButton_Text_RestoreDefaultColors = function() end
        ZO_TabButton_Text_AllowColorChanges = function() end
        ZO_TabButton_Text_SetTextColor = function() end

        EsoChat.TabUnread.OnMessage(CHAT_CHANNEL_GUILD_1)
        assertEqual(EsoChat.TabUnread.GetCount(1, 1), 1)

        container.currentBuffer = bufferGuild
        EsoChat.TabUnread.MaybeClearContainer(container)
        assertEqual(EsoChat.TabUnread.GetCount(1, 1), 0)
        assertEqual(labels[tabGuild], "Guild")
    end)

    it("OwnsFlash when pulse enabled", function()
        reset()
        assertTrue(EsoChat.TabUnread.OwnsFlash())
        EsoChat.db.tabs.unreadPulseEnabled = false
        assertFalse(EsoChat.TabUnread.OwnsFlash())
    end)

    it("resolves primaryContainer when containers[1] is missing", function()
        reset()
        local labels = {}
        local bufferMain = {}
        local bufferGuild = {}
        local tabGuild = {
            Flash = function() end,
            GetNamedChild = function()
                return nil
            end,
            PerformLayout = nil,
        }
        local primary = {
            id = 1,
            currentBuffer = bufferMain,
            windows = {
                [1] = { buffer = bufferMain, tab = { Flash = function() end, GetNamedChild = function() end } },
                [2] = { buffer = bufferGuild, tab = tabGuild },
            },
            IsScrolledUp = function()
                return false
            end,
            PerformLayout = function() end,
        }
        CHAT_SYSTEM = {
            containers = {},
            primaryContainer = primary,
        }
        GetNumChatContainers = function()
            return 1
        end
        GetNumChatContainerTabs = function()
            return 2
        end
        GetChannelCategoryFromChannel = function()
            return CHAT_CATEGORY_GUILD_1
        end
        IsChatContainerTabCategoryEnabled = function(c, t, cat)
            return t == 2 and cat == CHAT_CATEGORY_GUILD_1
        end
        GetChatContainerTabInfo = function(c, t)
            if t == 2 then
                return "Guild", false, true, false, false
            end
            return "General", false, true, false, false
        end
        ZO_TabButton_Text_SetText = function(ctrl, text)
            labels[ctrl] = text
        end
        ZO_TabButton_Text_RestoreDefaultColors = function() end
        ZO_TabButton_Text_AllowColorChanges = function() end
        ZO_TabButton_Text_SetTextColor = function() end

        assertEqual(EsoChat.TabUnread.ResolveContainer(1), primary)
        EsoChat.TabUnread.OnMessage(CHAT_CHANNEL_GUILD_1)
        assertEqual(EsoChat.TabUnread.GetCount(1, 2), 1)
        assertEqual(labels[tabGuild], "Guild (1)")
    end)

    it("counts even when tabs.enabled is false", function()
        reset()
        EsoChat.db.tabs.enabled = false
        local labels = {}
        local bufferMain = {}
        local bufferGuild = {}
        local tabGuild = {
            Flash = function() end,
            GetNamedChild = function()
                return nil
            end,
        }
        CHAT_SYSTEM = {
            containers = {
                [1] = {
                    id = 1,
                    currentBuffer = bufferMain,
                    windows = {
                        [1] = { buffer = bufferMain, tab = { Flash = function() end, GetNamedChild = function() end } },
                        [2] = { buffer = bufferGuild, tab = tabGuild },
                    },
                    IsScrolledUp = function()
                        return false
                    end,
                    PerformLayout = function() end,
                },
            },
        }
        GetNumChatContainers = function()
            return 1
        end
        GetNumChatContainerTabs = function()
            return 2
        end
        GetChannelCategoryFromChannel = function()
            return CHAT_CATEGORY_GUILD_1
        end
        IsChatContainerTabCategoryEnabled = function(c, t)
            return t == 2
        end
        GetChatContainerTabInfo = function(c, t)
            return t == 2 and "Guild" or "General", false, true, false, false
        end
        ZO_TabButton_Text_SetText = function(ctrl, text)
            labels[ctrl] = text
        end
        ZO_TabButton_Text_RestoreDefaultColors = function() end
        ZO_TabButton_Text_AllowColorChanges = function() end
        ZO_TabButton_Text_SetTextColor = function() end

        EsoChat.TabUnread.OnMessage(CHAT_CHANNEL_GUILD_1)
        assertEqual(EsoChat.TabUnread.GetCount(1, 2), 1)
        assertEqual(labels[tabGuild], "Guild (1)")
    end)
end)
