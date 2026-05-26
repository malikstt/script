loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Rayfield = rayfield

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local function showNotification(title, text, duration)
    duration = duration or 5
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration
    })
end

local request = request or http_request or (http and http.request)
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

task.spawn(function()
    repeat task.wait() until game:IsLoaded()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local VirtualUser = game:GetService("VirtualUser")
    local HttpService = game:GetService("HttpService")

    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local Index = Packages:WaitForChild("_Index")
    local networkerFolder = Index:WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker")
    local remotes = networkerFolder:WaitForChild("_remotes")

    local DataService = require(Packages.DataService).client
    DataService:waitForData()

    local Networker = require(Packages.Networker)

    local InventoryServiceClient = Networker.client.new("InventoryService")
    local XpTransferServiceClient = Networker.client.new("XpTransferService")

    local function getRemote(serviceName)
        local remoteFolder = remotes:FindFirstChild(serviceName) or remotes:WaitForChild(serviceName, 10)
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

    local boostKinds = BoostServiceUtils.getKinds()
    local diceItemIds = SpecialDiceServiceUtils.getInventoryItemIds()

    local diceNameMap = {}
    local nameToDiceId = {}
    for _, id in ipairs(diceItemIds) do
        local def = SpecialDiceServiceUtils.getDefinition(id)
        local name = def and def.name or id
        diceNameMap[id] = name
        nameToDiceId[name] = id
    end

    local function formatNumber(n)
        if type(n) ~= "number" then return tostring(n) end
        local suffixes = {
            {1e24,"Sp"},{1e21,"Sx"},{1e18,"Qn"},{1e15,"Qd"},{1e12,"T"},
            {1e9,"B"},{1e6,"M"},{1e3,"K"}
        }
        for _, s in ipairs(suffixes) do
            if math.abs(n) >= s[1] then
                local v = n / s[1]
                if math.abs(v - math.floor(v)) < 0.01 then
                    return string.format("%d%s", math.floor(v), s[2])
                else
                    return string.format("%.1f%s", v, s[2])
                end
            end
        end
        return tostring(math.floor(n))
    end

    local function getRarityName(odds)
        if not odds or type(odds) ~= "number" or odds <= 0 then return "Unknown" end
        local success, tier = RarityTiers.getTier(odds)
        return (success and tier and tier.name) or "Unknown"
    end

    local function getFirstSlimeFromResult(t)
        if type(t) ~= "table" then return nil end
        for _, v in ipairs(t) do
            if type(v) == "table" and v.id then return v end
        end
        return nil
    end

    local function getResultHash(results)
        if type(results) ~= "table" or #results == 0 then return "empty" end
        local parts = {}
        for i, res in ipairs(results) do
            local slime = getFirstSlimeFromResult(res)
            parts[i] = slime and tostring(slime.id) or tostring(i)
        end
        return #results .. "|" .. table.concat(parts, ",")
    end

    local function getCategoryFromMutations(muts)
        if not muts then return "basic" end
        if muts.inverted then return "inverted" end
        if muts.huge then return "huge" end
        if muts.big then return "big" end
        if muts.shiny then return "shiny" end
        return "basic"
    end

    local function isNewSlime(slimeId, mutations)
        local indexData = DataService:get("index") or {}
        local cats = indexData.categories or {}
        local catData = cats[getCategoryFromMutations(mutations)]
        local unlocked = catData and catData.unlocked or {}
        return not unlocked[slimeId]
    end

    local thumbnailCache = {}
    local function getAssetThumbnail(assetId)
        if not assetId then return nil end
        if thumbnailCache[assetId] then return thumbnailCache[assetId] end
        local resp = request({
            Url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetId .. "&size=420x420&format=Png&isCircular=false",
            Method = "GET"
        })
        if resp and resp.Success then
            local data = HttpService:JSONDecode(resp.Body)
            if data and data.data and data.data[1] then
                thumbnailCache[assetId] = data.data[1].imageUrl
                return thumbnailCache[assetId]
            end
        end
        return nil
    end

    local function getIconSize(mutations)
        if not mutations then return 64 end
        if mutations.huge then return 128 elseif mutations.big then return 96 end
        return 64
    end

    local function getEmbedColor(mutations)
        if not mutations then return 0x3498db end
        if mutations.inverted then return 0x9b59b6
        elseif mutations.huge then return 0xf1c40f
        elseif mutations.big then return 0xe67e22
        elseif mutations.shiny then return 0xf39c12
        end
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

    local sentWebhooks = {}

    local function mentionUser(userId)
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
        local mult = 1
        if mutations then
            if mutations.inverted then mult = mult * (Mutations.getVisualOddsMultiplier(mutations) or 1) end
            if mutations.huge then mult = mult * (Mutations.getVisualOddsMultiplier(mutations) or 1) end
            if mutations.big then mult = mult * (Mutations.getVisualOddsMultiplier(mutations) or 1) end
            if mutations.shiny then mult = mult * (Mutations.getVisualOddsMultiplier(mutations) or 1) end
        end
        local chance = odds > 0 and (1 / odds) * mult or 0
        return chance
    end

    local WEBHOOK_AVATAR = "https://media.discordapp.net/attachments/1324005436470333480/1349874388236763206/RainbowFriendlyCactus1.png?ex=6a1426bd&is=6a12d53d&hm=adc011c12e097b4238f08364c0ffbd6f30c9eff3f51b7706219b6c8cba76932d&=&format=png"

    local function sendWebhook(slimeId, slimeData, mutations, webhookUrl, userId, uniqueId)
        if sentWebhooks[uniqueId] then return end
        sentWebhooks[uniqueId] = true

        local mention = mentionUser(userId)
        local baseName = slimeData and slimeData.name or slimeId
        local displayName = mutations and Mutations.getDisplayName(baseName, mutations) or baseName
        local odds = slimeData and slimeData.odds or nil
        local damage = slimeData and slimeData.damage or 0
        local health = slimeData and slimeData.health or 0
        local visualMult = mutations and Mutations.getVisualOddsMultiplier(mutations) or 1
        local statBonus = mutations and Mutations.getStatBonus(mutations, "damage") or 1
        local effectiveOdds = odds and (odds / visualMult) or nil
        local rarityName = getRarityName(odds)
        local chanceStr = (effectiveOdds and type(effectiveOdds) == "number" and effectiveOdds > 0) and ("1 in " .. formatNumber(math.floor(1 / effectiveOdds + 0.5))) or "N/A"

        local iconAsset = (mutations and mutations.inverted) and (slimeData and slimeData.invertedIcon) or (slimeData and slimeData.image)
        local iconUrl = nil
        if iconAsset and iconAsset ~= "N/A" then
            local idMatch = string.match(tostring(iconAsset), "rbxassetid://(%d+)")
            if idMatch then iconUrl = getAssetThumbnail(idMatch) end
        end

        local mutationList = mutations and Mutations.getIds(mutations) or {}
        local finalDamage = damage * statBonus
        local finalHealth = health * statBonus
        local statsLine = ""
        if finalDamage > 0 and finalHealth > 0 then
            statsLine = string.format("⚔️ %s  ❤️ %s", formatNumber(finalDamage), formatNumber(finalHealth))
        elseif finalDamage > 0 then
            statsLine = string.format("⚔️ %s", formatNumber(finalDamage))
        elseif finalHealth > 0 then
            statsLine = string.format("❤️ %s", formatNumber(finalHealth))
        end

        local stats = DataService:get("stats") or {}
        local totalRolls = stats.rolls or 0
        local totalKills = stats.kills or 0
        local coins = DataService:get("coins") or 0
        local playerName = player and player.Name or "Someone"
        local iconSize = getIconSize(mutations)

        local fields = {
            {name = "Rarity", value = rarityName, inline = true},
            {name = "Chance", value = chanceStr, inline = true},
        }
        if statsLine ~= "" then
            table.insert(fields, {name = "Stats", value = statsLine, inline = true})
        end
        if #mutationList > 0 then
            table.insert(fields, {name = "Mutations", value = table.concat(mutationList, ", "), inline = true})
        end
        table.insert(fields, {name = "💰 Coins", value = formatNumber(coins), inline = true})
        table.insert(fields, {name = "⚔️ Kills", value = formatNumber(totalKills), inline = true})

        local userEmbed = {
            title = "🎲 New Slime Rolled!",
            description = string.format("**||%s||** rolled **%s**!\n\n🎲 **Total Rolls:** %s", playerName, displayName, ordinalSuffix(totalRolls)),
            thumbnail = iconUrl and {url = iconUrl, width = iconSize, height = iconSize} or nil,
            fields = fields,
            color = getEmbedColor(mutations),
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

        if PUBLIC_MINIMUM_CHANCE then
            local rollChance = getOddsValue(odds, mutations)
            if rollChance >= PUBLIC_MINIMUM_CHANCE then
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
                    color = getEmbedColor(mutations),
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
        else
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
                color = getEmbedColor(mutations),
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

    local function getBestSlimeGuid()
        local stats = DataService:get("stats") or {}
        local rarest = stats.rarestRoll
        if not rarest or not rarest.slimeData then return nil end
        local slimeData = rarest.slimeData
        local mutations = slimeData.mutations or {}
        local inventory = DataService:get("inventory") or {}
        for guid, data in pairs(inventory) do
            if type(data) == "table" and data.id == slimeData.id then
                local match = true
                for mutKey, mutVal in pairs(mutations) do
                    if data.mutations and data.mutations[mutKey] ~= mutVal then
                        match = false
                        break
                    end
                end
                if match then return guid end
            end
        end
        return nil
    end

    local function getAllUpgradeIds()
        local ids = {}
        local costs = {}
        local visited = {}
        local function traverse(tree)
            if type(tree) ~= "table" or visited[tree] then return end
            visited[tree] = true
            for k, v in pairs(tree) do
                if type(v) == "table" then
                    if v.cost then
                        table.insert(ids, k)
                        costs[k] = v.cost
                    end
                    traverse(v)
                end
            end
        end
        traverse(UpgradeTree.main)
        return ids, costs
    end

    local gameplayContainer = nil
    local function getGameplayContainer()
        if gameplayContainer and gameplayContainer.Parent then return gameplayContainer end
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name:match("^Gameplay") then
                gameplayContainer = child
                return child
            end
        end
        return nil
    end

    local rayfield
    local rayfieldOk, rayfieldResult = pcall(function()
        local src = game:HttpGet('https://sirius.menu/rayfield')
        local fn = loadstring(src)
        return fn()
    end)
    if rayfieldOk and rayfieldResult then
        rayfield = rayfieldResult
    else
        warn("[CactusHub] Failed to load Rayfield UI, using fallback")
        rayfield = setmetatable({}, {
            __index = function(t, k)
                if k == "Flags" then
                    local flags = setmetatable({}, {
                        __index = function(ft, fk)
                            return { CurrentValue = false, CurrentOption = { "" } }
                        end
                    })
                    return flags
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
        rayfield.Flags = rayfield.Flags or {}
    end

    local window = rayfield:CreateWindow({
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

    local mainTab = window:CreateTab("Main", 138602335586757)
    mainTab:CreateSection("Status")
    local fpsLabel = mainTab:CreateLabel("FPS: Calculating...")
    local pingLabel = mainTab:CreateLabel("Ping: Calculating...")
    local frameCount = 0
    local lastTime = tick()
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = tick()
        if now - lastTime >= 1 then
            fpsLabel:Set("FPS: " .. math.floor(frameCount / (now - lastTime)))
            frameCount = 0
            lastTime = now
        end
    end)
    task.spawn(function()
        while true do
            local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            pingLabel:Set("Ping: " .. math.floor(ping) .. "ms")
            task.wait(1)
        end
    end)
    mainTab:CreateParagraph({ Title = "Enabled By Default", Content = "[+] Anti AFK" })
    mainTab:CreateParagraph({ Title = "Latest Update", Content = "[+] Auto Send & Accept Friend Requests\n[+] Fixed Auto Collect Loot\n[+] Fixed Settings (Optimization Toggles)\n[+] Added Public Webhook in Discord\n[+] Hide Attack & Damage UI\n[+] Bug Fixes" })
    local dashboardBusy = false
    mainTab:CreateToggle({
        Name = "Dashboard",
        CurrentValue = false,
        Flag = "DashboardToggle",
        Callback = function(Value)
            if dashboardBusy then return end
            dashboardBusy = true
            if Value then
                task.spawn(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/no"))()
                    rayfield:Notify({Title = "Dashboard", Content = "Dashboard enabled!", Duration = 3})
                    dashboardBusy = false
                end)
            else
                local gui = player.PlayerGui:FindFirstChild("__MAINHUD__")
                if gui then gui:Destroy() end
                rayfield:Notify({Title = "Dashboard", Content = "Dashboard closed!", Duration = 3})
                dashboardBusy = false
            end
        end,
    })
    mainTab:CreateButton({ Name = "Save Config Manually", Callback = function() rayfield:SaveConfiguration() end })

    local farmingTab = window:CreateTab("Farming", 138602335586757)
    farmingTab:CreateSection("Zones")
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
    farmingTab:CreateDropdown({
        Name = "Zone Target",
        Options = zoneOptions,
        CurrentOption = { "Best Unlocked" },
        MultipleOptions = false,
        Flag = "FarmingZoneTarget",
        Callback = function() end,
    })
    farmingTab:CreateToggle({
        Name = "Auto Farm Zone",
        CurrentValue = false,
        Flag = "FarmingStayInBestZone",
        Callback = function(val)
            if val then
                task.spawn(function()
                    while rayfield.Flags.FarmingStayInBestZone and rayfield.Flags.FarmingStayInBestZone.CurrentValue do
                        local target = rayfield.Flags.FarmingZoneTarget.CurrentOption[1]
                        if target == "Best Unlocked" then
                            local maxZone = 33
                            for z = maxZone, 1, -1 do
                                if not (rayfield.Flags.FarmingStayInBestZone and rayfield.Flags.FarmingStayInBestZone.CurrentValue) then break end
                                ZonesRemote:InvokeServer("requestTeleportZone", z)
                                task.wait(1)
                                if (DataService:get("zone") or 1) == z then break end
                            end
                        else
                            local zoneNum = tonumber(target:match("Zone (%d+)"))
                            if zoneNum then ZonesRemote:InvokeServer("requestTeleportZone", zoneNum) end
                        end
                        task.wait(10)
                    end
                end)
            end
        end,
    })
    farmingTab:CreateToggle({
        Name = "Auto Unlock Affordable Zones",
        CurrentValue = false,
        Flag = "FarmingUnlockAffordableZones",
        Callback = function(val)
            if val then
                task.spawn(function()
                    while rayfield.Flags.FarmingUnlockAffordableZones and rayfield.Flags.FarmingUnlockAffordableZones.CurrentValue do
                        ZonesRemote:InvokeServer("requestPurchaseZone")
                        task.wait(5)
                    end
                end)
            end
        end,
    })

    farmingTab:CreateSection("Slimes")
    farmingTab:CreateToggle({
        Name = "Auto Equip Best Slimes",
        CurrentValue = false,
        Flag = "FarmingEquipBestSlimes",
        Callback = function(val)
            if val then
                task.spawn(function()
                    local waitTime = 30
                    while rayfield.Flags.FarmingEquipBestSlimes and rayfield.Flags.FarmingEquipBestSlimes.CurrentValue do
                        InventoryRemote:InvokeServer("requestEquipBest")
                        task.wait(waitTime)
                        waitTime = math.min(waitTime * 2, 600)
                    end
                end)
            end
        end,
    })
    farmingTab:CreateToggle({
        Name = "Auto Feed Best Slime",
        CurrentValue = false,
        Flag = "FarmingAutoFeed",
        Callback = function() end,
    })
    task.spawn(function()
        while task.wait(10) do
            if rayfield.Flags.FarmingAutoFeed and rayfield.Flags.FarmingAutoFeed.CurrentValue then
                local bestGuid = getBestSlimeGuid()
                if bestGuid then
                    local items = DataService:get("items") or {}
                    for itemId, amount in pairs(items) do
                        if type(amount) == "number" and amount > 0 then
                            InventoryServiceClient:fetch("requestUseFood", itemId, bestGuid, amount)
                            task.wait(0.3)
                        end
                    end
                end
            end
        end
    end)

    farmingTab:CreateToggle({
        Name = "Auto Transfer XP",
        CurrentValue = false,
        Flag = "FarmingTransferXP",
        Callback = function() end,
    })
    farmingTab:CreateDropdown({
        Name = "Transfer To",
        Options = { "Best Slime", "Whole Team" },
        CurrentOption = { "Best Slime" },
        MultipleOptions = false,
        Flag = "FarmingTransferTarget",
        Callback = function() end,
    })
    farmingTab:CreateDropdown({
        Name = "Transfer From",
        Options = { "Unequipped With XP", "All Slimes" },
        CurrentOption = { "Unequipped With XP" },
        MultipleOptions = false,
        Flag = "FarmingTransferSource",
        Callback = function() end,
    })
    task.spawn(function()
        while task.wait(30) do
            if rayfield.Flags.FarmingTransferXP and rayfield.Flags.FarmingTransferXP.CurrentValue then
                local inventory = DataService:get("inventory") or {}
                local equipped = DataService:get("equipped") or {}
                local teamSet = {}
                for _, uid in ipairs(equipped) do teamSet[uid] = true end
                local targetOption = rayfield.Flags.FarmingTransferTarget.CurrentOption[1]
                local sourceOption = rayfield.Flags.FarmingTransferSource.CurrentOption[1]
                local targets = {}
                if targetOption == "Best Slime" then
                    local best = getBestSlimeGuid()
                    if best then targets = { best } end
                else
                    for _, uid in ipairs(equipped) do table.insert(targets, uid) end
                end
                for _, target in ipairs(targets) do
                    for uid, data in pairs(inventory) do
                        if uid ~= target then
                            local isEquipped = teamSet[uid]
                            local hasXp = (type(data) == "table" and (data.xp or 0) > 0) or (type(data) == "number" and data > 0)
                            if sourceOption == "Unequipped With XP" and not isEquipped and hasXp then
                                XpTransferServiceClient:fetch("requestTransferXp", uid, target)
                                task.wait(0.5)
                            elseif sourceOption == "All Slimes" and hasXp then
                                XpTransferServiceClient:fetch("requestTransferXp", uid, target)
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end
        end
    end)

    farmingTab:CreateSection("Rolling")
    farmingTab:CreateToggle({
        Name = "Auto Fast Roll",
        CurrentValue = false,
        Flag = "FarmingFastRoll",
        Callback = function(val)
            if val then
                task.spawn(function()
                    local rollSlice = require(ReplicatedStorage:WaitForChild("Source"):WaitForChild("Features"):WaitForChild("Roll"):WaitForChild("RollSlice"))
                    while rayfield.Flags.FarmingFastRoll and rayfield.Flags.FarmingFastRoll.CurrentValue do
                        RollRemote:InvokeServer("requestRoll")
                        task.wait(rollSlice.rollTime())
                    end
                end)
            end
        end,
    })

    farmingTab:CreateSection("Loot")
    farmingTab:CreateToggle({
        Name = "Auto Collect Loot",
        CurrentValue = false,
        Flag = "FarmingCollectLoot",
        Callback = function(val)
            if val then
                task.spawn(function()
                    print("[CactusHub] Auto Collect Loot started")
                    while rayfield.Flags.FarmingCollectLoot and rayfield.Flags.FarmingCollectLoot.CurrentValue do
                        for _, folder in ipairs({"Loot", "Debris"}) do
                            local container = workspace:FindFirstChild(folder)
                            if container then
                                for _, item in ipairs(container:GetChildren()) do
                                    local id = item:GetAttribute("uniqueId") or item:GetAttribute("id") or item.Name
                                    if id then
                                        local success = LootRemote:InvokeServer("requestCollect", id)
                                        if success then
                                            print("[CactusHub] Collected: " .. tostring(item.Name) .. " | ID: " .. tostring(id))
                                        else
                                            print("[CactusHub] Failed to collect: " .. tostring(item.Name))
                                        end
                                    end
                                end
                            end
                        end
                        task.wait(0.5)
                    end
                    print("[CactusHub] Auto Collect Loot stopped")
                end)
            else
                print("[CactusHub] Auto Collect Loot disabled")
            end
        end,
    })

    -- ==================== ENEMY FARMING (MOVEMENT) ====================
    local enemySettings = {
        TeleportStyle = "Teleport",
        TargetPriorities = { ["Most Coins & Goop"] = true },
        AutoFarm = false,
        MutationFilter = "Any",
    }
    local enemyRange = 50
    local cachedEnemies = {}
    local lastEnemyCache = 0
    local currentEnemyTarget = nil
    local enemyTweenConn = nil

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
        return { coins = coins or 0, goop = goop or 0, health = health or 0, mutation = getEnemyMutation(enemy), distance = dist }
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
        if tick() - lastEnemyCache < 2 then return end
        lastEnemyCache = tick()
        cachedEnemies = {}
        local container = getGameplayContainer()
        if not container then return end
        local enemyFolder = container:FindFirstChild("Enemies")
        if not enemyFolder then return end
        for _, enemy in ipairs(enemyFolder:GetChildren()) do
            if enemy:IsA("Model") then
                table.insert(cachedEnemies, enemy)
            end
        end
    end

    local function matchesMutationFilter(enemy)
        if enemySettings.MutationFilter == "Any" then return true end
        return getEnemyMutation(enemy) == enemySettings.MutationFilter:lower()
    end

    local function computeEnemyScores()
        local char = player.Character
        if not char then return {} end
        local rp = char:FindFirstChild("HumanoidRootPart")
        if not rp then return {} end
        local entries = {}
        for _, enemy in ipairs(cachedEnemies) do
            if not isEnemyAlive(enemy) then continue end
            if not matchesMutationFilter(enemy) then continue end
            local root = getEnemyRoot(enemy)
            if not root then continue end
            local dist = (root.Position - rp.Position).Magnitude
            if dist > enemyRange then continue end
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
        local priorities = enemySettings.TargetPriorities
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

    local function selectEnemyTarget()
        local scores = computeEnemyScores()
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
        if enemySettings.TeleportStyle == "Teleport" then
            char:PivotTo(target)
        elseif enemySettings.TeleportStyle == "Tween" then
            if enemyTweenConn then enemyTweenConn:Disconnect() enemyTweenConn = nil end
            local start = char:GetPivot()
            local startTime = tick()
            local duration = 0.25
            enemyTweenConn = RunService.RenderStepped:Connect(function()
                local alpha = math.clamp((tick() - startTime) / duration, 0, 1)
                char:PivotTo(start:Lerp(target, alpha))
                if alpha >= 1 then enemyTweenConn:Disconnect() enemyTweenConn = nil end
            end)
        end
    end

    RunService.Heartbeat:Connect(function()
        refreshEnemyCache()
        if not enemySettings.AutoFarm then
            currentEnemyTarget = nil
            return
        end
        if currentEnemyTarget and isEnemyAlive(currentEnemyTarget) and currentEnemyTarget.Parent then
            return
        end
        local newTarget = selectEnemyTarget()
        if newTarget and newTarget ~= currentEnemyTarget then
            currentEnemyTarget = newTarget
            moveToEnemy(currentEnemyTarget)
        end
    end)

    farmingTab:CreateSection("Enemy Farming")
    farmingTab:CreateDropdown({
        Name = "Teleport Style",
        Options = {"Teleport", "Tween"},
        CurrentOption = {"Teleport"},
        MultipleOptions = false,
        Flag = "EnemyTeleportStyle",
        Callback = function(opt) enemySettings.TeleportStyle = opt[1] end,
    })
    farmingTab:CreateDropdown({
        Name = "Target Priority",
        Options = {"Most Coins & Goop", "Closest", "Lowest HP", "Mutations Only"},
        CurrentOption = {"Most Coins & Goop"},
        MultipleOptions = true,
        Flag = "EnemyTargetPriority",
        Callback = function(opts)
            enemySettings.TargetPriorities = {}
            for _, opt in ipairs(opts) do
                enemySettings.TargetPriorities[opt] = true
            end
        end,
    })
    farmingTab:CreateDropdown({
        Name = "Mutation Filter",
        Options = {"Any", "Inverted", "Huge", "Shiny", "Big"},
        CurrentOption = {"Any"},
        MultipleOptions = false,
        Flag = "EnemyMutationFilter",
        Callback = function(opt) enemySettings.MutationFilter = opt[1] end,
    })
    farmingTab:CreateToggle({
        Name = "Auto Farm Enemies",
        CurrentValue = false,
        Flag = "EnemyAutoFarm",
        Callback = function(val)
            enemySettings.AutoFarm = val
            if not val then currentEnemyTarget = nil end
        end,
    })

    -- ==================== INDEX AUTO COMPLETE ====================
    local SettingsState = require(ReplicatedStorage.Source.Features.Settings.SettingsState)
    local SettingsServiceClient = require(ReplicatedStorage.Source.Features.Settings.SettingsServiceClient)
    local settingsClient = {}
    settingsClient.networker = Networker.client.new("SettingsService", settingsClient)
    SettingsServiceClient.init(settingsClient)
    repeat task.wait() until SettingsState.get("luckOverrideEnabled") ~= nil

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
        local data = DataService:get("index") or {}
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

    local gameTab = window:CreateTab("Game", 82493603309814)
    local indexRunning = false
    local indexThread = nil
    local selectedCategoryOption = nil
    local progressLabels = {}
    local targetLabel, oddsLabel, luckLabel, categoryLabel

    gameTab:CreateSection("Index Auto Complete")
    gameTab:CreateToggle({
        Name = "Start Auto Complete",
        CurrentValue = false,
        Flag = "IndexAutoComplete",
        Callback = function(value)
            if value then
                indexRunning = true
                indexThread = task.spawn(function()
                    applyLuckSettings()
                    local modeFlag = rayfield.Flags.IndexRollMode
                    local mode = modeFlag and (type(modeFlag.CurrentOption) == "table" and modeFlag.CurrentOption[1] or modeFlag.CurrentOption) or "🌱 Easiest First"
                    if selectedCategoryOption == nil or selectedCategoryOption == "🎲 All (Recommended)" then
                        while indexRunning do
                            local sorted = getSortedCategoriesByPriority()
                            if #sorted == 0 then
                                categoryLabel:Set("📂 ✅ All Complete!")
                                targetLabel:Set("🎯 Target: —")
                                oddsLabel:Set("🎲 Odds: —")
                                indexRunning = false
                                break
                            end
                            local catId = sorted[1].id
                            local catLabel = catId:sub(1,1):upper() .. catId:sub(2)
                            local failCount = 0
                            local lastTargetId = nil
                            while indexRunning do
                                local missing = getMissingSlimes(catId)
                                if #missing == 0 then break end
                                local target = mode == "🎯 Rarest First" and missing[#missing] or missing[1]
                                local effOdds = getEffectiveOdds(target, catId)
                                if target.id ~= lastTargetId then
                                    lastTargetId = target.id
                                    applyLuckForTarget(effOdds)
                                end
                                targetLabel:Set("🎯 Target: " .. catLabel .. " " .. target.name)
                                oddsLabel:Set("🎲 Odds: " .. formatOdds(effOdds))
                                categoryLabel:Set(string.format("📂 %s (%d left)", catLabel, #missing))
                                local before = getUnlocked(catId)
                                RollRemote:InvokeServer("requestRoll")
                                task.wait(RollSlice.rollTime() + 0.25)
                                local after = getUnlocked(catId)
                                local gotOne = false
                                for id, val in pairs(after) do
                                    if val == true and not before[id] then
                                        gotOne = true
                                        failCount = 0
                                        local slime = Slimes.getSlime(id)
                                        local name = slime and slime.name or id
                                        print("[UNLOCKED]", catLabel, name)
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
                            if not indexRunning then break end
                        end
                    else
                        local catId = getCatIdFromOption(selectedCategoryOption)
                        if catId then
                            local catLabel = catId:sub(1,1):upper() .. catId:sub(2)
                            local failCount = 0
                            local lastTargetId = nil
                            while indexRunning do
                                local missing = getMissingSlimes(catId)
                                if #missing == 0 then break end
                                local modeFlag = rayfield.Flags.IndexRollMode
                                local mode = modeFlag and (type(modeFlag.CurrentOption) == "table" and modeFlag.CurrentOption[1] or modeFlag.CurrentOption) or "🌱 Easiest First"
                                local target = mode == "🎯 Rarest First" and missing[#missing] or missing[1]
                                local effOdds = getEffectiveOdds(target, catId)
                                if target.id ~= lastTargetId then
                                    lastTargetId = target.id
                                    applyLuckForTarget(effOdds)
                                end
                                targetLabel:Set("🎯 Target: " .. catLabel .. " " .. target.name)
                                oddsLabel:Set("🎲 Odds: " .. formatOdds(effOdds))
                                categoryLabel:Set(string.format("📂 %s (%d left)", catLabel, #missing))
                                local before = getUnlocked(catId)
                                RollRemote:InvokeServer("requestRoll")
                                task.wait(RollSlice.rollTime() + 0.25)
                                local after = getUnlocked(catId)
                                local gotOne = false
                                for id, val in pairs(after) do
                                    if val == true and not before[id] then
                                        gotOne = true
                                        failCount = 0
                                        local slime = Slimes.getSlime(id)
                                        local name = slime and slime.name or id
                                        print("[UNLOCKED]", catLabel, name)
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
                            if indexRunning then
                                categoryLabel:Set("📂 ✅ Complete!")
                                targetLabel:Set("🎯 Target: —")
                                oddsLabel:Set("🎲 Odds: —")
                            end
                        end
                        indexRunning = false
                    end
                    setLuckEnabled(false)
                    for _, catId in ipairs(CATEGORY_IDS) do
                        if progressLabels[catId] then
                            local label = catId:sub(1,1):upper() .. catId:sub(2)
                            local count = getUnlockedCount(catId)
                            progressLabels[catId]:Set(string.format("📊 %s: %d / %d", label, count, getTotalSlimes()))
                        end
                    end
                end)
            else
                indexRunning = false
                if indexThread then task.cancel(indexThread) indexThread = nil end
                setLuckEnabled(false)
                if targetLabel then targetLabel:Set("🎯 Target: —") end
                if oddsLabel then oddsLabel:Set("🎲 Odds: —") end
                if luckLabel then luckLabel:Set("🍀 Luck: —") end
                if categoryLabel then categoryLabel:Set("📂 Category: —") end
            end
        end,
    })

    gameTab:CreateSection("Index Settings")
    local categoryOptionsList = buildCategoryOptions()
    selectedCategoryOption = categoryOptionsList[1]
    gameTab:CreateDropdown({
        Name = "Category",
        Options = categoryOptionsList,
        CurrentOption = { categoryOptionsList[1] },
        MultipleOptions = false,
        Flag = "IndexCategory",
        Callback = function(opt) selectedCategoryOption = type(opt) == "table" and opt[1] or opt end,
    })
    gameTab:CreateDropdown({
        Name = "Roll Mode",
        Options = { "🌱 Easiest First", "🎯 Rarest First" },
        CurrentOption = { "🌱 Easiest First" },
        MultipleOptions = false,
        Flag = "IndexRollMode",
        Callback = function() end,
    })

    gameTab:CreateSection("Index Status")
    targetLabel = gameTab:CreateLabel("🎯 Target: —")
    oddsLabel = gameTab:CreateLabel("🎲 Odds: —")
    luckLabel = gameTab:CreateLabel("🍀 Luck: —")
    categoryLabel = gameTab:CreateLabel("📂 Category: —")

    gameTab:CreateSection("Index Progress")
    local totalSlimeCount = getTotalSlimes()
    for _, catId in ipairs(CATEGORY_IDS) do
        local label = catId:sub(1,1):upper() .. catId:sub(2)
        local count = getUnlockedCount(catId)
        progressLabels[catId] = gameTab:CreateLabel(string.format("📊 %s: %d / %d", label, count, totalSlimeCount))
    end

    -- ==================== AUTO FEED FRUITS ====================
    local ALL_FRUITS = require(Source.Game.Items.Fruits).getSortedFruits()
    local fruitOptionsList = {"Any"}
    local fruitLabelToId = {}
    for _, f in ipairs(ALL_FRUITS) do
        table.insert(fruitOptionsList, f.powerName)
        fruitLabelToId[f.powerName] = f.id
    end

    local autoFeedFruitsEnabled = false
    local selectedFruitIds = {"ANY"}
    local selectedSlimeFeedMode = "Best"
    local feedConnection = nil

    local function getOwnedFruitIds()
        local items = DataService:get("items") or {}
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
        local fruitDef = require(Source.Game.Items.Fruits).getFruit(fruitId)
        if not fruitDef then return false end
        local trees = slimeData.unlockedTrees
        if type(trees) ~= "table" then return false end
        return trees[fruitDef.treeId] == true
    end

    local function getSlimeDataFromKey(key)
        if type(key) ~= "string" then return nil, nil end
        if key:sub(1, 1) == "." then
            local inv = DataService:get("inventory") or {}
            local data = inv[key]
            if type(data) == "table" then
                return key, data
            end
        end
        return nil, nil
    end

    local function getBestSlimeEntry()
        local stats = DataService:get("stats") or {}
        local rarest = stats.rarestRoll
        if not rarest or not rarest.slimeData then return nil, nil end
        local rarestId = rarest.slimeData.id
        local rarestMutations = rarest.slimeData.mutations or {}
        local equipped = DataService:get("equipped") or {}
        local inv = DataService:get("inventory") or {}
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
        local firstGuid = nil
        local firstGuidData = nil
        for _, slimeKey in pairs(equipped) do
            if type(slimeKey) == "string" and slimeKey:sub(1, 1) == "." then
                local data = inv[slimeKey]
                if type(data) == "table" then
                    firstGuid = slimeKey
                    firstGuidData = data
                    break
                end
            end
        end
        return firstGuid, firstGuidData
    end

    local function getTargetSlimesForFruit()
        if selectedSlimeFeedMode == "Best" then
            local key, data = getBestSlimeEntry()
            if key and data then
                return {{key = key, data = data}}
            end
            return {}
        else
            local equipped = DataService:get("equipped") or {}
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

    local function doFeedFruits()
        local targets = getTargetSlimesForFruit()
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

    gameTab:CreateSection("Auto Feed Fruits")
    gameTab:CreateToggle({
        Name = "Auto Feed Fruits to Slime(s)",
        CurrentValue = false,
        Flag = "AutoFeedFruitsToggle",
        Callback = function(value)
            autoFeedFruitsEnabled = value
            if autoFeedFruitsEnabled then
                if feedConnection then feedConnection:Disconnect() end
                feedConnection = RunService.Heartbeat:Connect(function()
                    if autoFeedFruitsEnabled then pcall(doFeedFruits) end
                end)
            else
                if feedConnection then
                    feedConnection:Disconnect()
                    feedConnection = nil
                end
            end
        end,
    })
    gameTab:CreateDropdown({
        Name = "Slimes to Feed",
        Options = {"Best", "Split Across Team"},
        CurrentOption = {"Best"},
        MultipleOptions = false,
        Flag = "FeedSlimeMode",
        Callback = function(opt) selectedSlimeFeedMode = type(opt) == "table" and opt[1] or opt end,
    })
    gameTab:CreateDropdown({
        Name = "Fruits to Feed",
        Options = fruitOptionsList,
        CurrentOption = {"Any"},
        MultipleOptions = true,
        Flag = "FeedFruitList",
        Callback = function(opts)
            local picked = type(opts) == "table" and opts or {opts}
            selectedFruitIds = {}
            for _, label in ipairs(picked) do
                if label == "Any" then
                    selectedFruitIds = {"ANY"}
                    return
                else
                    table.insert(selectedFruitIds, fruitLabelToId[label])
                end
            end
            if #selectedFruitIds == 0 then
                selectedFruitIds = {"ANY"}
            end
        end,
    })

    -- ==================== EXISTING GAME TAB CONTENT (Rebirth, Upgrades, Combat) ====================
    gameTab:CreateSection("Rebirth")
    gameTab:CreateToggle({
        Name = "Auto Rebirth",
        CurrentValue = false,
        Flag = "GameAutoRebirth",
        Callback = function(val)
            if val then
                task.spawn(function()
                    while rayfield.Flags.GameAutoRebirth and rayfield.Flags.GameAutoRebirth.CurrentValue do
                        local rebirths = DataService:get("rebirths") or 0
                        local goop = DataService:get("goop") or 0
                        local furthestZone = DataService:get("furthestZone") or 0
                        local neededGoop = (2 ^ rebirths) * 500
                        local minZone = tonumber(rayfield.Flags.GameMinZoneRebirth and rayfield.Flags.GameMinZoneRebirth.CurrentValue or 0)
                        if furthestZone >= minZone and goop >= neededGoop then
                            RebirthRemote:InvokeServer("requestRebirth")
                        end
                        task.wait(10)
                    end
                end)
            end
        end,
    })
    gameTab:CreateInput({
        Name = "Minimum Zone To Rebirth",
        CurrentValue = "",
        PlaceholderText = "e.g. 10",
        RemoveTextAfterFocusLost = false,
        Flag = "GameMinZoneRebirth",
        Callback = function() end,
    })

    gameTab:CreateSection("Upgrades")
    gameTab:CreateToggle({
        Name = "Auto Upgrade Purchasing",
        CurrentValue = false,
        Flag = "GameAutoUpgrade",
        Callback = function(val)
            if val then
                task.spawn(function()
                    local upgradeIds, upgradeCosts = getAllUpgradeIds()
                    while task.wait(0.5) and rayfield.Flags.GameAutoUpgrade and rayfield.Flags.GameAutoUpgrade.CurrentValue do
                        local mode = rayfield.Flags.GameUpgradeMode and rayfield.Flags.GameUpgradeMode.CurrentOption[1] or "All"
                        local upgrades = DataService:get("upgrades") or {}
                        local coins = DataService:get("coins") or 0
                        local goop = DataService:get("goop") or 0
                        local rollCurrency = DataService:get("rollCurrency") or 0
                        for _, id in ipairs(upgradeIds) do
                            if not upgrades[id] then
                                local cost = upgradeCosts[id]
                                if cost then
                                    local amount = cost.amount or 0
                                    local currency = cost.currency
                                    local eligible = (mode == "All") or
                                        (mode == "Coins" and currency == "coins") or
                                        (mode == "Goop" and currency == "goop") or
                                        (mode == "Rolls" and currency == "rollCurrency")
                                    local hasCurrency = (currency == "coins" and coins >= amount) or
                                                        (currency == "goop" and goop >= amount) or
                                                        (currency == "rollCurrency" and rollCurrency >= amount)
                                    if eligible and hasCurrency then
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
    gameTab:CreateDropdown({
        Name = "Upgrade Mode",
        Options = {"All", "Goop", "Coins", "Rolls"},
        CurrentOption = {"All"},
        MultipleOptions = false,
        Flag = "GameUpgradeMode",
        Callback = function() end,
    })

    gameTab:CreateSection("Combat")
    gameTab:CreateToggle({
        Name = "Auto Shoot Enemies",
        CurrentValue = false,
        Flag = "CombatAutoShoot",
        Content = "Auto Shoot is enabled but visual effects will not appear — damage is still dealt.",
        Callback = function() end,
    })
    gameTab:CreateDropdown({
        Name = "Target Priority",
        Options = {"Closest", "Lowest HP", "Highest HP"},
        CurrentOption = {"Closest"},
        MultipleOptions = false,
        Flag = "CombatTargetPriority",
        Callback = function() end,
    })

    -- Ensure SlimeGun equipped
    local function ensureGunEquipped()
        local character = player.Character
        if not character then return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end
        local gun = character:FindFirstChild("SlimeGun") or player.Backpack:FindFirstChild("SlimeGun")
        if gun and gun.Parent ~= character then
            humanoid:EquipTool(gun)
        end
        return gun ~= nil
    end
    task.spawn(function()
        while true do
            ensureGunEquipped()
            task.wait(2)
        end
    end)

    -- Damage UI handling
    local damageUIParent = nil
    local function getDamageUIParent()
        if damageUIParent and damageUIParent.Parent then return damageUIParent end
        local playerGui = player.PlayerGui
        local screenGui = playerGui:FindFirstChild("SlimeGunHUD")
        if screenGui then
            local container = screenGui:FindFirstChild("PopupContainer")
            if container then
                damageUIParent = container
                return container
            end
        end
        return nil
    end

    task.spawn(function()
        local GameplayServiceClient = require(Source.Features.Gameplay.GameplayServiceClient)
        local GoopGunServiceClient = require(Source.Features.GoopGun.GoopGunServiceClient)
        local GoopGunServiceUtils = require(Source.Features.GoopGun.GoopGunServiceUtils)

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "SlimeGunHUD"
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.DisplayOrder = 999
        screenGui.Parent = player.PlayerGui

        local container = Instance.new("Frame")
        container.Name = "PopupContainer"
        container.Position = UDim2.new(1, -276, 0, 48)
        container.Size = UDim2.new(0, 260, 1, -96)
        container.BackgroundTransparency = 1
        container.Parent = screenGui

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.Padding = UDim.new(0, 6)
        layout.Parent = container

        local COLORS = {
            normal   = Color3.fromRGB(120, 220, 255),
            big      = Color3.fromRGB(255, 180, 50),
            huge     = Color3.fromRGB(255, 80, 80),
            shiny    = Color3.fromRGB(255, 230, 50),
            inverted = Color3.fromRGB(180, 80, 255),
        }

        local function getMutationColor(mutations)
            if not mutations then return COLORS.normal end
            if mutations.inverted then return COLORS.inverted end
            if mutations.huge then return COLORS.huge end
            if mutations.shiny then return COLORS.shiny end
            if mutations.big then return COLORS.big end
            return COLORS.normal
        end

        local function getEnemyLabel(enemy)
            local tier = "Lv." .. tostring(enemy.enemyId or 1)
            local uid = "#" .. tostring(enemy.uniqueId or "?")
            if enemy.mutations then
                local tags = {}
                for mut in pairs(enemy.mutations) do
                    table.insert(tags, mut:sub(1,1):upper() .. mut:sub(2))
                end
                if #tags > 0 then
                    return table.concat(tags, " ") .. " Slime " .. tier .. " " .. uid
                end
            end
            return "Slime " .. tier .. " " .. uid
        end

        local activePopups = {}
        local popupOrder = 0
        local TweenService = game:GetService("TweenService")

        local function pulseFrame(frame, accentColor)
            TweenService:Create(frame, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = accentColor
            }):Play()
            task.delay(0.06, function()
                TweenService:Create(frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
                    BackgroundColor3 = Color3.fromRGB(10, 10, 18)
                }):Play()
            end)
        end

        local function destroyPopup(uid)
            local p = activePopups[uid]
            if not p then return end
            activePopups[uid] = nil
            local frame = p.frame
            TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0)
            }):Play()
            for _, lbl in ipairs(p.labels) do
                TweenService:Create(lbl, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
            end
            TweenService:Create(p.accent, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
            task.delay(0.3, function() frame:Destroy() end)
        end

        local function scheduleExpiry(uid)
            local p = activePopups[uid]
            if not p then return end
            if p.expireTask then task.cancel(p.expireTask) end
            p.expireTask = task.delay(2.5, function()
                destroyPopup(uid)
            end)
        end

        local function createPopup(uid, enemyLabel, dmg, hpAfter, accentColor)
            popupOrder = popupOrder + 1
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 52)
            frame.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
            frame.BackgroundTransparency = 0.1
            frame.BorderSizePixel = 0
            frame.ClipsDescendants = true
            frame.LayoutOrder = popupOrder
            frame.Parent = container
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
            local accent = Instance.new("Frame")
            accent.Size = UDim2.new(0, 3, 1, 0)
            accent.BackgroundColor3 = accentColor
            accent.BorderSizePixel = 0
            accent.Parent = frame
            Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 10)
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Position = UDim2.new(0, 14, 0, 5)
            nameLabel.Size = UDim2.new(1, -90, 0, 18)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = enemyLabel
            nameLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 13
            nameLabel.Parent = frame
            local hpLabel = Instance.new("TextLabel")
            hpLabel.Position = UDim2.new(0, 14, 0, 25)
            hpLabel.Size = UDim2.new(1, -90, 0, 14)
            hpLabel.BackgroundTransparency = 1
            hpLabel.Text = "HP: " .. tostring(math.max(0, math.floor(hpAfter)))
            hpLabel.TextColor3 = Color3.fromRGB(130, 130, 150)
            hpLabel.TextXAlignment = Enum.TextXAlignment.Left
            hpLabel.Font = Enum.Font.Gotham
            hpLabel.TextSize = 11
            hpLabel.Parent = frame
            local hitsLabel = Instance.new("TextLabel")
            hitsLabel.Position = UDim2.new(0, 14, 0, 38)
            hitsLabel.Size = UDim2.new(1, -90, 0, 12)
            hitsLabel.BackgroundTransparency = 1
            hitsLabel.Text = "1 hit  •  " .. tostring(math.floor(dmg)) .. " total dmg"
            hitsLabel.TextColor3 = Color3.fromRGB(90, 90, 110)
            hitsLabel.TextXAlignment = Enum.TextXAlignment.Left
            hitsLabel.Font = Enum.Font.Gotham
            hitsLabel.TextSize = 10
            hitsLabel.Parent = frame
            local dmgLabel = Instance.new("TextLabel")
            dmgLabel.Position = UDim2.new(1, -80, 0, 0)
            dmgLabel.Size = UDim2.new(0, 72, 1, 0)
            dmgLabel.BackgroundTransparency = 1
            dmgLabel.Text = "-" .. tostring(math.floor(dmg))
            dmgLabel.TextColor3 = accentColor
            dmgLabel.TextXAlignment = Enum.TextXAlignment.Right
            dmgLabel.Font = Enum.Font.GothamBold
            dmgLabel.TextSize = 20
            dmgLabel.Parent = frame
            frame.Position = UDim2.new(-1, 0, 0, 0)
            TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, 0)
            }):Play()
            activePopups[uid] = {
                frame = frame,
                accent = accent,
                labels = { nameLabel, hpLabel, hitsLabel, dmgLabel },
                hpLabel = hpLabel,
                hitsLabel = hitsLabel,
                dmgLabel = dmgLabel,
                totalDmg = dmg,
                hits = 1,
                accentColor = accentColor,
                expireTask = nil,
            }
            scheduleExpiry(uid)
        end

        local function updatePopup(uid, dmg, hpAfter)
            local p = activePopups[uid]
            if not p then return end
            p.totalDmg = p.totalDmg + dmg
            p.hits = p.hits + 1
            p.hpLabel.Text = "HP: " .. tostring(math.max(0, math.floor(hpAfter)))
            p.hitsLabel.Text = p.hits .. " hits  •  " .. tostring(math.floor(p.totalDmg)) .. " total dmg"
            p.dmgLabel.Text = "-" .. tostring(math.floor(p.totalDmg))
            pulseFrame(p.frame, p.accentColor)
            scheduleExpiry(uid)
        end

        local function selectAutoShootTarget()
            local gameplay = GameplayServiceClient.gameplay
            if not gameplay then return nil end
            local character = player.Character
            if not character then return nil end
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return nil end
            local priority = rayfield.Flags.CombatTargetPriority.CurrentOption[1]
            local best, bestVal = nil, nil
            for uniqueId, enemy in pairs(gameplay.enemies) do
                if enemy.health and enemy.health > 0 then
                    if priority == "Closest" then
                        local dist = (enemy.pos - rootPart.Position).Magnitude
                        if bestVal == nil or dist < bestVal then
                            bestVal = dist
                            best = uniqueId
                        end
                    elseif priority == "Lowest HP" then
                        if bestVal == nil or enemy.health < bestVal then
                            bestVal = enemy.health
                            best = uniqueId
                        end
                    elseif priority == "Highest HP" then
                        if bestVal == nil or enemy.health > bestVal then
                            bestVal = enemy.health
                            best = uniqueId
                        end
                    end
                end
            end
            return best
        end

        while true do
            if rayfield.Flags.CombatAutoShoot and rayfield.Flags.CombatAutoShoot.CurrentValue then
                local character = player.Character
                if character and character:FindFirstChildOfClass("Humanoid") and character:FindFirstChildOfClass("Humanoid").Health > 0 then
                    ensureGunEquipped()
                    local upgrades = DataService:get("upgrades") or {}
                    local fireRate = GoopGunServiceUtils.getFireRate(upgrades)
                    local targetId = selectAutoShootTarget()
                    if targetId then
                        local gameplay = GameplayServiceClient.gameplay
                        local enemy = gameplay and gameplay.enemies[targetId]
                        local hpBefore = enemy and enemy.health or 0
                        local enemyLabel = enemy and getEnemyLabel(enemy) or "Slime"
                        local accentColor = enemy and getMutationColor(enemy.mutations) or COLORS.normal
                        local wrapper = GoopGunServiceClient.wrapper
                        if wrapper and wrapper.onEnemyHit then
                            wrapper.onEnemyHit(targetId)
                        end
                        task.wait()
                        local hpAfter = enemy and enemy.health or 0
                        local dmg = hpBefore - hpAfter
                        if dmg > 0 then
                            if activePopups[targetId] then
                                updatePopup(targetId, dmg, hpAfter)
                            else
                                createPopup(targetId, enemyLabel, dmg, hpAfter, accentColor)
                            end
                        end
                    end
                    task.wait(fireRate)
                else
                    task.wait(1)
                end
            else
                task.wait(0.5)
            end
        end
    end)

    -- ==================== MISC TAB ====================
    local miscTab = window:CreateTab("Misc", 96334002390551)
    miscTab:CreateSection("Codes & Rewards")
    miscTab:CreateToggle({
        Name = "Auto Redeem Codes",
        CurrentValue = false,
        Flag = "MiscRedeemCodes",
        Callback = function(val)
            if val then
                task.spawn(function()
                    local codes = { "gullible", "test", "goingBananas", "AAisComing", "Sliming" }
                    while rayfield.Flags.MiscRedeemCodes and rayfield.Flags.MiscRedeemCodes.CurrentValue do
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
    miscTab:CreateToggle({
        Name = "Auto Claim Offline Earnings",
        CurrentValue = false,
        Flag = "MiscClaimOffline",
        Callback = function(val)
            if val then
                task.spawn(function()
                    while rayfield.Flags.MiscClaimOffline and rayfield.Flags.MiscClaimOffline.CurrentValue do
                        OfflineEarningsRemote:InvokeServer("requestClaim")
                        task.wait(60)
                    end
                end)
            end
        end,
    })
    miscTab:CreateToggle({
        Name = "Auto Claim Index Rewards",
        CurrentValue = false,
        Flag = "MiscClaimIndex",
        Callback = function(val)
            if val then
                task.spawn(function()
                    local function claimIndexRewards()
                        local indexData = DataService:get("index")
                        if not indexData or not indexData.categories then return end
                        for catId, rewards in pairs(IndexRewards) do
                            local cat = indexData.categories[catId]
                            if cat then
                                local unlocked = cat.unlocked or {}
                                local unlockedCount = 0
                                for _, v in pairs(unlocked) do if v == true then unlockedCount = unlockedCount + 1 end end
                                local claimed = cat.claimedRewards or {}
                                for _, reward in ipairs(rewards) do
                                    if unlockedCount >= reward.req and not claimed[reward.key] then
                                        IndexRemote:InvokeServer("requestClaimReward", catId)
                                        task.wait(0.5)
                                    end
                                end
                            end
                        end
                    end
                    while rayfield.Flags.MiscClaimIndex and rayfield.Flags.MiscClaimIndex.CurrentValue do
                        claimIndexRewards()
                        task.wait(60)
                    end
                end)
            end
        end,
    })

    miscTab:CreateSection("Consumables")
    miscTab:CreateToggle({
        Name = "Auto Use Potions",
        CurrentValue = false,
        Flag = "MiscUsePotions",
        Callback = function(val)
            if val then
                task.spawn(function()
                    while task.wait(1) and rayfield.Flags.MiscUsePotions and rayfield.Flags.MiscUsePotions.CurrentValue do
                        local boosts = DataService:get("boosts") or {}
                        local selected = rayfield.Flags.MiscPotionTypes and rayfield.Flags.MiscPotionTypes.CurrentOption or {}
                        for _, kind in ipairs(selected) do
                            local boost = boosts[kind]
                            if boost and (boost.amount or 0) > 0 then
                                BoostRemote:InvokeServer("requestUseBoost", kind)
                            end
                        end
                    end
                end)
            end
        end,
    })
    miscTab:CreateDropdown({
        Name = "Potion Types",
        Options = boostKinds,
        CurrentOption = {boostKinds[1]},
        MultipleOptions = true,
        Flag = "MiscPotionTypes",
        Callback = function() end,
    })
    miscTab:CreateToggle({
        Name = "Auto Use Dice & Items",
        CurrentValue = false,
        Flag = "MiscUseDice",
        Callback = function(val)
            if val then
                task.spawn(function()
                    while task.wait(1) and rayfield.Flags.MiscUseDice and rayfield.Flags.MiscUseDice.CurrentValue do
                        local items = DataService:get("items") or {}
                        local selected = rayfield.Flags.MiscDiceTypes and rayfield.Flags.MiscDiceTypes.CurrentOption or {}
                        for _, name in ipairs(selected) do
                            local id = nameToDiceId[name]
                            if id and (items[id] or 0) > 0 then
                                InventoryRemote:InvokeServer("requestUseItem", id)
                            end
                        end
                    end
                end)
            end
        end,
    })
    do
        local diceNames = {}
        for _, id in ipairs(diceItemIds) do
            table.insert(diceNames, diceNameMap[id])
        end
        miscTab:CreateDropdown({
            Name = "Dice & Item Types",
            Options = diceNames,
            CurrentOption = {diceNames[1]},
            MultipleOptions = true,
            Flag = "MiscDiceTypes",
            Callback = function() end,
        })
    end

    -- ==================== WEBHOOK TAB ====================
    local webhookTab = window:CreateTab("Webhook", 84577758013974)
    webhookTab:CreateSection("Warning")
    webhookTab:CreateParagraph({
        Title = "⚠️ WARNING",
        Content = "WEBHOOK WILL ONLY WORK IF YOU MANUALLY ENABLE AUTO ROLL IN GAME\nPLEASE DISABLE FAST ROLL (from Farming Tab) if you have it enabled"
    })
    webhookTab:CreateSection("Configuration")
    webhookTab:CreateToggle({
        Name = "Enable Webhook",
        CurrentValue = false,
        Flag = "WebhookEnabled",
        Callback = function() end,
    })
    local userWebhookUrl = ""
    webhookTab:CreateInput({
        Name = "Webhook URL",
        CurrentValue = "",
        PlaceholderText = "Paste your Discord webhook URL",
        RemoveTextAfterFocusLost = false,
        Flag = "WebhookURLDisplay",
        Callback = function(url)
            if url and url:match("^https://discord") then
                userWebhookUrl = url
                local masked = string.rep("•", #url - 6) .. url:sub(-6)
                rayfield:Notify({Title = "Webhook", Content = "URL saved: " .. masked, Duration = 3})
            end
        end,
    })
    webhookTab:CreateInput({
        Name = "User ID",
        CurrentValue = "",
        PlaceholderText = "Discord User ID",
        RemoveTextAfterFocusLost = false,
        Flag = "WebhookUserID",
        Callback = function() end,
    })
    webhookTab:CreateInput({
        Name = "Minimum Chance To Send",
        CurrentValue = "",
        PlaceholderText = "e.g. 1B or 1000000000",
        RemoveTextAfterFocusLost = false,
        Flag = "WebhookMinChance",
        Callback = function() end,
    })
    webhookTab:CreateButton({
        Name = "Test Webhook",
        Callback = function()
            if userWebhookUrl == "" then
                rayfield:Notify({Title = "Webhook", Content = "Please paste a Webhook URL first.", Duration = 4})
                return
            end
            if not rayfield.Flags.WebhookEnabled.CurrentValue then
                rayfield:Notify({Title = "Webhook", Content = "Please enable Webhook first.", Duration = 4})
                return
            end
            local userId = rayfield.Flags.WebhookUserID.CurrentValue
            local mention = (userId and userId ~= "" and userId ~= "everyone" and userId ~= "here") and ("<@" .. userId .. "> ") or ""
            local resp = request({
                Url = userWebhookUrl,
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
            if not resp then
                rayfield:Notify({Title = "Webhook", Content = "Failed to send test.", Duration = 4})
            else
                rayfield:Notify({Title = "Webhook", Content = "Test sent successfully!", Duration = 4})
            end
        end,
    })
    webhookTab:CreateSection("Filters")
    webhookTab:CreateToggle({
        Name = "Send All Slimes",
        CurrentValue = false,
        Flag = "WebhookSendAll",
        Callback = function() end,
    })
    webhookTab:CreateToggle({
        Name = "Send New Slimes Only",
        CurrentValue = false,
        Flag = "WebhookSendNew",
        Callback = function() end,
    })
    webhookTab:CreateToggle({
        Name = "Send Mutated Slimes",
        CurrentValue = false,
        Flag = "WebhookSendMutated",
        Callback = function() end,
    })
    webhookTab:CreateDropdown({
        Name = "Mutations Filter",
        Options = {"All", "Shiny", "Big", "Huge", "Inverted"},
        CurrentOption = {"All"},
        MultipleOptions = true,
        Flag = "WebhookMutations",
        Callback = function() end,
    })

    local lastResultHash = nil
    local function shouldSendWebhook(slimeId, mutations)
        local sendAll = rayfield.Flags.WebhookSendAll and rayfield.Flags.WebhookSendAll.CurrentValue
        local sendNew = rayfield.Flags.WebhookSendNew and rayfield.Flags.WebhookSendNew.CurrentValue
        local sendMutated = rayfield.Flags.WebhookSendMutated and rayfield.Flags.WebhookSendMutated.CurrentValue
        if sendAll then return true end
        if sendNew and isNewSlime(slimeId, mutations) then return true end
        if sendMutated and mutations and next(mutations) then
            local filterMuts = rayfield.Flags.WebhookMutations and rayfield.Flags.WebhookMutations.CurrentOption or {"All"}
            local allSelected = false
            for _, m in ipairs(filterMuts) do if m == "All" then allSelected = true break end end
            if allSelected then return true end
            local cat = getCategoryFromMutations(mutations)
            for _, m in ipairs(filterMuts) do
                if m:lower() == cat then return true end
            end
        end
        return false
    end

    task.spawn(function()
        while true do
            task.wait(0.1)
            if not rayfield.Flags.WebhookEnabled or not rayfield.Flags.WebhookEnabled.CurrentValue then
                -- wait
            elseif userWebhookUrl ~= "" then
                if not RollSlice or type(RollSlice.rollResults) ~= "function" then
                    task.wait(1)
                else
                    local results = RollSlice.rollResults()
                    if type(results) ~= "table" or #results == 0 then
                        task.wait(0.5)
                    else
                        local hash = getResultHash(results)
                        if hash ~= lastResultHash then
                            lastResultHash = hash
                            for _, res in ipairs(results) do
                                local slime = getFirstSlimeFromResult(res)
                                if slime then
                                    local slimeId = tostring(slime.id or "")
                                    if slimeId ~= "" then
                                        local mutations = (type(slime.mutations) == "table" and next(slime.mutations) ~= nil) and slime.mutations or nil
                                        local slimeData = Slimes.getSlime(slimeId)
                                        local minChanceStr = rayfield.Flags.WebhookMinChance.CurrentValue
                                        local minChanceNum = parseChanceString(minChanceStr)
                                        local send = shouldSendWebhook(slimeId, mutations)
                                        if send and minChanceNum then
                                            local odds = slimeData and slimeData.odds or 0
                                            local chanceValue = odds > 0 and (1 / odds) or 0
                                            if chanceValue > minChanceNum then
                                                send = false
                                            end
                                        end
                                        if send then
                                            local userId = rayfield.Flags.WebhookUserID.CurrentValue
                                            local uniqueKey = hash .. "_" .. slimeId .. "_" .. tostring(mutations and Mutations.getIds(mutations) or "")
                                            task.spawn(sendWebhook, slimeId, slimeData, mutations, userWebhookUrl, userId, uniqueKey)
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

    -- ==================== SETTINGS TAB ====================
    local settingsTab = window:CreateTab("Settings", 122930981612451)
    settingsTab:CreateSection("System")
    settingsTab:CreateToggle({
        Name = "Anti Kick",
        CurrentValue = false,
        Flag = "SettingsAntiKick",
        Callback = function() end,
    })
    settingsTab:CreateToggle({
        Name = "Auto Rejoin On Disconnect",
        CurrentValue = false,
        Flag = "SettingsAutoRejoin",
        Callback = function() end,
    })
    settingsTab:CreateToggle({
        Name = "Auto Friend Requests",
        CurrentValue = false,
        Flag = "AutoFriend",
        Callback = function(val)
            if val then
                task.spawn(function()
                    while rayfield.Flags.AutoFriend and rayfield.Flags.AutoFriend.CurrentValue do
                        local playersList = game:GetService("Players"):GetChildren()
                        for _, p in ipairs(playersList) do
                            player:RequestFriendship(p)
                            task.wait(1)
                        end
                        task.wait(600)
                    end
                end)
            end
        end,
    })
    settingsTab:CreateLabel("( I'm not sure if it works )")

    settingsTab:CreateSection("Advanced Optimization")
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
    local function optSafeDestroy(obj) if obj and obj.Parent then obj:Destroy() end end
    local function optTryHidden(obj, prop, val) if sethiddenproperty then sethiddenproperty(obj, prop, val) end end
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
            if not v:IsA("TriangleMeshPart") then optTryHidden(v, "RenderFidelity", 2) end
        end
    end
    local function optLighting()
        local L = game:GetService("Lighting")
        L.GlobalShadows = false; L.FogEnd = 100000; L.FogStart = 100000; L.Brightness = 1
        L.Ambient = Color3.fromRGB(180,180,180); L.OutdoorAmbient = Color3.fromRGB(180,180,180)
        L.ShadowSoftness = 0; L.EnvironmentDiffuseScale = 0; L.EnvironmentSpecularScale = 0
        optTryHidden(L, "Technology", 0)
        for _, c in ipairs(L:GetChildren()) do if OPT_LIGHTING_TYPES[c.ClassName] then c:Destroy() end end
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            local clouds = terrain:FindFirstChildOfClass("Clouds"); if clouds then clouds:Destroy() end
            terrain.WaterWaveSize = 0; terrain.WaterWaveSpeed = 0; terrain.WaterReflectance = 0; terrain.WaterTransparency = 1
        end
        table.insert(optConnections, L.ChildAdded:Connect(function(child)
            if OPT_LIGHTING_TYPES[child.ClassName] then task.defer(child.Destroy, child) end
        end))
    end
    local function optCharacter(character)
        if not character then return end
        local hum = character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
            hum.NameDisplayDistance = 0; hum.HealthDisplayDistance = 0
        end
        for _, v in ipairs(character:GetDescendants()) do
            local cn = v.ClassName
            if OPT_VISUAL_TYPES[cn] then v:Destroy()
            elseif v:IsA("BasePart") then v.CastShadow = false; v.Reflectance = 0; v.Material = CHEAP_MATERIAL
            elseif cn == "Decal" or cn == "Texture" then v.Transparency = 1
            elseif cn == "SpecialMesh" then v.TextureId = ""
            elseif cn == "Accessory" then v:Destroy() end
        end
    end
    local function optWorkspaceScan()
        local Camera = workspace.CurrentCamera
        local charSet = {}
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do if p.Character then charSet[p.Character] = true end end
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj ~= Camera and not charSet[obj] then
                for _, v in ipairs(obj:GetDescendants()) do optApplyInstance(v) end
            end
        end
        table.insert(optConnections, workspace.ChildAdded:Connect(function(obj)
            if obj == workspace.CurrentCamera then return end
            task.defer(function() for _, v in ipairs(obj:GetDescendants()) do optApplyInstance(v) end end)
        end))
    end
    local function optPlayers()
        local PlayersService = game:GetService("Players")
        for _, p in ipairs(PlayersService:GetPlayers()) do
            if p.Character then optCharacter(p.Character) end
            table.insert(optConnections, p.CharacterAdded:Connect(function(char) task.defer(optCharacter, char) end))
        end
        table.insert(optConnections, PlayersService.PlayerAdded:Connect(function(p)
            table.insert(optConnections, p.CharacterAdded:Connect(function(char) task.defer(optCharacter, char) end))
        end))
    end
    local function optCamera()
        local cam = workspace.CurrentCamera; if not cam then return end
        cam.FieldOfView = 70
        for _, v in ipairs(cam:GetChildren()) do if OPT_LIGHTING_TYPES[v.ClassName] then v:Destroy() end end
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
        rs:Set3dRenderingEnabled(false); task.wait(0.1); rs:Set3dRenderingEnabled(true)
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
    optMainToggle = settingsTab:CreateToggle({
        Name = "Optimize All",
        CurrentValue = false,
        Flag = "OptimizeAll",
        Callback = function(Value) if not updatingOptimizations then setAllOptimizations(Value) end end,
    })
    optGPUToggle = settingsTab:CreateToggle({
        Name = "Optimize GPU (Low Graphics)",
        CurrentValue = false,
        Flag = "OptimizeGPU",
        Callback = function(Value)
            if updatingOptimizations then return end
            if Value then
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                local L = game:GetService("Lighting")
                L.GlobalShadows = false; L.EnvironmentDiffuseScale = 0; L.EnvironmentSpecularScale = 0
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") then v.CastShadow = false; v.Reflectance = 0; v.Material = CHEAP_MATERIAL end
                end
                local rs = game:GetService("RunService")
                rs:Set3dRenderingEnabled(false); task.wait(0.1); rs:Set3dRenderingEnabled(true)
            end
        end,
    })
    optParticlesToggle = settingsTab:CreateToggle({
        Name = "Remove All Particles & Effects",
        CurrentValue = false,
        Flag = "OptimizeParticles",
        Callback = function(Value)
            if updatingOptimizations then return end
            if Value then
                for _, v in ipairs(game:GetDescendants()) do if OPT_VISUAL_TYPES[v.ClassName] then v:Destroy() end end
            end
        end,
    })
    optFireToggle = settingsTab:CreateToggle({
        Name = "Remove Fire Effects",
        CurrentValue = false,
        Flag = "FireOptimization",
        Callback = function(Value)
            if updatingOptimizations then return end
            if Value then for _, v in ipairs(game:GetDescendants()) do if v:IsA("Fire") then v:Destroy() end end end
        end,
    })
    optGCToggle = settingsTab:CreateToggle({
        Name = "Lua GC (Memory Cleaner)",
        CurrentValue = false,
        Flag = "LuaGC",
        Callback = function(Value)
            if updatingOptimizations then return end
            if Value then
                if _G.__memoryCleaner then _G.__memoryCleaner:Disconnect() end
                _G.__memoryCleaner = game:GetService("RunService").Heartbeat:Connect(function() gcinfo() end)
            else
                if _G.__memoryCleaner then _G.__memoryCleaner:Disconnect(); _G.__memoryCleaner = nil end
            end
        end,
    })
    optIntenseToggle = settingsTab:CreateToggle({
        Name = "Intense Optimization",
        CurrentValue = false,
        Flag = "IntenseOptimization",
        Callback = function(Value)
            if updatingOptimizations then return end
            if Value then loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/Optimization.lua"))() end
        end,
    })
    optHideDamageToggle = settingsTab:CreateToggle({
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

    -- ==================== STATS TAB ====================
    local statsTab = window:CreateTab("Stats", 4483362458)
    local function safeGet(...)
        local data = DataService._data._data
        local cur = data
        for _, k in ipairs({...}) do
            if type(cur) ~= "table" then return 0 end
            cur = cur[k]
            if cur == nil then return 0 end
        end
        return cur
    end
    local function safeNum(...) return tonumber(safeGet(...)) or 0 end
    local suffixes = {{1e24,"Sp"},{1e21,"Sx"},{1e18,"Qn"},{1e15,"Qd"},{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}}
    local function fmt(n)
        n = tonumber(n) or 0
        for _, p in ipairs(suffixes) do
            if n >= p[1] then
                local s = string.format("%.2f", n / p[1]):gsub("%.?0+$","")
                return s .. p[2]
            end
        end
        return tostring(math.floor(n))
    end
    local function fmtTime(s)
        s = math.floor(tonumber(s) or 0)
        local d = math.floor(s/86400); local h = math.floor((s%86400)/3600); local m = math.floor((s%3600)/60)
        if d > 0 then return d.."d "..h.."h "..m.."m"
        elseif h > 0 then return h.."h "..m.."m"
        elseif m > 0 then return m.."m "..math.floor(s%60).."s"
        else return math.floor(s%60).."s" end
    end
    local function countKeys(t) if type(t)~="table" then return 0 end local c=0 for _ in pairs(t) do c=c+1 end return c end
    local function getBestRoll()
        local rd = safeGet("stats","rarestRoll","slimeData")
        if type(rd) ~= "table" then return "None", "N/A" end
        local id = tostring(rd.id or "?")
        local muts = rd.mutations
        local prefix = ""
        if type(muts) == "table" then
            if muts.inverted then prefix = "Inverted "
            elseif muts.shiny and muts.huge then prefix = "Shiny Huge "
            elseif muts.shiny and muts.big then prefix = "Shiny Big "
            elseif muts.huge then prefix = "Huge "
            elseif muts.shiny then prefix = "Shiny "
            elseif muts.big then prefix = "Big " end
        end
        local name = prefix .. id:sub(1,1):upper()..id:sub(2)
        local odds = safeNum("stats","rarestRoll","odds")
        return name, odds > 0 and ("1 in "..fmt(math.floor(odds))) or "N/A"
    end
    local function getEquipped()
        local eq = safeGet("equipped")
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
        local cats = safeGet("index","categories")
        if type(cats) ~= "table" then return 0,0,0,0,0 end
        local function c(cat) local t = cats[cat]; return type(t)=="table" and countKeys(t.unlocked or {}) or 0 end
        return c("basic"), c("big"), c("shiny"), c("huge"), c("inverted")
    end
    local function getTotalInv()
        local inv = safeGet("inventory")
        if type(inv)~="table" then return 0 end
        local t=0; for _,v in pairs(inv) do if type(v)=="number" then t=t+v end end; return t
    end
    local function getUniqueSpecies()
        local inv = safeGet("inventory")
        if type(inv)~="table" then return 0 end
        local seen={}; local c=0
        for k in pairs(inv) do
            if type(k)=="string" and not k:match("^%.") then
                local base = k:match("%-(.+)$") or k
                if not seen[base] then seen[base]=true; c=c+1 end
            end
        end; return c
    end

    local sessionStart = os.clock()
    local startRolls = safeNum("stats","rolls")
    local startKills = safeNum("stats","kills")
    local startCoins = safeNum("coins")
    local startGoop = safeNum("goop")
    local prevRolls, prevCoins, prevGoop = startRolls, startCoins, startGoop
    local lastWin = os.clock()
    local windowRPS, windowCPS, windowGPS = nil, nil, nil
    local lastRollMove, lastCoinMove, lastGoopMove = os.clock(), os.clock(), os.clock()
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
            prevRolls, prevCoins, prevGoop = r, c, g
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

    local statLabels = {}
    local function lbl(key, text) statLabels[key] = statsTab:CreateLabel(text) end
    lbl("sess", "Session: --  |  Played: --  |  Rebirths: --")
    lbl("rolls1", "Rolls/sec: --  |  Rolls/min: --  |  Rolls/hr: --")
    lbl("rolls2", "Session Rolls: --  |  Lifetime: --")
    lbl("coins1", "Coins/min: --  |  Coins/hr: --")
    lbl("coins2", "Session Coins: --  |  Total Ever: --")
    lbl("goop1", "Goop/min: --  |  Goop/hr: --")
    lbl("goop2", "Session Goop: --  |  Balance: --")
    lbl("kills", "Session Kills: --  |  Lifetime Kills: --")
    lbl("best", "Best Ever: --  |  Odds: --")
    lbl("daily", "Best Today Odds: --")
    lbl("prog", "Zone: --  |  Max Zone: --  |  Roll Currency: --")
    lbl("idx1", "Basic: --  |  Big: --  |  Shiny: --  |  Huge: --  |  Inverted: --")
    lbl("inv", "Total Slimes: --  |  Species: --  |  Crafting: --")
    lbl("equipped", "Equipped: --")

    local function updateStats()
        local now = os.clock()
        local elapsed = math.max(1, now - sessionStart)
        local rolls = safeNum("stats","rolls")
        local kills = safeNum("stats","kills")
        local coins = safeNum("coins")
        local goop = safeNum("goop")
        local timePl = safeNum("stats","timePlayed")
        local totCoins = safeNum("stats","totalCoins")
        local rebirths = safeNum("rebirths")
        local zone = safeNum("zone")
        local maxZone = safeNum("furthestZone")
        local rollCur = safeNum("rollCurrency")
        local sessRolls = math.max(0, rolls - startRolls)
        local sessKills = math.max(0, kills - startKills)
        local sessCoins = math.max(0, coins - startCoins)
        local sessGoop = math.max(0, goop - startGoop)
        local sessH = math.floor(elapsed/3600); local sessM = math.floor((elapsed%3600)/60); local sessS = math.floor(elapsed%60)
        local rps = getRate(windowRPS, lastRollMove, startRolls, rolls)
        local cps = getRate(windowCPS, lastCoinMove, startCoins, coins)
        local gps = getRate(windowGPS, lastGoopMove, startGoop, goop)
        local bestName, bestOdds = getBestRoll()
        local dailyOdds = safeNum("stats","dailyRarestRoll","odds")
        local dailyStr = dailyOdds > 0 and ("1 in "..fmt(math.floor(dailyOdds))) or "N/A"
        local basic, big, shiny, huge, inverted = getIndexCounts()
        local crafting = countKeys(safeGet("craftingRecipes") or {})
        statLabels.sess:Set(string.format("Session: %dh%dm%ds  |  Played: %s  |  Rebirths: %s", sessH, sessM, sessS, fmtTime(timePl), fmt(rebirths)))
        statLabels.rolls1:Set(string.format("Rolls/sec: %.2f  |  Rolls/min: %s  |  Rolls/hr: %s", rps, fmt(rps*60), fmt(rps*3600)))
        statLabels.rolls2:Set("Session Rolls: "..fmt(sessRolls).."  |  Lifetime: "..fmt(rolls))
        statLabels.coins1:Set("Coins/min: "..fmt(cps*60).."  |  Coins/hr: "..fmt(cps*3600))
        statLabels.coins2:Set("Session Coins: "..fmt(sessCoins).."  |  Total Ever: "..fmt(totCoins))
        statLabels.goop1:Set("Goop/min: "..fmt(gps*60).."  |  Goop/hr: "..fmt(gps*3600))
        statLabels.goop2:Set("Session Goop: "..fmt(sessGoop).."  |  Balance: "..fmt(goop))
        statLabels.kills:Set("Session Kills: "..fmt(sessKills).."  |  Lifetime Kills: "..fmt(kills))
        statLabels.best:Set("Best Ever: "..bestName.."  |  Odds: "..bestOdds)
        statLabels.daily:Set("Best Today Odds: "..dailyStr)
        statLabels.prog:Set("Zone: "..fmt(zone).."  |  Max Zone: "..fmt(maxZone).."  |  Roll Currency: "..fmt(rollCur))
        statLabels.idx1:Set("Basic: "..basic.."  |  Big: "..big.."  |  Shiny: "..shiny.."  |  Huge: "..huge.."  |  Inverted: "..inverted)
        statLabels.inv:Set("Total Slimes: "..fmt(getTotalInv()).."  |  Species: "..getUniqueSpecies().."  |  Crafting: "..crafting)
        statLabels.equipped:Set("Equipped: "..getEquipped())
    end
    task.spawn(function() while true do updateStats(); task.wait(2) end end)

    -- ==================== CRAFTING (Integrated into Game tab) ====================
    local craftingTab = gameTab
    local function getCraftingRemote()
        return ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("CraftingService"):WaitForChild("RemoteFunction")
    end
    local RecipesModule = require(Source.Features.Crafting.Recipes)
    local function getMutationValue(mutId) local data = Mutations.get(mutId); return data and data.value or 0 end
    local function getSizeMutations() return Mutations.sizeMutations or {} end
    local function getModifierMutations() return Mutations.modifierMutations or {} end
    local function parseUniqueId(uid)
        local base, sizeMut, modMut = uid, nil, nil
        for _, sId in ipairs(getSizeMutations()) do
            local prefix = sId .. "_"
            if base:sub(1, #prefix) == prefix then sizeMut = sId; base = base:sub(#prefix + 1); break end
        end
        if base:sub(1,1) == "-" then base = base:sub(2) end
        for _, mId in ipairs(getModifierMutations()) do
            local suffix = "_" .. mId
            if base:sub(-#suffix) == suffix then modMut = mId; base = base:sub(1, -#suffix - 1); break end
        end; return base, sizeMut, modMut
    end
    local function scoreUniqueId(uid)
        local _, sizeMut, modMut = parseUniqueId(uid)
        local score = 0
        if sizeMut then score = score + getMutationValue(sizeMut) * 1000 end
        if modMut then score = score + getMutationValue(modMut) * 100 end
        return score
    end
    local function getOwnedAmount(data) if type(data)=="number" then return math.max(data,0) elseif type(data)=="table" then return 1 else return 0 end end
    local function isXpSlime(data) return type(data)=="table" end
    local function getEquippedSet() local eq = DataService:get("equipped") or {}; local set={}; for _,uid in ipairs(eq) do set[uid]=true end; return set end
    local function getBestSlimeSet()
        local inv = DataService:get("inventory") or {}
        local best, bestScore = nil, -1
        for uid, data in pairs(inv) do
            if not isXpSlime(data) then
                local s = scoreUniqueId(uid)
                if s > bestScore then bestScore = s; best = uid end
            end
        end
        local set={}; if best then set[best]=true end; return set
    end
    local function getXpSlimeSet() local inv=DataService:get("inventory") or {}; local set={}; for uid,data in pairs(inv) do if isXpSlime(data) then set[uid]=true end end; return set end
    local function buildProtectedSet(categories)
        local catSet={}; for _,c in ipairs(categories) do catSet[c]=true end
        local protected={}
        if catSet["Equipped Slimes"] then for uid in pairs(getEquippedSet()) do protected[uid]=true end end
        if catSet["Best Slime"] then for uid in pairs(getBestSlimeSet()) do protected[uid]=true end end
        if catSet["Xp Slimes"] then for uid in pairs(getXpSlimeSet()) do protected[uid]=true end end
        return protected
    end
    local function getUnlockedRecipeIds()
        local unlocked = DataService:get("craftingRecipes") or {}
        local all = RecipesModule.getRecipes() or {}
        local result={}; for _,recipe in ipairs(all) do if unlocked[recipe.id] then table.insert(result, recipe.id) end end; return result
    end
    local function getRecipe(id) return RecipesModule.getRecipe(id) end
    local function findBestIngredient(baseId, usedCounts, protectedPets)
        local inv = DataService:get("inventory") or {}
        local bestUid, bestScore = nil, -1
        for uid, data in pairs(inv) do
            if not protectedPets[uid] then
                local parsedBase = parseUniqueId(uid)
                if parsedBase == baseId then
                    local owned = getOwnedAmount(data)
                    local used = usedCounts[uid] or 0
                    if owned - used > 0 then
                        local s = scoreUniqueId(uid)
                        if s > bestScore then bestScore = s; bestUid = uid end
                    end
                end
            end
        end; return bestUid
    end
    local craftingState = { selectedRecipeIds = {}, craftAmount = 1, autoCraftEnabled = false, autoCraftAmount = 1, autoCraftThread = nil, protectCategories = { "Best Slime", "Equipped Slimes", "Xp Slimes" }, protectedPets = {} }
    craftingState.protectedPets = buildProtectedSet(craftingState.protectCategories)
    local function getMaxCraftsForRecipe(recipeId)
        local recipe = getRecipe(recipeId); if not recipe then return 0 end
        local inv = DataService:get("inventory") or {}
        local usedCounts = {}; local maxCrafts = math.huge
        for _, inp in ipairs(recipe.inputs) do
            local bestUid = findBestIngredient(inp.id, usedCounts, craftingState.protectedPets)
            if not bestUid then return 0 end
            usedCounts[bestUid] = (usedCounts[bestUid] or 0) + 1
            local owned = getOwnedAmount(inv[bestUid])
            local used = usedCounts[bestUid]
            local available = owned - used + 1
            if available < maxCrafts then maxCrafts = available end
        end; return maxCrafts == math.huge and 0 or maxCrafts
    end
    local function buildCraftArgsForRecipe(recipeId, amount)
        local recipe = getRecipe(recipeId); if not recipe then return nil end
        local ingredientIds = {}; local usedCounts = {}
        for _, inp in ipairs(recipe.inputs) do
            local uid = findBestIngredient(inp.id, usedCounts, craftingState.protectedPets) or ("-" .. inp.id)
            usedCounts[uid] = (usedCounts[uid] or 0) + 1
            table.insert(ingredientIds, uid)
        end; return { "requestCraftRecipe", recipeId, ingredientIds, tostring(amount) }
    end
    local function doCraftAll(amount)
        local results = {}
        for _, recipeId in ipairs(craftingState.selectedRecipeIds) do
            local args = buildCraftArgsForRecipe(recipeId, amount)
            if args then
                local result = getCraftingRemote():InvokeServer(table.unpack(args))
                results[recipeId] = result ~= false
            end
        end; return results
    end
    local recipeIdsList = getUnlockedRecipeIds()
    if #recipeIdsList > 0 then craftingState.selectedRecipeIds = { recipeIdsList[1] } end
    craftingTab:CreateSection("Recipes")
    craftingTab:CreateDropdown({
        Name = "Select Recipes to Craft",
        Options = recipeIdsList,
        CurrentOption = { recipeIdsList[1] or "" },
        MultipleOptions = true,
        Flag = "CraftingSelectedRecipes",
        Callback = function(opts) craftingState.selectedRecipeIds = opts end,
    })
    craftingTab:CreateSection("Craft")
    craftingTab:CreateSlider({
        Name = "Craft Amount", Range = {1,99}, Increment = 1, Suffix = "x", CurrentValue = 1,
        Flag = "CraftingAmount", Callback = function(val) craftingState.craftAmount = val end,
    })
    craftingTab:CreateButton({
        Name = "Craft Now",
        Callback = function()
            local results = doCraftAll(craftingState.craftAmount)
            local succeeded, failed = 0, 0
            for _, ok in pairs(results) do if ok then succeeded = succeeded+1 else failed = failed+1 end end
            rayfield:Notify({Title = "Cactus Hub", Content = succeeded .. " crafts succeeded" .. (failed>0 and (", "..failed.." failed") or ""), Duration = 3, Image = 4483362458})
        end,
    })
    craftingTab:CreateSection("Auto Craft")
    local autoCraftMax = 1
    local function updateAutoCraftMax()
        local minMax = math.huge
        for _, recipeId in ipairs(craftingState.selectedRecipeIds) do
            local maxCrafts = getMaxCraftsForRecipe(recipeId)
            if maxCrafts < minMax then minMax = maxCrafts end
        end; autoCraftMax = (minMax == math.huge and 1) or math.max(1, minMax)
    end
    updateAutoCraftMax()
    craftingTab:CreateSlider({
        Name = "Auto Craft Amount", Range = {1,99}, Increment = 1, Suffix = "x", CurrentValue = 1,
        Flag = "CraftingAutoAmount", Callback = function(val) craftingState.autoCraftAmount = val end,
    })
    craftingTab:CreateToggle({
        Name = "Enable Auto Craft",
        CurrentValue = false,
        Flag = "CraftingAutoToggle",
        Callback = function(enabled)
            craftingState.autoCraftEnabled = enabled
            if enabled then
                updateAutoCraftMax()
                local maxAmount = autoCraftMax
                if craftingState.autoCraftAmount > maxAmount then craftingState.autoCraftAmount = maxAmount end
                if craftingState.autoCraftThread then task.cancel(craftingState.autoCraftThread) end
                craftingState.autoCraftThread = task.spawn(function()
                    while craftingState.autoCraftEnabled do
                        updateAutoCraftMax()
                        local craftAmount = math.min(craftingState.autoCraftAmount, autoCraftMax)
                        if craftAmount > 0 then doCraftAll(craftAmount) end
                        task.wait(5)
                    end
                end)
                rayfield:Notify({Title = "Auto Craft", Content = "Started - "..craftingState.autoCraftAmount.."x per recipe (max "..autoCraftMax..")", Duration = 3, Image = 4483362458})
            else
                if craftingState.autoCraftThread then task.cancel(craftingState.autoCraftThread); craftingState.autoCraftThread = nil end
                rayfield:Notify({Title = "Auto Craft", Content = "Stopped.", Duration = 3, Image = 4483362458})
            end
        end,
    })
    craftingTab:CreateSection("Protected Pets")
    craftingTab:CreateDropdown({
        Name = "Protect Categories",
        Options = { "Best Slime", "Equipped Slimes", "Xp Slimes" },
        CurrentOption = { "Best Slime", "Equipped Slimes", "Xp Slimes" },
        MultipleOptions = true,
        Flag = "CraftingProtectCategories",
        Callback = function(opts) craftingState.protectCategories = opts; craftingState.protectedPets = buildProtectedSet(opts) end,
    })
    rayfield:Notify({Title = "Cactus Hub", Content = "Loaded - "..#recipeIdsList.." unlocked recipes ready.", Duration = 5, Image = 4483362458})

    -- Anti AFK
    local vu = game:GetService('VirtualUser')
    player.Idled:Connect(function() vu:CaptureController(); vu:ClickButton2(Vector2.new()) end)

    -- Auto Rejoin
    game:GetService("GuiService").ErrorMessageChanged:Connect(function()
        if rayfield.Flags.SettingsAutoRejoin and rayfield.Flags.SettingsAutoRejoin.CurrentValue then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
        end
    end)

    rayfield:LoadConfiguration()
end)
