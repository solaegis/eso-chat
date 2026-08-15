-- EsoChat - standard solaegis LAM support footer

local EC = EsoChat

--- Open mail compose to the donation account with default gold attached.
--- Used by the LAM panel donation link and the support footer button.
function EC.OpenGoldDonationMail()
    local account = EC.DONATION_ACCOUNT
    local amount = EC.DONATION_GOLD_DEFAULT
    local maxGold = GetCurrentMoney and GetCurrentMoney() or amount
    if amount > maxGold then
        amount = maxGold
    end

    local function chatFallback()
        EC.Chat(
            string.format("Send gold manually: mail %s with %s gold attached.", account, zo_strformat("<<1>>", amount))
        )
    end

    if IsInGamepadPreferredMode and IsInGamepadPreferredMode() then
        chatFallback()
        return
    end

    local ok, err = pcall(function()
        if not MAIL_SEND or not MAIL_SEND.ComposeMailTo then
            error("MAIL_SEND unavailable")
        end
        MAIL_SEND:ComposeMailTo(account)
        local function attachGold()
            if CallSecureProtected then
                CallSecureProtected("QueueMoneyAttachment", amount)
            end
        end
        if zo_callLater then
            zo_callLater(attachGold, 100)
        else
            attachGold()
        end
    end)

    if not ok then
        EC.Debug("Send gold failed: " .. tostring(err))
        chatFallback()
    end
end

--- Append the standard solaegis support footer to a LibAddonMenu options table.
--- @param options table
--- @param displayName string|nil defaults to EC.DISPLAY_NAME
function EC.AppendSupportFooter(options, displayName)
    local name = displayName or EC.DISPLAY_NAME
    local donationUrl = EC.DONATION_URL

    table.insert(options, {
        type = "divider",
        width = "full",
    })

    table.insert(options, {
        type = "header",
        name = "Support",
        width = "full",
    })

    table.insert(options, {
        type = "description",
        text = string.format(
            "|cFFD700Enjoying %s?|r\n\nIf you find this addon useful, consider supporting its development!",
            name
        ),
        width = "full",
    })

    table.insert(options, {
        type = "button",
        name = "Buy Me a Coffee",
        tooltip = string.format(
            "Support the development of %s\n\nOpens your browser to the Buy Me a Coffee page",
            name
        ),
        func = function()
            local success, opened = pcall(function()
                if RequestOpenURL then
                    RequestOpenURL(donationUrl)
                    return true
                end
                return false
            end)

            if success and opened then
                EC.Chat("Opening Buy Me a Coffee page...")
            else
                EC.Chat("Buy Me a Coffee: " .. donationUrl)
                EC.Chat("(Copy the URL above and paste it in your browser)")
            end
        end,
        width = "full",
    })

    table.insert(options, {
        type = "button",
        name = "Send Gold In-Game",
        tooltip = string.format(
            "Open mail to %s with %s gold pre-attached.\n\nYou still press Send yourself — addons cannot send mail automatically.",
            EC.DONATION_ACCOUNT,
            zo_strformat("<<1>>", EC.DONATION_GOLD_DEFAULT)
        ),
        func = EC.OpenGoldDonationMail,
        width = "full",
    })
end
