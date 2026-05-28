task.spawn(function()
    repeat task.wait() until game:IsLoaded()
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local player = Players.LocalPlayer

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
        local replicatedStorage = game:GetService("ReplicatedStorage")
        local playersService = game:GetService("Players")
        local localPlayer = playersService.LocalPlayer
        local runService = game:GetService("RunService")
        local virtualUser = game:GetService("VirtualUser")
        local httpService = game:GetService("HttpService")

        local packages = replicatedStorage:WaitForChild("Packages")
        local indexFolder = packages:WaitForChild("_Index")
        local networker = indexFolder:WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker")
        local remotes = networker:WaitForChild("_remotes")

        local dataServiceClient = require(packages.DataService).client
        dataServiceClient:waitForData()

        local networkerModule = require(packages.Networker)

        local inventoryServiceClient, xpTransferServiceClient
        inventoryServiceClient = networkerModule.client.new("InventoryService")
        xpTransferServiceClient = networkerModule.client.new("XpTransferService")

        local function getRemoteFunction(remoteName)
            local remoteFolder = remotes:FindFirstChild(remoteName) or remotes:WaitForChild(remoteName, 10)
            if not remoteFolder then return nil end
            local remoteFunction = remoteFolder:FindFirstChild("RemoteFunction") or remoteFolder:WaitForChild("RemoteFunction", 10)
            return remoteFunction
        end

        local rollServiceRemote = getRemoteFunction("RollService")
        local codeServiceRemote = getRemoteFunction("CodeService")
        local inventoryServiceRemote = getRemoteFunction("InventoryService")
        local rebirthServiceRemote = getRemoteFunction("RebirthService")
        local zonesServiceRemote = getRemoteFunction("ZonesService")
        local upgradeServiceRemote = getRemoteFunction("UpgradeService")
        local boostServiceRemote = getRemoteFunction("BoostService")
        local offlineEarningsRemote = getRemoteFunction("OfflineEarningsService")
        local indexServiceRemote = getRemoteFunction("IndexService")
        local lootServiceRemote = getRemoteFunction("LootService")

        local source = replicatedStorage:WaitForChild("Source", 30)
        if not source then return end

        local rarityTiers = require(source.Game.Items.RarityTiers)
        local upgradeTree = require(source.Features.Upgrades.UpgradeTree)
        local indexRewards = require(source.Features.Index.IndexRewards)
        local boostServiceUtils = require(source.Features.Boosts.BoostServiceUtils)
        local specialDiceUtils = require(source.Features.SpecialDice.SpecialDiceServiceUtils)
        local rollSlice = require(source.Features.Roll.RollSlice)
        local slimesModule = require(source.Game.Items.Slimes)
        local mutationsModule = require(source.Features.Mutations.Mutations)

        local boostKinds = boostServiceUtils.getKinds()
        local inventoryItemIds = specialDiceUtils.getInventoryItemIds()

        local itemIdToName = {}
        local itemNameToId = {}
        for _, itemId in ipairs(inventoryItemIds) do
            local definition = specialDiceUtils.getDefinition(itemId)
            local itemName = definition and definition.name or itemId
            itemIdToName[itemId] = itemName
            itemNameToId[itemName] = itemId
        end

        local function formatNumber(number)
            if type(number) ~= "number" then return tostring(number) end
            local suffixes = {
                {1e24,"Sp"},{1e21,"Sx"},{1e18,"Qn"},{1e15,"Qd"},{1e12,"T"},
                {1e9,"B"},{1e6,"M"},{1e3,"K"}
            }
            for _, suffixData in ipairs(suffixes) do
                if math.abs(number) >= suffixData[1] then
                    local formatted = number / suffixData[1]
                    if math.abs(formatted - math.floor(formatted)) < 0.01 then
                        return string.format("%d%s", math.floor(formatted), suffixData[2])
                    else
                        return string.format("%.1f%s", formatted, suffixData[2])
                    end
                end
            end
            return tostring(math.floor(number))
        end

        local function getRarityName(odds)
            if not odds or type(odds) ~= "number" or odds <= 0 then return "Unknown" end
            local success, tierData = rarityTiers.getTier(odds)
            return (success and tierData and tierData.name) or "Unknown"
        end

        local function extractSlimeData(rollResultTable)
            if type(rollResultTable) ~= "table" then return nil end
            for _, item in ipairs(rollResultTable) do
                if type(item) == "table" and item.id then return item end
            end
            return nil
        end

        local function encodeRollResults(rollResults)
            if type(rollResults) ~= "table" or #rollResults == 0 then return "empty" end
            local encoded = {}
            for index, roll in ipairs(rollResults) do
                local slimeData = extractSlimeData(roll)
                encoded[index] = slimeData and tostring(slimeData.id) or tostring(index)
            end
            return #rollResults .. "|" .. table.concat(encoded, ",")
        end

        local function getMutationType(mutations)
            if not mutations then return "basic" end
            if mutations.inverted then return "inverted" end
            if mutations.huge then return "huge" end
            if mutations.big then return "big" end
            if mutations.shiny then return "shiny" end
            return "basic"
        end

        local function isNewSlime(slimeId, mutations)
            local indexData = dataServiceClient:get("index") or {}
            local categories = indexData.categories or {}
            local category = categories[getMutationType(mutations)]
            local unlocked = category and category.unlocked or {}
            return not unlocked[slimeId]
        end

        local function getMutationTypeString(mutations)
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
                local decoded = httpService:JSONDecode(response.Body)
                if decoded and decoded.data and decoded.data[1] then
                    thumbnailCache[assetId] = decoded.data[1].imageUrl
                    return thumbnailCache[assetId]
                end
            end
            return nil
        end

        local function getThumbnailSize(mutations)
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

        local function ordinalSuffix(number)
            local numStr = tostring(number)
            local lastDigit = number % 10
            local lastTwo = number % 100
            if lastTwo >= 11 and lastTwo <= 13 then return numStr.."th" end
            if lastDigit == 1 then return numStr.."st" end
            if lastDigit == 2 then return numStr.."nd" end
            if lastDigit == 3 then return numStr.."rd" end
            return numStr.."th"
        end

        local recentWebhookNotifications = {}

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
                if mutations.inverted then multiplier = multiplier * (mutationsModule.getVisualOddsMultiplier(mutations) or 1) end
                if mutations.huge then multiplier = multiplier * (mutationsModule.getVisualOddsMultiplier(mutations) or 1) end
                if mutations.big then multiplier = multiplier * (mutationsModule.getVisualOddsMultiplier(mutations) or 1) end
                if mutations.shiny then multiplier = multiplier * (mutationsModule.getVisualOddsMultiplier(mutations) or 1) end
            end
            local chance = odds > 0 and (1 / odds) * multiplier or 0
            return chance
        end

        local WEBHOOK_AVATAR = "https://media.discordapp.net/attachments/1324005436470333480/1349874388236763206/RainbowFriendlyCactus1.png?ex=6a1426bd&is=6a12d53d&hm=adc011c12e097b4238f08364c0ffbd6f30c9eff3f51b7706219b6c8cba76932d&=&format=png"

        local function sendWebhookNotification(slimeId, slimeData, mutations, webhookUrl, mentionUserId, notificationKey)
            if recentWebhookNotifications[notificationKey] then return end
            recentWebhookNotifications[notificationKey] = true
            
            local mentionText = formatMention(mentionUserId)
            local slimeName = slimeData and slimeData.name or slimeId
            local displayName = mutations and mutationsModule.getDisplayName(slimeName, mutations) or slimeName
            local odds = slimeData and slimeData.odds or nil
            local damage = slimeData and slimeData.damage or 0
            local health = slimeData and slimeData.health or 0
            local oddsMultiplier = mutations and mutationsModule.getVisualOddsMultiplier(mutations) or 1
            local statBonus = mutations and mutationsModule.getStatBonus(mutations, "damage") or 1
            local actualOdds = odds and (odds / oddsMultiplier) or nil
            local rarityName = getRarityName(odds)
            local chanceText = (actualOdds and type(actualOdds) == "number" and actualOdds > 0) and string.format("1 in %s", formatNumber(math.floor(1 / actualOdds + 0.5))) or "N/A"

            local iconAssetId = (mutations and mutations.inverted) and (slimeData and slimeData.invertedIcon) or (slimeData and slimeData.image)
            local thumbnailUrl = nil
            if iconAssetId and iconAssetId ~= "N/A" then
                local assetNumber = string.match(tostring(iconAssetId), "rbxassetid://(%d+)")
                if assetNumber then thumbnailUrl = getThumbnailUrl(assetNumber) end
            end

            local mutationIds = mutations and mutationsModule.getIds(mutations) or {}
            local finalDamage = damage * statBonus
            local finalHealth = health * statBonus
            local statsString = ""
            if finalDamage > 0 and finalHealth > 0 then
                statsString = string.format("⚔️ %s  ❤️ %s", formatNumber(finalDamage), formatNumber(finalHealth))
            elseif finalDamage > 0 then
                statsString = string.format("⚔️ %s", formatNumber(finalDamage))
            elseif finalHealth > 0 then
                statsString = string.format("❤️ %s", formatNumber(finalHealth))
            end

            local statsData = dataServiceClient:get("stats") or {}
            local totalRolls = statsData.rolls or 0
            local totalKills = statsData.kills or 0
            local coins = dataServiceClient:get("coins") or 0
            local playerName = localPlayer and localPlayer.Name or "Someone"
            local thumbnailSize = getThumbnailSize(mutations)

            local embedFields = {
                {name = "Rarity", value = rarityName,     inline = true},
                {name = "Chance", value = chanceText,  inline = true},
            }
            if statsString ~= "" then
                table.insert(embedFields, {name = "Stats", value = statsString, inline = true})
            end
            if #mutationIds > 0 then
                table.insert(embedFields, {name = "Mutations", value = table.concat(mutationIds, ", "), inline = true})
            end
            table.insert(embedFields, {name = "💰 Coins", value = formatNumber(coins), inline = true})
            table.insert(embedFields, {name = "⚔️ Kills", value = formatNumber(totalKills), inline = true})

            local userEmbed = {
                title       = "🎲 New Slime Rolled!",
                description = string.format("**||%s||** rolled **%s**!\n\n🎲 **Total Rolls:** %s", playerName, displayName, ordinalSuffix(totalRolls)),
                thumbnail   = thumbnailUrl and {url = thumbnailUrl, width = thumbnailSize, height = thumbnailSize} or nil,
                fields      = embedFields,
                color       = getEmbedColor(mutations),
            }

            request({
                Url = webhookUrl,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = httpService:JSONEncode({
                    content = mentionText,
                    username = "Cactus Hub",
                    avatar_url = WEBHOOK_AVATAR,
                    embeds = {userEmbed}
                })
            })

            if PUBLIC_MINIMUM_CHANCE then
                local rollChance = getOddsValue(odds, mutations)
                if rollChance >= PUBLIC_MINIMUM_CHANCE then
                    local publicFields = {}
                    for _, field in ipairs(embedFields) do
                        if field.name ~= "💰 Coins" and field.name ~= "⚔️ Kills" then
                            table.insert(publicFields, field)
                        end
                    end
                    local publicEmbed = {
                        title       = "🎲 New Slime Rolled!",
                        description = string.format("**Someone** rolled **%s**!\n\n🎲 **Total Rolls:** %s", displayName, ordinalSuffix(totalRolls)),
                        thumbnail   = thumbnailUrl and {url = thumbnailUrl, width = thumbnailSize, height = thumbnailSize} or nil,
                        fields      = publicFields,
                        color       = getEmbedColor(mutations),
                    }
                    request({
                        Url = PUBLIC_WEBHOOK_URL,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = httpService:JSONEncode({
                            content = "",
                            username = "Cactus Hub",
                            avatar_url = WEBHOOK_AVATAR,
                            embeds = {publicEmbed}
                        })
                    })
                end
            else
                local publicFields = {}
                for _, field in ipairs(embedFields) do
                    if field.name ~= "💰 Coins" and field.name ~= "⚔️ Kills" then
                        table.insert(publicFields, field)
                    end
                end
                local publicEmbed = {
                    title       = "🎲 New Slime Rolled!",
                    description = string.format("**Someone** rolled **%s**!\n\n🎲 **Total Rolls:** %s", displayName, ordinalSuffix(totalRolls)),
                    thumbnail   = thumbnailUrl and {url = thumbnailUrl, width = thumbnailSize, height = thumbnailSize} or nil,
                    fields      = publicFields,
                    color       = getEmbedColor(mutations),
                }
                request({
                    Url = PUBLIC_WEBHOOK_URL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = httpService:JSONEncode({
                        content = "",
                        username = "Cactus Hub",
                        avatar_url = WEBHOOK_AVATAR,
                        embeds = {publicEmbed}
                    })
                })
            end
        end

        local function getBestSlimeUid()
            local statsData = dataServiceClient:get("stats") or {}
            local rarestRoll = statsData.rarestRoll
            if not rarestRoll or not rarestRoll.slimeData then return nil end
            local slimeData = rarestRoll.slimeData
            local mutations = slimeData.mutations or {}
            local inventory = dataServiceClient:get("inventory") or {}
            for uid, data in pairs(inventory) do
                if type(data) == "table" and data.id == slimeData.id then
                    local matches = true
                    for mutKey, mutValue in pairs(mutations) do
                        if data.mutations and data.mutations[mutKey] ~= mutValue then
                            matches = false
                            break
                        end
                    end
                    if matches then return uid end
                end
            end
            return nil
        end

        local function getAllUpgrades()
            local upgradeIds = {}
            local upgradeCosts = {}
            local visited = {}
            
            local function traverseUpgrades(upgradeTable)
                if type(upgradeTable) ~= "table" or visited[upgradeTable] then return end
                visited[upgradeTable] = true
                for key, value in pairs(upgradeTable) do
                    if type(value) == "table" then
                        if value.cost then
                            table.insert(upgradeIds, key)
                            upgradeCosts[key] = value.cost
                        end
                        traverseUpgrades(value)
                    end
                end
            end
            
            traverseUpgrades(upgradeTree.main)
            return upgradeIds, upgradeCosts
        end

        local gameplayFolder = nil
        local function getGameplayFolder()
            if gameplayFolder and gameplayFolder.Parent then return gameplayFolder end
            for _, child in ipairs(workspace:GetChildren()) do
                if child.Name:match("^Gameplay") then
                    gameplayFolder = child
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

        local mainWindow = rayfield:CreateWindow({
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

        local mainTab = mainWindow:CreateTab("Main", 138602335586757)

        mainTab:CreateSection("Status")

        local fpsLabel = mainTab:CreateLabel("FPS: Calculating...")
        local pingLabel = mainTab:CreateLabel("Ping: Calculating...")

        local frameCount = 0
        local lastTime = tick()
        runService.RenderStepped:Connect(function()
            frameCount = frameCount + 1
            local currentTime = tick()
            if currentTime - lastTime >= 1 then
                fpsLabel:Set("FPS: " .. math.floor(frameCount / (currentTime - lastTime)))
                frameCount = 0
                lastTime = currentTime
            end
        end)

        task.spawn(function()
            while true do
                local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                pingLabel:Set("Ping: " .. math.floor(ping) .. "ms")
                task.wait(1)
            end
        end)

        mainTab:CreateParagraph({
            Title = "Enabled By Default",
            Content = "[+] Anti AFK"
        })

        mainTab:CreateParagraph({
            Title = "Latest Update",
            Content = "[+] Auto Send & Accept Friend Requests\n[+] Fixed Auto Collect Loot\n[+] Fixed Settings (Optimization Toggles)\n[+] Added Public Webhook in Discord\n[+] Hide Attack & Damage UI\n[+] Bug Fixes"
        })

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
                    local gui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("__MAINHUD__")
                    if gui then
                        gui:Destroy()
                    end
                    rayfield:Notify({Title = "Dashboard", Content = "Dashboard closed!", Duration = 3})
                    dashboardBusy = false
                end
            end,
        })

        mainTab:CreateButton({
            Name = "Save Config Manually",
            Callback = function()
                rayfield:SaveConfiguration()
            end,
        })

        local farmingTab = mainWindow:CreateTab("Farming", 138602335586757)

        farmingTab:CreateSection("Zones")

        local ZonesModule = require(replicatedStorage:WaitForChild("Source").Game.Items.Zones)
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
            Callback = function(option)
            end,
        })

        farmingTab:CreateToggle({
            Name = "Auto Farm Zone",
            CurrentValue = false,
            Flag = "FarmingStayInBestZone",
            Callback = function(enabled)
                if enabled then
                    task.spawn(function()
                        while rayfield.Flags.FarmingStayInBestZone and rayfield.Flags.FarmingStayInBestZone.CurrentValue do
                            local targetOption = rayfield.Flags.FarmingZoneTarget.CurrentOption[1]
                            if targetOption == "Best Unlocked" then
                                local maxZone = 33
                                for zoneNum = maxZone, 1, -1 do
                                    if not (rayfield.Flags.FarmingStayInBestZone and rayfield.Flags.FarmingStayInBestZone.CurrentValue) then break end
                                    zonesServiceRemote:InvokeServer("requestTeleportZone", zoneNum)
                                    task.wait(1)
                                    if (dataServiceClient:get("zone") or 1) == zoneNum then break end
                                end
                            else
                                local zoneNum = tonumber(targetOption:match("Zone (%d+)"))
                                if zoneNum then
                                    zonesServiceRemote:InvokeServer("requestTeleportZone", zoneNum)
                                end
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
            Callback = function(enabled)
                if enabled then
                    task.spawn(function()
                        while rayfield.Flags.FarmingUnlockAffordableZones and rayfield.Flags.FarmingUnlockAffordableZones.CurrentValue do
                            zonesServiceRemote:InvokeServer("requestPurchaseZone")
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
            Callback = function(enabled)
                if enabled then
                    task.spawn(function()
                        local waitTime = 30
                        while rayfield.Flags.FarmingEquipBestSlimes and rayfield.Flags.FarmingEquipBestSlimes.CurrentValue do
                            inventoryServiceRemote:InvokeServer("requestEquipBest")
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
            Callback = function(enabled) end,
        })

        task.spawn(function()
            while task.wait(10) do
                if rayfield.Flags.FarmingAutoFeed and rayfield.Flags.FarmingAutoFeed.CurrentValue then
                    local bestSlimeUid = getBestSlimeUid()
                    if bestSlimeUid then
                        local items = dataServiceClient:get("items") or {}
                        for itemId, quantity in pairs(items) do
                            if type(quantity) == "number" and quantity > 0 then
                                inventoryServiceClient:fetch("requestUseFood", itemId, bestSlimeUid, quantity)
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
            Callback = function(enabled) end,
        })

        farmingTab:CreateDropdown({
            Name = "Transfer To",
            Options = { "Best Slime", "Whole Team" },
            CurrentOption = { "Best Slime" },
            MultipleOptions = false,
            Flag = "FarmingTransferTarget",
            Callback = function(option) end,
        })

        farmingTab:CreateDropdown({
            Name = "Transfer From",
            Options = { "Unequipped With XP", "All Slimes" },
            CurrentOption = { "Unequipped With XP" },
            MultipleOptions = false,
            Flag = "FarmingTransferSource",
            Callback = function(option) end,
        })

        task.spawn(function()
            while task.wait(30) do
                if rayfield.Flags.FarmingTransferXP and rayfield.Flags.FarmingTransferXP.CurrentValue then
                    local inventory = dataServiceClient:get("inventory") or {}
                    local equipped = dataServiceClient:get("equipped") or {}
                    local equippedSet = {}
                    for _, uid in ipairs(equipped) do equippedSet[uid] = true end
                    local targetOption = rayfield.Flags.FarmingTransferTarget.CurrentOption[1]
                    local sourceOption = rayfield.Flags.FarmingTransferSource.CurrentOption[1]
                    local targets = {}
                    if targetOption == "Best Slime" then
                        local best = getBestSlimeUid()
                        if best then targets = { best } end
                    else
                        for _, uid in ipairs(equipped) do table.insert(targets, uid) end
                    end
                    for _, target in ipairs(targets) do
                        for uid, data in pairs(inventory) do
                            if uid ~= target then
                                local isEquipped = equippedSet[uid]
                                local hasXp = (type(data) == "table" and (data.xp or 0) > 0) or (type(data) == "number" and data > 0)
                                if sourceOption == "Unequipped With XP" and not isEquipped and hasXp then
                                    xpTransferServiceClient:fetch("requestTransferXp", uid, target)
                                    task.wait(0.5)
                                elseif sourceOption == "All Slimes" and hasXp then
                                    xpTransferServiceClient:fetch("requestTransferXp", uid, target)
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
            Callback = function(enabled)
                if enabled then
                    task.spawn(function()
                        local rollSliceModule = require(replicatedStorage:WaitForChild("Source"):WaitForChild("Features"):WaitForChild("Roll"):WaitForChild("RollSlice"))
                        while rayfield.Flags.FarmingFastRoll and rayfield.Flags.FarmingFastRoll.CurrentValue do
                            game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("RollService"):WaitForChild("RemoteFunction"):InvokeServer("requestRoll")
                            task.wait(rollSliceModule.rollTime())
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
            Callback = function(enabled)
                if enabled then
                    task.spawn(function()
                        print("[CactusHub] Auto Collect Loot started")
                        while rayfield.Flags.FarmingCollectLoot and rayfield.Flags.FarmingCollectLoot.CurrentValue do
                            for _, folderName in ipairs({"Loot", "Debris"}) do
                                local container = workspace:FindFirstChild(folderName)
                                if container then
                                    for _, item in ipairs(container:GetChildren()) do
                                        local id = item:GetAttribute("uniqueId") or item:GetAttribute("id") or item.Name
                                        if id then
                                            local success = lootServiceRemote:InvokeServer("requestCollect", id)
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

        local gameTab = mainWindow:CreateTab("Game", 82493603309814)

        gameTab:CreateSection("Rebirth")

        gameTab:CreateToggle({
            Name = "Auto Rebirth",
            CurrentValue = false,
            Flag = "GameAutoRebirth",
            Callback = function(enabled)
                if enabled then
                    task.spawn(function()
                        while rayfield.Flags.GameAutoRebirth and rayfield.Flags.GameAutoRebirth.CurrentValue do
                            local rebirths = dataServiceClient:get("rebirths") or 0
                            local goop = dataServiceClient:get("goop") or 0
                            local furthestZone = dataServiceClient:get("furthestZone") or 0
                            local requiredGoop = (2 ^ rebirths) * 500
                            local minZone = tonumber(rayfield.Flags.GameMinZoneRebirth and rayfield.Flags.GameMinZoneRebirth.CurrentValue or 0)
                            if furthestZone >= minZone and goop >= requiredGoop then
                                rebirthServiceRemote:InvokeServer("requestRebirth")
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
            Callback = function(value) end,
        })

        gameTab:CreateSection("Upgrades")

        gameTab:CreateToggle({
            Name = "Auto Upgrade Purchasing",
            CurrentValue = false,
            Flag = "GameAutoUpgrade",
            Callback = function(enabled)
                if enabled then
                    task.spawn(function()
                        local upgradeIds, upgradeCosts = getAllUpgrades()
                        while task.wait(0.5) and rayfield.Flags.GameAutoUpgrade and rayfield.Flags.GameAutoUpgrade.CurrentValue do
                            local upgradeMode = rayfield.Flags.GameUpgradeMode and rayfield.Flags.GameUpgradeMode.CurrentOption[1] or "All"
                            local unlockedUpgrades = dataServiceClient:get("upgrades") or {}
                            local coins = dataServiceClient:get("coins") or 0
                            local goop = dataServiceClient:get("goop") or 0
                            local rollCurrency = dataServiceClient:get("rollCurrency") or 0
                            for _, upgradeId in ipairs(upgradeIds) do
                                if not unlockedUpgrades[upgradeId] then
                                    local costData = upgradeCosts[upgradeId]
                                    if costData then
                                        local cost = costData.amount or 0
                                        local currency = costData.currency
                                        local matchesMode = upgradeMode == "All"
                                            or (upgradeMode == "Coins" and currency == "coins")
                                            or (upgradeMode == "Goop" and currency == "goop")
                                            or (upgradeMode == "Rolls" and currency == "rollCurrency")
                                        local canAfford = (currency == "coins" and coins >= cost)
                                            or (currency == "goop" and goop >= cost)
                                            or (currency == "rollCurrency" and rollCurrency >= cost)
                                        if matchesMode and canAfford then
                                            upgradeServiceRemote:InvokeServer("requestUnlock", upgradeId)
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
            Callback = function(option) end,
        })

        gameTab:CreateSection("Combat")

        gameTab:CreateToggle({
            Name = "Auto Shoot Enemies",
            CurrentValue = false,
            Flag = "CombatAutoShoot",
            Content = "Auto Shoot is enabled but visual effects will not appear — damage is still dealt.",
            Callback = function(enabled) end,
        })

        gameTab:CreateDropdown({
            Name = "Target Priority",
            Options = {"Closest", "Lowest HP", "Highest HP"},
            CurrentOption = {"Closest"},
            MultipleOptions = false,
            Flag = "CombatTargetPriority",
            Callback = function(option) end,
        })

        local function ensureGunEquipped()
            local character = localPlayer.Character
            if not character then return false end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return false end
            local gun = character:FindFirstChild("SlimeGun") or localPlayer.Backpack:FindFirstChild("SlimeGun")
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

        local damageUIParent = nil
        local function getDamageUIParent()
            if damageUIParent and damageUIParent.Parent then return damageUIParent end
            local playerGui = localPlayer.PlayerGui
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
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Players = game:GetService("Players")
            local player = Players.LocalPlayer
            
            local GameplayServiceClient = require(ReplicatedStorage.Source.Features.Gameplay.GameplayServiceClient)
            local GoopGunServiceClient = require(ReplicatedStorage.Source.Features.GoopGun.GoopGunServiceClient)
            local GoopGunServiceUtils = require(ReplicatedStorage.Source.Features.GoopGun.GoopGunServiceUtils)
            local DataService = require(ReplicatedStorage.Packages.DataService).client
            
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
                if mutations.huge     then return COLORS.huge end
                if mutations.shiny    then return COLORS.shiny end
                if mutations.big      then return COLORS.big end
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
                local popup = activePopups[uid]
                if not popup then return end
                activePopups[uid] = nil
                local frame = popup.frame
                TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0)
                }):Play()
                for _, label in ipairs(popup.labels) do
                    TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
                end
                TweenService:Create(popup.accent, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
                task.delay(0.3, function() frame:Destroy() end)
            end
            
            local function scheduleExpiry(uid)
                local popup = activePopups[uid]
                if not popup then return end
                if popup.expireTask then task.cancel(popup.expireTask) end
                popup.expireTask = task.delay(2.5, function()
                    destroyPopup(uid)
                end)
            end
            
            local function createPopup(uid, enemyLabel, damage, hpAfter, accentColor)
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
                hitsLabel.Text = "1 hit  •  " .. tostring(math.floor(damage)) .. " total dmg"
                hitsLabel.TextColor3 = Color3.fromRGB(90, 90, 110)
                hitsLabel.TextXAlignment = Enum.TextXAlignment.Left
                hitsLabel.Font = Enum.Font.Gotham
                hitsLabel.TextSize = 10
                hitsLabel.Parent = frame
            
                local damageLabel = Instance.new("TextLabel")
                damageLabel.Position = UDim2.new(1, -80, 0, 0)
                damageLabel.Size = UDim2.new(0, 72, 1, 0)
                damageLabel.BackgroundTransparency = 1
                damageLabel.Text = "-" .. tostring(math.floor(damage))
                damageLabel.TextColor3 = accentColor
                damageLabel.TextXAlignment = Enum.TextXAlignment.Right
                damageLabel.Font = Enum.Font.GothamBold
                damageLabel.TextSize = 20
                damageLabel.Parent = frame
            
                frame.Position = UDim2.new(-1, 0, 0, 0)
                TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, 0, 0, 0)
                }):Play()
            
                activePopups[uid] = {
                    frame      = frame,
                    accent     = accent,
                    labels     = { nameLabel, hpLabel, hitsLabel, damageLabel },
                    hpLabel    = hpLabel,
                    hitsLabel  = hitsLabel,
                    damageLabel   = damageLabel,
                    totalDamage   = damage,
                    hits       = 1,
                    accentColor = accentColor,
                    expireTask = nil,
                }
            
                scheduleExpiry(uid)
            end
            
            local function updatePopup(uid, damage, hpAfter)
                local popup = activePopups[uid]
                if not popup then return end
            
                popup.totalDamage = popup.totalDamage + damage
                popup.hits = popup.hits + 1
            
                popup.hpLabel.Text   = "HP: " .. tostring(math.max(0, math.floor(hpAfter)))
                popup.hitsLabel.Text = popup.hits .. " hits  •  " .. tostring(math.floor(popup.totalDamage)) .. " total dmg"
                popup.damageLabel.Text  = "-" .. tostring(math.floor(popup.totalDamage))
            
                pulseFrame(popup.frame, popup.accentColor)
                scheduleExpiry(uid)
            end
            
            local function selectTarget()
                local gameplay = GameplayServiceClient.gameplay
                if not gameplay then return nil end
                local character = player.Character
                if not character then return nil end
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if not rootPart then return nil end
            
                local priority = rayfield.Flags.CombatTargetPriority.CurrentOption[1]
                local bestTarget, bestValue = nil, nil
            
                for uniqueId, enemy in pairs(gameplay.enemies) do
                    if enemy.health and enemy.health > 0 then
                        if priority == "Closest" then
                            local dist = (enemy.pos - rootPart.Position).Magnitude
                            if bestValue == nil or dist < bestValue then
                                bestValue = dist
                                bestTarget = uniqueId
                            end
                        elseif priority == "Lowest HP" then
                            if bestValue == nil or enemy.health < bestValue then
                                bestValue = enemy.health
                                bestTarget = uniqueId
                            end
                        elseif priority == "Highest HP" then
                            if bestValue == nil or enemy.health > bestValue then
                                bestValue = enemy.health
                                bestTarget = uniqueId
                            end
                        end
                    end
                end
                return bestTarget
            end
            
            while true do
                if rayfield.Flags.CombatAutoShoot and rayfield.Flags.CombatAutoShoot.CurrentValue then
                    local character = player.Character
                    if character and character:FindFirstChildOfClass("Humanoid") and character:FindFirstChildOfClass("Humanoid").Health > 0 then
                        ensureGunEquipped()
                        local upgrades = DataService:get("upgrades") or {}
                        local fireRate = GoopGunServiceUtils.getFireRate(upgrades)
                        local targetId = selectTarget()
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
                            local damage = hpBefore - hpAfter
            
                            if damage > 0 then
                                if activePopups[targetId] then
                                    updatePopup(targetId, damage, hpAfter)
                                else
                                    createPopup(targetId, enemyLabel, damage, hpAfter, accentColor)
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

        local function getPrimaryPart(model)
            return model.PrimaryPart
                or model:FindFirstChild("HumanoidRootPart")
                or model:FindFirstChild("RootPart")
                or model:FindFirstChildWhichIsA("BasePart")
        end

        local floatEnemiesEnabled = false
        local attackFloatingEnabled = false

        local enemyList = {}
        local slimeList = {}
        local lastUpdateTime = 0

        local function updateEntityLists()
            local currentTime = tick()
            if currentTime - lastUpdateTime < 0.5 then return end
            lastUpdateTime = currentTime

            local gameplay = getGameplayFolder()
            if not gameplay then return end

            local enemiesContainer = gameplay:FindFirstChild("Enemies")
            local slimesContainer = gameplay:FindFirstChild("Slimes")

            enemyList = {}
            if enemiesContainer then
                for _, child in ipairs(enemiesContainer:GetChildren()) do
                    if child:IsA("Model") then
                        local root = getPrimaryPart(child)
                        if root then
                            table.insert(enemyList, {model = child, root = root})
                        end
                    end
                end
            end

            slimeList = {}
            if slimesContainer then
                for _, child in ipairs(slimesContainer:GetChildren()) do
                    if child:IsA("Model") then
                        local root = getPrimaryPart(child)
                        if root then
                            table.insert(slimeList, {model = child, root = root, id = child.Name})
                        end
                    end
                end
            end
        end

        local function isEntityValid(entity)
            if not entity or not entity.Parent then return false end
            local root = getPrimaryPart(entity)
            if not root then return false end
            local humanoid = entity:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health <= 0 then return false end
            return true
        end

        local function findClosestEnemy(position)
            local gameplay = getGameplayFolder()
            if not gameplay then return nil end
            local enemiesContainer = gameplay:FindFirstChild("Enemies")
            if not enemiesContainer then return nil end
            local closest, closestDist = nil, math.huge
            for _, child in ipairs(enemiesContainer:GetChildren()) do
                if child:IsA("Model") and isEntityValid(child) then
                    local root = getPrimaryPart(child)
                    if root then
                        local dist = (root.Position - position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closest = child
                        end
                    end
                end
            end
            return closest
        end

        gameTab:CreateSection("Floating Enemies")

        gameTab:CreateToggle({
            Name = "Float Enemies Around Player",
            CurrentValue = false,
            Flag = "GameFloatEnemies",
            Callback = function(enabled)
                floatEnemiesEnabled = enabled
            end,
        })

        gameTab:CreateSlider({
            Name = "Float Radius",
            Range = {5, 25},
            Increment = 1,
            Suffix = "studs",
            CurrentValue = 12,
            Flag = "GameFloatRadius",
            Callback = function(value) end,
        })

        gameTab:CreateSlider({
            Name = "Float Rotation Speed",
            Range = {0.5, 5},
            Increment = 0.1,
            Suffix = "x",
            CurrentValue = 1,
            Flag = "GameFloatSpeed",
            Callback = function(value) end,
        })

        gameTab:CreateSlider({
            Name = "Float Wave Speed",
            Range = {1, 10},
            Increment = 0.5,
            Suffix = "x",
            CurrentValue = 3,
            Flag = "GameFloatWaveSpeed",
            Callback = function(value) end,
        })

        gameTab:CreateSlider({
            Name = "Float Wave Height",
            Range = {0.5, 5},
            Increment = 0.5,
            Suffix = "studs",
            CurrentValue = 1.5,
            Flag = "GameFloatWaveHeight",
            Callback = function(value) end,
        })

        gameTab:CreateSection("Attack System")

        gameTab:CreateToggle({
            Name = "Attack Floating Enemies",
            CurrentValue = false,
            Flag = "GameAttackEnemies",
            Callback = function(enabled)
                attackFloatingEnabled = enabled
            end,
        })

        gameTab:CreateSlider({
            Name = "Attack Range",
            Range = {10, 50},
            Increment = 1,
            Suffix = "studs",
            CurrentValue = 25,
            Flag = "GameAttackRange",
            Callback = function(value) end,
        })

        gameTab:CreateSlider({
            Name = "Attack Lunge Speed",
            Range = {5, 30},
            Increment = 1,
            Suffix = "x",
            CurrentValue = 15,
            Flag = "GameAttackLungeSpeed",
            Callback = function(value) end,
        })

        local attackCooldowns = {}

        local function setModelCframe(model, newCframe)
            if not model or not model.Parent then return end
            local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            if primaryPart and not primaryPart:IsA("UnionOperation") then
                model:PivotTo(newCframe)
            end
        end

        runService.RenderStepped:Connect(function()
            if not floatEnemiesEnabled and not attackFloatingEnabled then return end

            updateEntityLists()

            local character = localPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end

            local currentTime = tick()
            local radius = rayfield.Flags.GameFloatRadius and rayfield.Flags.GameFloatRadius.CurrentValue or 12
            local rotationSpeed = rayfield.Flags.GameFloatSpeed and rayfield.Flags.GameFloatSpeed.CurrentValue or 1
            local waveSpeed = rayfield.Flags.GameFloatWaveSpeed and rayfield.Flags.GameFloatWaveSpeed.CurrentValue or 3
            local waveHeight = rayfield.Flags.GameFloatWaveHeight and rayfield.Flags.GameFloatWaveHeight.CurrentValue or 1.5

            if floatEnemiesEnabled and #enemyList > 0 then
                local enemyCount = #enemyList
                for index, enemy in ipairs(enemyList) do
                    local angle = ((index / enemyCount) * math.pi * 2) + (currentTime * rotationSpeed)
                    local yOffset = math.sin((currentTime * waveSpeed) + index) * waveHeight

                    local targetPos = rootPart.Position + Vector3.new(
                        math.cos(angle) * radius,
                        yOffset + 2,
                        math.sin(angle) * radius
                    )

                    local direction = (targetPos - rootPart.Position).Unit
                    setModelCframe(enemy.model, CFrame.lookAt(targetPos, targetPos + direction))
                end
            end

            if attackFloatingEnabled and #slimeList > 0 and #enemyList > 0 then
                local attackRange = rayfield.Flags.GameAttackRange and rayfield.Flags.GameAttackRange.CurrentValue or 25
                local lungeSpeed = rayfield.Flags.GameAttackLungeSpeed and rayfield.Flags.GameAttackLungeSpeed.CurrentValue or 15

                local slimeCount = #slimeList
                for index, slime in ipairs(slimeList) do
                    local angle = ((index / slimeCount) * math.pi * 2) + (currentTime * rotationSpeed)
                    local yOffset = math.sin((currentTime * waveSpeed) + index) * waveHeight

                    local orbitPos = rootPart.Position + Vector3.new(
                        math.cos(angle) * radius,
                        yOffset + 2,
                        math.sin(angle) * radius
                    )

                    local closestEnemy, closestDist = nil, attackRange
                    for _, enemy in ipairs(enemyList) do
                        local dist = (orbitPos - enemy.root.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestEnemy = enemy
                        end
                    end

                    local targetPos = orbitPos
                    local lookPos = orbitPos + (orbitPos - rootPart.Position).Unit

                    if closestEnemy then
                        if not attackCooldowns[slime.id] then
                            attackCooldowns[slime.id] = currentTime
                        end

                        local timeSinceAttack = currentTime - attackCooldowns[slime.id]
                        local lungeFactor = math.sin(timeSinceAttack * lungeSpeed)

                        if lungeFactor > 0 then
                            targetPos = orbitPos:Lerp(closestEnemy.root.Position, lungeFactor * 0.85)
                            lookPos = closestEnemy.root.Position
                        else
                            attackCooldowns[slime.id] = currentTime
                        end
                    else
                        attackCooldowns[slime.id] = nil
                    end

                    setModelCframe(slime.model, CFrame.lookAt(targetPos, lookPos))
                end
            end
        end)

        local miscTab = mainWindow:CreateTab("Misc", 96334002390551)

        miscTab:CreateSection("Codes & Rewards")

        miscTab:CreateToggle({
            Name = "Auto Redeem Codes",
            CurrentValue = false,
            Flag = "MiscRedeemCodes",
            Callback = function(enabled)
                if enabled then
                    task.spawn(function()
                        local codes = {
                            "gullible",
                            "test",
                            "goingBananas",
                            "AAisComing",
                            "Sliming",
                        }
                        while rayfield.Flags.MiscRedeemCodes and rayfield.Flags.MiscRedeemCodes.CurrentValue do
                            for _, code in ipairs(codes) do
                                codeServiceRemote:InvokeServer("redeem", code)
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
            Callback = function(enabled)
                if enabled then
                    task.spawn(function()
                        while rayfield.Flags.MiscClaimOffline and rayfield.Flags.MiscClaimOffline.CurrentValue do
                            offlineEarningsRemote:InvokeServer("requestClaim")
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
            Callback = function(enabled)
                if enabled then
                    task.spawn(function()
                        local function claimIndexRewards()
                            local indexData = dataServiceClient:get("index")
                            if not indexData or not indexData.categories then return end
                            for categoryName, rewardsTable in pairs(indexRewards) do
                                local category = indexData.categories[categoryName]
                                if category then
                                    local unlocked = category.unlocked or {}
                                    local unlockedCount = 0
                                    for _, isUnlocked in pairs(unlocked) do
                                        if isUnlocked then unlockedCount = unlockedCount + 1 end
                                    end
                                    local claimedRewards = category.claimedRewards or {}
                                    for _, reward in ipairs(rewardsTable) do
                                        if unlockedCount >= reward.req and not claimedRewards[reward.key] then
                                            indexServiceRemote:InvokeServer("requestClaimReward", categoryName)
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
            Callback = function(enabled)
                if enabled then
                    task.spawn(function()
                        while task.wait(1) and rayfield.Flags.MiscUsePotions and rayfield.Flags.MiscUsePotions.CurrentValue do
                            local boosts = dataServiceClient:get("boosts") or {}
                            local potionTypes = rayfield.Flags.MiscPotionTypes and rayfield.Flags.MiscPotionTypes.CurrentOption or {}
                            for _, potionKind in ipairs(potionTypes) do
                                local boostData = boosts[potionKind]
                                if boostData and (boostData.amount or 0) > 0 then
                                    boostServiceRemote:InvokeServer("requestUseBoost", potionKind)
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
            Callback = function(option) end,
        })

        miscTab:CreateToggle({
            Name = "Auto Use Dice & Items",
            CurrentValue = false,
            Flag = "MiscUseDice",
            Callback = function(enabled)
                if enabled then
                    task.spawn(function()
                        while task.wait(1) and rayfield.Flags.MiscUseDice and rayfield.Flags.MiscUseDice.CurrentValue do
                            local items = dataServiceClient:get("items") or {}
                            local diceTypes = rayfield.Flags.MiscDiceTypes and rayfield.Flags.MiscDiceTypes.CurrentOption or {}
                            for _, diceName in ipairs(diceTypes) do
                                local itemId = itemNameToId[diceName]
                                if itemId and (items[itemId] or 0) > 0 then
                                    inventoryServiceRemote:InvokeServer("requestUseItem", itemId)
                                end
                            end
                        end
                    end)
                end
            end,
        })

        do
            local diceNames = {}
            for _, itemId in ipairs(inventoryItemIds) do
                table.insert(diceNames, itemIdToName[itemId])
            end
            miscTab:CreateDropdown({
                Name = "Dice & Item Types",
                Options = diceNames,
                CurrentOption = {diceNames[1]},
                MultipleOptions = true,
                Flag = "MiscDiceTypes",
                Callback = function(option) end,
            })
        end

        local webhookTab = mainWindow:CreateTab("Webhook", 84577758013974)

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
            Callback = function(enabled) end,
        })

        local savedWebhookUrl = ""
        webhookTab:CreateInput({
            Name = "Webhook URL",
            CurrentValue = "",
            PlaceholderText = "Paste your Discord webhook URL",
            RemoveTextAfterFocusLost = false,
            Flag = "WebhookURLDisplay",
            Callback = function(url)
                if url and url:match("^https://discord") then
                    savedWebhookUrl = url
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
            Callback = function(value) end,
        })

        webhookTab:CreateInput({
            Name = "Minimum Chance To Send",
            CurrentValue = "",
            PlaceholderText = "e.g. 1B or 1000000000",
            RemoveTextAfterFocusLost = false,
            Flag = "WebhookMinChance",
            Callback = function(value) end,
        })

        webhookTab:CreateButton({
            Name = "Test Webhook",
            Callback = function()
                if savedWebhookUrl == "" then
                    rayfield:Notify({Title = "Webhook", Content = "Please paste a Webhook URL first.", Duration = 4})
                    return
                end
                if not rayfield.Flags.WebhookEnabled.CurrentValue then
                    rayfield:Notify({Title = "Webhook", Content = "Please enable Webhook first.", Duration = 4})
                    return
                end
                local userId = rayfield.Flags.WebhookUserID.CurrentValue
                local mention = formatMention(userId)
                local response = request({
                    Url = savedWebhookUrl,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = httpService:JSONEncode({
                        content  = mention,
                        username = "Cactus Hub",
                        avatar_url = WEBHOOK_AVATAR,
                        embeds   = {{
                            title       = "✅ Webhook Test",
                            description = "Your webhook is working correctly!",
                            color       = 0x2ecc71,
                        }}
                    })
                })
                if not response then
                    rayfield:Notify({
                        Title   = "Webhook",
                        Content = "Failed to send test.",
                        Duration = 4,
                    })
                else
                    rayfield:Notify({
                        Title   = "Webhook",
                        Content = "Test sent successfully!",
                        Duration = 4,
                    })
                end
            end,
        })

        webhookTab:CreateSection("Filters")

        webhookTab:CreateToggle({
            Name = "Send All Slimes",
            CurrentValue = false,
            Flag = "WebhookSendAll",
            Callback = function(enabled) end,
        })

        webhookTab:CreateToggle({
            Name = "Send New Slimes Only",
            CurrentValue = false,
            Flag = "WebhookSendNew",
            Callback = function(enabled) end,
        })

        webhookTab:CreateToggle({
            Name = "Send Mutated Slimes",
            CurrentValue = false,
            Flag = "WebhookSendMutated",
            Callback = function(enabled) end,
        })

        webhookTab:CreateDropdown({
            Name = "Mutations Filter",
            Options = {"All", "Shiny", "Big", "Huge", "Inverted"},
            CurrentOption = {"All"},
            MultipleOptions = true,
            Flag = "WebhookMutations",
            Callback = function(option) end,
        })

        local lastRollResultsHash = nil

        local function passesMutationFilter(mutations)
            local selectedMutations = rayfield.Flags.WebhookMutations and rayfield.Flags.WebhookMutations.CurrentOption or {"All"}
            local allSelected = false
            for _, mut in ipairs(selectedMutations) do
                if mut == "All" then
                    allSelected = true
                    break
                end
            end
            if allSelected then return true end
            if not mutations then return false end
            local mutationType = getMutationTypeString(mutations)
            for _, mut in ipairs(selectedMutations) do
                if string.lower(mut) == mutationType then return true end
            end
            return false
        end

        task.spawn(function()
            while true do
                task.wait(0.1)

                if not rayfield.Flags.WebhookEnabled or not rayfield.Flags.WebhookEnabled.CurrentValue then

                elseif savedWebhookUrl ~= "" then
                    if not rollSlice or type(rollSlice.rollResults) ~= "function" then
                        task.wait(1)
                    else
                        local currentRolls = rollSlice.rollResults()
                        if type(currentRolls) ~= "table" or #currentRolls == 0 then
                            task.wait(0.5)
                        else
                            local currentHash = encodeRollResults(currentRolls)
                            if currentHash ~= lastRollResultsHash then
                                lastRollResultsHash = currentHash

                                local sendAll = rayfield.Flags.WebhookSendAll and rayfield.Flags.WebhookSendAll.CurrentValue
                                local sendNewOnly = rayfield.Flags.WebhookSendNew and rayfield.Flags.WebhookSendNew.CurrentValue
                                local sendMutated = rayfield.Flags.WebhookSendMutated and rayfield.Flags.WebhookSendMutated.CurrentValue
                                local minChanceStr = rayfield.Flags.WebhookMinChance.CurrentValue
                                local minChanceNum = parseChanceString(minChanceStr)

                                for _, rollResult in ipairs(currentRolls) do
                                    local slimeData = extractSlimeData(rollResult)
                                    if slimeData then
                                        local slimeId = tostring(slimeData.id or "")
                                        if slimeId ~= "" then
                                            local mutations = type(slimeData.mutations) == "table" and next(slimeData.mutations) ~= nil and slimeData.mutations or nil
                                            local slimeOk, slimeInfo = pcall(slimesModule.getSlime, slimeId)
                                            local slimeDefinition = slimeOk and slimeInfo or nil

                                            local hasMutation = mutations ~= nil
                                            local isNew = isNewSlime(slimeId, mutations)

                                            local shouldSend = sendAll or (sendNewOnly and isNew) or (sendMutated and hasMutation and passesMutationFilter(mutations))

                                            if shouldSend and minChanceNum then
                                                local odds = slimeDefinition and slimeDefinition.odds or 0
                                                local chanceValue = odds > 0 and (1 / odds) or 0
                                                if chanceValue > minChanceNum then
                                                    shouldSend = false
                                                end
                                            end

                                            if shouldSend then
                                                local userId = rayfield.Flags.WebhookUserID.CurrentValue
                                                local notificationKey = currentHash .. "_" .. slimeId .. "_" .. tostring(mutations and mutationsModule.getIds(mutations) or "")
                                                task.spawn(sendWebhookNotification, slimeId, slimeDefinition, mutations, savedWebhookUrl, userId, notificationKey)
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

        local settingsTab = mainWindow:CreateTab("Settings", 122930981612451)

        settingsTab:CreateSection("System")

        settingsTab:CreateToggle({
            Name = "Anti Kick",
            CurrentValue = false,
            Flag = "SettingsAntiKick",
            Callback = function(enabled) end,
        })

        settingsTab:CreateToggle({
            Name = "Auto Rejoin On Disconnect",
            CurrentValue = false,
            Flag = "SettingsAutoRejoin",
            Callback = function(enabled) end,
        })

        settingsTab:CreateToggle({
            Name = "Auto Friend Requests",
            CurrentValue = false,
            Flag = "AutoFriend",
            Callback = function(value)
                if value then
                    task.spawn(function()
                        while rayfield.Flags.AutoFriend and rayfield.Flags.AutoFriend.CurrentValue do
                            local players = game:GetService("Players"):GetChildren()
                            for _, otherPlayer in ipairs(players) do
                                localPlayer:RequestFriendship(otherPlayer)
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
        local optApplied = false

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
            for _, child in ipairs(L:GetChildren()) do
                if OPT_LIGHTING_TYPES[child.ClassName] then child:Destroy() end
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
            for _, descendant in ipairs(character:GetDescendants()) do
                local cn = descendant.ClassName
                if OPT_VISUAL_TYPES[cn] then
                    descendant:Destroy()
                elseif descendant:IsA("BasePart") then
                    descendant.CastShadow = false
                    descendant.Reflectance = 0
                    descendant.Material = CHEAP_MATERIAL
                elseif cn == "Decal" or cn == "Texture" then
                    descendant.Transparency = 1
                elseif cn == "SpecialMesh" then
                    descendant.TextureId = ""
                elseif cn == "Accessory" then
                    descendant:Destroy()
                end
            end
        end

        local function optWorkspaceScan()
            local Camera = workspace.CurrentCamera
            local characterSet = {}
            for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                if p.Character then characterSet[p.Character] = true end
            end
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj ~= Camera and not characterSet[obj] then
                    for _, descendant in ipairs(obj:GetDescendants()) do
                        optApplyInstance(descendant)
                    end
                end
            end
            table.insert(optConnections, workspace.ChildAdded:Connect(function(obj)
                if obj == workspace.CurrentCamera then return end
                task.defer(function()
                    for _, descendant in ipairs(obj:GetDescendants()) do
                        optApplyInstance(descendant)
                    end
                end)
            end))
        end

        local function optPlayers()
            local Players = game:GetService("Players")
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
            for _, child in ipairs(cam:GetChildren()) do
                if OPT_LIGHTING_TYPES[child.ClassName] then child:Destroy() end
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
            for _, conn in ipairs(optConnections) do conn:Disconnect() end
            table.clear(optConnections)
        end

        local optGPUToggle
        local optParticlesToggle
        local optFireToggle
        local optGCToggle
        local optIntenseToggle
        local optHideDamageToggle
        local optMainToggle
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
            Callback = function(Value)
                if updatingOptimizations then return end
                setAllOptimizations(Value)
            end,
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
                    L.GlobalShadows = false
                    L.EnvironmentDiffuseScale = 0
                    L.EnvironmentSpecularScale = 0
                    for _, descendant in ipairs(workspace:GetDescendants()) do
                        if descendant:IsA("BasePart") then
                            descendant.CastShadow = false
                            descendant.Reflectance = 0
                            descendant.Material = CHEAP_MATERIAL
                        end
                    end
                    local rs = game:GetService("RunService")
                    rs:Set3dRenderingEnabled(false)
                    task.wait(0.1)
                    rs:Set3dRenderingEnabled(true)
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
                    for _, descendant in ipairs(game:GetDescendants()) do
                        if OPT_VISUAL_TYPES[descendant.ClassName] then
                            descendant:Destroy()
                        end
                    end
                end
            end,
        })

        optFireToggle = settingsTab:CreateToggle({
            Name = "Remove Fire Effects",
            CurrentValue = false,
            Flag = "FireOptimization",
            Callback = function(Value)
                if updatingOptimizations then return end
                if Value then
                    for _, descendant in ipairs(game:GetDescendants()) do
                        if descendant:IsA("Fire") then descendant:Destroy() end
                    end
                end
            end,
        })

        optGCToggle = settingsTab:CreateToggle({
            Name = "Lua GC (Memory Cleaner)",
            CurrentValue = false,
            Flag = "LuaGC",
            Callback = function(Value)
                if updatingOptimizations then return end
                if Value then
                    if _G.__memoryCleaner then
                        _G.__memoryCleaner:Disconnect()
                    end
                    _G.__memoryCleaner = game:GetService("RunService").Heartbeat:Connect(function()
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

        optIntenseToggle = settingsTab:CreateToggle({
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

        local statsTab = mainWindow:CreateTab("Stats", 4483362458)

        local DataClient = dataServiceClient
        local function safeGet(...)
            local data = DataClient._data._data
            local cur = data
            for _, k in ipairs({...}) do
                if type(cur) ~= "table" then return 0 end
                cur = cur[k]
                if cur == nil then return 0 end
            end
            return cur
        end

        local function safeNum(...)
            return tonumber(safeGet(...)) or 0
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
                elseif muts.big then prefix = "Big "
                end
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
            local function count(cat)
                local t = cats[cat]
                return type(t)=="table" and countKeys(t.unlocked or {}) or 0
            end
            return count("basic"), count("big"), count("shiny"), count("huge"), count("inverted")
        end

        local function getTotalInv()
            local inv = safeGet("inventory")
            if type(inv) ~= "table" then return 0 end
            local total = 0
            for _, v in pairs(inv) do if type(v)=="number" then total = total + v end end
            return total
        end

        local function getUniqueSpecies()
            local inv = safeGet("inventory")
            if type(inv) ~= "table" then return 0 end
            local seen = {}; local c = 0
            for k in pairs(inv) do
                if type(k)=="string" and not k:match("^%.") then
                    local base = k:match("%-(.+)$") or k
                    if not seen[base] then seen[base]=true; c = c + 1 end
                end
            end
            return c
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
                local dt  = math.max(1, now - lastWin)
                lastWin   = now
                local r = safeNum("stats","rolls")
                local c = safeNum("coins")
                local g = safeNum("goop")
                local dr = math.max(0, r - prevRolls)
                local dc = math.max(0, c - prevCoins)
                local dg = math.max(0, g - prevGoop)
                if dr > 0 then windowRPS = dr/dt;    lastRollMove = now end
                if dc > 0 then windowCPS = dc/dt;    lastCoinMove = now end
                if dg > 0 then windowGPS = dg/dt;    lastGoopMove = now end
                prevRolls = r; prevCoins = c; prevGoop = g
            end
        end)

        local function getRate(windowVal, lastMove, startVal, curVal)
            local now     = os.clock()
            local elapsed = math.max(1, now - sessionStart)
            if (now - lastMove) > STALE then return 0 end
            if windowVal and windowVal > 0 then return windowVal end
            local gain = math.max(0, curVal - startVal)
            return gain > 0 and (gain / elapsed) or 0
        end

        local labels = {}
        local function lbl(key, text) labels[key] = statsTab:CreateLabel(text) end

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
            local now     = os.clock()
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
            local crafting = countKeys(safeGet("craftingRecipes") or {})

            labels.sess:Set(string.format("Session: %dh%dm%ds  |  Played: %s  |  Rebirths: %s", sessH, sessM, sessS, fmtTime(timePl), fmt(rebirths)))
            labels.rolls1:Set(string.format("Rolls/sec: %.2f  |  Rolls/min: %s  |  Rolls/hr: %s", rps, fmt(rps*60), fmt(rps*3600)))
            labels.rolls2:Set("Session Rolls: "..fmt(sessRolls).."  |  Lifetime: "..fmt(rolls))
            labels.coins1:Set("Coins/min: "..fmt(cps*60).."  |  Coins/hr: "..fmt(cps*3600))
            labels.coins2:Set("Session Coins: "..fmt(sessCoins).."  |  Total Ever: "..fmt(totCoins))
            labels.goop1:Set("Goop/min: "..fmt(gps*60).."  |  Goop/hr: "..fmt(gps*3600))
            labels.goop2:Set("Session Goop: "..fmt(sessGoop).."  |  Balance: "..fmt(goop))
            labels.kills:Set("Session Kills: "..fmt(sessKills).."  |  Lifetime Kills: "..fmt(kills))
            labels.best:Set("Best Ever: "..bestName.."  |  Odds: "..bestOdds)
            labels.daily:Set("Best Today Odds: "..dailyStr)
            labels.prog:Set("Zone: "..fmt(zone).."  |  Max Zone: "..fmt(maxZone).."  |  Roll Currency: "..fmt(rollCur))
            labels.idx1:Set("Basic: "..basic.."  |  Big: "..big.."  |  Shiny: "..shiny.."  |  Huge: "..huge.."  |  Inverted: "..inverted)
            labels.inv:Set("Total Slimes: "..fmt(getTotalInv()).."  |  Species: "..getUniqueSpecies().."  |  Crafting: "..crafting)
            labels.equipped:Set("Equipped: "..getEquipped())
        end

        task.spawn(function()
            while true do
                updateAll()
                task.wait(2)
            end
        end)

        local craftingTab = gameTab

        local RS = game:GetService("ReplicatedStorage")
        local function getCraftingRemote()
            return RS
                :WaitForChild("Packages")
                :WaitForChild("_Index")
                :WaitForChild("leifstout_networker@0.3.1")
                :WaitForChild("networker")
                :WaitForChild("_remotes")
                :WaitForChild("CraftingService")
                :WaitForChild("RemoteFunction")
        end

        local function getCraftingData(key)
            return dataServiceClient:get(key)
        end

        local MutationsModule = mutationsModule
        local RecipesModule
        RecipesModule = require(RS.Source.Features.Crafting.Recipes)

        local function getMutationValue(mutId)
            if not MutationsModule then return 0 end
            local data = MutationsModule.get(mutId)
            return data and data.value or 0
        end

        local function getSizeMutations()
            return MutationsModule and MutationsModule.sizeMutations or {}
        end

        local function getModifierMutations()
            return MutationsModule and MutationsModule.modifierMutations or {}
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
                if not bestUid then
                    return 0
                end
                usedCounts[bestUid] = (usedCounts[bestUid] or 0) + 1
                local owned = getOwnedAmount(inventory[bestUid])
                local used = usedCounts[bestUid]
                local available = owned - used + 1
                if available < maxCrafts then
                    maxCrafts = available
                end
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
                    local result = getCraftingRemote():InvokeServer(table.unpack(args))
                    results[recipeId] = result ~= false
                end
            end
            return results
        end

        local recipeIdsList = getUnlockedRecipeIds()
        if #recipeIdsList > 0 then
            craftingState.selectedRecipeIds = { recipeIdsList[1] }
        end

        craftingTab:CreateSection("Recipes")

        craftingTab:CreateDropdown({
            Name = "Select Recipes to Craft",
            Options = recipeIdsList,
            CurrentOption = { recipeIdsList[1] or "" },
            MultipleOptions = true,
            Flag = "CraftingSelectedRecipes",
            Callback = function(options)
                craftingState.selectedRecipeIds = options
            end,
        })

        craftingTab:CreateSection("Craft")

        craftingTab:CreateSlider({
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

        craftingTab:CreateButton({
            Name = "Craft Now",
            Callback = function()
                local results = doCraftAll(craftingState.craftAmount)
                local succeeded, failed = 0, 0
                for _, ok in pairs(results) do
                    if ok then succeeded = succeeded + 1 else failed = failed + 1 end
                end
                rayfield:Notify({
                    Title = "Cactus Hub",
                    Content = succeeded .. " crafts succeeded" .. (failed > 0 and (", " .. failed .. " failed") or ""),
                    Duration = 3,
                    Image = 4483362458,
                })
            end,
        })

        craftingTab:CreateSection("Auto Craft")

        local autoCraftMax = 1

        local function updateAutoCraftMax()
            local minMax = math.huge
            for _, recipeId in ipairs(craftingState.selectedRecipeIds) do
                local maxCrafts = getMaxCraftsForRecipe(recipeId)
                if maxCrafts < minMax then
                    minMax = maxCrafts
                end
            end
            if minMax == math.huge then
                autoCraftMax = 1
            else
                autoCraftMax = math.max(1, minMax)
            end
        end

        updateAutoCraftMax()

        craftingTab:CreateSlider({
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

        craftingTab:CreateToggle({
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
                    rayfield:Notify({
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
                    rayfield:Notify({
                        Title = "Auto Craft",
                        Content = "Stopped.",
                        Duration = 3,
                        Image = 4483362458,
                    })
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
            Callback = function(options)
                craftingState.protectCategories = options
                craftingState.protectedPets = buildProtectedSet(options)
            end,
        })

        rayfield:Notify({
            Title = "Cactus Hub",
            Content = "Loaded - " .. #recipeIdsList .. " unlocked recipes ready.",
            Duration = 5,
            Image = 4483362458,
        })

        local virtualUser = game:GetService('VirtualUser')
        game:GetService("Players").LocalPlayer.Idled:Connect(function()
            virtualUser:CaptureController()
            virtualUser:ClickButton2(Vector2.new())
        end)

        game:GetService("GuiService").ErrorMessageChanged:Connect(function()
            if rayfield.Flags.SettingsAutoRejoin and rayfield.Flags.SettingsAutoRejoin.CurrentValue then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
            end
        end)

        rayfield:LoadConfiguration()
    end)
end)
