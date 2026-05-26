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

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local VirtualUser = game:GetService("VirtualUser")
    local HttpService = game:GetService("HttpService")

    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local IndexFolder = Packages:WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker")
    local Remotes = IndexFolder:WaitForChild("_remotes")

    local DataClient = require(Packages.DataService).client
    DataClient:waitForData()

    local NetworkerClient = require(Packages.Networker)

    local InventoryRemote = NetworkerClient.client.new("InventoryService")
    local XpTransferRemote = NetworkerClient.client.new("XpTransferService")

    local function getRemote(name)
        local remoteFolder = Remotes:FindFirstChild(name) or Remotes:WaitForChild(name, 10)
        if not remoteFolder then return nil end
        local remoteFunction = remoteFolder:FindFirstChild("RemoteFunction") or remoteFolder:WaitForChild("RemoteFunction", 10)
        return remoteFunction
    end

    local RollRemote = getRemote("RollService")
    local CodeRemote = getRemote("CodeService")
    local InventoryRemoteFunc = getRemote("InventoryService")
    local RebirthRemote = getRemote("RebirthService")
    local ZonesRemote = getRemote("ZonesService")
    local UpgradeRemote = getRemote("UpgradeService")
    local BoostRemote = getRemote("BoostService")
    local OfflineRemote = getRemote("OfflineEarningsService")
    local IndexRemote = getRemote("IndexService")
    local LootRemote = getRemote("LootService")

    local Source = ReplicatedStorage:WaitForChild("Source", 30)
    if not Source then return end

    local RarityTiers = require(Source.Game.Items.RarityTiers)
    local UpgradeTree = require(Source.Features.Upgrades.UpgradeTree)
    local IndexRewards = require(Source.Features.Index.IndexRewards)
    local BoostUtils = require(Source.Features.Boosts.BoostServiceUtils)
    local SpecialDiceUtils = require(Source.Features.SpecialDice.SpecialDiceServiceUtils)
    local RollSlice = require(Source.Features.Roll.RollSlice)
    local Slimes = require(Source.Game.Items.Slimes)
    local Mutations = require(Source.Features.Mutations.Mutations)

    local BoostKinds = BoostUtils.getKinds()
    local DiceIds = SpecialDiceUtils.getInventoryItemIds()

    local DiceNameMap = {}
    local DiceNameToId = {}
    for _, id in ipairs(DiceIds) do
        local def = SpecialDiceUtils.getDefinition(id)
        local name = def and def.name or id
        DiceNameMap[id] = name
        DiceNameToId[name] = id
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
        local tier, data = RarityTiers.getTier(odds)
        return (tier and data and data.name) or "Unknown"
    end

    local function findSlimeFromRoll(rollData)
        if type(rollData) ~= "table" then return nil end
        for _, v in ipairs(rollData) do
            if type(v) == "table" and v.id then return v end
        end
        return nil
    end

    local function encodeRolls(rolls)
        if type(rolls) ~= "table" or #rolls == 0 then return "empty" end
        local ids = {}
        for i, v in ipairs(rolls) do
            local slime = findSlimeFromRoll(v)
            ids[i] = slime and tostring(slime.id) or tostring(i)
        end
        return #rolls .. "|" .. table.concat(ids, ",")
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
        local index = DataClient:get("index") or {}
        local categories = index.categories or {}
        local cat = categories[getMutationType(mutations)]
        local unlocked = cat and cat.unlocked or {}
        return not unlocked[slimeId]
    end

    local function getMutationDisplay(mutations)
        if not mutations then return "basic" end
        if mutations.inverted then return "inverted" end
        if mutations.huge then return "huge" end
        if mutations.big then return "big" end
        if mutations.shiny then return "shiny" end
        return "basic"
    end

    local thumbnailCache = {}
    local function getThumbnail(assetId)
        if not assetId then return nil end
        if thumbnailCache[assetId] then return thumbnailCache[assetId] end
        local res = request({
            Url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetId .. "&size=420x420&format=Png&isCircular=false",
            Method = "GET"
        })
        if res and res.Success then
            local data = HttpService:JSONDecode(res.Body)
            if data and data.data and data.data[1] then
                thumbnailCache[assetId] = data.data[1].imageUrl
                return thumbnailCache[assetId]
            end
        end
        return nil
    end

    local function getThumbSize(mutations)
        if not mutations then return 64 end
        if mutations.huge then return 128 elseif mutations.big then return 96 end
        return 64
    end

    local function getEmbedColor(mutations)
        if not mutations then return 0x3498db end
        if mutations.inverted then return 0x9b59b6
        elseif mutations.huge then return 0xf1c40f
        elseif mutations.big then return 0xe67e22
        elseif mutations.shiny then return 0xf39c12 end
        return 0x3498db
    end

    local function ordinalSuffix(n)
        local s = tostring(n)
        local last = n % 10
        local lastTwo = n % 100
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
        local multiplier = 1
        if mutations then
            if mutations.inverted then multiplier = multiplier * (Mutations.getVisualOddsMultiplier(mutations) or 1) end
            if mutations.huge then multiplier = multiplier * (Mutations.getVisualOddsMultiplier(mutations) or 1) end
            if mutations.big then multiplier = multiplier * (Mutations.getVisualOddsMultiplier(mutations) or 1) end
            if mutations.shiny then multiplier = multiplier * (Mutations.getVisualOddsMultiplier(mutations) or 1) end
        end
        local chance = odds > 0 and (1 / odds) * multiplier or 0
        return chance
    end

    local WEBHOOK_AVATAR = "https://media.discordapp.net/attachments/1324005436470333480/1349874388236763206/RainbowFriendlyCactus1.png?ex=6a1426bd&is=6a12d53d&hm=adc011c12e097b4238f08364c0ffbd6f30c9eff3f51b7706219b6c8cba76932d&=&format=png"

    local function sendWebhook(slimeId, slimeData, mutations, webhookUrl, userId, webhookKey)
        if sentWebhooks[webhookKey] then return end
        sentWebhooks[webhookKey] = true
        
        local mention = mentionUser(userId)
        local displayName = mutations and Mutations.getDisplayName(slimeId, mutations) or slimeId
        local odds = slimeData and slimeData.odds or nil
        local damage = slimeData and slimeData.damage or 0
        local health = slimeData and slimeData.health or 0
        local oddsMultiplier = mutations and Mutations.getVisualOddsMultiplier(mutations) or 1
        local damageMultiplier = mutations and Mutations.getStatBonus(mutations, "damage") or 1
        local effectiveOdds = odds and (odds / oddsMultiplier) or nil
        local rarityName = getRarityName(odds)
        local chanceString = (effectiveOdds and type(effectiveOdds) == "number" and effectiveOdds > 0) and string.format("1 in %s", formatNumber(math.floor(1 / effectiveOdds + 0.5))) or "N/A"

        local iconAsset = (mutations and mutations.inverted) and (slimeData and slimeData.invertedIcon) or (slimeData and slimeData.image)
        local iconUrl = nil
        if iconAsset and iconAsset ~= "N/A" then
            local assetId = string.match(tostring(iconAsset), "rbxassetid://(%d+)")
            if assetId then iconUrl = getThumbnail(assetId) end
        end

        local mutationIds = mutations and Mutations.getIds(mutations) or {}
        local finalDamage = damage * damageMultiplier
        local finalHealth = health * damageMultiplier
        local statsText = ""
        if finalDamage > 0 and finalHealth > 0 then
            statsText = string.format("⚔️ %s  ❤️ %s", formatNumber(finalDamage), formatNumber(finalHealth))
        elseif finalDamage > 0 then
            statsText = string.format("⚔️ %s", formatNumber(finalDamage))
        elseif finalHealth > 0 then
            statsText = string.format("❤️ %s", formatNumber(finalHealth))
        end

        local stats = DataClient:get("stats") or {}
        local totalRolls = stats.rolls or 0
        local kills = stats.kills or 0
        local coins = DataClient:get("coins") or 0
        local playerName = player and player.Name or "Someone"
        local thumbSize = getThumbSize(mutations)

        local fields = {
            {name = "Rarity", value = rarityName, inline = true},
            {name = "Chance", value = chanceString, inline = true},
        }
        if statsText ~= "" then
            table.insert(fields, {name = "Stats", value = statsText, inline = true})
        end
        if #mutationIds > 0 then
            table.insert(fields, {name = "Mutations", value = table.concat(mutationIds, ", "), inline = true})
        end
        table.insert(fields, {name = "💰 Coins", value = formatNumber(coins), inline = true})
        table.insert(fields, {name = "⚔️ Kills", value = formatNumber(kills), inline = true})

        local userEmbed = {
            title = "🎲 New Slime Rolled!",
            description = string.format("**||%s||** rolled **%s**!\n\n🎲 **Total Rolls:** %s", playerName, displayName, ordinalSuffix(totalRolls)),
            thumbnail = iconUrl and {url = iconUrl, width = thumbSize, height = thumbSize} or nil,
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
                    thumbnail = iconUrl and {url = iconUrl, width = thumbSize, height = thumbSize} or nil,
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
                thumbnail = iconUrl and {url = iconUrl, width = thumbSize, height = thumbSize} or nil,
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

    local function getBestSlimeUid()
        local stats = DataClient:get("stats") or {}
        local rarest = stats.rarestRoll
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

    local function getAllUpgradeIds()
        local ids = {}
        local costs = {}
        local visited = {}
        local function scan(tree)
            if type(tree) ~= "table" or visited[tree] then return end
            visited[tree] = true
            for key, val in pairs(tree) do
                if type(val) == "table" then
                    if val.cost then
                        table.insert(ids, key)
                        costs[key] = val.cost
                    end
                    scan(val)
                end
            end
        end
        scan(UpgradeTree.main)
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

    local rayfieldOk, rayfield = pcall(function()
        local src = game:HttpGet('https://sirius.menu/rayfield')
        local fn = loadstring(src)
        return fn()
    end)
    if not rayfieldOk then
        rayfield = setmetatable({}, {
            __index = function(t, k)
                if k == "Flags" then
                    return setmetatable({}, { __index = function() return { CurrentValue = false, CurrentOption = { "" } } end })
                end
                return function() return setmetatable({}, { __index = function() return function() return {} end end }) end
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

    mainTab:CreateParagraph({
        Title = "Enabled By Default",
        Content = "[+] Anti AFK"
    })

    mainTab:CreateParagraph({
        Title = "Latest Update",
        Content = "[+] Auto Complete Index\n[+] Move to Enemy\n[+] Dice Stack\n[+] Auto Fruits\n[+] Bug Fixes"
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
                local gui = player.PlayerGui:FindFirstChild("__MAINHUD__")
                if gui then gui:Destroy() end
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
        Callback = function(option) end,
    })

    farmingTab:CreateToggle({
        Name = "Auto Farm Zone",
        CurrentValue = false,
        Flag = "FarmingStayInBestZone",
        Callback = function(value)
            if value then
                task.spawn(function()
                    while rayfield.Flags.FarmingStayInBestZone and rayfield.Flags.FarmingStayInBestZone.CurrentValue do
                        local targetOption = rayfield.Flags.FarmingZoneTarget.CurrentOption[1]
                        if targetOption == "Best Unlocked" then
                            local maxZone = 33
                            for z = maxZone, 1, -1 do
                                if not (rayfield.Flags.FarmingStayInBestZone and rayfield.Flags.FarmingStayInBestZone.CurrentValue) then break end
                                ZonesRemote:InvokeServer("requestTeleportZone", z)
                                task.wait(1)
                                if (DataClient:get("zone") or 1) == z then break end
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

    farmingTab:CreateToggle({
        Name = "Auto Unlock Affordable Zones",
        CurrentValue = false,
        Flag = "FarmingUnlockAffordableZones",
        Callback = function(value)
            if value then
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
        Callback = function(value)
            if value then
                task.spawn(function()
                    local waitTime = 30
                    while rayfield.Flags.FarmingEquipBestSlimes and rayfield.Flags.FarmingEquipBestSlimes.CurrentValue do
                        InventoryRemoteFunc:InvokeServer("requestEquipBest")
                        task.wait(waitTime)
                        waitTime = math.min(waitTime * 2, 600)
                    end
                end)
            end
        end,
    })

    farmingTab:CreateToggle({
        Name = "Auto Transfer XP",
        CurrentValue = false,
        Flag = "FarmingTransferXP",
        Callback = function(value) end,
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
                local inventory = DataClient:get("inventory") or {}
                local equipped = DataClient:get("equipped") or {}
                local teamSet = {}
                for _, uid in ipairs(equipped) do teamSet[uid] = true end
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
                            local isEquipped = teamSet[uid]
                            local hasXp = (type(data) == "table" and (data.xp or 0) > 0) or (type(data) == "number" and data > 0)
                            if sourceOption == "Unequipped With XP" and not isEquipped and hasXp then
                                XpTransferRemote:fetch("requestTransferXp", uid, target)
                                task.wait(0.5)
                            elseif sourceOption == "All Slimes" and hasXp then
                                XpTransferRemote:fetch("requestTransferXp", uid, target)
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
        Callback = function(value)
            if value then
                task.spawn(function()
                    local rollSlice = require(Source.Features.Roll.RollSlice)
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
        Callback = function(value)
            if value then
                task.spawn(function()
                    while rayfield.Flags.FarmingCollectLoot and rayfield.Flags.FarmingCollectLoot.CurrentValue do
                        for _, folder in ipairs({"Loot", "Debris"}) do
                            local container = workspace:FindFirstChild(folder)
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

    farmingTab:CreateSection("Dice Stack")

    local SpecialRollUtils = require(Source.Features.Roll.SpecialRollUtils)
    local SpecialRollNetworker = NetworkerClient.client.new("RollService", {})

    local DICE_LIST = { "golden", "diamond", "void", "galaxy" }
    local diceSelected = { golden = true, diamond = true, void = true, galaxy = true }
    local diceStackActive = false
    local dicePaused = { golden = false, diamond = false, void = false, galaxy = false }

    local diceLuckLabel = farmingTab:CreateLabel("Total Stacked: x0")

    farmingTab:CreateToggle({
        Name = "Auto Stack Dice",
        CurrentValue = false,
        Flag = "DiceStackToggle",
        Callback = function(v)
            diceStackActive = v
            if not v then
                for _, dice in ipairs(DICE_LIST) do
                    if dicePaused[dice] then
                        pcall(function() SpecialRollNetworker:fetch("requestSetSpecialRollPaused", dice, false) end)
                        dicePaused[dice] = false
                    end
                end
            end
        end,
    })

    local diceOptionsList = {}
    for _, d in ipairs(DICE_LIST) do
        table.insert(diceOptionsList, d:gsub("^%l", string.upper))
    end
    table.sort(diceOptionsList)

    farmingTab:CreateDropdown({
        Name = "Dice to Stack",
        Options = { "All", unpack(diceOptionsList) },
        CurrentOption = { "All" },
        MultipleOptions = true,
        Flag = "DiceStackSelection",
        Callback = function(choices)
            for _, dice in ipairs(DICE_LIST) do
                diceSelected[dice] = false
            end
            for _, choice in ipairs(choices) do
                if choice == "All" then
                    for _, dice in ipairs(DICE_LIST) do
                        diceSelected[dice] = true
                    end
                    break
                else
                    diceSelected[choice:lower()] = true
                end
            end
        end,
    })

    task.spawn(function()
        while true do
            task.wait(0.5)

            local upgrades = DataClient:get("upgrades") or {}
            local progression = DataClient:get("specialRollProgression") or {}

            local totalStacked = 0
            for _, dice in ipairs(DICE_LIST) do
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
                diceLuckLabel:Set("Total Stacked: x" .. string.format("%.1f", totalStacked))
            end)

            if not diceStackActive then continue end

            local toWatch = {}
            for _, dice in ipairs(DICE_LIST) do
                if diceSelected[dice] then
                    local ok = false
                    pcall(function()
                        ok = SpecialRollUtils.isUnlocked(dice, upgrades)
                    end)
                    if ok then
                        table.insert(toWatch, dice)
                    end
                end
            end

            if #toWatch == 0 then continue end

            local allReady = true
            for _, dice in ipairs(toWatch) do
                local prog = progression[dice]
                local rolls = prog and prog.rollsUntilNext or math.huge
                if rolls <= 1 then
                    if not dicePaused[dice] then
                        pcall(function() SpecialRollNetworker:fetch("requestSetSpecialRollPaused", dice, true) end)
                        dicePaused[dice] = true
                    end
                else
                    allReady = false
                end
            end

            if allReady then
                for _, dice in ipairs(toWatch) do
                    pcall(function() SpecialRollNetworker:fetch("requestSetSpecialRollPaused", dice, false) end)
                    dicePaused[dice] = false
                end
                rayfield:Notify({
                    Title = "Unleashed!",
                    Content = "All stacked — releasing now.",
                    Duration = 3,
                    Image = 4483362458,
                })
                task.wait(2)
            end
        end
    end)

    farmingTab:CreateSection("Auto Fruits")

    local FruitsModule = require(Source.Game.Items.Fruits)
    local ALL_FRUITS = FruitsModule.getSortedFruits()
    local fruitOptionsList = { "Any" }
    local fruitLabelToId = {}
    for _, f in ipairs(ALL_FRUITS) do
        table.insert(fruitOptionsList, f.powerName)
        fruitLabelToId[f.powerName] = f.id
    end

    local autoFruitsEnabled = false
    local selectedFruitIds = { "ANY" }
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
                        InventoryRemoteFunc:InvokeServer("requestUseFruit", fruitId, slimeKey)
                    end)
                end
            end
        end
    end

    farmingTab:CreateToggle({
        Name = "Auto Feed Fruits to Slime(s)",
        CurrentValue = false,
        Flag = "AutoFruitsToggle",
        Callback = function(value)
            autoFruitsEnabled = value
            if autoFruitsEnabled then
                if feedConnection then feedConnection:Disconnect() end
                feedConnection = RunService.Heartbeat:Connect(function()
                    if autoFruitsEnabled then pcall(doFeed) end
                end)
            else
                if feedConnection then
                    feedConnection:Disconnect()
                    feedConnection = nil
                end
            end
        end,
    })

    farmingTab:CreateDropdown({
        Name = "Slimes to Feed",
        Options = { "Best", "Split Across Team" },
        CurrentOption = { "Best" },
        MultipleOptions = false,
        Flag = "FruitsSlimeMode",
        Callback = function(option)
            selectedSlimeMode = type(option) == "table" and option[1] or option
        end,
    })

    local sortedFruitOptions = {}
    for _, opt in ipairs(fruitOptionsList) do
        table.insert(sortedFruitOptions, opt)
    end
    table.sort(sortedFruitOptions)
    if sortedFruitOptions[1] ~= "Any" then
        table.insert(sortedFruitOptions, 1, "Any")
    end

    farmingTab:CreateDropdown({
        Name = "Fruits to Feed",
        Options = sortedFruitOptions,
        CurrentOption = { "Any" },
        MultipleOptions = true,
        Flag = "FruitsSelection",
        Callback = function(options)
            local picked = type(options) == "table" and options or { options }
            selectedFruitIds = {}
            for _, label in ipairs(picked) do
                if label == "Any" then
                    selectedFruitIds = { "ANY" }
                    return
                else
                    table.insert(selectedFruitIds, fruitLabelToId[label])
                end
            end
            if #selectedFruitIds == 0 then
                selectedFruitIds = { "ANY" }
            end
        end,
    })

    local gameTab = window:CreateTab("Game", 82493603309814)

    gameTab:CreateSection("Rebirth")

    gameTab:CreateToggle({
        Name = "Auto Rebirth",
        CurrentValue = false,
        Flag = "GameAutoRebirth",
        Callback = function(value)
            if value then
                task.spawn(function()
                    while rayfield.Flags.GameAutoRebirth and rayfield.Flags.GameAutoRebirth.CurrentValue do
                        local rebirths = DataClient:get("rebirths") or 0
                        local goop = DataClient:get("goop") or 0
                        local furthestZone = DataClient:get("furthestZone") or 0
                        local cost = (2 ^ rebirths) * 500
                        local minZone = tonumber(rayfield.Flags.GameMinZoneRebirth and rayfield.Flags.GameMinZoneRebirth.CurrentValue or 0)
                        if furthestZone >= minZone and goop >= cost then
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
        Callback = function(val) end,
    })

    gameTab:CreateSection("Upgrades")

    gameTab:CreateToggle({
        Name = "Auto Upgrade Purchasing",
        CurrentValue = false,
        Flag = "GameAutoUpgrade",
        Callback = function(value)
            if value then
                task.spawn(function()
                    local upgradeIds, upgradeCosts = getAllUpgradeIds()
                    while task.wait(0.5) and rayfield.Flags.GameAutoUpgrade and rayfield.Flags.GameAutoUpgrade.CurrentValue do
                        local mode = rayfield.Flags.GameUpgradeMode and rayfield.Flags.GameUpgradeMode.CurrentOption[1] or "All"
                        local purchased = DataClient:get("upgrades") or {}
                        local coins = DataClient:get("coins") or 0
                        local goop = DataClient:get("goop") or 0
                        local rollCurrency = DataClient:get("rollCurrency") or 0
                        for _, id in ipairs(upgradeIds) do
                            if not purchased[id] then
                                local cost = upgradeCosts[id]
                                if cost then
                                    local amount = cost.amount or 0
                                    local currency = cost.currency
                                    local valid = (mode == "All")
                                        or (mode == "Coins" and currency == "coins")
                                        or (mode == "Goop" and currency == "goop")
                                        or (mode == "Rolls" and currency == "rollCurrency")
                                    local canAfford = (currency == "coins" and coins >= amount)
                                        or (currency == "goop" and goop >= amount)
                                        or (currency == "rollCurrency" and rollCurrency >= amount)
                                    if valid and canAfford then
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
        Options = { "All", "Goop", "Coins", "Rolls" },
        CurrentOption = { "All" },
        MultipleOptions = false,
        Flag = "GameUpgradeMode",
        Callback = function(option) end,
    })

    gameTab:CreateSection("Index Auto Complete")

    local SettingsState = require(Source.Features.Settings.SettingsState)
    local SettingsServiceClient = require(Source.Features.Settings.SettingsServiceClient)

    local function getLive(key)
        local v = SettingsState.get(key)
        if type(v) == "function" then return v() end
        return v
    end

    SettingsState.init()

    local settingsClient = {}
    settingsClient.networker = NetworkerClient.client.new("SettingsService", settingsClient)
    SettingsServiceClient.init(settingsClient)

    repeat task.wait() until getLive("luckOverrideEnabled") ~= nil

    local CATEGORY_IDS = { "basic", "shiny", "big", "huge", "inverted" }

    local MUTATION_ODDS = {
        basic = nil,
        shiny = 0.004,
        big = 0.01,
        huge = 0.001,
        inverted = 0.0004,
    }

    local currentLuckValue = 1

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
        currentLuckValue = clamped
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
        local options = { "🎲 All (Recommended)" }
        for _, catId in ipairs(CATEGORY_IDS) do
            local missing = getMissingSlimes(catId)
            local label = catId:sub(1, 1):upper() .. catId:sub(2)
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
            local label = catId:sub(1, 1):upper() .. catId:sub(2)
            if option:find(label) then return catId end
        end
        return nil
    end

    local indexRunning = false
    local indexThread = nil
    local luckPollThread = nil
    local selectedCategoryOption = nil
    local indexLabels = {}

    local indexTargetLabel = gameTab:CreateLabel("🎯 Target: —")
    local indexOddsLabel = gameTab:CreateLabel("🎲 Odds: —")
    local indexLuckLabel = gameTab:CreateLabel("🍀 Luck: —")
    local indexCategoryLabel = gameTab:CreateLabel("📂 Category: —")

    local function refreshIndexProgress()
        local total = getTotalSlimes()
        for _, catId in ipairs(CATEGORY_IDS) do
            if indexLabels[catId] then
                local label = catId:sub(1, 1):upper() .. catId:sub(2)
                local count = getUnlockedCount(catId)
                indexLabels[catId]:Set(string.format("📊 %s: %d / %d", label, count, total))
            end
        end
    end

    local function startLuckPoll()
        luckPollThread = task.spawn(function()
            while indexRunning do
                indexLuckLabel:Set("🍀 Luck Override: x" .. tostring(currentLuckValue))
                refreshIndexProgress()
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
        local catLabel = catId:sub(1, 1):upper() .. catId:sub(2)
        local lastTargetId = nil

        while indexRunning do
            local missing = getMissingSlimes(catId)
            if #missing == 0 then return true end

            local target = mode == "🎯 Rarest First" and missing[#missing] or missing[1]
            local effOdds = getEffectiveOdds(target, catId)

            if target.id ~= lastTargetId then
                lastTargetId = target.id
                applyLuckForTarget(effOdds)
            end

            indexTargetLabel:Set("🎯 Target: " .. catLabel .. " " .. target.name)
            indexOddsLabel:Set("🎲 Odds: " .. formatOdds(effOdds))
            indexCategoryLabel:Set(string.format("📂 %s (%d left)", catLabel, #missing))

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
                    warn("[Index Stuck]", failCount, "rolls |", catLabel, target.name)
                end
            end

            task.wait()
        end

        return false
    end

    local categoryOptionsList = buildCategoryOptions()
    selectedCategoryOption = categoryOptionsList[1]

    gameTab:CreateDropdown({
        Name = "Index Category",
        Options = categoryOptionsList,
        CurrentOption = { categoryOptionsList[1] },
        MultipleOptions = false,
        Flag = "IndexCategory",
        Callback = function(option)
            selectedCategoryOption = type(option) == "table" and option[1] or option
        end,
    })

    gameTab:CreateDropdown({
        Name = "Roll Mode",
        Options = { "🌱 Easiest First", "🎯 Rarest First" },
        CurrentOption = { "🌱 Easiest First" },
        MultipleOptions = false,
        Flag = "IndexRollMode",
        Callback = function() end,
    })

    gameTab:CreateToggle({
        Name = "Start Auto Complete Index",
        CurrentValue = false,
        Flag = "IndexAutoComplete",
        Callback = function(value)
            if value then
                indexRunning = true
                indexThread = task.spawn(function()
                    applyLuckSettings()
                    startLuckPoll()

                    local mode = rayfield.Flags.IndexRollMode and rayfield.Flags.IndexRollMode.CurrentOption[1] or "🌱 Easiest First"

                    if selectedCategoryOption == nil or selectedCategoryOption == "🎲 All (Recommended)" then
                        while indexRunning do
                            local sorted = getSortedCategoriesByPriority()
                            if #sorted == 0 then
                                indexCategoryLabel:Set("📂 ✅ All Complete!")
                                indexTargetLabel:Set("🎯 Target: —")
                                indexOddsLabel:Set("🎲 Odds: —")
                                indexRunning = false
                                break
                            end
                            local completed = runCategory(sorted[1].id, mode)
                            if not completed then break end
                        end
                    else
                        local catId = getCatIdFromOption(selectedCategoryOption)
                        if catId then
                            runCategory(catId, mode)
                            if indexRunning then
                                indexCategoryLabel:Set("📂 ✅ Complete!")
                                indexTargetLabel:Set("🎯 Target: —")
                                indexOddsLabel:Set("🎲 Odds: —")
                            end
                        end
                        indexRunning = false
                    end

                    stopLuckPoll()
                    setLuckEnabled(false)
                    refreshIndexProgress()
                end)
            else
                indexRunning = false
                stopLuckPoll()
                if indexThread then
                    task.cancel(indexThread)
                    indexThread = nil
                end
                setLuckEnabled(false)
                indexTargetLabel:Set("🎯 Target: —")
                indexOddsLabel:Set("🎲 Odds: —")
                indexLuckLabel:Set("🍀 Luck: —")
                indexCategoryLabel:Set("📂 Category: —")
                refreshIndexProgress()
            end
        end,
    })

    gameTab:CreateSection("Index Progress")

    local totalSlimesCount = getTotalSlimes()
    for _, catId in ipairs(CATEGORY_IDS) do
        local label = catId:sub(1, 1):upper() .. catId:sub(2)
        local count = getUnlockedCount(catId)
        indexLabels[catId] = gameTab:CreateLabel(string.format("📊 %s: %d / %d", label, count, totalSlimesCount))
    end

    gameTab:CreateSection("Move to Enemy")

    local moveSettings = {
        TeleportStyle = "Teleport",
        TargetPriorities = { ["Most Coins & Goop"] = true },
        AutoFarm = false,
        MutationFilter = "Any",
    }

    local MOVE_RANGE = 50

    local cachedGameplayContainer = nil
    local cachedEnemies = {}
    local lastEnemyCacheTime = 0
    local currentMoveTarget = nil
    local tweenConnection = nil

    local function getGameplayContainerMove()
        if cachedGameplayContainer and cachedGameplayContainer.Parent then return cachedGameplayContainer end
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name:match("^Gameplay") then
                cachedGameplayContainer = child
                return child
            end
        end
        return nil
    end

    local function getEnemyRootPart(enemy)
        return enemy:FindFirstChild("HumanoidRootPart")
            or enemy.PrimaryPart
            or enemy:FindFirstChildWhichIsA("BasePart")
    end

    local function getEnemyMutation(enemy)
        for _, mut in ipairs({ "inverted", "huge", "shiny", "big" }) do
            local ok, val = pcall(function() return enemy:GetAttribute(mut) end)
            if ok and val then return mut end
            if enemy:FindFirstChild(mut) then return mut end
            local m = enemy:FindFirstChild("Mutation")
            if m and m.Value == mut then return mut end
            if enemy.Name:lower():find(mut) then return mut end
        end
        return nil
    end

    local function getEnemyValueData(enemy, rootPart)
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

    local function refreshEnemyCacheMove()
        if tick() - lastEnemyCacheTime < 2 then return end
        lastEnemyCacheTime = tick()
        cachedEnemies = {}
        local container = getGameplayContainerMove()
        if not container then return end
        local enemyFolder = container:FindFirstChild("Enemies")
        if not enemyFolder then return end
        for _, enemy in ipairs(enemyFolder:GetChildren()) do
            if enemy:IsA("Model") then
                table.insert(cachedEnemies, enemy)
            end
        end
    end

    local function matchesMutationFilterMove(enemy)
        if moveSettings.MutationFilter == "Any" then return true end
        return getEnemyMutation(enemy) == moveSettings.MutationFilter:lower()
    end

    local function computeEnemyScores()
        local char = player.Character
        if not char then return {} end
        local rp = char:FindFirstChild("HumanoidRootPart")
        if not rp then return {} end

        local entries = {}
        for _, enemy in ipairs(cachedEnemies) do
            if not isEnemyAlive(enemy) then continue end
            if not matchesMutationFilterMove(enemy) then continue end
            local root = getEnemyRootPart(enemy)
            if not root then continue end
            local dist = (root.Position - rp.Position).Magnitude
            if dist > MOVE_RANGE then continue end
            local data = getEnemyValueData(enemy, root)
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
        local priorities = moveSettings.TargetPriorities
        for _, e in ipairs(entries) do
            local s = 0
            if priorities["Most Coins & Goop"] then
                local coinsNorm = maxCoins > 0 and e.data.coins / maxCoins or 0
                local goopNorm = maxGoop > 0 and e.data.goop / maxGoop or 0
                s = s + (coinsNorm + goopNorm) / 2
            end
            if priorities["Closest"] then
                s = s + (maxDist > 0 and 1 - e.data.distance / maxDist or 0)
            end
            if priorities["Lowest HP"] then
                s = s + (maxHealth > 0 and 1 - e.data.health / maxHealth or 0)
            end
            if priorities["Mutations Only"] then
                s = s + (e.data.mutation and 1 or 0)
            end
            scores[e.enemy] = s
        end

        return scores
    end

    local function selectMoveTarget()
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

    local function moveToEnemyTarget(enemy)
        local char = player.Character
        if not char then return end
        local root = getEnemyRootPart(enemy)
        if not root then return end
        local targetCFrame = root.CFrame * CFrame.new(0, 3, 0)

        if moveSettings.TeleportStyle == "Teleport" then
            char:PivotTo(targetCFrame)
        elseif moveSettings.TeleportStyle == "Tween" then
            if tweenConnection then tweenConnection:Disconnect() end
            local start = char:GetPivot()
            local startTime = tick()
            local duration = 0.25
            tweenConnection = RunService.RenderStepped:Connect(function()
                local alpha = math.clamp((tick() - startTime) / duration, 0, 1)
                char:PivotTo(start:Lerp(targetCFrame, alpha))
                if alpha >= 1 then
                    tweenConnection:Disconnect()
                    tweenConnection = nil
                end
            end)
        end
    end

    RunService.Heartbeat:Connect(function()
        refreshEnemyCacheMove()

        if not moveSettings.AutoFarm then
            currentMoveTarget = nil
            return
        end

        if currentMoveTarget and isEnemyAlive(currentMoveTarget) and currentMoveTarget.Parent then
            return
        end

        local newTarget = selectMoveTarget()
        if newTarget and newTarget ~= currentMoveTarget then
            currentMoveTarget = newTarget
            moveToEnemyTarget(currentMoveTarget)
        end
    end)

    gameTab:CreateDropdown({
        Name = "Teleport Style",
        Options = { "Teleport", "Tween" },
        CurrentOption = { "Teleport" },
        MultipleOptions = false,
        Flag = "MoveTeleportStyle",
        Callback = function(option)
            moveSettings.TeleportStyle = type(option) == "table" and option[1] or option
        end,
    })

    local priorityOptionsList = { "Most Coins & Goop", "Closest", "Lowest HP", "Mutations Only" }
    table.sort(priorityOptionsList)

    gameTab:CreateDropdown({
        Name = "Target Priority",
        Options = priorityOptionsList,
        CurrentOption = { "Most Coins & Goop" },
        MultipleOptions = true,
        Flag = "MoveTargetPriority",
        Callback = function(options)
            moveSettings.TargetPriorities = {}
            for _, opt in ipairs(options) do
                moveSettings.TargetPriorities[opt] = true
            end
        end,
    })

    local mutationFilterOptions = { "Any", "Inverted", "Huge", "Shiny", "Big" }
    table.sort(mutationFilterOptions)
    if mutationFilterOptions[1] ~= "Any" then
        table.insert(mutationFilterOptions, 1, "Any")
    end

    gameTab:CreateDropdown({
        Name = "Mutation Filter",
        Options = mutationFilterOptions,
        CurrentOption = { "Any" },
        MultipleOptions = false,
        Flag = "MoveMutationFilter",
        Callback = function(option)
            moveSettings.MutationFilter = type(option) == "table" and option[1] or option
        end,
    })

    gameTab:CreateToggle({
        Name = "Auto Move to Enemy",
        CurrentValue = false,
        Flag = "MoveAutoFarm",
        Callback = function(value)
            moveSettings.AutoFarm = value
            if not value then currentMoveTarget = nil end
        end,
    })

    local miscTab = window:CreateTab("Misc", 96334002390551)

    miscTab:CreateSection("Codes & Rewards")

    miscTab:CreateToggle({
        Name = "Auto Redeem Codes",
        CurrentValue = false,
        Flag = "MiscRedeemCodes",
        Callback = function(value)
            if value then
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
        Callback = function(value)
            if value then
                task.spawn(function()
                    while rayfield.Flags.MiscClaimOffline and rayfield.Flags.MiscClaimOffline.CurrentValue do
                        OfflineRemote:InvokeServer("requestClaim")
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
        Callback = function(value)
            if value then
                task.spawn(function()
                    local function claimRewards()
                        local indexData = DataClient:get("index")
                        if not indexData or not indexData.categories then return end
                        for categoryKey, rewardsList in pairs(IndexRewards) do
                            local cat = indexData.categories[categoryKey]
                            if cat then
                                local unlocked = cat.unlocked or {}
                                local unlockedCount = 0
                                for _, v in pairs(unlocked) do if v == true then unlockedCount = unlockedCount + 1 end end
                                local claimed = cat.claimedRewards or {}
                                for _, reward in ipairs(rewardsList) do
                                    if unlockedCount >= reward.req and not claimed[reward.key] then
                                        IndexRemote:InvokeServer("requestClaimReward", categoryKey)
                                        task.wait(0.5)
                                    end
                                end
                            end
                        end
                    end
                    while rayfield.Flags.MiscClaimIndex and rayfield.Flags.MiscClaimIndex.CurrentValue do
                        claimRewards()
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
        Callback = function(value)
            if value then
                task.spawn(function()
                    while task.wait(1) and rayfield.Flags.MiscUsePotions and rayfield.Flags.MiscUsePotions.CurrentValue do
                        local boosts = DataClient:get("boosts") or {}
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

    local sortedBoostKinds = {}
    for _, k in ipairs(BoostKinds) do table.insert(sortedBoostKinds, k) end
    table.sort(sortedBoostKinds)

    miscTab:CreateDropdown({
        Name = "Potion Types",
        Options = sortedBoostKinds,
        CurrentOption = { sortedBoostKinds[1] or "" },
        MultipleOptions = true,
        Flag = "MiscPotionTypes",
        Callback = function(option) end,
    })

    miscTab:CreateToggle({
        Name = "Auto Use Dice & Items",
        CurrentValue = false,
        Flag = "MiscUseDice",
        Callback = function(value)
            if value then
                task.spawn(function()
                    while task.wait(1) and rayfield.Flags.MiscUseDice and rayfield.Flags.MiscUseDice.CurrentValue do
                        local items = DataClient:get("items") or {}
                        local selected = rayfield.Flags.MiscDiceTypes and rayfield.Flags.MiscDiceTypes.CurrentOption or {}
                        for _, name in ipairs(selected) do
                            local id = DiceNameToId[name]
                            if id and (items[id] or 0) > 0 then
                                InventoryRemoteFunc:InvokeServer("requestUseItem", id)
                            end
                        end
                    end
                end)
            end
        end,
    })

    local sortedDiceNames = {}
    for _, id in ipairs(DiceIds) do
        table.insert(sortedDiceNames, DiceNameMap[id])
    end
    table.sort(sortedDiceNames)

    miscTab:CreateDropdown({
        Name = "Dice & Item Types",
        Options = sortedDiceNames,
        CurrentOption = { sortedDiceNames[1] or "" },
        MultipleOptions = true,
        Flag = "MiscDiceTypes",
        Callback = function(option) end,
    })

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
        Callback = function(value) end,
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
                rayfield:Notify({ Title = "Webhook", Content = "URL saved: " .. masked, Duration = 3 })
            end
        end,
    })

    webhookTab:CreateInput({
        Name = "User ID",
        CurrentValue = "",
        PlaceholderText = "Discord User ID",
        RemoveTextAfterFocusLost = false,
        Flag = "WebhookUserID",
        Callback = function(val) end,
    })

    webhookTab:CreateInput({
        Name = "Minimum Chance To Send",
        CurrentValue = "",
        PlaceholderText = "e.g. 1B or 1000000000",
        RemoveTextAfterFocusLost = false,
        Flag = "WebhookMinChance",
        Callback = function(val) end,
    })

    webhookTab:CreateButton({
        Name = "Test Webhook",
        Callback = function()
            if userWebhookUrl == "" then
                rayfield:Notify({ Title = "Webhook", Content = "Please paste a Webhook URL first.", Duration = 4 })
                return
            end
            if not rayfield.Flags.WebhookEnabled.CurrentValue then
                rayfield:Notify({ Title = "Webhook", Content = "Please enable Webhook first.", Duration = 4 })
                return
            end
            local userId = rayfield.Flags.WebhookUserID.CurrentValue
            local mention = mentionUser(userId)
            local res = request({
                Url = userWebhookUrl,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({
                    content = mention,
                    username = "Cactus Hub",
                    avatar_url = WEBHOOK_AVATAR,
                    embeds = { {
                        title = "✅ Webhook Test",
                        description = "Your webhook is working correctly!",
                        color = 0x2ecc71,
                    } }
                })
            })
            if not res then
                rayfield:Notify({ Title = "Webhook", Content = "Failed to send test.", Duration = 4 })
            else
                rayfield:Notify({ Title = "Webhook", Content = "Test sent successfully!", Duration = 4 })
            end
        end,
    })

    webhookTab:CreateSection("Filters")

    webhookTab:CreateToggle({
        Name = "Send All Slimes",
        CurrentValue = false,
        Flag = "WebhookSendAll",
        Callback = function(val) end,
    })

    webhookTab:CreateToggle({
        Name = "Send New Slimes Only",
        CurrentValue = false,
        Flag = "WebhookSendNew",
        Callback = function(val) end,
    })

    webhookTab:CreateToggle({
        Name = "Send Mutated Slimes",
        CurrentValue = false,
        Flag = "WebhookSendMutated",
        Callback = function(val) end,
    })

    local mutationFilterWebhook = { "All", "Shiny", "Big", "Huge", "Inverted" }
    table.sort(mutationFilterWebhook)
    if mutationFilterWebhook[1] ~= "All" then
        table.insert(mutationFilterWebhook, 1, "All")
    end

    webhookTab:CreateDropdown({
        Name = "Mutations Filter",
        Options = mutationFilterWebhook,
        CurrentOption = { "All" },
        MultipleOptions = true,
        Flag = "WebhookMutations",
        Callback = function(option) end,
    })

    local lastRollHash = nil

    local function webhookMutationFilter(mutations)
        local selected = rayfield.Flags.WebhookMutations and rayfield.Flags.WebhookMutations.CurrentOption or { "All" }
        local matchAll = false
        for _, opt in ipairs(selected) do
            if opt == "All" then
                matchAll = true
                break
            end
        end
        if matchAll then return true end
        if not mutations then return false end
        local mutType = getMutationDisplay(mutations)
        for _, opt in ipairs(selected) do
            if string.lower(opt) == mutType then return true end
        end
        return false
    end

    task.spawn(function()
        while true do
            task.wait(0.1)

            if not rayfield.Flags.WebhookEnabled or not rayfield.Flags.WebhookEnabled.CurrentValue then
            elseif userWebhookUrl ~= "" then
                if type(RollSlice.rollResults) ~= "function" then
                    task.wait(1)
                else
                    local rollResults = RollSlice.rollResults()
                    if type(rollResults) ~= "table" or #rollResults == 0 then
                        task.wait(0.5)
                    else
                        local hash = encodeRolls(rollResults)
                        if hash ~= lastRollHash then
                            lastRollHash = hash

                            local sendAll = rayfield.Flags.WebhookSendAll and rayfield.Flags.WebhookSendAll.CurrentValue
                            local sendNew = rayfield.Flags.WebhookSendNew and rayfield.Flags.WebhookSendNew.CurrentValue
                            local sendMutated = rayfield.Flags.WebhookSendMutated and rayfield.Flags.WebhookSendMutated.CurrentValue
                            local minChanceStr = rayfield.Flags.WebhookMinChance.CurrentValue
                            local minChanceNum = parseChanceString(minChanceStr)

                            for _, roll in ipairs(rollResults) do
                                local slime = findSlimeFromRoll(roll)
                                if slime then
                                    local slimeId = tostring(slime.id or "")
                                    if slimeId ~= "" then
                                        local mutations = type(slime.mutations) == "table" and next(slime.mutations) ~= nil and slime.mutations or nil
                                        local slimeOk, slimeData = pcall(Slimes.getSlime, slimeId)
                                        local slimeInfo = slimeOk and slimeData or nil

                                        local hasMutation = mutations ~= nil
                                        local isNew = isNewIndexEntry(slimeId, mutations)

                                        local shouldSend = sendAll or (sendNew and isNew) or (sendMutated and hasMutation and webhookMutationFilter(mutations))

                                        if shouldSend and minChanceNum then
                                            local odds = slimeInfo and slimeInfo.odds or 0
                                            local chanceValue = odds > 0 and (1 / odds) or 0
                                            if chanceValue > minChanceNum then
                                                shouldSend = false
                                            end
                                        end

                                        if shouldSend then
                                            local userId = rayfield.Flags.WebhookUserID.CurrentValue
                                            local webhookKey = hash .. "_" .. slimeId .. "_" .. tostring(mutations and Mutations.getIds(mutations) or "")
                                            task.spawn(sendWebhook, slimeId, slimeInfo, mutations, userWebhookUrl, userId, webhookKey)
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

    local settingsTab = window:CreateTab("Settings", 122930981612451)

    settingsTab:CreateSection("System")

    settingsTab:CreateToggle({
        Name = "Anti Kick",
        CurrentValue = false,
        Flag = "SettingsAntiKick",
        Callback = function(value) end,
    })

    settingsTab:CreateToggle({
        Name = "Auto Rejoin On Disconnect",
        CurrentValue = false,
        Flag = "SettingsAutoRejoin",
        Callback = function(value) end,
    })

    settingsTab:CreateToggle({
        Name = "Auto Friend Requests",
        CurrentValue = false,
        Flag = "AutoFriend",
        Callback = function(value)
            if value then
                task.spawn(function()
                    while rayfield.Flags.AutoFriend and rayfield.Flags.AutoFriend.CurrentValue do
                        local players = Players:GetChildren()
                        for _, p in ipairs(players) do
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
        ParticleEmitter = true, Trail = true, Beam = true, Fire = true,
        Smoke = true, Sparkles = true, SurfaceAppearance = true,
        Highlight = true, SelectionBox = true, SelectionSphere = true, Atmosphere = true,
    }
    local OPT_LIGHTING_TYPES = {
        BloomEffect = true, BlurEffect = true, ColorCorrectionEffect = true,
        DepthOfFieldEffect = true, SunRaysEffect = true, PixelateEffect = true,
        FilmGrainEffect = true, Atmosphere = true, Sky = true,
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
        local rs = RunService
        rs:Set3dRenderingEnabled(false)
        task.wait(0.1)
        rs:Set3dRenderingEnabled(true)
    end

    local function cleanOptConnections()
        for _, c in ipairs(optConnections) do c:Disconnect() end
        table.clear(optConnections)
    end

    local optGPUToggle
    local optParticlesToggle
    local optFireToggle
    local optGCToggle
    local optIntenseToggle
    local optMainToggle
    local updatingOptimizations = false

    local function setAllOptimizations(value)
        if optGPUToggle then optGPUToggle:Set(value) end
        if optParticlesToggle then optParticlesToggle:Set(value) end
        if optFireToggle then optFireToggle:Set(value) end
        if optGCToggle then optGCToggle:Set(value) end
        if optIntenseToggle then optIntenseToggle:Set(value) end
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
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CastShadow = false
                        v.Reflectance = 0
                        v.Material = CHEAP_MATERIAL
                    end
                end
                local rs = RunService
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
                for _, v in ipairs(game:GetDescendants()) do
                    if OPT_VISUAL_TYPES[v.ClassName] then
                        v:Destroy()
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
                for _, v in ipairs(game:GetDescendants()) do
                    if v:IsA("Fire") then v:Destroy() end
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

    local statsTab = window:CreateTab("Stats", 4483362458)

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
        { 1e24, "Sp" }, { 1e21, "Sx" }, { 1e18, "Qn" }, { 1e15, "Qd" },
        { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" },
    }

    local function fmtNum(n)
        n = tonumber(n) or 0
        for _, p in ipairs(SUFFIXES) do
            if n >= p[1] then
                local s = string.format("%.2f", n / p[1]):gsub("%.?0+$", "")
                return s .. p[2]
            end
        end
        return tostring(math.floor(n))
    end

    local function fmtTime(s)
        s = math.floor(tonumber(s) or 0)
        local d = math.floor(s / 86400)
        local h = math.floor((s % 86400) / 3600)
        local m = math.floor((s % 3600) / 60)
        if d > 0 then return d .. "d " .. h .. "h " .. m .. "m"
        elseif h > 0 then return h .. "h " .. m .. "m"
        elseif m > 0 then return m .. "m " .. math.floor(s % 60) .. "s"
        else return math.floor(s % 60) .. "s" end
    end

    local function countKeys(t)
        if type(t) ~= "table" then return 0 end
        local c = 0
        for _ in pairs(t) do c = c + 1 end
        return c
    end

    local function getBestRollStats()
        local rd = safeGet("stats", "rarestRoll", "slimeData")
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
        local name = prefix .. id:sub(1, 1):upper() .. id:sub(2)
        local odds = safeNum("stats", "rarestRoll", "odds")
        return name, odds > 0 and ("1 in " .. fmtNum(math.floor(odds))) or "N/A"
    end

    local function getEquippedNames()
        local eq = safeGet("equipped")
        if type(eq) ~= "table" then return "None" end
        local names = {}
        for i = 1, 7 do
            local v = eq[i]
            if v and type(v) == "string" then
                local clean = v:match("%-(.+)$") or v:gsub("^%.", "")
                table.insert(names, clean:sub(1, 1):upper() .. clean:sub(2))
            end
        end
        return #names > 0 and table.concat(names, ", ") or "None"
    end

    local function getIndexCounts()
        local cats = safeGet("index", "categories")
        if type(cats) ~= "table" then return 0, 0, 0, 0, 0 end
        local function c(cat)
            local t = cats[cat]
            return type(t) == "table" and countKeys(t.unlocked or {}) or 0
        end
        return c("basic"), c("big"), c("shiny"), c("huge"), c("inverted")
    end

    local function getTotalInventory()
        local inv = safeGet("inventory")
        if type(inv) ~= "table" then return 0 end
        local t = 0
        for _, v in pairs(inv) do if type(v) == "number" then t = t + v end end
        return t
    end

    local function getUniqueSpecies()
        local inv = safeGet("inventory")
        if type(inv) ~= "table" then return 0 end
        local seen = {}
        local c = 0
        for k in pairs(inv) do
            if type(k) == "string" and not k:match("^%.") then
                local base = k:match("%-(.+)$") or k
                if not seen[base] then seen[base] = true c = c + 1 end
            end
        end
        return c
    end

    local sessionStart = os.clock()
    local startRolls = safeNum("stats", "rolls")
    local startKills = safeNum("stats", "kills")
    local startCoins = safeNum("coins")
    local startGoop = safeNum("goop")

    local prevRolls = startRolls
    local prevCoins = startCoins
    local prevGoop = startGoop
    local lastWin = os.clock()

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
            local r = safeNum("stats", "rolls")
            local c = safeNum("coins")
            local g = safeNum("goop")
            local dr = math.max(0, r - prevRolls)
            local dc = math.max(0, c - prevCoins)
            local dg = math.max(0, g - prevGoop)
            if dr > 0 then windowRPS = dr / dt lastRollMove = now end
            if dc > 0 then windowCPS = dc / dt lastCoinMove = now end
            if dg > 0 then windowGPS = dg / dt lastGoopMove = now end
            prevRolls = r
            prevCoins = c
            prevGoop = g
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
    local function lbl(key, text) L[key] = statsTab:CreateLabel(text) end

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

    local function updateAllStats()
        local now = os.clock()
        local elapsed = math.max(1, now - sessionStart)

        local rolls = safeNum("stats", "rolls")
        local kills = safeNum("stats", "kills")
        local coins = safeNum("coins")
        local goop = safeNum("goop")
        local timePl = safeNum("stats", "timePlayed")
        local totCoins = safeNum("stats", "totalCoins")
        local rebirths = safeNum("rebirths")
        local zone = safeNum("zone")
        local maxZone = safeNum("furthestZone")
        local rollCur = safeNum("rollCurrency")

        local sessRolls = math.max(0, rolls - startRolls)
        local sessKills = math.max(0, kills - startKills)
        local sessCoins = math.max(0, coins - startCoins)
        local sessGoop = math.max(0, goop - startGoop)

        local sessH = math.floor(elapsed / 3600)
        local sessM = math.floor((elapsed % 3600) / 60)
        local sessS = math.floor(elapsed % 60)

        local rps = getRate(windowRPS, lastRollMove, startRolls, rolls)
        local cps = getRate(windowCPS, lastCoinMove, startCoins, coins)
        local gps = getRate(windowGPS, lastGoopMove, startGoop, goop)

        local bestName, bestOdds = getBestRollStats()
        local dailyOdds = safeNum("stats", "dailyRarestRoll", "odds")
        local dailyStr = dailyOdds > 0 and ("1 in " .. fmtNum(math.floor(dailyOdds))) or "N/A"
        local basic, big, shiny, huge, inverted = getIndexCounts()
        local crafting = countKeys(safeGet("craftingRecipes") or {})

        L.sess:Set(string.format("Session: %dh%dm%ds  |  Played: %s  |  Rebirths: %s", sessH, sessM, sessS, fmtTime(timePl), fmtNum(rebirths)))
        L.rolls1:Set(string.format("Rolls/sec: %.2f  |  Rolls/min: %s  |  Rolls/hr: %s", rps, fmtNum(rps * 60), fmtNum(rps * 3600)))
        L.rolls2:Set("Session Rolls: " .. fmtNum(sessRolls) .. "  |  Lifetime: " .. fmtNum(rolls))
        L.coins1:Set("Coins/min: " .. fmtNum(cps * 60) .. "  |  Coins/hr: " .. fmtNum(cps * 3600))
        L.coins2:Set("Session Coins: " .. fmtNum(sessCoins) .. "  |  Total Ever: " .. fmtNum(totCoins))
        L.goop1:Set("Goop/min: " .. fmtNum(gps * 60) .. "  |  Goop/hr: " .. fmtNum(gps * 3600))
        L.goop2:Set("Session Goop: " .. fmtNum(sessGoop) .. "  |  Balance: " .. fmtNum(goop))
        L.kills:Set("Session Kills: " .. fmtNum(sessKills) .. "  |  Lifetime Kills: " .. fmtNum(kills))
        L.best:Set("Best Ever: " .. bestName .. "  |  Odds: " .. bestOdds)
        L.daily:Set("Best Today Odds: " .. dailyStr)
        L.prog:Set("Zone: " .. fmtNum(zone) .. "  |  Max Zone: " .. fmtNum(maxZone) .. "  |  Roll Currency: " .. fmtNum(rollCur))
        L.idx1:Set("Basic: " .. basic .. "  |  Big: " .. big .. "  |  Shiny: " .. shiny .. "  |  Huge: " .. huge .. "  |  Inverted: " .. inverted)
        L.inv:Set("Total Slimes: " .. fmtNum(getTotalInventory()) .. "  |  Species: " .. getUniqueSpecies() .. "  |  Crafting: " .. crafting)
        L.equipped:Set("Equipped: " .. getEquippedNames())
    end

    task.spawn(function()
        while true do
            updateAllStats()
            task.wait(2)
        end
    end)

    local craftingTab = gameTab

    local function getCraftingRemote()
        return ReplicatedStorage
            :WaitForChild("Packages")
            :WaitForChild("_Index")
            :WaitForChild("leifstout_networker@0.3.1")
            :WaitForChild("networker")
            :WaitForChild("_remotes")
            :WaitForChild("CraftingService")
            :WaitForChild("RemoteFunction")
    end

    local RecipesModule = require(Source.Features.Crafting.Recipes)

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
        local equipped = DataClient:get("equipped") or {}
        local set = {}
        for _, uid in pairs(equipped) do set[uid] = true end
        return set
    end

    local function getBestSlimeSet()
        local inventory = DataClient:get("inventory") or {}
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
        local inventory = DataClient:get("inventory") or {}
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
        local unlocked = DataClient:get("craftingRecipes") or {}
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
        local inventory = DataClient:get("inventory") or {}
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

        local inventory = DataClient:get("inventory") or {}
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
    player.Idled:Connect(function()
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new())
    end)

    game:GetService("GuiService").ErrorMessageChanged:Connect(function()
        if rayfield.Flags.SettingsAutoRejoin and rayfield.Flags.SettingsAutoRejoin.CurrentValue then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
        end
    })

    rayfield:LoadConfiguration()
end)
