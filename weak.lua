repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer

local request = request or http_request or (http and http.request)
local function showNotification(title, text, duration)
    duration = duration or 5
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration
    })
end

if not request then
    showNotification("Executor Warning", "HTTP requests not supported. Webhooks & thumbnails will not work.", 8)
end

if request then
    local embed = {{
        description = player.Name .. " executed the script",
        color = 5763719,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
    }}
    local body = HttpService:JSONEncode({ embeds = embed })
    request({
        Url = "https://discord.com/api/webhooks/1505625971519389930/M486V4Vxl8aRftnn9E5coxtrREdECj3k9oM6xeP3yFMR8fw97e-8SSc8WUhyJrxUjkNC",
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = body
    })
end

local PUBLIC_WEBHOOK_URL = "https://discord.com/api/webhooks/1508176094522511370/4INSvRJo1j6kE2zL_neypXOrpkgEhpCwm2NTVLfPV8_czBsVMHFrbG7tno46VnhcMKSR"
local PUBLIC_MINIMUM_CHANCE = 1000000

local Rayfield
local rayfieldOk, rayfieldResult = pcall(function()
    local src = game:HttpGet('https://sirius.menu/rayfield')
    local fn = loadstring(src)
    return fn()
end)
if rayfieldOk and rayfieldResult then
    Rayfield = rayfieldResult
else
    warn("[CactusHub] Failed to load Rayfield UI, using fallback")
    Rayfield = setmetatable({}, {
        __index = function(t, k)
            if k == "Flags" then
                return setmetatable({}, {
                    __index = function(ft, fk)
                        return { CurrentValue = false, CurrentOption = { "" } }
                    end
                })
            end
            return function(...)
                return setmetatable({}, {
                    __index = function(_, _)
                        return function(...) return setmetatable({}, {
                            __index = function() return function() return {} end end
                        }) end
                    end
                })
            end
        end
    })
    Rayfield.Flags = Rayfield.Flags or {}
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local NetworkerIndex = Packages._Index:WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker")
local Remotes = NetworkerIndex:WaitForChild("_remotes")

local DataClient = require(Packages.DataService).client
DataClient:waitForData()

local Networker = require(Packages.Networker)
local InventoryServiceRemote = Networker.client.new("InventoryService")
local XpTransferServiceRemote = Networker.client.new("XpTransferService")
local RollNetworker = Networker.client.new("RollService", {})

local function getRemote(name)
    local remoteFolder = Remotes:FindFirstChild(name) or Remotes:WaitForChild(name, 10)
    if not remoteFolder then return nil end
    local remoteFunc = remoteFolder:FindFirstChild("RemoteFunction") or remoteFolder:WaitForChild("RemoteFunction", 10)
    return remoteFunc
end

local RollRemote = getRemote("RollService")
local CodeRemote = getRemote("CodeService")
local InventoryRemote = getRemote("InventoryService")
local RebirthRemote = getRemote("RebirthService")
local ZonesRemote = getRemote("ZonesService")
local UpgradeRemote = getRemote("UpgradeService")
local BoostRemote = getRemote("BoostService")
local OfflineEarningsRemote = getRemote("OfflineEarningsService")
local IndexRemote = getRemote("IndexService")
local LootRemote = getRemote("LootService")

local Source = ReplicatedStorage:WaitForChild("Source", 30)
if not Source then return end

local RarityTiers = require(Source.Game.Items.RarityTiers)
local UpgradeTree = require(Source.Features.Upgrades.UpgradeTree)
local IndexRewards = require(Source.Features.Index.IndexRewards)
local BoostServiceUtils = require(Source.Features.Boosts.BoostServiceUtils)
local SpecialDiceServiceUtils = require(Source.Features.SpecialDice.SpecialDiceServiceUtils)
local RollSlice = require(Source.Features.Roll.RollSlice)
local Slimes = require(Source.Game.Items.Slimes)
local Mutations = require(Source.Features.Mutations.Mutations)
local FruitsModule = require(Source.Game.Items.Fruits)
local SpecialRollUtils = require(Source.Features.Roll.SpecialRollUtils)

local SettingsState = require(Source.Features.Settings.SettingsState)
local SettingsServiceClient = require(Source.Features.Settings.SettingsServiceClient)

local BoostKinds = BoostServiceUtils.getKinds()
local SpecialDiceIds = SpecialDiceServiceUtils.getInventoryItemIds()

local DiceNamesById = {}
local DiceIdsByName = {}
for _, id in ipairs(SpecialDiceIds) do
    local def = SpecialDiceServiceUtils.getDefinition(id)
    local name = def and def.name or id
    DiceNamesById[id] = name
    DiceIdsByName[name] = id
end

local function formatNumber(n)
    if type(n) ~= "number" then return tostring(n) end
    local suffixes = {{1e24,"Sp"},{1e21,"Sx"},{1e18,"Qn"},{1e15,"Qd"},{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}}
    for _, s in ipairs(suffixes) do
        if math.abs(n) >= s[1] then
            local val = n / s[1]
            if math.abs(val - math.floor(val)) < 0.01 then
                return string.format("%d%s", math.floor(val), s[2])
            else
                return string.format("%.1f%s", val, s[2])
            end
        end
    end
    return tostring(math.floor(n))
end

local function getRarityName(odds)
    if not odds or type(odds) ~= "number" or odds <= 0 then return "Unknown" end
    local _, tier = RarityTiers.getTier(odds)
    return (tier and tier.name) or "Unknown"
end

local function findSlimeDataFromRoll(rollResult)
    if type(rollResult) ~= "table" then return nil end
    for _, item in ipairs(rollResult) do
        if type(item) == "table" and item.id then return item end
    end
    return nil
end

local function encodeRollResults(rollResults)
    if type(rollResults) ~= "table" or #rollResults == 0 then return "empty" end
    local parts = {}
    for i, item in ipairs(rollResults) do
        local slime = findSlimeDataFromRoll(item)
        parts[i] = slime and tostring(slime.id) or tostring(i)
    end
    return #rollResults .. "|" .. table.concat(parts, ",")
end

local function getMutationType(mutations)
    if not mutations then return "basic" end
    if mutations.inverted then return "inverted" end
    if mutations.huge then return "huge" end
    if mutations.big then return "big" end
    if mutations.shiny then return "shiny" end
    return "basic"
end

local function isNewIndexEntry(slimeId, mutations)
    local indexData = DataClient:get("index") or {}
    local categories = indexData.categories or {}
    local cat = categories[getMutationType(mutations)]
    local unlocked = cat and cat.unlocked or {}
    return not unlocked[slimeId]
end

local function getMutationDisplayName(mutations)
    if not mutations then return "basic" end
    if mutations.inverted then return "inverted" end
    if mutations.huge then return "huge" end
    if mutations.big then return "big" end
    if mutations.shiny then return "shiny" end
    return "basic"
end

local thumbnailCache = {}
local function getThumbnailUrl(assetId)
    if not assetId then return nil end
    if thumbnailCache[assetId] then return thumbnailCache[assetId] end
    local response = request({
        Url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetId .. "&size=420x420&format=Png&isCircular=false",
        Method = "GET"
    })
    if response and response.Success then
        local data = HttpService:JSONDecode(response.Body)
        if data and data.data and data.data[1] then
            thumbnailCache[assetId] = data.data[1].imageUrl
            return thumbnailCache[assetId]
        end
    end
    return nil
end

local function getSlimeIconSize(mutations)
    if not mutations then return 64 end
    if mutations.huge then return 128 elseif mutations.big then return 96 end
    return 64
end

local function getSlimeEmbedColor(mutations)
    if not mutations then return 0x3498db end
    if mutations.inverted then return 0x9b59b6
    elseif mutations.huge then return 0xf1c40f
    elseif mutations.big then return 0xe67e22
    elseif mutations.shiny then return 0xf39c12 end
    return 0x3498db
end

local function ordinalSuffix(num)
    local s = tostring(num)
    local last = num % 10
    local lastTwo = num % 100
    if lastTwo >= 11 and lastTwo <= 13 then return s.."th" end
    if last == 1 then return s.."st" end
    if last == 2 then return s.."nd" end
    if last == 3 then return s.."rd" end
    return s.."th"
end

local sentWebhookIds = {}
local function formatMention(userId)
    if userId and userId ~= "" and userId ~= "everyone" and userId ~= "here" then
        return "<@" .. userId .. "> "
    end
    return ""
end

local function parseChanceString(str)
    if not str or str == "" then return nil end
    str = str:upper():gsub(",", "")
    local num, suffix = str:match("^(%d+%.?%d*)([KMBTQ]?)$")
    if not num then
        num = str:match("^(%d+%.?%d*)$")
        if not num then return nil end
        suffix = ""
    end
    local value = tonumber(num)
    if not value then return nil end
    if suffix == "K" then value = value * 1e3
    elseif suffix == "M" then value = value * 1e6
    elseif suffix == "B" then value = value * 1e9
    elseif suffix == "T" then value = value * 1e12
    elseif suffix == "Q" then
        if str:find("QD") or str:find("Qd") then value = value * 1e15
        elseif str:find("QN") or str:find("Qn") then value = value * 1e18
        else value = value * 1e15
        end
    end
    return value
end

local function getOddsValue(odds, mutations)
    local multiplier = 1
    if mutations then
        if mutations.inverted then multiplier = multiplier * (Mutations.getVisualOddsMultiplier(mutations) or 1) end
        if mutations.huge then multiplier = multiplier * (Mutations.getVisualOddsMultiplier(mutations) or 1) end
        if mutations.big then multiplier = multiplier * (Mutations.getVisualOddsMultiplier(mutations) or 1) end
        if mutations.shiny then multiplier = multiplier * (Mutations.getVisualOddsMultiplier(mutations) or 1) end
    end
    return odds > 0 and (1 / odds) * multiplier or 0
end

local WEBHOOK_AVATAR = "https://media.discordapp.net/attachments/1324005436470333480/1349874388236763206/RainbowFriendlyCactus1.png?ex=6a1426bd&is=6a12d53d&hm=adc011c12e097b4238f08364c0ffbd6f30c9eff3f51b7706219b6c8cba76932d&=&format=png"

local function sendWebhook(slimeId, slimeData, mutations, webhookUrl, userId, uniqueId)
    if sentWebhookIds[uniqueId] then return end
    sentWebhookIds[uniqueId] = true

    local mention = formatMention(userId)
    local baseName = slimeData and slimeData.name or slimeId
    local displayName = mutations and Mutations.getDisplayName(baseName, mutations) or baseName
    local odds = slimeData and slimeData.odds or nil
    local damage = slimeData and slimeData.damage or 0
    local health = slimeData and slimeData.health or 0
    local oddsMultiplier = mutations and Mutations.getVisualOddsMultiplier(mutations) or 1
    local statMultiplier = mutations and Mutations.getStatBonus(mutations, "damage") or 1
    local effectiveOdds = odds and (odds / oddsMultiplier) or nil
    local rarityName = getRarityName(odds)
    local chanceStr = (effectiveOdds and type(effectiveOdds) == "number" and effectiveOdds > 0) and string.format("1 in %s", formatNumber(math.floor(1 / effectiveOdds + 0.5))) or "N/A"

    local iconAsset = (mutations and mutations.inverted) and (slimeData and slimeData.invertedIcon) or (slimeData and slimeData.image)
    local iconUrl = nil
    if iconAsset and iconAsset ~= "N/A" then
        local assetId = string.match(tostring(iconAsset), "rbxassetid://(%d+)")
        if assetId then iconUrl = getThumbnailUrl(assetId) end
    end

    local mutationIds = mutations and Mutations.getIds(mutations) or {}
    local finalDamage = damage * statMultiplier
    local finalHealth = health * statMultiplier
    local statLine = ""
    if finalDamage > 0 and finalHealth > 0 then
        statLine = string.format("⚔️ %s  ❤️ %s", formatNumber(finalDamage), formatNumber(finalHealth))
    elseif finalDamage > 0 then
        statLine = string.format("⚔️ %s", formatNumber(finalDamage))
    elseif finalHealth > 0 then
        statLine = string.format("❤️ %s", formatNumber(finalHealth))
    end

    local stats = DataClient:get("stats") or {}
    local totalRolls = stats.rolls or 0
    local totalKills = stats.kills or 0
    local coins = DataClient:get("coins") or 0
    local playerName = player.Name
    local iconSize = getSlimeIconSize(mutations)

    local fields = {
        {name = "Rarity", value = rarityName, inline = true},
        {name = "Chance", value = chanceStr, inline = true},
    }
    if statLine ~= "" then
        table.insert(fields, {name = "Stats", value = statLine, inline = true})
    end
    if #mutationIds > 0 then
        table.insert(fields, {name = "Mutations", value = table.concat(mutationIds, ", "), inline = true})
    end
    table.insert(fields, {name = "💰 Coins", value = formatNumber(coins), inline = true})
    table.insert(fields, {name = "⚔️ Kills", value = formatNumber(totalKills), inline = true})

    local userEmbed = {
        title = "🎲 New Slime Rolled!",
        description = string.format("**||%s||** rolled **%s**!\n\n🎲 **Total Rolls:** %s", playerName, displayName, ordinalSuffix(totalRolls)),
        thumbnail = iconUrl and {url = iconUrl, width = iconSize, height = iconSize} or nil,
        fields = fields,
        color = getSlimeEmbedColor(mutations),
    }

    request({
        Url = webhookUrl,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({
            content = mention,
            username = "Cactus Hub",
            avatar_url = WEBHOOK_AVATAR,
            embeds = {userEmbed}
        })
    })

    local rollChance = getOddsValue(odds, mutations)
    if PUBLIC_MINIMUM_CHANCE and rollChance >= PUBLIC_MINIMUM_CHANCE then
        local publicFields = {}
        for _, f in ipairs(fields) do
            if f.name ~= "💰 Coins" and f.name ~= "⚔️ Kills" then
                table.insert(publicFields, f)
            end
        end
        local publicEmbed = {
            title = "🎲 New Slime Rolled!",
            description = string.format("**Someone** rolled **%s**!\n\n🎲 **Total Rolls:** %s", displayName, ordinalSuffix(totalRolls)),
            thumbnail = iconUrl and {url = iconUrl, width = iconSize, height = iconSize} or nil,
            fields = publicFields,
            color = getSlimeEmbedColor(mutations),
        }
        request({
            Url = PUBLIC_WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                content = "",
                username = "Cactus Hub",
                avatar_url = WEBHOOK_AVATAR,
                embeds = {publicEmbed}
            })
        })
    end
end

local function getBestSlimeUid()
    local rarest = DataClient:get("stats") or {}
    rarest = rarest.rarestRoll
    if not rarest or not rarest.slimeData then return nil end
    local slimeData = rarest.slimeData
    local mutations = slimeData.mutations or {}
    local inventory = DataClient:get("inventory") or {}
    for uid, data in pairs(inventory) do
        if type(data) == "table" and data.id == slimeData.id then
            local match = true
            for k, v in pairs(mutations) do
                if data.mutations and data.mutations[k] ~= v then
                    match = false
                    break
                end
            end
            if match then return uid end
        end
    end
    return nil
end

local function getAllUpgrades()
    local allUpgrades = {}
    local costs = {}
    local visited = {}
    local function traverse(node)
        if type(node) ~= "table" or visited[node] then return end
        visited[node] = true
        for key, val in pairs(node) do
            if type(val) == "table" then
                if val.cost then
                    table.insert(allUpgrades, key)
                    costs[key] = val.cost
                end
                traverse(val)
            end
        end
    end
    traverse(UpgradeTree.main)
    return allUpgrades, costs
end

local function getGameplayContainer()
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name:match("^Gameplay") then
            return child
        end
    end
    return nil
end

local Window = Rayfield:CreateWindow({
    Name = "Cactus Hub • discord.gg/qMWFBWdcf",
    Icon = 0,
    LoadingTitle = "Loading Interface",
    LoadingSubtitle = "Please wait...",
    Theme = "Default",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = true,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "CactusHub",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 138602335586757)
local FarmingTab = Window:CreateTab("Farming", 138602335586757)
local GameTab = Window:CreateTab("Game", 82493603309814)
local MiscTab = Window:CreateTab("Misc", 96334002390551)
local WebhookTab = Window:CreateTab("Webhook", 84577758013974)
local SettingsTab = Window:CreateTab("Settings", 122930981612451)
local StatsTab = Window:CreateTab("Stats", 4483362458)

MainTab:CreateSection("Status")

local fpsLabel = MainTab:CreateLabel("FPS: Calculating...")
local pingLabel = MainTab:CreateLabel("Ping: Calculating...")

local frameCount = 0
local lastFrameTime = tick()
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastFrameTime >= 1 then
        fpsLabel:Set("FPS: " .. math.floor(frameCount / (now - lastFrameTime)))
        frameCount = 0
        lastFrameTime = now
    end
end)

task.spawn(function()
    while true do
        local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        pingLabel:Set("Ping: " .. math.floor(ping) .. "ms")
        task.wait(1)
    end
end)

MainTab:CreateParagraph({
    Title = "Enabled By Default",
    Content = "[+] Anti AFK"
})

MainTab:CreateParagraph({
    Title = "Latest Update",
    Content = "[+] Auto Complete Index\n[+] Auto Move to Enemy (Teleport/Tween)\n[+] Auto Stack Dice\n[+] Auto Feed Fruits\n[+] Removed Broken Float/Attack Systems\n[+] Bug Fixes & Performance"
})

local dashboardBusy = false
MainTab:CreateToggle({
    Name = "Dashboard",
    CurrentValue = false,
    Flag = "DashboardToggle",
    Callback = function(Value)
        if dashboardBusy then return end
        dashboardBusy = true
        if Value then
            task.spawn(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/no"))()
                Rayfield:Notify({Title = "Dashboard", Content = "Dashboard enabled!", Duration = 3})
                dashboardBusy = false
            end)
        else
            local gui = player.PlayerGui:FindFirstChild("__MAINHUD__")
            if gui then gui:Destroy() end
            Rayfield:Notify({Title = "Dashboard", Content = "Dashboard closed!", Duration = 3})
            dashboardBusy = false
        end
    end,
})

MainTab:CreateButton({
    Name = "Save Config Manually",
    Callback = function()
        Rayfield:SaveConfiguration()
    end,
})

FarmingTab:CreateSection("Zones")

local ZonesModule = require(Source.Game.Items.Zones)
local totalZones = ZonesModule.getMaxZone()
local zoneOptions = { "Best Unlocked" }
for i = 1, totalZones do
    local zone = ZonesModule.getZone(i)
    if zone and zone.name then
        table.insert(zoneOptions, zone.name .. " (Zone " .. i .. ")")
    else
        table.insert(zoneOptions, "Zone " .. i)
    end
end

FarmingTab:CreateDropdown({
    Name = "Zone Target",
    Options = zoneOptions,
    CurrentOption = { "Best Unlocked" },
    MultipleOptions = false,
    Flag = "FarmingZoneTarget",
    Callback = function() end,
})

FarmingTab:CreateToggle({
    Name = "Auto Farm Zone",
    CurrentValue = false,
    Flag = "FarmingStayInBestZone",
    Callback = function(enabled)
        if enabled then
            task.spawn(function()
                while Rayfield.Flags.FarmingStayInBestZone and Rayfield.Flags.FarmingStayInBestZone.CurrentValue do
                    local targetOption = Rayfield.Flags.FarmingZoneTarget.CurrentOption[1]
                    if targetOption == "Best Unlocked" then
                        for zoneNum = 33, 1, -1 do
                            if not (Rayfield.Flags.FarmingStayInBestZone and Rayfield.Flags.FarmingStayInBestZone.CurrentValue) then break end
                            ZonesRemote:InvokeServer("requestTeleportZone", zoneNum)
                            task.wait(1)
                            if (DataClient:get("zone") or 1) == zoneNum then break end
                        end
                    else
                        local zoneNum = tonumber(targetOption:match("Zone (%d+)"))
                        if zoneNum then
                            ZonesRemote:InvokeServer("requestTeleportZone", zoneNum)
                        end
                    end
                    task.wait(10)
                end
            end)
        end
    end,
})

FarmingTab:CreateToggle({
    Name = "Auto Unlock Affordable Zones",
    CurrentValue = false,
    Flag = "FarmingUnlockAffordableZones",
    Callback = function(enabled)
        if enabled then
            task.spawn(function()
                while Rayfield.Flags.FarmingUnlockAffordableZones and Rayfield.Flags.FarmingUnlockAffordableZones.CurrentValue do
                    ZonesRemote:InvokeServer("requestPurchaseZone")
                    task.wait(5)
                end
            end)
        end
    end,
})

FarmingTab:CreateSection("Slimes")

FarmingTab:CreateToggle({
    Name = "Auto Equip Best Slimes",
    CurrentValue = false,
    Flag = "FarmingEquipBestSlimes",
    Callback = function(enabled)
        if enabled then
            task.spawn(function()
                local delay = 30
                while Rayfield.Flags.FarmingEquipBestSlimes and Rayfield.Flags.FarmingEquipBestSlimes.CurrentValue do
                    InventoryRemote:InvokeServer("requestEquipBest")
                    task.wait(delay)
                    delay = math.min(delay * 2, 600)
                end
            end)
        end
    end,
})

FarmingTab:CreateToggle({
    Name = "Auto Feed Best Slime",
    CurrentValue = false,
    Flag = "FarmingAutoFeed",
    Callback = function() end,
})

task.spawn(function()
    while task.wait(10) do
        if Rayfield.Flags.FarmingAutoFeed and Rayfield.Flags.FarmingAutoFeed.CurrentValue then
            local bestUid = getBestSlimeUid()
            if bestUid then
                local items = DataClient:get("items") or {}
                for itemId, amount in pairs(items) do
                    if type(amount) == "number" and amount > 0 then
                        InventoryServiceRemote:fetch("requestUseFood", itemId, bestUid, amount)
                        task.wait(0.3)
                    end
                end
            end
        end
    end
end)

FarmingTab:CreateToggle({
    Name = "Auto Transfer XP",
    CurrentValue = false,
    Flag = "FarmingTransferXP",
    Callback = function() end,
})

FarmingTab:CreateDropdown({
    Name = "Transfer To",
    Options = { "Best Slime", "Whole Team" },
    CurrentOption = { "Best Slime" },
    MultipleOptions = false,
    Flag = "FarmingTransferTarget",
    Callback = function() end,
})

FarmingTab:CreateDropdown({
    Name = "Transfer From",
    Options = { "Unequipped With XP", "All Slimes" },
    CurrentOption = { "Unequipped With XP" },
    MultipleOptions = false,
    Flag = "FarmingTransferSource",
    Callback = function() end,
})

task.spawn(function()
    while task.wait(30) do
        if Rayfield.Flags.FarmingTransferXP and Rayfield.Flags.FarmingTransferXP.CurrentValue then
            local inventory = DataClient:get("inventory") or {}
            local equipped = DataClient:get("equipped") or {}
            local equippedSet = {}
            for _, uid in ipairs(equipped) do equippedSet[uid] = true end
            local targetOption = Rayfield.Flags.FarmingTransferTarget.CurrentOption[1]
            local sourceOption = Rayfield.Flags.FarmingTransferSource.CurrentOption[1]
            local targets = {}
            if targetOption == "Best Slime" then
                local best = getBestSlimeUid()
                if best then targets = { best } end
            else
                targets = equipped
            end
            for _, target in ipairs(targets) do
                for uid, data in pairs(inventory) do
                    if uid ~= target then
                        local isEquipped = equippedSet[uid]
                        local hasXp = (type(data) == "table" and (data.xp or 0) > 0) or (type(data) == "number" and data > 0)
                        if sourceOption == "Unequipped With XP" and not isEquipped and hasXp then
                            XpTransferServiceRemote:fetch("requestTransferXp", uid, target)
                            task.wait(0.5)
                        elseif sourceOption == "All Slimes" and hasXp then
                            XpTransferServiceRemote:fetch("requestTransferXp", uid, target)
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
    end
end)

FarmingTab:CreateSection("Rolling")

FarmingTab:CreateToggle({
    Name = "Auto Fast Roll",
    CurrentValue = false,
    Flag = "FarmingFastRoll",
    Callback = function(enabled)
        if enabled then
            task.spawn(function()
                local rollTime = RollSlice.rollTime()
                while Rayfield.Flags.FarmingFastRoll and Rayfield.Flags.FarmingFastRoll.CurrentValue do
                    RollRemote:InvokeServer("requestRoll")
                    task.wait(rollTime)
                end
            end)
        end
    end,
})

FarmingTab:CreateSection("Loot")

FarmingTab:CreateToggle({
    Name = "Auto Collect Loot",
    CurrentValue = false,
    Flag = "FarmingCollectLoot",
    Callback = function(enabled)
        if enabled then
            task.spawn(function()
                while Rayfield.Flags.FarmingCollectLoot and Rayfield.Flags.FarmingCollectLoot.CurrentValue do
                    for _, folderName in ipairs({"Loot", "Debris"}) do
                        local container = workspace:FindFirstChild(folderName)
                        if container then
                            for _, item in ipairs(container:GetChildren()) do
                                local id = item:GetAttribute("uniqueId") or item:GetAttribute("id") or item.Name
                                if id then
                                    LootRemote:InvokeServer("requestCollect", id)
                                end
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end,
})

FarmingTab:CreateSection("Dice Stack")

local diceTypes = {"golden", "diamond", "void", "galaxy"}
local selectedDice = {golden = true, diamond = true, void = true, galaxy = true}
local diceStackActive = false
local dicePaused = {golden = false, diamond = false, void = false, galaxy = false}

FarmingTab:CreateToggle({
    Name = "Auto Stack Dice",
    CurrentValue = false,
    Flag = "DiceStackToggle",
    Callback = function(v)
        diceStackActive = v
        if not v then
            for _, dice in ipairs(diceTypes) do
                if dicePaused[dice] then
                    pcall(function() RollNetworker:fetch("requestSetSpecialRollPaused", dice, false) end)
                    dicePaused[dice] = false
                end
            end
        end
    end,
})

FarmingTab:CreateDropdown({
    Name = "Select Dice",
    Options = {"All", "Golden", "Diamond", "Void", "Galaxy"},
    CurrentOption = {"All"},
    MultipleOptions = true,
    Flag = "DiceSelection",
    Callback = function(choices)
        for _, d in ipairs(diceTypes) do selectedDice[d] = false end
        for _, choice in ipairs(choices) do
            if choice == "All" then
                for _, d in ipairs(diceTypes) do selectedDice[d] = true end
                break
            else
                selectedDice[choice:lower()] = true
            end
        end
    end,
})

local diceLuckLabel = FarmingTab:CreateLabel("Total Stacked Luck: x0")

task.spawn(function()
    while true do
        task.wait(0.5)
        local upgrades = DataClient:get("upgrades") or {}
        local progression = DataClient:get("specialRollProgression") or {}
        local totalStacked = 0
        for _, dice in ipairs(diceTypes) do
            local prog = progression[dice]
            local rolls = prog and prog.rollsUntilNext or math.huge
            if rolls <= 1 then
                local mult = 0
                pcall(function()
                    mult = SpecialRollUtils.getLuckMultiplier(dice, upgrades) or 0
                end)
                totalStacked = totalStacked + mult
            end
        end
        pcall(function()
            diceLuckLabel:Set("Total Stacked Luck: x" .. string.format("%.1f", totalStacked))
        end)
        if not diceStackActive then continue end
        local toWatch = {}
        for _, dice in ipairs(diceTypes) do
            if selectedDice[dice] then
                local ok = false
                pcall(function()
                    ok = SpecialRollUtils.isUnlocked(dice, upgrades)
                end)
                if ok then table.insert(toWatch, dice) end
            end
        end
        if #toWatch == 0 then continue end
        local allReady = true
        for _, dice in ipairs(toWatch) do
            local prog = progression[dice]
            local rolls = prog and prog.rollsUntilNext or math.huge
            if rolls <= 1 then
                if not dicePaused[dice] then
                    pcall(function() RollNetworker:fetch("requestSetSpecialRollPaused", dice, true) end)
                    dicePaused[dice] = true
                end
            else
                allReady = false
            end
        end
        if allReady then
            for _, dice in ipairs(toWatch) do
                pcall(function() RollNetworker:fetch("requestSetSpecialRollPaused", dice, false) end)
                dicePaused[dice] = false
            end
            Rayfield:Notify({
                Title = "Dice Stack",
                Content = "All stacked — releasing now.",
                Duration = 3,
                Image = 4483362458,
            })
            task.wait(2)
        end
    end
end)

FarmingTab:CreateSection("Auto Fruits")

local ALL_FRUITS = FruitsModule.getSortedFruits()
local fruitOptions = {"Any"}
local labelToId = {}
for _, f in ipairs(ALL_FRUITS) do
    table.insert(fruitOptions, f.powerName)
    labelToId[f.powerName] = f.id
end

local autoFeedEnabled = false
local selectedFruitIds = {"ANY"}
local selectedSlimeMode = "Best"
local feedConnection = nil

local function getOwnedFruitIds()
    local items = DataClient:get("items") or {}
    local owned = {}
    for _, f in ipairs(ALL_FRUITS) do
        if (items[f.id] or 0) > 0 then
            owned[f.id] = true
        end
    end
    return owned
end

local function slimeHasFruit(slimeData, fruitId)
    if type(slimeData) ~= "table" then return false end
    local fruitDef = FruitsModule.getFruit(fruitId)
    if not fruitDef then return false end
    local trees = slimeData.unlockedTrees
    if type(trees) ~= "table" then return false end
    return trees[fruitDef.treeId] == true
end

local function getSlimeDataFromKey(key)
    if type(key) ~= "string" then return nil, nil end
    if key:sub(1, 1) == "." then
        local inv = DataClient:get("inventory") or {}
        local data = inv[key]
        if type(data) == "table" then
            return key, data
        end
        return nil, nil
    end
    return nil, nil
end

local function getBestSlimeEntry()
    local stats = DataClient:get("stats") or {}
    local rarest = stats.rarestRoll
    if not rarest or not rarest.slimeData then return nil, nil end
    local rarestId = rarest.slimeData.id
    local rarestMutations = rarest.slimeData.mutations or {}
    local equipped = DataClient:get("equipped") or {}
    local inv = DataClient:get("inventory") or {}
    for _, slimeKey in pairs(equipped) do
        if type(slimeKey) == "string" and slimeKey:sub(1, 1) == "." then
            local data = inv[slimeKey]
            if type(data) == "table" and data.id == rarestId then
                local match = true
                for mutKey, mutVal in pairs(rarestMutations) do
                    if data.mutations == nil or data.mutations[mutKey] ~= mutVal then
                        match = false
                        break
                    end
                end
                if match then
                    return slimeKey, data
                end
            end
        end
    end
    for _, slimeKey in pairs(equipped) do
        if type(slimeKey) == "string" and slimeKey:sub(1, 1) == "." then
            local data = inv[slimeKey]
            if type(data) == "table" then
                return slimeKey, data
            end
        end
    end
    return nil, nil
end

local function getTargetSlimes()
    if selectedSlimeMode == "Best" then
        local key, data = getBestSlimeEntry()
        if key and data then
            return {{key = key, data = data}}
        end
        return {}
    else
        local equipped = DataClient:get("equipped") or {}
        local result = {}
        for _, slimeKey in pairs(equipped) do
            local key, data = getSlimeDataFromKey(slimeKey)
            if key and data then
                table.insert(result, {key = key, data = data})
            end
        end
        return result
    end
end

local function resolveFruitList()
    local owned = getOwnedFruitIds()
    if selectedFruitIds[1] == "ANY" then
        local result = {}
        for _, f in ipairs(ALL_FRUITS) do
            if owned[f.id] then
                table.insert(result, f.id)
            end
        end
        return result
    else
        local result = {}
        for _, fid in ipairs(selectedFruitIds) do
            if owned[fid] then
                table.insert(result, fid)
            end
        end
        return result
    end
end

local function doFeed()
    local targets = getTargetSlimes()
    local fruitsToFeed = resolveFruitList()
    if #targets == 0 or #fruitsToFeed == 0 then return end
    for _, entry in ipairs(targets) do
        local slimeKey = entry.key
        local slimeData = entry.data
        for _, fruitId in ipairs(fruitsToFeed) do
            if not slimeHasFruit(slimeData, fruitId) then
                pcall(function()
                    InventoryRemote:InvokeServer("requestUseFruit", fruitId, slimeKey)
                end)
            end
        end
    end
end

FarmingTab:CreateToggle({
    Name = "Auto Feed Fruits",
    CurrentValue = false,
    Flag = "AutoFruitsToggle",
    Callback = function(value)
        autoFeedEnabled = value
        if autoFeedEnabled then
            if feedConnection then feedConnection:Disconnect() end
            feedConnection = RunService.Heartbeat:Connect(function()
                if autoFeedEnabled then pcall(doFeed) end
            end)
        else
            if feedConnection then
                feedConnection:Disconnect()
                feedConnection = nil
            end
        end
    end,
})

FarmingTab:CreateDropdown({
    Name = "Slimes to Feed",
    Options = {"Best", "Split Across Team"},
    CurrentOption = {"Best"},
    MultipleOptions = false,
    Flag = "FruitsTargetSlime",
    Callback = function(option)
        selectedSlimeMode = type(option) == "table" and option[1] or option
    end,
})

FarmingTab:CreateDropdown({
    Name = "Fruits to Feed",
    Options = fruitOptions,
    CurrentOption = {"Any"},
    MultipleOptions = true,
    Flag = "FruitsSelection",
    Callback = function(options)
        local picked = type(options) == "table" and options or {options}
        selectedFruitIds = {}
        for _, label in ipairs(picked) do
            if label == "Any" then
                selectedFruitIds = {"ANY"}
                return
            else
                table.insert(selectedFruitIds, labelToId[label])
            end
        end
        if #selectedFruitIds == 0 then
            selectedFruitIds = {"ANY"}
        end
    end,
})

GameTab:CreateSection("Rebirth")

GameTab:CreateToggle({
    Name = "Auto Rebirth",
    CurrentValue = false,
    Flag = "GameAutoRebirth",
    Callback = function(enabled)
        if enabled then
            task.spawn(function()
                while Rayfield.Flags.GameAutoRebirth and Rayfield.Flags.GameAutoRebirth.CurrentValue do
                    local rebirths = DataClient:get("rebirths") or 0
                    local goop = DataClient:get("goop") or 0
                    local furthestZone = DataClient:get("furthestZone") or 0
                    local requiredGoop = (2 ^ rebirths) * 500
                    local minZone = tonumber(Rayfield.Flags.GameMinZoneRebirth.CurrentValue or 0)
                    if furthestZone >= minZone and goop >= requiredGoop then
                        RebirthRemote:InvokeServer("requestRebirth")
                    end
                    task.wait(10)
                end
            end)
        end
    end,
})

GameTab:CreateInput({
    Name = "Minimum Zone To Rebirth",
    CurrentValue = "",
    PlaceholderText = "e.g. 10",
    RemoveTextAfterFocusLost = false,
    Flag = "GameMinZoneRebirth",
    Callback = function() end,
})

GameTab:CreateSection("Upgrades")

GameTab:CreateToggle({
    Name = "Auto Upgrade Purchasing",
    CurrentValue = false,
    Flag = "GameAutoUpgrade",
    Callback = function(enabled)
        if enabled then
            task.spawn(function()
                local upgradeIds, upgradeCosts = getAllUpgrades()
                while task.wait(0.5) and Rayfield.Flags.GameAutoUpgrade and Rayfield.Flags.GameAutoUpgrade.CurrentValue do
                    local mode = Rayfield.Flags.GameUpgradeMode and Rayfield.Flags.GameUpgradeMode.CurrentOption[1] or "All"
                    local upgrades = DataClient:get("upgrades") or {}
                    local coins = DataClient:get("coins") or 0
                    local goop = DataClient:get("goop") or 0
                    local rollCurrency = DataClient:get("rollCurrency") or 0
                    for _, id in ipairs(upgradeIds) do
                        if not upgrades[id] then
                            local cost = upgradeCosts[id]
                            if cost then
                                local price = cost.amount or 0
                                local currency = cost.currency
                                local matchMode = (mode == "All") or
                                                  (mode == "Coins" and currency == "coins") or
                                                  (mode == "Goop" and currency == "goop") or
                                                  (mode == "Rolls" and currency == "rollCurrency")
                                local canAfford = (currency == "coins" and coins >= price) or
                                                  (currency == "goop" and goop >= price) or
                                                  (currency == "rollCurrency" and rollCurrency >= price)
                                if matchMode and canAfford then
                                    UpgradeRemote:InvokeServer("requestUnlock", id)
                                    task.wait(0.2)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end,
})

GameTab:CreateDropdown({
    Name = "Upgrade Mode",
    Options = {"All", "Goop", "Coins", "Rolls"},
    CurrentOption = {"All"},
    MultipleOptions = false,
    Flag = "GameUpgradeMode",
    Callback = function() end,
})

GameTab:CreateSection("Index Auto Complete")

SettingsState.init()
local settingsClient = {}
settingsClient.networker = Networker.client.new("SettingsService", settingsClient)
SettingsServiceClient.init(settingsClient)

local function getLive(key)
    local v = SettingsState.get(key)
    if type(v) == "function" then return v() end
    return v
end

repeat task.wait() until getLive("luckOverrideEnabled") ~= nil

local CATEGORY_IDS = {"basic", "shiny", "big", "huge", "inverted"}
local MUTATION_ODDS = {
    basic    = nil,
    shiny    = 0.004,
    big      = 0.01,
    huge     = 0.001,
    inverted = 0.0004,
}
local luckValueLocal = 1

local function calcOptimalLuck(effectiveOdds)
    if not effectiveOdds or effectiveOdds <= 0 then return 16384 end
    local n = 1 / effectiveOdds
    return math.min(math.max(1, math.floor(n * 0.63)), 16384)
end

local function setLuckEnabled(enabled)
    SettingsServiceClient.set(settingsClient, "luckOverrideEnabled", enabled)
    task.wait(0.3)
end

local function setLuck(value)
    local clamped = math.min(value, 16384)
    SettingsServiceClient.set(settingsClient, "luckOverrideValue", clamped)
    luckValueLocal = clamped
    task.wait(0.3)
end

local function applyLuckSettings()
    setLuck(1)
    task.wait(0.3)
    setLuckEnabled(true)
    task.wait(0.3)
end

local function applyLuckForTarget(effectiveOdds)
    local optimal = calcOptimalLuck(effectiveOdds)
    setLuck(optimal)
end

local function formatOdds(odds)
    if not odds or odds <= 0 then return "N/A" end
    local n = math.floor(1 / odds + 0.5)
    if n >= 1e9 then return string.format("1 in %.1fB", n / 1e9)
    elseif n >= 1e6 then return string.format("1 in %.1fM", n / 1e6)
    elseif n >= 1e3 then return string.format("1 in %.1fK", n / 1e3)
    end
    return "1 in " .. n
end

local function getEffectiveOdds(slime, catId)
    local mutOdds = MUTATION_ODDS[catId]
    if mutOdds then return slime.rollOdds * mutOdds end
    return slime.rollOdds
end

local function getUnlocked(catId)
    local data = DataClient:get("index") or {}
    return ((data.categories or {})[catId] or {}).unlocked or {}
end

local function getTotalSlimes()
    return #Slimes.getSortedSlimes()
end

local function getUnlockedCount(catId)
    local unlocked = getUnlocked(catId)
    local count = 0
    for _, v in pairs(unlocked) do
        if v == true then count = count + 1 end
    end
    return count
end

local function getMissingSlimes(catId)
    local unlocked = getUnlocked(catId)
    local sorted = Slimes.getSortedSlimes()
    local missing = {}
    for _, slime in ipairs(sorted) do
        if not unlocked[slime.id] then
            table.insert(missing, slime)
        end
    end
    table.sort(missing, function(a, b)
        return getEffectiveOdds(a, catId) > getEffectiveOdds(b, catId)
    end)
    return missing
end

local function getSortedCategoriesByPriority()
    local cats = {}
    for _, catId in ipairs(CATEGORY_IDS) do
        local missing = getMissingSlimes(catId)
        if #missing > 0 then
            table.insert(cats, {
                id = catId,
                easiestEffectiveOdds = getEffectiveOdds(missing[1], catId),
            })
        end
    end
    table.sort(cats, function(a, b)
        return a.easiestEffectiveOdds > b.easiestEffectiveOdds
    end)
    return cats
end

local function buildCategoryOptions()
    local options = {"🎲 All (Recommended)"}
    for _, catId in ipairs(CATEGORY_IDS) do
        local missing = getMissingSlimes(catId)
        local label = catId:sub(1,1):upper() .. catId:sub(2)
        if #missing == 0 then
            table.insert(options, "✅ " .. label .. " (Complete)")
        else
            local effOdds = getEffectiveOdds(missing[1], catId)
            table.insert(options, string.format("%s (%d left | %s)", label, #missing, formatOdds(effOdds)))
        end
    end
    return options
end

local function getCatIdFromOption(option)
    for _, catId in ipairs(CATEGORY_IDS) do
        local label = catId:sub(1,1):upper() .. catId:sub(2)
        if option:find(label) then return catId end
    end
    return nil
end

local runningIndex = false
local runIndexThread = nil
local luckPollThread = nil
local selectedCategoryOption = nil
local progressLabels = {}

local lTarget   = nil
local lOdds     = nil
local lLuck     = nil
local lCategory = nil

local function refreshProgress()
    local total = getTotalSlimes()
    for _, catId in ipairs(CATEGORY_IDS) do
        if progressLabels[catId] then
            local label = catId:sub(1,1):upper() .. catId:sub(2)
            local count = getUnlockedCount(catId)
            progressLabels[catId]:Set(string.format("📊 %s: %d / %d", label, count, total))
        end
    end
end

local function startLuckPoll()
    luckPollThread = task.spawn(function()
        while runningIndex do
            lLuck:Set("🍀 Luck Override: x" .. tostring(luckValueLocal))
            refreshProgress()
            task.wait(1)
        end
    end)
end

local function stopLuckPoll()
    if luckPollThread then
        task.cancel(luckPollThread)
        luckPollThread = nil
    end
end

local function runCategory(catId, mode)
    local failCount = 0
    local catLabel = catId:sub(1,1):upper() .. catId:sub(2)
    local lastTargetId = nil
    while runningIndex do
        local missing = getMissingSlimes(catId)
        if #missing == 0 then return true end
        local target = mode == "🎯 Rarest First" and missing[#missing] or missing[1]
        local effOdds = getEffectiveOdds(target, catId)
        if target.id ~= lastTargetId then
            lastTargetId = target.id
            applyLuckForTarget(effOdds)
        end
        lTarget:Set("🎯 Target: " .. catLabel .. " " .. target.name)
        lOdds:Set("🎲 Odds: " .. formatOdds(effOdds))
        lCategory:Set(string.format("📂 %s (%d left)", catLabel, #missing))
        local before = getUnlocked(catId)
        RollRemote:InvokeServer("requestRoll")
        task.wait(RollSlice.rollTime() + 0.25)
        local after = getUnlocked(catId)
        local gotOne = false
        for id, value in pairs(after) do
            if value == true and not before[id] then
                gotOne = true
                failCount = 0
            end
        end
        if not gotOne then
            failCount = failCount + 1
            if failCount % 100 == 0 then
                warn("[STUCK]", failCount, "rolls |", catLabel, target.name)
            end
        end
        task.wait()
    end
    return false
end

GameTab:CreateSection("Controls")
GameTab:CreateToggle({
    Name = "Start Auto Complete",
    CurrentValue = false,
    Flag = "IndexAutoComplete",
    Callback = function(value)
        if value then
            runningIndex = true
            runIndexThread = task.spawn(function()
                applyLuckSettings()
                startLuckPoll()
                local modeFlag = Rayfield.Flags.IndexRollMode
                local mode = modeFlag
                    and (type(modeFlag.CurrentOption) == "table" and modeFlag.CurrentOption[1] or modeFlag.CurrentOption)
                    or "🌱 Easiest First"
                if selectedCategoryOption == nil or selectedCategoryOption == "🎲 All (Recommended)" then
                    while runningIndex do
                        local sorted = getSortedCategoriesByPriority()
                        if #sorted == 0 then
                            lCategory:Set("📂 ✅ All Complete!")
                            lTarget:Set("🎯 Target: —")
                            lOdds:Set("🎲 Odds: —")
                            runningIndex = false
                            break
                        end
                        local completed = runCategory(sorted[1].id, mode)
                        if not completed then break end
                    end
                else
                    local catId = getCatIdFromOption(selectedCategoryOption)
                    if catId then
                        runCategory(catId, mode)
                        if runningIndex then
                            lCategory:Set("📂 ✅ Complete!")
                            lTarget:Set("🎯 Target: —")
                            lOdds:Set("🎲 Odds: —")
                        end
                    end
                    runningIndex = false
                end
                stopLuckPoll()
                setLuckEnabled(false)
                refreshProgress()
            end)
        else
            runningIndex = false
            stopLuckPoll()
            if runIndexThread then
                task.cancel(runIndexThread)
                runIndexThread = nil
            end
            setLuckEnabled(false)
            lTarget:Set("🎯 Target: —")
            lOdds:Set("🎲 Odds: —")
            lLuck:Set("🍀 Luck: —")
            lCategory:Set("📂 Category: —")
            refreshProgress()
        end
    end,
})

GameTab:CreateSection("Settings")
local categoryOptions = buildCategoryOptions()
selectedCategoryOption = categoryOptions[1]

GameTab:CreateDropdown({
    Name = "Category",
    Options = categoryOptions,
    CurrentOption = { categoryOptions[1] },
    MultipleOptions = false,
    Flag = "IndexCategory",
    Callback = function(option)
        selectedCategoryOption = type(option) == "table" and option[1] or option
    end,
})

GameTab:CreateDropdown({
    Name = "Roll Mode",
    Options = { "🌱 Easiest First", "🎯 Rarest First" },
    CurrentOption = { "🌱 Easiest First" },
    MultipleOptions = false,
    Flag = "IndexRollMode",
    Callback = function() end,
})

GameTab:CreateSection("Status")
lTarget   = GameTab:CreateLabel("🎯 Target: —")
lOdds     = GameTab:CreateLabel("🎲 Odds: —")
lLuck     = GameTab:CreateLabel("🍀 Luck: —")
lCategory = GameTab:CreateLabel("📂 Category: —")

GameTab:CreateSection("Index Progress")
local total = getTotalSlimes()
for _, catId in ipairs(CATEGORY_IDS) do
    local label = catId:sub(1,1):upper() .. catId:sub(2)
    local count = getUnlockedCount(catId)
    progressLabels[catId] = GameTab:CreateLabel(string.format("📊 %s: %d / %d", label, count, total))
end

GameTab:CreateSection("Move to Enemy")

local farmSettings = {
    TeleportStyle = "Teleport",
    TargetPriorities = { ["Most Coins & Goop"] = true },
    AutoFarm = false,
    MutationFilter = "Any",
}
local FARM_RANGE = 50
local farmCache = {}
local farmLastCache = 0
local farmCurrentTarget = nil
local farmTweenConn = nil

local function getEnemyRoot(enemy)
    return enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildWhichIsA("BasePart")
end

local function getEnemyMutation(enemy)
    for _, mut in ipairs({"inverted", "huge", "shiny", "big"}) do
        local ok, val = pcall(function() return enemy:GetAttribute(mut) end)
        if ok and val then return mut end
        if enemy:FindFirstChild(mut) then return mut end
        local m = enemy:FindFirstChild("Mutation")
        if m and m.Value == mut then return mut end
        if enemy.Name:lower():find(mut) then return mut end
    end
    return nil
end

local function getEnemyValue(enemy, rootPart)
    local coins = enemy:GetAttribute("reward") or enemy:GetAttribute("coins") or enemy:GetAttribute("coinReward")
    local goop = enemy:GetAttribute("goop") or enemy:GetAttribute("goopReward")
    local health = enemy:GetAttribute("health") or enemy:GetAttribute("maxHealth")
    local humanoid = enemy:FindFirstChildWhichIsA("Humanoid")
    if humanoid then health = health or humanoid.MaxHealth end
    local valueObj = enemy:FindFirstChild("Reward") or enemy:FindFirstChild("Coins") or enemy:FindFirstChild("Value")
    if valueObj and valueObj:IsA("NumberValue") then coins = coins or valueObj.Value end
    local goopObj = enemy:FindFirstChild("Goop") or enemy:FindFirstChild("GoopReward")
    if goopObj and goopObj:IsA("NumberValue") then goop = goop or goopObj.Value end
    local healthObj = enemy:FindFirstChild("Health") or enemy:FindFirstChild("MaxHealth")
    if healthObj and healthObj:IsA("NumberValue") then health = health or healthObj.Value end
    local dist = math.huge
    local char = player.Character
    if char and rootPart then
        local rp = char:FindFirstChild("HumanoidRootPart")
        if rp then dist = (rootPart.Position - rp.Position).Magnitude end
    end
    return {
        coins = coins or 0,
        goop = goop or 0,
        health = health or 0,
        mutation = getEnemyMutation(enemy),
        distance = dist,
    }
end

local function isEnemyAlive(enemy)
    if not enemy or not enemy.Parent then return false end
    local humanoid = enemy:FindFirstChildWhichIsA("Humanoid")
    if humanoid and humanoid.Health <= 0 then return false end
    local hp = enemy:GetAttribute("health") or enemy:GetAttribute("currentHealth")
    if hp and hp <= 0 then return false end
    return true
end

local function refreshEnemyCache()
    if tick() - farmLastCache < 2 then return end
    farmLastCache = tick()
    farmCache = {}
    local container = getGameplayContainer()
    if not container then return end
    local enemyFolder = container:FindFirstChild("Enemies")
    if not enemyFolder then return end
    for _, enemy in ipairs(enemyFolder:GetChildren()) do
        if enemy:IsA("Model") then
            table.insert(farmCache, enemy)
        end
    end
end

local function matchesMutationFilter(enemy)
    if farmSettings.MutationFilter == "Any" then return true end
    return getEnemyMutation(enemy) == farmSettings.MutationFilter:lower()
end

local function computeScores()
    local char = player.Character
    if not char then return {} end
    local rp = char:FindFirstChild("HumanoidRootPart")
    if not rp then return {} end
    local entries = {}
    for _, enemy in ipairs(farmCache) do
        if not isEnemyAlive(enemy) then continue end
        if not matchesMutationFilter(enemy) then continue end
        local root = getEnemyRoot(enemy)
        if not root then continue end
        local dist = (root.Position - rp.Position).Magnitude
        if dist > FARM_RANGE then continue end
        local data = getEnemyValue(enemy, root)
        table.insert(entries, { enemy = enemy, data = data })
    end
    if #entries == 0 then return {} end
    local maxCoins, maxGoop, maxHealth, maxDist = 0, 0, 0, 0
    for _, e in ipairs(entries) do
        if e.data.coins > maxCoins then maxCoins = e.data.coins end
        if e.data.goop > maxGoop then maxGoop = e.data.goop end
        if e.data.health > maxHealth then maxHealth = e.data.health end
        if e.data.distance > maxDist then maxDist = e.data.distance end
    end
    local scores = {}
    local priorities = farmSettings.TargetPriorities
    for _, e in ipairs(entries) do
        local s = 0
        if priorities["Most Coins & Goop"] then
            local coinsNorm = maxCoins > 0 and e.data.coins / maxCoins or 0
            local goopNorm = maxGoop > 0 and e.data.goop / maxGoop or 0
            s = s + (coinsNorm + goopNorm) / 2
        end
        if priorities["Closest"] then s = s + (maxDist > 0 and 1 - e.data.distance / maxDist or 0) end
        if priorities["Lowest HP"] then s = s + (maxHealth > 0 and 1 - e.data.health / maxHealth or 0) end
        if priorities["Mutations Only"] then s = s + (e.data.mutation and 1 or 0) end
        scores[e.enemy] = s
    end
    return scores
end

local function selectTarget()
    local scores = computeScores()
    local best, bestScore = nil, -math.huge
    for enemy, score in pairs(scores) do
        if score > bestScore then
            bestScore = score
            best = enemy
        end
    end
    return best
end

local function moveToEnemy(enemy)
    local char = player.Character
    if not char then return end
    local root = getEnemyRoot(enemy)
    if not root then return end
    local target = root.CFrame * CFrame.new(0, 3, 0)
    if farmSettings.TeleportStyle == "Teleport" then
        char:PivotTo(target)
    elseif farmSettings.TeleportStyle == "Tween" then
        if farmTweenConn then farmTweenConn:Disconnect() farmTweenConn = nil end
        local start = char:GetPivot()
        local startTime = tick()
        local duration = 0.25
        farmTweenConn = RunService.RenderStepped:Connect(function()
            local alpha = math.clamp((tick() - startTime) / duration, 0, 1)
            char:PivotTo(start:Lerp(target, alpha))
            if alpha >= 1 then farmTweenConn:Disconnect() farmTweenConn = nil end
        end)
    end
end

RunService.Heartbeat:Connect(function()
    refreshEnemyCache()
    if not farmSettings.AutoFarm then
        farmCurrentTarget = nil
        return
    end
    if farmCurrentTarget and isEnemyAlive(farmCurrentTarget) and farmCurrentTarget.Parent then
        return
    end
    local newTarget = selectTarget()
    if newTarget and newTarget ~= farmCurrentTarget then
        farmCurrentTarget = newTarget
        moveToEnemy(farmCurrentTarget)
    end
end)

GameTab:CreateDropdown({
    Name = "Teleport Style",
    Options = {"Teleport", "Tween"},
    CurrentOption = {"Teleport"},
    MultipleOptions = false,
    Flag = "FarmTeleportStyle",
    Callback = function(option) farmSettings.TeleportStyle = option[1] end,
})

GameTab:CreateDropdown({
    Name = "Target Priority",
    Options = {"Most Coins & Goop", "Closest", "Lowest HP", "Mutations Only"},
    CurrentOption = {"Most Coins & Goop"},
    MultipleOptions = true,
    Flag = "FarmTargetPriority",
    Callback = function(options)
        farmSettings.TargetPriorities = {}
        for _, opt in ipairs(options) do
            farmSettings.TargetPriorities[opt] = true
        end
    end,
})

GameTab:CreateDropdown({
    Name = "Mutation Filter",
    Options = {"Any", "Inverted", "Huge", "Shiny", "Big"},
    CurrentOption = {"Any"},
    MultipleOptions = true,
    Flag = "FarmMutationFilter",
    Callback = function(option) farmSettings.MutationFilter = option[1] end,
})

GameTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Callback = function(value)
        farmSettings.AutoFarm = value
        if not value then farmCurrentTarget = nil end
    end,
})

MiscTab:CreateSection("Codes & Rewards")

MiscTab:CreateToggle({
    Name = "Auto Redeem Codes",
    CurrentValue = false,
    Flag = "MiscRedeemCodes",
    Callback = function(enabled)
        if enabled then
            task.spawn(function()
                local codes = { "gullible", "test", "goingBananas", "AAisComing", "Sliming" }
                while Rayfield.Flags.MiscRedeemCodes and Rayfield.Flags.MiscRedeemCodes.CurrentValue do
                    for _, code in ipairs(codes) do
                        CodeRemote:InvokeServer("redeem", code)
                        task.wait(0.5)
                    end
                    task.wait(300)
                end
            end)
        end
    end,
})

MiscTab:CreateToggle({
    Name = "Auto Claim Offline Earnings",
    CurrentValue = false,
    Flag = "MiscClaimOffline",
    Callback = function(enabled)
        if enabled then
            task.spawn(function()
                while Rayfield.Flags.MiscClaimOffline and Rayfield.Flags.MiscClaimOffline.CurrentValue do
                    OfflineEarningsRemote:InvokeServer("requestClaim")
                    task.wait(60)
                end
            end)
        end
    end,
})

MiscTab:CreateToggle({
    Name = "Auto Claim Index Rewards",
    CurrentValue = false,
    Flag = "MiscClaimIndex",
    Callback = function(enabled)
        if enabled then
            task.spawn(function()
                local function claimRewards()
                    local idx = DataClient:get("index")
                    if not idx or not idx.categories then return end
                    for catName, rewards in pairs(IndexRewards) do
                        local catInfo = idx.categories[catName]
                        if catInfo then
                            local unlocked = catInfo.unlocked or {}
                            local unlockedCount = 0
                            for _, v in pairs(unlocked) do if v == true then unlockedCount = unlockedCount + 1 end end
                            local claimed = catInfo.claimedRewards or {}
                            for _, reward in ipairs(rewards) do
                                if unlockedCount >= reward.req and not claimed[reward.key] then
                                    IndexRemote:InvokeServer("requestClaimReward", catName)
                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                end
                while Rayfield.Flags.MiscClaimIndex and Rayfield.Flags.MiscClaimIndex.CurrentValue do
                    claimRewards()
                    task.wait(60)
                end
            end)
        end
    end,
})

MiscTab:CreateSection("Consumables")

MiscTab:CreateToggle({
    Name = "Auto Use Potions",
    CurrentValue = false,
    Flag = "MiscUsePotions",
    Callback = function(enabled)
        if enabled then
            task.spawn(function()
                while task.wait(1) and Rayfield.Flags.MiscUsePotions and Rayfield.Flags.MiscUsePotions.CurrentValue do
                    local boosts = DataClient:get("boosts") or {}
                    local potionTypes = Rayfield.Flags.MiscPotionTypes and Rayfield.Flags.MiscPotionTypes.CurrentOption or {}
                    for _, kind in ipairs(potionTypes) do
                        if boosts[kind] and (boosts[kind].amount or 0) > 0 then
                            BoostRemote:InvokeServer("requestUseBoost", kind)
                        end
                    end
                end
            end)
        end
    end,
})

MiscTab:CreateDropdown({
    Name = "Potion Types",
    Options = BoostKinds,
    CurrentOption = {BoostKinds[1]},
    MultipleOptions = true,
    Flag = "MiscPotionTypes",
    Callback = function() end,
})

MiscTab:CreateToggle({
    Name = "Auto Use Dice & Items",
    CurrentValue = false,
    Flag = "MiscUseDice",
    Callback = function(enabled)
        if enabled then
            task.spawn(function()
                while task.wait(1) and Rayfield.Flags.MiscUseDice and Rayfield.Flags.MiscUseDice.CurrentValue do
                    local items = DataClient:get("items") or {}
                    local diceTypesSelected = Rayfield.Flags.MiscDiceTypes and Rayfield.Flags.MiscDiceTypes.CurrentOption or {}
                    for _, diceName in ipairs(diceTypesSelected) do
                        local diceId = DiceIdsByName[diceName]
                        if diceId and (items[diceId] or 0) > 0 then
                            InventoryRemote:InvokeServer("requestUseItem", diceId)
                        end
                    end
                end
            end)
        end
    end,
})

local diceOptions = {}
for _, id in ipairs(SpecialDiceIds) do
    table.insert(diceOptions, DiceNamesById[id])
end
MiscTab:CreateDropdown({
    Name = "Dice & Item Types",
    Options = diceOptions,
    CurrentOption = {diceOptions[1]},
    MultipleOptions = true,
    Flag = "MiscDiceTypes",
    Callback = function() end,
})

WebhookTab:CreateSection("Warning")
WebhookTab:CreateParagraph({
    Title = "⚠️ WARNING",
    Content = "WEBHOOK WILL ONLY WORK IF YOU MANUALLY ENABLE AUTO ROLL IN GAME\nPLEASE DISABLE FAST ROLL (from Farming Tab) if you have it enabled"
})

WebhookTab:CreateSection("Configuration")

WebhookTab:CreateToggle({
    Name = "Enable Webhook",
    CurrentValue = false,
    Flag = "WebhookEnabled",
    Callback = function() end,
})

local savedWebhookUrl = ""
WebhookTab:CreateInput({
    Name = "Webhook URL",
    CurrentValue = "",
    PlaceholderText = "Paste your Discord webhook URL",
    RemoveTextAfterFocusLost = false,
    Flag = "WebhookURLDisplay",
    Callback = function(url)
        if url and url:match("^https://discord") then
            savedWebhookUrl = url
            local masked = string.rep("•", #url - 6) .. url:sub(-6)
            Rayfield:Notify({Title = "Webhook", Content = "URL saved: " .. masked, Duration = 3})
        end
    end,
})

WebhookTab:CreateInput({
    Name = "User ID",
    CurrentValue = "",
    PlaceholderText = "Discord User ID",
    RemoveTextAfterFocusLost = false,
    Flag = "WebhookUserID",
    Callback = function() end,
})

WebhookTab:CreateInput({
    Name = "Minimum Chance To Send",
    CurrentValue = "",
    PlaceholderText = "e.g. 1B or 1000000000",
    RemoveTextAfterFocusLost = false,
    Flag = "WebhookMinChance",
    Callback = function() end,
})

WebhookTab:CreateButton({
    Name = "Test Webhook",
    Callback = function()
        if savedWebhookUrl == "" then
            Rayfield:Notify({Title = "Webhook", Content = "Please paste a Webhook URL first.", Duration = 4})
            return
        end
        if not Rayfield.Flags.WebhookEnabled.CurrentValue then
            Rayfield:Notify({Title = "Webhook", Content = "Please enable Webhook first.", Duration = 4})
            return
        end
        local userId = Rayfield.Flags.WebhookUserID.CurrentValue
        local mention = formatMention(userId)
        local response = request({
            Url = savedWebhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                content = mention,
                username = "Cactus Hub",
                avatar_url = WEBHOOK_AVATAR,
                embeds = {{
                    title = "✅ Webhook Test",
                    description = "Your webhook is working correctly!",
                    color = 0x2ecc71,
                }}
            })
        })
        if not response then
            Rayfield:Notify({Title = "Webhook", Content = "Failed to send test.", Duration = 4})
        else
            Rayfield:Notify({Title = "Webhook", Content = "Test sent successfully!", Duration = 4})
        end
    end,
})

WebhookTab:CreateSection("Filters")

WebhookTab:CreateToggle({
    Name = "Send All Slimes",
    CurrentValue = false,
    Flag = "WebhookSendAll",
    Callback = function() end,
})

WebhookTab:CreateToggle({
    Name = "Send New Slimes Only",
    CurrentValue = false,
    Flag = "WebhookSendNew",
    Callback = function() end,
})

WebhookTab:CreateToggle({
    Name = "Send Mutated Slimes",
    CurrentValue = false,
    Flag = "WebhookSendMutated",
    Callback = function() end,
})

WebhookTab:CreateDropdown({
    Name = "Mutations Filter",
    Options = {"All", "Shiny", "Big", "Huge", "Inverted"},
    CurrentOption = {"All"},
    MultipleOptions = true,
    Flag = "WebhookMutations",
    Callback = function() end,
})

local function webhookMutationFilter(mutations)
    local selected = Rayfield.Flags.WebhookMutations and Rayfield.Flags.WebhookMutations.CurrentOption or {"All"}
    local allSelected = false
    for _, opt in ipairs(selected) do
        if opt == "All" then allSelected = true; break end
    end
    if allSelected then return true end
    if not mutations then return false end
    local mutType = getMutationDisplayName(mutations)
    for _, opt in ipairs(selected) do
        if string.lower(opt) == mutType then return true end
    end
    return false
end

local lastRollsHash = nil
task.spawn(function()
    while true do
        task.wait(0.1)
        if not Rayfield.Flags.WebhookEnabled or not Rayfield.Flags.WebhookEnabled.CurrentValue then
        elseif savedWebhookUrl ~= "" then
            if not RollSlice or type(RollSlice.rollResults) ~= "function" then
                task.wait(1)
            else
                local rollResults = RollSlice.rollResults()
                if type(rollResults) ~= "table" or #rollResults == 0 then
                    task.wait(0.5)
                else
                    local hash = encodeRollResults(rollResults)
                    if hash ~= lastRollsHash then
                        lastRollsHash = hash
                        local sendAll = Rayfield.Flags.WebhookSendAll and Rayfield.Flags.WebhookSendAll.CurrentValue
                        local sendNew = Rayfield.Flags.WebhookSendNew and Rayfield.Flags.WebhookSendNew.CurrentValue
                        local sendMutated = Rayfield.Flags.WebhookSendMutated and Rayfield.Flags.WebhookSendMutated.CurrentValue
                        local minChanceStr = Rayfield.Flags.WebhookMinChance.CurrentValue
                        local minChanceNum = parseChanceString(minChanceStr)
                        for _, roll in ipairs(rollResults) do
                            local slimeData = findSlimeDataFromRoll(roll)
                            if slimeData then
                                local slimeId = tostring(slimeData.id or "")
                                if slimeId ~= "" then
                                    local mutations = type(slimeData.mutations) == "table" and next(slimeData.mutations) and slimeData.mutations or nil
                                    local isMutated = mutations ~= nil
                                    local isNew = isNewIndexEntry(slimeId, mutations)
                                    local shouldSend = sendAll or (sendNew and isNew) or (sendMutated and isMutated and webhookMutationFilter(mutations))
                                    if shouldSend and minChanceNum then
                                        local ok, slimeDef = pcall(Slimes.getSlime, slimeId)
                                        if not ok then slimeDef = nil end
                                        local odds = slimeDef and slimeDef.odds or 0
                                        local chanceValue = odds > 0 and (1 / odds) or 0
                                        if chanceValue > minChanceNum then
                                            shouldSend = false
                                        end
                                    end
                                    if shouldSend then
                                        local userId = Rayfield.Flags.WebhookUserID.CurrentValue
                                        local uniqueId = hash .. "_" .. slimeId .. "_" .. tostring(mutations and Mutations.getIds(mutations) or "")
                                        local ok2, slimeDef2 = pcall(Slimes.getSlime, slimeId)
                                        if not ok2 then slimeDef2 = nil end
                                        task.spawn(sendWebhook, slimeId, slimeDef2, mutations, savedWebhookUrl, userId, uniqueId)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

SettingsTab:CreateSection("System")

SettingsTab:CreateToggle({
    Name = "Anti Kick",
    CurrentValue = false,
    Flag = "SettingsAntiKick",
    Callback = function() end,
})

SettingsTab:CreateToggle({
    Name = "Auto Rejoin On Disconnect",
    CurrentValue = false,
    Flag = "SettingsAutoRejoin",
    Callback = function() end,
})

SettingsTab:CreateToggle({
    Name = "Auto Friend Requests",
    CurrentValue = false,
    Flag = "AutoFriend",
    Callback = function(value)
        if value then
            task.spawn(function()
                while Rayfield.Flags.AutoFriend and Rayfield.Flags.AutoFriend.CurrentValue do
                    for _, p in ipairs(Players:GetChildren()) do
                        player:RequestFriendship(p)
                        task.wait(1)
                    end
                    task.wait(600)
                end
            end)
        end
    end,
})
SettingsTab:CreateLabel("( I'm not sure if it works )")

SettingsTab:CreateSection("Advanced Optimization")

local optConnections = {}
local CHEAP_MATERIAL = Enum.Material.SmoothPlastic
local OPT_VISUAL_TYPES = {
    ParticleEmitter=true, Trail=true, Beam=true, Fire=true,
    Smoke=true, Sparkles=true, SurfaceAppearance=true,
    Highlight=true, SelectionBox=true, SelectionSphere=true, Atmosphere=true,
}
local OPT_LIGHTING_TYPES = {
    BloomEffect=true, BlurEffect=true, ColorCorrectionEffect=true,
    DepthOfFieldEffect=true, SunRaysEffect=true, PixelateEffect=true,
    FilmGrainEffect=true, Atmosphere=true, Sky=true,
}

local function optSafeDestroy(obj)
    if obj and obj.Parent then obj:Destroy() end
end

local function optTryHidden(obj, prop, val)
    if sethiddenproperty then sethiddenproperty(obj, prop, val) end
end

local function optApplyInstance(v)
    local cn = v.ClassName
    if OPT_VISUAL_TYPES[cn] then optSafeDestroy(v) return end
    if cn == "Decal" or cn == "Texture" then v.Transparency = 1 return end
    if cn == "SpecialMesh" then v.TextureId = "" return end
    if cn == "PointLight" or cn == "SpotLight" or cn == "SurfaceLight" then v.Enabled = false return end
    if v:IsA("BasePart") then
        v.CastShadow = false
        v.Reflectance = 0
        v.Material = CHEAP_MATERIAL
        if not v:IsA("TriangleMeshPart") then
            optTryHidden(v, "RenderFidelity", 2)
        end
    end
end

local function optLighting()
    local L = game:GetService("Lighting")
    L.GlobalShadows = false
    L.FogEnd = 100000
    L.FogStart = 100000
    L.Brightness = 1
    L.Ambient = Color3.fromRGB(180, 180, 180)
    L.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
    L.ShadowSoftness = 0
    L.EnvironmentDiffuseScale = 0
    L.EnvironmentSpecularScale = 0
    optTryHidden(L, "Technology", 0)
    for _, c in ipairs(L:GetChildren()) do
        if OPT_LIGHTING_TYPES[c.ClassName] then c:Destroy() end
    end
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        local clouds = terrain:FindFirstChildOfClass("Clouds")
        if clouds then clouds:Destroy() end
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 1
    end
    table.insert(optConnections, L.ChildAdded:Connect(function(child)
        if OPT_LIGHTING_TYPES[child.ClassName] then
            task.defer(child.Destroy, child)
        end
    end))
end

local function optCharacter(character)
    if not character then return end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        hum.NameDisplayDistance = 0
        hum.HealthDisplayDistance = 0
    end
    for _, v in ipairs(character:GetDescendants()) do
        local cn = v.ClassName
        if OPT_VISUAL_TYPES[cn] then
            v:Destroy()
        elseif v:IsA("BasePart") then
            v.CastShadow = false
            v.Reflectance = 0
            v.Material = CHEAP_MATERIAL
        elseif cn == "Decal" or cn == "Texture" then
            v.Transparency = 1
        elseif cn == "SpecialMesh" then
            v.TextureId = ""
        elseif cn == "Accessory" then
            v:Destroy()
        end
    end
end

local function optWorkspaceScan()
    local Camera = workspace.CurrentCamera
    local charSet = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then charSet[p.Character] = true end
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj ~= Camera and not charSet[obj] then
            for _, v in ipairs(obj:GetDescendants()) do
                optApplyInstance(v)
            end
        end
    end
    table.insert(optConnections, workspace.ChildAdded:Connect(function(obj)
        if obj == workspace.CurrentCamera then return end
        task.defer(function()
            for _, v in ipairs(obj:GetDescendants()) do
                optApplyInstance(v)
            end
        end)
    end))
end

local function optPlayers()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then optCharacter(p.Character) end
        table.insert(optConnections, p.CharacterAdded:Connect(function(char)
            task.defer(optCharacter, char)
        end))
    end
    table.insert(optConnections, Players.PlayerAdded:Connect(function(p)
        table.insert(optConnections, p.CharacterAdded:Connect(function(char)
            task.defer(optCharacter, char)
        end))
    end))
end

local function optCamera()
    local cam = workspace.CurrentCamera
    if not cam then return end
    cam.FieldOfView = 70
    for _, v in ipairs(cam:GetChildren()) do
        if OPT_LIGHTING_TYPES[v.ClassName] then v:Destroy() end
    end
end

local function optGUI()
    local sg = game:GetService("StarterGui")
    sg:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    sg:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    sg:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
end

local function optRenderQuality()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel01
    local rs = game:GetService("RunService")
    rs:Set3dRenderingEnabled(false)
    task.wait(0.1)
    rs:Set3dRenderingEnabled(true)
end

local function cleanOptConnections()
    for _, c in ipairs(optConnections) do c:Disconnect() end
    table.clear(optConnections)
end

local optGPUToggle, optParticlesToggle, optFireToggle, optGCToggle, optIntenseToggle, optHideDamageToggle, optMainToggle
local updatingOptimizations = false

local function setAllOptimizations(value)
    if optGPUToggle then optGPUToggle:Set(value) end
    if optParticlesToggle then optParticlesToggle:Set(value) end
    if optFireToggle then optFireToggle:Set(value) end
    if optGCToggle then optGCToggle:Set(value) end
    if optIntenseToggle then optIntenseToggle:Set(value) end
    if optHideDamageToggle then optHideDamageToggle:Set(value) end
end

optMainToggle = SettingsTab:CreateToggle({
    Name = "Optimize All",
    CurrentValue = false,
    Flag = "OptimizeAll",
    Callback = function(Value)
        if updatingOptimizations then return end
        setAllOptimizations(Value)
    end,
})

optGPUToggle = SettingsTab:CreateToggle({
    Name = "Optimize GPU (Low Graphics)",
    CurrentValue = false,
    Flag = "OptimizeGPU",
    Callback = function(Value)
        if updatingOptimizations then return end
        if Value then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            local L = game:GetService("Lighting")
            L.GlobalShadows = false
            L.EnvironmentDiffuseScale = 0
            L.EnvironmentSpecularScale = 0
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CastShadow = false
                    v.Reflectance = 0
                    v.Material = CHEAP_MATERIAL
                end
            end
            local rs = game:GetService("RunService")
            rs:Set3dRenderingEnabled(false)
            task.wait(0.1)
            rs:Set3dRenderingEnabled(true)
        end
    end,
})

optParticlesToggle = SettingsTab:CreateToggle({
    Name = "Remove All Particles & Effects",
    CurrentValue = false,
    Flag = "OptimizeParticles",
    Callback = function(Value)
        if updatingOptimizations then return end
        if Value then
            for _, v in ipairs(game:GetDescendants()) do
                if OPT_VISUAL_TYPES[v.ClassName] then
                    v:Destroy()
                end
            end
        end
    end,
})

optFireToggle = SettingsTab:CreateToggle({
    Name = "Remove Fire Effects",
    CurrentValue = false,
    Flag = "FireOptimization",
    Callback = function(Value)
        if updatingOptimizations then return end
        if Value then
            for _, v in ipairs(game:GetDescendants()) do
                if v:IsA("Fire") then v:Destroy() end
            end
        end
    end,
})

optGCToggle = SettingsTab:CreateToggle({
    Name = "Lua GC (Memory Cleaner)",
    CurrentValue = false,
    Flag = "LuaGC",
    Callback = function(Value)
        if updatingOptimizations then return end
        if Value then
            if _G.__memoryCleaner then
                _G.__memoryCleaner:Disconnect()
            end
            _G.__memoryCleaner = RunService.Heartbeat:Connect(function()
                gcinfo()
            end)
        else
            if _G.__memoryCleaner then
                _G.__memoryCleaner:Disconnect()
                _G.__memoryCleaner = nil
            end
        end
    end,
})

optIntenseToggle = SettingsTab:CreateToggle({
    Name = "Intense Optimization",
    CurrentValue = false,
    Flag = "IntenseOptimization",
    Callback = function(Value)
        if updatingOptimizations then return end
        if Value then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/Optimization.lua"))()
        end
    end,
})

local function getDamageUIParent()
    local playerGui = player.PlayerGui
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui.Name:find("Damage") or gui.Name:find("Combat") then
            return gui
        end
    end
    return nil
end

optHideDamageToggle = SettingsTab:CreateToggle({
    Name = "Hide Damage UI",
    CurrentValue = false,
    Flag = "HideDamageUI",
    Callback = function(Value)
        if updatingOptimizations then return end
        local container = getDamageUIParent()
        if container then
            container.Visible = not Value
        else
            task.spawn(function()
                while not getDamageUIParent() and task.wait(0.5) do end
                local cont = getDamageUIParent()
                if cont then cont.Visible = not Value end
            end)
        end
    end,
})

local function safeNum(...)
    local data = DataClient._data._data
    local cur = data
    for _, k in ipairs({...}) do
        if type(cur) ~= "table" then return 0 end
        cur = cur[k]
        if cur == nil then return 0 end
    end
    return tonumber(cur) or 0
end

local SUFFIXES = {
    {1e24,"Sp"},{1e21,"Sx"},{1e18,"Qn"},{1e15,"Qd"},
    {1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"},
}

local function fmt(n)
    n = tonumber(n) or 0
    for _, p in ipairs(SUFFIXES) do
        if n >= p[1] then
            local s = string.format("%.2f", n / p[1]):gsub("%.?0+$","")
            return s .. p[2]
        end
    end
    return tostring(math.floor(n))
end

local function fmtTime(s)
    s = math.floor(tonumber(s) or 0)
    local d = math.floor(s/86400)
    local h = math.floor((s%86400)/3600)
    local m = math.floor((s%3600)/60)
    if d > 0 then return d.."d "..h.."h "..m.."m"
    elseif h > 0 then return h.."h "..m.."m"
    elseif m > 0 then return m.."m "..math.floor(s%60).."s"
    else return math.floor(s%60).."s" end
end

local function countKeys(t)
    if type(t) ~= "table" then return 0 end
    local c = 0; for _ in pairs(t) do c = c + 1 end; return c
end

local function getBestRoll()
    local rd = DataClient:get("stats") and DataClient:get("stats").rarestRoll
    if type(rd) ~= "table" then return "None", "N/A" end
    local slimeData = rd.slimeData
    if type(slimeData) ~= "table" then return "None", "N/A" end
    local id = tostring(slimeData.id or "?")
    local muts = slimeData.mutations
    local prefix = ""
    if type(muts) == "table" then
        if muts.inverted then prefix = "Inverted "
        elseif muts.shiny and muts.huge then prefix = "Shiny Huge "
        elseif muts.shiny and muts.big then prefix = "Shiny Big "
        elseif muts.huge then prefix = "Huge "
        elseif muts.shiny then prefix = "Shiny "
        elseif muts.big then prefix = "Big "
        end
    end
    local name = prefix .. id:sub(1,1):upper()..id:sub(2)
    local odds = rd.odds or 0
    return name, odds > 0 and ("1 in "..fmt(math.floor(odds))) or "N/A"
end

local function getEquipped()
    local eq = DataClient:get("equipped")
    if type(eq) ~= "table" then return "None" end
    local names = {}
    for i = 1, 7 do
        local v = eq[i]
        if v and type(v) == "string" then
            local clean = v:match("%-(.+)$") or v:gsub("^%.","")
            table.insert(names, clean:sub(1,1):upper()..clean:sub(2))
        end
    end
    return #names > 0 and table.concat(names, ", ") or "None"
end

local function getIndexCounts()
    local cats = DataClient:get("index") and DataClient:get("index").categories
    if type(cats) ~= "table" then return 0,0,0,0,0 end
    local function c(cat)
        local t = cats[cat]
        return type(t)=="table" and countKeys(t.unlocked or {}) or 0
    end
    return c("basic"), c("big"), c("shiny"), c("huge"), c("inverted")
end

local function getTotalInv()
    local inv = DataClient:get("inventory")
    if type(inv) ~= "table" then return 0 end
    local total = 0
    for _, v in pairs(inv) do if type(v)=="number" then total = total + v end end
    return total
end

local function getUniqueSpecies()
    local inv = DataClient:get("inventory")
    if type(inv) ~= "table" then return 0 end
    local seen = {}
    local count = 0
    for k in pairs(inv) do
        if type(k)=="string" and not k:match("^%.") then
            local base = k:match("%-(.+)$") or k
            if not seen[base] then seen[base]=true; count = count + 1 end
        end
    end
    return count
end

local sessionStart = os.clock()
local startRolls   = safeNum("stats","rolls")
local startKills   = safeNum("stats","kills")
local startCoins   = safeNum("coins")
local startGoop    = safeNum("goop")

local prevRolls = startRolls
local prevCoins = startCoins
local prevGoop  = startGoop
local lastWin   = os.clock()

local windowRPS, windowCPS, windowGPS = nil, nil, nil
local lastRollMove = os.clock()
local lastCoinMove = os.clock()
local lastGoopMove = os.clock()
local STALE = 60

task.spawn(function()
    while true do
        task.wait(10)
        local now = os.clock()
        local dt = math.max(1, now - lastWin)
        lastWin = now
        local r = safeNum("stats","rolls")
        local c = safeNum("coins")
        local g = safeNum("goop")
        local dr = math.max(0, r - prevRolls)
        local dc = math.max(0, c - prevCoins)
        local dg = math.max(0, g - prevGoop)
        if dr > 0 then windowRPS = dr/dt; lastRollMove = now end
        if dc > 0 then windowCPS = dc/dt; lastCoinMove = now end
        if dg > 0 then windowGPS = dg/dt; lastGoopMove = now end
        prevRolls = r; prevCoins = c; prevGoop = g
    end
end)

local function getRate(windowVal, lastMove, startVal, curVal)
    local now = os.clock()
    local elapsed = math.max(1, now - sessionStart)
    if (now - lastMove) > STALE then return 0 end
    if windowVal and windowVal > 0 then return windowVal end
    local gain = math.max(0, curVal - startVal)
    return gain > 0 and (gain / elapsed) or 0
end

local L = {}
local function lbl(key, text) L[key] = StatsTab:CreateLabel(text) end

lbl("sess",        "Session: --  |  Played: --  |  Rebirths: --")
lbl("rolls1",      "Rolls/sec: --  |  Rolls/min: --  |  Rolls/hr: --")
lbl("rolls2",      "Session Rolls: --  |  Lifetime: --")
lbl("coins1",      "Coins/min: --  |  Coins/hr: --")
lbl("coins2",      "Session Coins: --  |  Total Ever: --")
lbl("goop1",       "Goop/min: --  |  Goop/hr: --")
lbl("goop2",       "Session Goop: --  |  Balance: --")
lbl("kills",       "Session Kills: --  |  Lifetime Kills: --")
lbl("best",        "Best Ever: --  |  Odds: --")
lbl("daily",       "Best Today Odds: --")
lbl("prog",        "Zone: --  |  Max Zone: --  |  Roll Currency: --")
lbl("idx1",        "Basic: --  |  Big: --  |  Shiny: --  |  Huge: --  |  Inverted: --")
lbl("inv",         "Total Slimes: --  |  Species: --  |  Crafting: --")
lbl("equipped",    "Equipped: --")

local function updateAll()
    local now = os.clock()
    local elapsed = math.max(1, now - sessionStart)

    local rolls    = safeNum("stats","rolls")
    local kills    = safeNum("stats","kills")
    local coins    = safeNum("coins")
    local goop     = safeNum("goop")
    local timePl   = safeNum("stats","timePlayed")
    local totCoins = safeNum("stats","totalCoins")
    local rebirths = safeNum("rebirths")
    local zone     = safeNum("zone")
    local maxZone  = safeNum("furthestZone")
    local rollCur  = safeNum("rollCurrency")

    local sessRolls = math.max(0, rolls - startRolls)
    local sessKills = math.max(0, kills - startKills)
    local sessCoins = math.max(0, coins - startCoins)
    local sessGoop  = math.max(0, goop  - startGoop)

    local sessH = math.floor(elapsed/3600)
    local sessM = math.floor((elapsed%3600)/60)
    local sessS = math.floor(elapsed%60)

    local rps = getRate(windowRPS, lastRollMove, startRolls, rolls)
    local cps = getRate(windowCPS, lastCoinMove, startCoins, coins)
    local gps = getRate(windowGPS, lastGoopMove, startGoop,  goop)

    local bestName, bestOdds = getBestRoll()
    local dailyOdds = safeNum("stats","dailyRarestRoll","odds")
    local dailyStr  = dailyOdds > 0 and ("1 in "..fmt(math.floor(dailyOdds))) or "N/A"
    local basic, big, shiny, huge, inverted = getIndexCounts()
    local crafting = countKeys(DataClient:get("craftingRecipes") or {})

    L.sess:Set(string.format("Session: %dh%dm%ds  |  Played: %s  |  Rebirths: %s", sessH, sessM, sessS, fmtTime(timePl), fmt(rebirths)))
    L.rolls1:Set(string.format("Rolls/sec: %.2f  |  Rolls/min: %s  |  Rolls/hr: %s", rps, fmt(rps*60), fmt(rps*3600)))
    L.rolls2:Set("Session Rolls: "..fmt(sessRolls).."  |  Lifetime: "..fmt(rolls))
    L.coins1:Set("Coins/min: "..fmt(cps*60).."  |  Coins/hr: "..fmt(cps*3600))
    L.coins2:Set("Session Coins: "..fmt(sessCoins).."  |  Total Ever: "..fmt(totCoins))
    L.goop1:Set("Goop/min: "..fmt(gps*60).."  |  Goop/hr: "..fmt(gps*3600))
    L.goop2:Set("Session Goop: "..fmt(sessGoop).."  |  Balance: "..fmt(goop))
    L.kills:Set("Session Kills: "..fmt(sessKills).."  |  Lifetime Kills: "..fmt(kills))
    L.best:Set("Best Ever: "..bestName.."  |  Odds: "..bestOdds)
    L.daily:Set("Best Today Odds: "..dailyStr)
    L.prog:Set("Zone: "..fmt(zone).."  |  Max Zone: "..fmt(maxZone).."  |  Roll Currency: "..fmt(rollCur))
    L.idx1:Set("Basic: "..basic.."  |  Big: "..big.."  |  Shiny: "..shiny.."  |  Huge: "..huge.."  |  Inverted: "..inverted)
    L.inv:Set("Total Slimes: "..fmt(getTotalInv()).."  |  Species: "..getUniqueSpecies().."  |  Crafting: "..crafting)
    L.equipped:Set("Equipped: "..getEquipped())
end

task.spawn(function()
    while true do
        updateAll()
        task.wait(2)
    end
end)

local CraftingRemote = getRemote("CraftingService")
local RecipesModule = require(Source.Features.Crafting.Recipes)

local function getCraftingData(key)
    return DataClient:get(key)
end

local function getMutationValue(mutId)
    if not Mutations then return 0 end
    local data = Mutations.get(mutId)
    return data and data.value or 0
end

local function getSizeMutations()
    return Mutations and Mutations.sizeMutations or {}
end

local function getModifierMutations()
    return Mutations and Mutations.modifierMutations or {}
end

local function parseUniqueId(uid)
    local base, sizeMut, modMut = uid, nil, nil
    for _, sId in ipairs(getSizeMutations()) do
        local prefix = sId .. "_"
        if base:sub(1, #prefix) == prefix then
            sizeMut = sId
            base = base:sub(#prefix + 1)
            break
        end
    end
    if base:sub(1, 1) == "-" then base = base:sub(2) end
    for _, mId in ipairs(getModifierMutations()) do
        local suffix = "_" .. mId
        if base:sub(-#suffix) == suffix then
            modMut = mId
            base = base:sub(1, -#suffix - 1)
            break
        end
    end
    return base, sizeMut, modMut
end

local function scoreUniqueId(uid)
    local _, sizeMut, modMut = parseUniqueId(uid)
    local score = 0
    if sizeMut then score = score + getMutationValue(sizeMut) * 1000 end
    if modMut then score = score + getMutationValue(modMut) * 100 end
    return score
end

local function getOwnedAmount(data)
    if type(data) == "number" then return math.max(data, 0) end
    if type(data) == "table" then return 1 end
    return 0
end

local function isXpSlime(data)
    return type(data) == "table"
end

local function getEquippedSet()
    local equipped = getCraftingData("equipped") or {}
    local set = {}
    for _, uid in pairs(equipped) do set[uid] = true end
    return set
end

local function getBestSlimeSet()
    local inventory = getCraftingData("inventory") or {}
    local best = nil
    local bestScore = -1
    for uid, data in pairs(inventory) do
        if not isXpSlime(data) then
            local s = scoreUniqueId(uid)
            if s > bestScore then
                bestScore = s
                best = uid
            end
        end
    end
    local set = {}
    if best then set[best] = true end
    return set
end

local function getXpSlimeSet()
    local inventory = getCraftingData("inventory") or {}
    local set = {}
    for uid, data in pairs(inventory) do
        if isXpSlime(data) then set[uid] = true end
    end
    return set
end

local function buildProtectedSet(categories)
    local catSet = {}
    for _, c in ipairs(categories) do catSet[c] = true end
    local protected = {}
    if catSet["Equipped Slimes"] then
        for uid in pairs(getEquippedSet()) do protected[uid] = true end
    end
    if catSet["Best Slime"] then
        for uid in pairs(getBestSlimeSet()) do protected[uid] = true end
    end
    if catSet["Xp Slimes"] then
        for uid in pairs(getXpSlimeSet()) do protected[uid] = true end
    end
    return protected
end

local function getUnlockedRecipeIds()
    if not RecipesModule then return {} end
    local unlocked = getCraftingData("craftingRecipes") or {}
    local all = RecipesModule.getRecipes() or {}
    local result = {}
    for _, recipe in ipairs(all) do
        if unlocked[recipe.id] then
            table.insert(result, recipe.id)
        end
    end
    return result
end

local function getRecipe(id)
    if not RecipesModule then return nil end
    return RecipesModule.getRecipe(id)
end

local function findBestIngredient(baseId, usedCounts, protectedPets)
    local inventory = getCraftingData("inventory") or {}
    local bestUid, bestScore = nil, -1
    for uid, data in pairs(inventory) do
        if not protectedPets[uid] then
            local parsedBase = parseUniqueId(uid)
            if parsedBase == baseId then
                local owned = getOwnedAmount(data)
                local used = usedCounts[uid] or 0
                if owned - used > 0 then
                    local s = scoreUniqueId(uid)
                    if s > bestScore then
                        bestScore = s
                        bestUid = uid
                    end
                end
            end
        end
    end
    return bestUid
end

local craftingState = {
    selectedRecipeIds = {},
    craftAmount = 1,
    autoCraftEnabled = false,
    autoCraftAmount = 1,
    autoCraftThread = nil,
    protectCategories = { "Best Slime", "Equipped Slimes", "Xp Slimes" },
    protectedPets = {},
}

craftingState.protectedPets = buildProtectedSet(craftingState.protectCategories)

local function getMaxCraftsForRecipe(recipeId)
    local recipe = getRecipe(recipeId)
    if not recipe then return 0 end
    local inventory = getCraftingData("inventory") or {}
    local usedCounts = {}
    local maxCrafts = math.huge
    for _, inp in ipairs(recipe.inputs) do
        local bestUid = findBestIngredient(inp.id, usedCounts, craftingState.protectedPets)
        if not bestUid then return 0 end
        usedCounts[bestUid] = (usedCounts[bestUid] or 0) + 1
        local owned = getOwnedAmount(inventory[bestUid])
        local used = usedCounts[bestUid]
        local available = owned - used + 1
        if available < maxCrafts then maxCrafts = available end
    end
    return maxCrafts == math.huge and 0 or maxCrafts
end

local function buildCraftArgsForRecipe(recipeId, amount)
    local recipe = getRecipe(recipeId)
    if not recipe then return nil end
    local ingredientIds = {}
    local usedCounts = {}
    for i, inp in ipairs(recipe.inputs) do
        local uid = findBestIngredient(inp.id, usedCounts, craftingState.protectedPets) or ("-" .. inp.id)
        usedCounts[uid] = (usedCounts[uid] or 0) + 1
        table.insert(ingredientIds, uid)
    end
    return { "requestCraftRecipe", recipeId, ingredientIds, tostring(amount) }
end

local function doCraftAll(amount)
    local results = {}
    for _, recipeId in ipairs(craftingState.selectedRecipeIds) do
        local args = buildCraftArgsForRecipe(recipeId, amount)
        if args then
            local result = CraftingRemote:InvokeServer(table.unpack(args))
            results[recipeId] = result ~= false
        end
    end
    return results
end

local recipeIdsList = getUnlockedRecipeIds()
if #recipeIdsList > 0 then
    craftingState.selectedRecipeIds = { recipeIdsList[1] }
end

GameTab:CreateSection("Recipes")
GameTab:CreateDropdown({
    Name = "Select Recipes to Craft",
    Options = recipeIdsList,
    CurrentOption = { recipeIdsList[1] or "" },
    MultipleOptions = true,
    Flag = "CraftingSelectedRecipes",
    Callback = function(options)
        craftingState.selectedRecipeIds = options
    end,
})

GameTab:CreateSection("Craft")
GameTab:CreateSlider({
    Name = "Craft Amount",
    Range = { 1, 99 },
    Increment = 1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "CraftingAmount",
    Callback = function(val)
        craftingState.craftAmount = val
    end,
})

GameTab:CreateButton({
    Name = "Craft Now",
    Callback = function()
        local results = doCraftAll(craftingState.craftAmount)
        local succeeded, failed = 0, 0
        for _, ok in pairs(results) do
            if ok then succeeded = succeeded + 1 else failed = failed + 1 end
        end
        Rayfield:Notify({
            Title = "Cactus Hub",
            Content = succeeded .. " crafts succeeded" .. (failed > 0 and (", " .. failed .. " failed") or ""),
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

GameTab:CreateSection("Auto Craft")
local autoCraftMax = 1

local function updateAutoCraftMax()
    local minMax = math.huge
    for _, recipeId in ipairs(craftingState.selectedRecipeIds) do
        local maxCrafts = getMaxCraftsForRecipe(recipeId)
        if maxCrafts < minMax then minMax = maxCrafts end
    end
    if minMax == math.huge then autoCraftMax = 1 else autoCraftMax = math.max(1, minMax) end
end

updateAutoCraftMax()

GameTab:CreateSlider({
    Name = "Auto Craft Amount",
    Range = { 1, 99 },
    Increment = 1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "CraftingAutoAmount",
    Callback = function(val)
        craftingState.autoCraftAmount = val
    end,
})

GameTab:CreateToggle({
    Name = "Enable Auto Craft",
    CurrentValue = false,
    Flag = "CraftingAutoToggle",
    Callback = function(enabled)
        craftingState.autoCraftEnabled = enabled
        if enabled then
            updateAutoCraftMax()
            local maxAmount = autoCraftMax
            if craftingState.autoCraftAmount > maxAmount then
                craftingState.autoCraftAmount = maxAmount
            end
            if craftingState.autoCraftThread then task.cancel(craftingState.autoCraftThread) end
            craftingState.autoCraftThread = task.spawn(function()
                while craftingState.autoCraftEnabled do
                    updateAutoCraftMax()
                    local craftAmount = math.min(craftingState.autoCraftAmount, autoCraftMax)
                    if craftAmount > 0 then
                        doCraftAll(craftAmount)
                    end
                    task.wait(5)
                end
            end)
            Rayfield:Notify({
                Title = "Auto Craft",
                Content = "Started - " .. craftingState.autoCraftAmount .. "x per recipe (max " .. autoCraftMax .. ")",
                Duration = 3,
                Image = 4483362458,
            })
        else
            if craftingState.autoCraftThread then
                task.cancel(craftingState.autoCraftThread)
                craftingState.autoCraftThread = nil
            end
            Rayfield:Notify({
                Title = "Auto Craft",
                Content = "Stopped.",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

GameTab:CreateSection("Protected Pets")
GameTab:CreateDropdown({
    Name = "Protect Categories",
    Options = { "Best Slime", "Equipped Slimes", "Xp Slimes" },
    CurrentOption = { "Best Slime", "Equipped Slimes", "Xp Slimes" },
    MultipleOptions = true,
    Flag = "CraftingProtectCategories",
    Callback = function(options)
        craftingState.protectCategories = options
        craftingState.protectedPets = buildProtectedSet(options)
    end,
})

game:GetService("Players").LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

game:GetService("GuiService").ErrorMessageChanged:Connect(function()
    if Rayfield.Flags.SettingsAutoRejoin and Rayfield.Flags.SettingsAutoRejoin.CurrentValue then
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end
end)

Rayfield:LoadConfiguration()
