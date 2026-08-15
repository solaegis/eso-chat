-- EsoChat - Module bootstrap

local EC = EsoChat

EC.ChatModules = EC.ChatModules or {}

local started = false
local activated = false

function EC.ChatModules.Start()
    if started then
        return
    end
    started = true

    if EC.History and EC.History.Start then
        EC.History.Start()
    end

    EVENT_MANAGER:RegisterForEvent(EC.NAME .. "Activated", EVENT_PLAYER_ACTIVATED, function()
        if activated then
            -- Zone change / re-activate: keep size and re-raise max if needed
            if EC.ContainerLayout then
                if EC.ContainerLayout.RaiseMaxSize then
                    EC.ContainerLayout.RaiseMaxSize()
                end
                if EC.ContainerLayout.Restore then
                    EC.ContainerLayout.Restore()
                end
            end
            if EC.Automation and EC.Automation.OnPlayerActivated then
                EC.Automation.OnPlayerActivated()
            end
            return
        end
        activated = true

        if EC.Compat and EC.Compat.Start then
            EC.Compat.Start()
        end
        if EC.Formatter and EC.Formatter.Install then
            EC.Formatter.Install()
        end
        -- Window resize must start even if tab features are disabled
        if EC.ContainerLayout and EC.ContainerLayout.Start then
            -- #region agent log
            if EC.AgentDebug then
                EC.AgentDebug.Log("H5", "ChatModules.PLAYER_ACTIVATED", "calling ContainerLayout.Start", {
                    hasDb = EC.db ~= nil,
                })
            end
            -- #endregion
            EC.ContainerLayout.Start()
        end
        -- Unread pulse/counter independent of tabs.enabled master toggle
        if EC.TabUnread and EC.TabUnread.Start then
            EC.TabUnread.Start()
        end
        if EC.Tabs and EC.Tabs.Start then
            EC.Tabs.Start()
        end
        if EC.Notes and EC.Notes.Start then
            EC.Notes.Start()
        end
        if EC.InputEnhance and EC.InputEnhance.Start then
            EC.InputEnhance.Start()
        end
        if EC.SettingsIO and EC.SettingsIO.MaybeRemindBackup then
            EC.SettingsIO.MaybeRemindBackup()
        end
        if EC.Automation and EC.Automation.OnPlayerActivated then
            EC.Automation.OnPlayerActivated()
        end
        if EC.LootEmoji and EC.LootEmoji.Start then
            EC.LootEmoji.Start()
        end
        if EC.Tabs and EC.Tabs.SnapshotLayout then
            -- Capture layout after container restore settles
            zo_callLater(function()
                EC.Tabs.SnapshotLayout()
            end, 1500)
        end
    end)
end
