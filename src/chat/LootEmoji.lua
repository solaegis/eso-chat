-- EsoChat - Optional loot-in-chat and emoji hooks (scoped, default off)

local EC = EsoChat

EC.LootEmoji = EC.LootEmoji or {}
local LootEmoji = EC.LootEmoji

function LootEmoji.Start()
    local loot = EC.db and EC.db.loot
    if loot and loot.enabled then
        EVENT_MANAGER:RegisterForEvent(EC.NAME .. "Loot", EVENT_LOOT_RECEIVED, function(_, _, itemName, quantity)
            local line = string.format("Loot: %s x%s", tostring(itemName), tostring(quantity))
            if loot.showPrices then
                EC.DebugPrint("LOOT", "price lookup skipped (no LibPrice hard-dep)")
            end
            if CHAT_SYSTEM and CHAT_SYSTEM.AddMessage then
                CHAT_SYSTEM:AddMessage(line)
            else
                EC.Chat(line)
            end
        end)
    end
    -- Emoji: placeholder — enable only with LMP custom font in future
    local emoji = EC.db and EC.db.emoji
    if emoji and emoji.enabled then
        EC.DebugPrint("EMOJI", "Emoji mode on (requires LibMediaProvider font; no pack shipped)")
    end
end

return LootEmoji
