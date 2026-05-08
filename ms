task.spawn(function()
    for _, x in pairs(getconnections(game.Players.LocalPlayer.Idled)) do
        x:Disable()
    end
end)
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/no"))()
end)

repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("__MAINHUD__")

repeat task.wait() until game:IsLoaded()
local cfg = getgenv().slime_rng_cfg or {}

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local Packages = RS:WaitForChild("Packages")
local Index = Packages:WaitForChild("_Index")
local Networker = Index:WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker")
local Remotes = Networker:WaitForChild("_remotes")

local DataClient = require(Packages.DataService).client
DataClient:waitForData()

local RollRemote = Remotes:WaitForChild("RollService"):WaitForChild("RemoteFunction")
local CodeRemote = Remotes:WaitForChild("CodeService"):WaitForChild("RemoteFunction")
local InventoryRemote = Remotes:WaitForChild("InventoryService"):WaitForChild("RemoteFunction")
local RebirthRemote = Remotes:WaitForChild("RebirthService"):WaitForChild("RemoteFunction")
local ZonesRemote = Remotes:WaitForChild("ZonesService"):WaitForChild("RemoteFunction")
local UpgradeRemote = Remotes:WaitForChild("UpgradeService"):WaitForChild("RemoteFunction")
local BoostRemote = Remotes:WaitForChild("BoostService"):WaitForChild("RemoteFunction")
local OfflineRemote = Remotes:WaitForChild("OfflineEarningsService"):WaitForChild("RemoteFunction")
local IndexRemote = Remotes:WaitForChild("IndexService"):WaitForChild("RemoteFunction")

local Source = RS:WaitForChild("Source", 30)
if not Source then
    warn("[Slime RNG] ReplicatedStorage.Source not found.")
    return
end

local Items = Source:WaitForChild("Game"):WaitForChild("Items")
local Roll = Source:WaitForChild("Features"):WaitForChild("Roll")
local MutationsFolder = Source:WaitForChild("Features"):WaitForChild("Mutations")

local RollSlice = require(Roll:WaitForChild("RollSlice"))
local SlimeData = require(Items:WaitForChild("Slimes"))
local RarityTiers = require(Items:WaitForChild("RarityTiers"))
local Mutations = require(MutationsFolder:WaitForChild("Mutations"))
local Zones = require(RS.Source.Game.Items.Zones)
local UpgradeTree = require(RS.Source.Features.Upgrades.UpgradeTree)
local IndexRewards = require(RS.Source.Features.Index.IndexRewards)

local expectedConfigs = {
    "OFFLINE_EARNINGS", "FAST_ROLL", "REDEEM_CODES", "CODES",
    "EQUIP_BEST_SLIMES", "AUTO_REBIRTH", "REQUIRED_ZONE_TO_REBIRTH",
    "UNLOCK_AFFORDABLE_ZONES", "AUTOFARM_BEST_ZONE", "AUTO_BUY_UPGRADES",
    "USE_POTIONS", "POTIONS_TO_USE", "USE_DICES", "DICES_TO_USE",
    "AUTO_CLAIM_INDEX_REWARDS", "AUTO_COLLECT_LOOT", "OPTIMIZATION", "WEBHOOK_URL", "MINIMUM_LUCK_SENT"
}

print("[Slime RNG] Script started")
print("[Slime RNG] Loading config...")

local found = 0
for _, key in ipairs(expectedConfigs) do
    if cfg[key] ~= nil then
        found = found + 1
    else
        warn("[Slime RNG] Missing " .. key .. " config, skipping it (runs as false / nil)")
    end
end

print(string.format("[Slime RNG] Found %d/%d configs", found, #expectedConfigs))
print("[Slime RNG] Starting features...")

local EMOJI_DICE = "🎲"
local EMOJI_COIN = "🪙"
local EMOJI_SWORD = "⚔️"
local EMOJI_HEART = "❤️"

local function formatNumber(num)
    if type(num) ~= "number" then return tostring(num) end
    local absNum = math.abs(num)
    local suffix = ""
    local divisor = 1
    if absNum >= 1e18 then
        suffix = "Qn"; divisor = 1e18
    elseif absNum >= 1e15 then
        suffix = "Qd"; divisor = 1e15
    elseif absNum >= 1e12 then
        suffix = "T"; divisor = 1e12
    elseif absNum >= 1e9 then
        suffix = "B"; divisor = 1e9
    elseif absNum >= 1e6 then
        suffix = "M"; divisor = 1e6
    elseif absNum >= 1e3 then
        suffix = "K"; divisor = 1e3
    end
    if suffix ~= "" then
        local formatted = num / divisor
        if math.abs(formatted - math.floor(formatted)) < 0.01 then
            return string.format("%d%s", math.floor(formatted), suffix)
        else
            return string.format("%.1f%s", formatted, suffix):gsub("%.0f", "")
        end
    end
    return tostring(math.floor(num))
end

local function parseLuck(str)
    if type(str) ~= "string" then return 0 end
    local num, suffix = str:match("^([%d%.]+)(%a*)$")
    if not num then return 0 end
    num = tonumber(num) or 0
    suffix = suffix:upper()
    if suffix == "QN" then return num * 1e18
    elseif suffix == "QD" then return num * 1e15
    elseif suffix == "T" then return num * 1e12
    elseif suffix == "B" then return num * 1e9
    elseif suffix == "M" then return num * 1e6
    elseif suffix == "K" then return num * 1e3
    end
    return num
end

local function getRarityName(odds)
    if not odds or odds <= 0 then return "Unknown" end
    local ok, tier = pcall(RarityTiers.getTier, odds)
    return (ok and tier and tier.name) or "Unknown"
end

local function getActualItem(result)
    if type(result) ~= "table" then return nil end
    for _, entry in ipairs(result) do
        if type(entry) == "table" and entry.id then
            return entry
        end
    end
    return nil
end

local function ordinal(n)
    local s = tostring(n)
    local last = n % 10
    local tens = n % 100
    if tens >= 11 and tens <= 13 then return s .. "th" end
    if last == 1 then return s .. "st" end
    if last == 2 then return s .. "nd" end
    if last == 3 then return s .. "rd" end
    return s .. "th"
end

local function getAssetImageUrl(assetId)
    if not assetId then return nil end
    local url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetId .. "&size=420x420&format=Png&isCircular=false"
    local success, response = pcall(function()
        return request({ Url = url, Method = "GET" })
    end)
    if success and response and response.Success then
        local data = HttpService:JSONDecode(response.Body)
        if data and data.data and data.data[1] and data.data[1].imageUrl then
            return data.data[1].imageUrl
        end
    end
    return nil
end

local function getThumbnailSize(mutations)
    if not mutations then return 64 end
    if mutations.huge then return 128
    elseif mutations.big then return 96 end
    return 64
end

local function getEmbedColor(mutations)
    if not mutations then return nil end
    if mutations.inverted then return 0x9b59b6
    elseif mutations.huge then return 0xf1c40f
    elseif mutations.big then return 0xe67e22
    elseif mutations.shiny then return 0xf39c12 end
    return nil
end

local function sendWebhook(url, playerName, displayName, rarity, chanceText, statsText, mutations, mutList, imageUrl, totalRolls, coins, kills)
    local finalImageUrl = nil
    local thumbnailSize = getThumbnailSize(mutations)

    if imageUrl and imageUrl ~= "N/A" then
        local assetId = string.match(imageUrl, "rbxassetid://(%d+)")
        if assetId then
            finalImageUrl = getAssetImageUrl(assetId)
        end
    end

    local hiddenName = "||" .. playerName .. "||"
    local description = string.format("**%s** rolled **%s**!\n\n%s **Total Rolls:** %s", hiddenName, displayName, EMOJI_DICE, ordinal(totalRolls))

    local fields = {
        {name = "Rarity", value = rarity, inline = true},
        {name = "Chance", value = chanceText, inline = true}
    }

    if statsText and statsText ~= "" then
        table.insert(fields, {name = "Stats", value = statsText, inline = true})
    end

    local mutationInName = false
    local upperName = string.upper(displayName)
    if string.find(upperName, "BIG") or string.find(upperName, "HUGE") or string.find(upperName, "SHINY") or string.find(upperName, "INVERTED") then
        mutationInName = true
    end

    if mutList and #mutList > 0 and not mutationInName then
        table.insert(fields, {name = "Mutations", value = table.concat(mutList, ", "), inline = true})
    end

    table.insert(fields, {name = EMOJI_COIN .. " Coins", value = formatNumber(coins), inline = true})
    table.insert(fields, {name = EMOJI_SWORD .. " Kills", value = formatNumber(kills), inline = true})

    local payload = {
        username = "makik",
        embeds = {{
            title = "New Slime Rolled!",
            description = description,
            thumbnail = finalImageUrl and {url = finalImageUrl, width = thumbnailSize, height = thumbnailSize} or nil,
            fields = fields,
            color = getEmbedColor(mutations)
        }}
    }

    pcall(function()
        request({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
        print("[WEBHOOK] Sent: " .. displayName)
    end)
end

if cfg.OPTIMIZATION then
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/Optimization.lua"))()
    end)
end

if cfg.OFFLINE_EARNINGS then
    pcall(OfflineRemote.InvokeServer, OfflineRemote, "requestClaim")
end

if cfg.EQUIP_BEST_SLIMES then
    task.spawn(function()
        local delay = 30
        while true do
            pcall(InventoryRemote.InvokeServer, InventoryRemote, "requestEquipBest")
            task.wait(delay)
            delay = math.min(delay * 2, 600)
        end
    end)
end

if cfg.REDEEM_CODES then
    task.spawn(function()
        local codes = DataClient._data._data._codes or {}
        for _, code in ipairs(cfg.CODES) do
            if not codes[code] then
                pcall(CodeRemote.InvokeServer, CodeRemote, "redeem", code)
                task.wait(0.5)
            end
        end
    end)
end

if cfg.AUTO_REBIRTH then
    task.spawn(function()
        while true do
            local rebirths = DataClient:get("rebirths") or 0
            local goop = DataClient:get("goop") or 0
            local furthestZone = DataClient:get("furthestZone") or 0
            local nextCost = (2 ^ rebirths) * 500
            if furthestZone >= cfg.REQUIRED_ZONE_TO_REBIRTH and goop >= nextCost then
                pcall(RebirthRemote.InvokeServer, RebirthRemote, "requestRebirth")
            end
            task.wait(10)
        end
    end)
end

local currentZone = DataClient:get("zone") or 1

if cfg.UNLOCK_AFFORDABLE_ZONES then
    task.spawn(function()
        while true do
            pcall(ZonesRemote.InvokeServer, ZonesRemote, "requestPurchaseZone")
            task.wait(5)
        end
    end)
end

if cfg.AUTOFARM_BEST_ZONE then
    task.spawn(function()
        local MAX_ZONE = 25
        while true do
            for zone = MAX_ZONE, 1, -1 do
                local success = pcall(
                    ZonesRemote.InvokeServer,
                    ZonesRemote,
                    "requestTeleportZone",
                    zone
                )
                if success then
                    task.wait(1)
                    local newZone = DataClient:get("zone") or 1
                    if newZone == zone then
                        print("Successfully teleported to zone", zone)
                        currentZone = zone
                        break
                    end
                end
            end
            task.wait(10)
        end
    end)
end

if cfg.AUTO_BUY_UPGRADES then
    task.spawn(function()
        local function collectUpgrades(tbl, ids)
            if type(tbl) ~= "table" then return end
            for id, data in pairs(tbl) do
                if type(data) == "table" and data.cost then
                    table.insert(ids, id)
                end
            end
        end
        local allUpgrades = {}
        collectUpgrades(UpgradeTree.main, allUpgrades)
        if UpgradeTree.main.lootTree and UpgradeTree.main.lootTree.subTree then
            collectUpgrades(UpgradeTree.main.lootTree.subTree, allUpgrades)
        end
        if UpgradeTree.main.playerTree and UpgradeTree.main.playerTree.subTree then
            collectUpgrades(UpgradeTree.main.playerTree.subTree, allUpgrades)
        end
        local function getCost(id)
            local function findIn(tbl)
                if type(tbl) ~= "table" then return nil end
                for k, data in pairs(tbl) do
                    if k == id and type(data) == "table" then return data.cost end
                end
            end
            return findIn(UpgradeTree.main)
                or findIn(UpgradeTree.main.lootTree and UpgradeTree.main.lootTree.subTree)
                or findIn(UpgradeTree.main.playerTree and UpgradeTree.main.playerTree.subTree)
        end
        while task.wait(0.5) do
            local owned = DataClient:get("upgrades") or {}
            local coins = DataClient:get("coins") or 0
            local goop = DataClient:get("goop") or 0
            local rollCurrency = DataClient:get("rollCurrency") or 0
            for _, id in ipairs(allUpgrades) do
                if not owned[id] then
                    local cost = getCost(id)
                    if cost then
                        local amount = cost.amount or 0
                        local currency = cost.currency
                        local canAfford = (currency == "coins" and coins >= amount)
                            or (currency == "goop" and goop >= amount)
                            or (currency == "rollCurrency" and rollCurrency >= amount)
                        if canAfford then
                            local ok = pcall(UpgradeRemote.InvokeServer, UpgradeRemote, "requestUnlock", id)
                            if ok then task.wait(0.2) end
                        end
                    end
                end
            end
        end
    end)
end

if cfg.USE_POTIONS or cfg.USE_DICES then
    task.spawn(function()
        while task.wait(1) do
            local boosts = DataClient:get("boosts") or {}
            local items = DataClient:get("items") or {}
            if cfg.USE_POTIONS then
                for _, potion in ipairs(cfg.POTIONS_TO_USE) do
                    local data = boosts[potion]
                    if data and (data.amount or 0) > 0 then
                        pcall(BoostRemote.InvokeServer, BoostRemote, "requestUseBoost", potion)
                    end
                end
            end
            if cfg.USE_DICES then
                for _, dice in ipairs(cfg.DICES_TO_USE) do
                    if (items[dice] or 0) > 0 then
                        pcall(InventoryRemote.InvokeServer, InventoryRemote, "requestUseItem", dice)
                    end
                end
            end
        end
    end)
end

if cfg.AUTO_CLAIM_INDEX_REWARDS then
    task.spawn(function()
        local function checkRewards()
            local data = DataClient:get("index")
            if not data or not data.categories then return end
            for category, rewards in pairs(IndexRewards) do
                local catData = data.categories[category]
                if catData then
                    local unlocked = catData.unlocked or {}
                    local count = 0
                    for _, v in pairs(unlocked) do
                        if v == true then count = count + 1 end
                    end
                    local claimed = catData.claimedRewards or {}
                    for _, reward in ipairs(rewards) do
                        if count >= reward.req and not claimed[reward.key] then
                            pcall(IndexRemote.InvokeServer, IndexRemote, "requestClaimReward", category)
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
        while true do
            checkRewards()
            task.wait(60)
        end
    end)
end

if cfg.AUTO_COLLECT_LOOT then
    task.spawn(function()
        print("Loot auto-collector started")

        local LootRemote = RS:WaitForChild("Packages")
            :WaitForChild("_Index")
            :WaitForChild("leifstout_networker@0.3.1")
            :WaitForChild("networker")
            :WaitForChild("_remotes")
            :WaitForChild("LootService")
            :WaitForChild("RemoteFunction")

        while true do
            task.wait(30)

            local LootFolder = workspace:FindFirstChild("Loot")

            if not LootFolder then
                print("No Loot folder found")
                continue
            end

            local lootItems = LootFolder:GetChildren()

            print("Loot found:", #lootItems)

            if #lootItems == 0 then
                print("No loot to collect")
                continue
            end

            for _, loot in ipairs(lootItems) do
                print("Collecting:", loot.Name)

                local success, result = pcall(function()
                    return LootRemote:InvokeServer("requestCollect", loot.Name)
                end)

                if not success then
                    warn("Failed to collect:", loot.Name, result)
                else
                    print("Collected:", loot.Name, result)
                end
            end
        end
    end)
end

local webhookUrl = nil
if type(cfg.WEBHOOK_URL) == "table" then
    for _, v in ipairs(cfg.WEBHOOK_URL) do
        if type(v) == "string" and v ~= "" then
            webhookUrl = v
            break
        end
    end
elseif type(cfg.WEBHOOK_URL) == "string" and cfg.WEBHOOK_URL ~= "" then
    webhookUrl = cfg.WEBHOOK_URL
end

if webhookUrl and RollSlice then
    task.spawn(function()
        print("[Slime RNG] Watching for roll results...")
        local myPlayer = LocalPlayer
        local minLuck = parseLuck(cfg.MINIMUM_LUCK_SENT or "0")
        local lastTotalRolls = 0  -- Track roll count instead of fingerprint

        while true do
            task.wait(0.1)
            local ok, results = pcall(RollSlice.rollResults)
            if not ok then continue end

            -- Get current total rolls
            local stats = DataClient:get("stats") or {}
            local totalRolls = stats.rolls or 0
            
            -- Only process if total rolls increased (new roll happened)
            if totalRolls > lastTotalRolls then
                lastTotalRolls = totalRolls
                
                if type(results) == "table" and #results > 0 then
                    local kills = stats.kills or 0
                    local coins = DataClient:get("coins") or 0

                    for i, result in ipairs(results) do
                        local item = getActualItem(result)
                        if not item then continue end
                        local id = tostring(item.id or "unknown")
                        local sok, slime = pcall(SlimeData.getSlime, id)
                        slime = sok and slime or nil
                        local mutations = type(item.mutations) == "table" and next(item.mutations) ~= nil and item.mutations or nil
                        local isInverted = mutations and mutations.inverted == true
                        local image = isInverted and (slime and slime.invertedIcon or "N/A") or (slime and slime.image or "N/A")
                        local name = slime and slime.name or id
                        local baseOdds = slime and slime.odds or nil
                        local baseDmg = slime and slime.damage or 0
                        local baseHp = slime and slime.health or 0
                        local rarity = baseOdds and getRarityName(baseOdds) or "Unknown"
                        local oddsMultiplier = mutations and Mutations.getVisualOddsMultiplier(mutations) or 1
                        local statBonus = mutations and Mutations.getStatBonus(mutations, "damage") or 1
                        local finalOdds = baseOdds and (baseOdds / oddsMultiplier) or nil
                        local finalDmg = baseDmg * statBonus
                        local finalHp = baseHp * statBonus
                        local chanceText = finalOdds and string.format("1 in %s", formatNumber(math.floor(1 / finalOdds + 0.5))) or "N/A"
                        local chanceNumber = finalOdds and (1 / finalOdds) or nil
                        local displayName = mutations and Mutations.getDisplayName(name, mutations) or name
                        local mutList = mutations and Mutations.getIds(mutations) or {}
                        
                        if minLuck > 0 and chanceNumber and chanceNumber < minLuck then 
                            continue 
                        end
                        
                        local statsText = ""
                        if finalDmg > 0 and finalHp > 0 then
                            statsText = string.format("%s %s  %s %s", EMOJI_SWORD, formatNumber(finalDmg), EMOJI_HEART, formatNumber(finalHp))
                        elseif finalDmg > 0 then
                            statsText = string.format("%s %s", EMOJI_SWORD, formatNumber(finalDmg))
                        elseif finalHp > 0 then
                            statsText = string.format("%s %s", EMOJI_HEART, formatNumber(finalHp))
                        end
                        
                        local playerName = myPlayer and myPlayer.Name or "Someone"
                        
                        print(string.format("%s roll : %s (%s)", ordinal(totalRolls), displayName, id))
                        print(string.format("  Rarity    : %s", rarity))
                        print(string.format("  Chance    : %s", chanceText))
                        print(string.format("  Image     : %s", image))
                        if finalDmg > 0 then print(string.format("  Damage    : %s", formatNumber(finalDmg))) end
                        if finalHp > 0 then print(string.format("  Health    : %s", formatNumber(finalHp))) end
                        if #mutList > 0 then print(string.format("  Mutations : %s", table.concat(mutList, ", "))) end
                        
                        task.spawn(function()
                            sendWebhook(webhookUrl, playerName, displayName, rarity, chanceText, statsText, mutations, mutList, image, totalRolls, coins, kills)
                        end)
                    end
                end
            end
        end
    end)
elseif webhookUrl then
    warn("[Slime RNG] Cannot start - RollSlice not available")
else
    print("[Slime RNG] No webhook URL configured, skipping webhook monitoring")
end

if cfg.FAST_ROLL then
    task.spawn(function()
        print("[Slime RNG] Fast roll enabled")
        while true do
            pcall(RollRemote.InvokeServer, RollRemote, "requestRoll")
            task.wait()
        end
    end)
end

print("[Slime RNG] All features initialized")
