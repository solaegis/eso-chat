-- EsoChat - LibAddonMenu-2.0 settings panel

local EC = EsoChat

local PANEL_NAME = "EsoChatPanel"
local lamPanel = nil

function EC.OpenSettings()
    if LibAddonMenu2 and LibAddonMenu2.OpenToPanel and lamPanel then
        LibAddonMenu2:OpenToPanel(lamPanel)
    else
        EC.Chat("Open Settings > Addons > " .. EC.DISPLAY_NAME)
    end
end

function EC.RegisterSettingsPanel()
    if not LibAddonMenu2 then
        EC.Chat("LibAddonMenu-2.0 not found — use /ech for status; settings UI unavailable")
        return
    end

    local LAM = LibAddonMenu2

    local panelData = {
        type = "panel",
        name = EC.DISPLAY_NAME,
        displayName = EC.DISPLAY_NAME,
        author = EC.AUTHOR,
        version = EC.VERSION,
        slashCommand = "/echsettings",
        registerForRefresh = true,
        registerForDefaults = true,
        website = EC.WEBSITE_URL,
        feedback = EC.FEEDBACK_URL,
        donation = EC.OpenGoldDonationMail,
        defaultsFunc = function()
            EC.ResetSettings()
        end,
    }

    local optionsTable = {
        {
            type = "header",
            name = "General",
            width = "full",
        },
        {
            type = "checkbox",
            name = "Enabled",
            tooltip = "Master toggle for addon features (scaffold sample setting).",
            getFunc = function()
                return EC.db == nil or EC.db.enabled ~= false
            end,
            setFunc = function(value)
                if EC.db then
                    EC.db.enabled = value
                end
            end,
            default = true,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Debug logging",
            tooltip = "Show extra debug messages in chat (and LibDebugLogger when installed).",
            getFunc = function()
                return EC.db and EC.db.debug == true
            end,
            setFunc = function(value)
                if EC.db then
                    EC.db.debug = value
                end
                EC.debug = value
            end,
            default = false,
            width = "full",
        },
    }

    EC.AppendSupportFooter(optionsTable)

    lamPanel = LAM:RegisterAddonPanel(PANEL_NAME, panelData)
    LAM:RegisterOptionControls(PANEL_NAME, optionsTable)
end
