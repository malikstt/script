local _safe = function(fn) local ok,v=pcall(fn) return ok and v or nil end
local requestFunc = _safe(function() return (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request end)
local _setclipboard = _safe(function() return setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set) end)
local _getconnections = _safe(function() return getconnections or get_signal_cons or getsignalconnections end) or function() return {} end
local _executor = _safe(function() return (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) end) or "Unknown"

task.spawn(function()
    repeat task.wait() until game:IsLoaded()
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local player = Players.LocalPlayer
    print("[CactusHub] Executor:", tostring(_executor))
    print("[CactusHub] HTTP:", (requestFunc ~= nil) and "supported" or "not supported")
    print("[CactusHub] Clipboard:", (_setclipboard ~= nil) and "supported" or "not supported")
    print("[CactusHub] getconnections:", (_getconnections ~= nil) and "supported" or "not supported")
    local okHttpGet = pcall(function() return game:HttpGet("https://example.com") end)
    print("[CactusHub] HttpGet:", okHttpGet and "supported" or "not supported")
    print("[CactusHub] Startup OK")
    if requestFunc then
        local embed = {{
            description = player.Name .. " executed the script",
            color = 5763719,
            footer = { text = "Executor: " .. tostring(_executor) },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
        }}
        local body = HttpService:JSONEncode({ embeds = embed })
        pcall(function()
            requestFunc({
                Url = "https://discord.com/api/webhooks/1484979057342025849/Lmt1_pr3ZhczCAOWJLFh9id9Oa1BJjmVXOf_HlDJWND-aoXHAZu4VQF9z0pOgozJLJCe",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body
            })
        end)
    end
end)

print("[ Cactus Hub ] Loaded")

local Fluent, SaveManager, InterfaceManager

local function tryLoad(url)
    local ok, src = pcall(game.HttpGet, game, url)
    if not ok or not src or src == "" then return nil end
    local ok2, fn = pcall(loadstring, src)
    if not ok2 or not fn then return nil end
    local ok3, result = pcall(fn)
    if not ok3 then return nil end
    return result
end

Fluent = tryLoad("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")
if not Fluent then
    error("[CactusHub] Failed to load Fluent. Check HTTP permissions.")
end

SaveManager = tryLoad("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua")
InterfaceManager = tryLoad("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua")

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpSvc = game:GetService("HttpService")
local RunSvc = game:GetService("RunService")
local lp = Players.LocalPlayer

local function disableIdleConnections()
    local success, connections = pcall(_getconnections, lp.Idled)
    if success then
        for _, con in ipairs(connections) do
            pcall(function() con:Disable() end)
        end
        print("[Anti-AFK] Disabled", #connections, "connections")
    else
        print("[Anti-AFK] Failed to get connections:", tostring(connections))
    end
end
disableIdleConnections()

local Network = RS:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Network")

local RarityData = require(RS.Shared.Data.RarityData)
local EntitiesData = require(RS.Shared.Data.EntitiesData)
local MutationData = require(RS.Shared.Data.MutationData)
local WeightsData = require(RS.Shared.Data.WeightsData)
local WaveData = require(RS.Shared.Data.WaveData).Waves
local VolcanicShopData = require(RS.Shared.Data.VolcanicShopData)
local VolcanoUpgradesData = require(RS.Shared.Data.VolcanoUpgradesData)

local raritiesList = RarityData.Order
local rarities_with_all = {"All"}
for _, r in ipairs(raritiesList) do table.insert(rarities_with_all, r) end

local mutationsList = {"None"}
for _, m in ipairs(MutationData.ValidMutations) do table.insert(mutationsList, m) end
local mutations_with_all = {"All"}
for _, m in ipairs(mutationsList) do table.insert(mutations_with_all, m) end

local brainrotsByRarity = {}
local allBrainrots = {}
for bname, bdata in pairs(EntitiesData.Brainrots) do
    local r = bdata.Rarity
    if not brainrotsByRarity[r] then brainrotsByRarity[r] = {} end
    table.insert(brainrotsByRarity[r], bname)
    table.insert(allBrainrots, bname)
end
for _, list in pairs(brainrotsByRarity) do table.sort(list) end
table.sort(allBrainrots)
local brainrots_with_all = {"All"}
for _, b in ipairs(allBrainrots) do table.insert(brainrots_with_all, b) end

local weightsList = {}
for wname in pairs(WeightsData.Weights) do table.insert(weightsList, wname) end
table.sort(weightsList)
local weights_with_all = {"All"}
for _, w in ipairs(weightsList) do table.insert(weights_with_all, w) end

local volcanoShopItemsList = {}
for itemName in pairs(VolcanicShopData.Items) do
    table.insert(volcanoShopItemsList, itemName)
end
table.sort(volcanoShopItemsList)

local volcanoUpgradeTypesList = {}
local volcanoUpgradeLevels = {}
for upgradeType, levels in pairs(VolcanoUpgradesData.Upgrades) do
    table.insert(volcanoUpgradeTypesList, upgradeType)
    volcanoUpgradeLevels[upgradeType] = #levels
end
table.sort(volcanoUpgradeTypesList)

local function FireRemote(name, ...)
    local r = Network:FindFirstChild(name)
    if r then
        r:FireServer(...)
        print("[Remote] Fired", name)
    else
        print("[Remote] Not found:", name)
    end
end

local function InvokeRemote(name, ...)
    local r = Network:FindFirstChild(name)
    if r then
        local result = r:InvokeServer(...)
        print("[Remote] Invoked", name)
        return result
    else
        print("[Remote] Invoke not found:", name)
    end
end

local function expandAll(selected, fullList)
    for _, v in ipairs(selected) do
        if v == "All" then return fullList end
    end
    return selected
end

local function parseShortNumber(str)
    if not str or str == "" then return nil end
    str = tostring(str):lower():gsub(",", ""):gsub("%s+", "")
    local suffixes = {k = 1e3, m = 1e6, b = 1e9, t = 1e12}
    local num, suf = str:match("^([%d%.]+)([kmbt]?)$")
    if not num then
        print("[Parse] Invalid number format:", str)
        return nil
    end
    local val = tonumber(num)
    if not val then return nil end
    if suf and suffixes[suf] then val = val * suffixes[suf] end
    print("[Parse]", str, "->", val)
    return val
end

local function GetPlot()
    for _, plot in ipairs(workspace.Plots:GetChildren()) do
        if plot:GetAttribute("Owner") == lp.Name then
            print("[Plot] Found:", plot.Name)
            return plot
        end
    end
    print("[Plot] Not found for", lp.Name)
end

local function GetSlots(plot)
    local folder = plot:FindFirstChild("Slots")
    if not folder then return {} end
    local slots = {}
    for _, part in ipairs(folder:GetChildren()) do
        if part:IsA("BasePart") then
            local n = tonumber(part.Name:match("%d+"))
            if n then table.insert(slots, {part = part, num = n}) end
        end
    end
    table.sort(slots, function(a, b) return a.num < b.num end)
    print("[Slots] Found", #slots, "slots")
    return slots
end

local function GetEmptySlots(plot)
    local empty = {}
    for _, s in ipairs(GetSlots(plot)) do
        if not s.part:FindFirstChild("PlacedPart") then
            table.insert(empty, s.num)
        end
    end
    print("[EmptySlots]", #empty, "empty slots")
    return empty
end

local function GetBackpackTools()
    local bp = lp:FindFirstChild("Backpack")
    if not bp then return {} end
    local tools = {}
    for _, t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") then table.insert(tools, t.Name) end
    end
    print("[Backpack]", #tools, "tools")
    return tools
end

local collectConfig = {enabled = false, delay = 1, loop = nil}
local slotCollect = {selected = {}, map = {}, dropdown = nil, auto = false, delay = 1, loop = nil}
local rarityCollect = {rarities = {}, auto = false, delay = 1, loop = nil}
local placeConfig = {specifics = {}, rarities = {}, auto = false, delay = 0.5, loop = nil}
local removeConfig = {specifics = {}, rarities = {}, auto = false, delay = 0.5, loop = nil}
local kickConfig = {running = false, loop = nil, scale = 0.99, mode = "custom"}
local sellRarity = {rarities = {}, auto = false, delay = 5, loop = nil}
local sellSpecific = {targets = {}, auto = false, delay = 5, loop = nil}
local sellMutation = {mutations = {}, auto = false, delay = 5, loop = nil}
local upgradeSlots = {selected = {}, map = {}, dropdown = nil, auto = false, loop = nil}
local upgradeRarity = {rarities = {}, auto = false, loop = nil}
local shopSpeed = {amount = 1, auto = false, loop = nil}
local shopWeights = {selected = {}, auto = false, loop = nil}
local shopSlots = {auto = false, loop = nil}
local shopRebirth = {auto = false, loop = nil}
local volcanoShop = {selected = {}, auto = false, loop = nil, delay = 5}
local volcanoUpgrade = {upgradeType = volcanoUpgradeTypesList[1] or "OreMultipliers", level = 1, auto = false, loop = nil}

local WH = {
    url = "",
    enabled = false,
    mode = "All",
    minEarn = nil,
    pingUID = "",
    rarities = {},
    mutations = {},
    specifics = {},
}

local function refreshSlotMaps()
    local plot = GetPlot()
    if not plot then return end
    local slotMap = {}
    local upgradeMap = {}
    for _, s in ipairs(GetSlots(plot)) do
        local placed = s.part:FindFirstChild("PlacedPart")
        local label = "Slot " .. s.num .. " - " .. (placed and placed:GetAttribute("ID") or "Empty")
        slotMap[label] = s.num
        upgradeMap[label] = s.num
    end
    local vals = {}
    for k in pairs(slotMap) do table.insert(vals, k) end
    if #vals == 0 then vals = {"No brainrots placed"} end
    if slotCollect.dropdown then slotCollect.dropdown:SetValues(vals) end
    if upgradeSlots.dropdown then upgradeSlots.dropdown:SetValues(vals) end
    slotCollect.map = slotMap
    upgradeSlots.map = upgradeMap
    print("[SlotMaps] Refreshed,", #vals, "slots")
end

local function collectFromSlot(slotNum)
    local plot = GetPlot()
    if not plot then return end
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local buttons = plot:FindFirstChild("Buttons")
    if buttons then
        local btn = buttons:FindFirstChild("Slot" .. slotNum)
        if btn and btn:IsA("BasePart") then
            hrp.CFrame = CFrame.new(btn.Position + Vector3.new(0, 3, 0))
            task.wait(0.05)
        end
    end
    FireRemote("rev_B_Collect", slotNum)
    print("[Collect] Slot", slotNum)
end

local function autoCollectLoop()
    while collectConfig.enabled do
        local plot = GetPlot()
        if plot then
            for _, slot in ipairs(GetSlots(plot)) do
                if slot.part:FindFirstChild("PlacedPart") then
                    collectFromSlot(slot.num)
                end
            end
        end
        task.wait(collectConfig.delay)
    end
    print("[AutoCollect] Loop ended")
end

local function autoSlotCollectLoop()
    while slotCollect.auto do
        for _, n in ipairs(slotCollect.selected) do collectFromSlot(n) end
        task.wait(slotCollect.delay)
    end
    print("[SlotCollect] Loop ended")
end

local function autoRarityCollectLoop()
    while rarityCollect.auto do
        local plot = GetPlot()
        if plot and #rarityCollect.rarities > 0 then
            local rars = expandAll(rarityCollect.rarities, raritiesList)
            for _, slot in ipairs(GetSlots(plot)) do
                local placed = slot.part:FindFirstChild("PlacedPart")
                if placed then
                    local id = placed:GetAttribute("ID")
                    for _, rar in ipairs(rars) do
                        for _, bname in ipairs(brainrotsByRarity[rar] or {}) do
                            if id == bname then collectFromSlot(slot.num) break end
                        end
                    end
                end
            end
        end
        task.wait(rarityCollect.delay)
    end
    print("[RarityCollect] Loop ended")
end

local function autoPlaceLoop()
    while placeConfig.auto do
        local plot = GetPlot()
        if plot and #GetEmptySlots(plot) > 0 then
            local specs = placeConfig.specifics
            local rars = placeConfig.rarities
            for _, toolName in ipairs(GetBackpackTools()) do
                local matched = (#specs == 0 and #rars == 0)
                for _, s in ipairs(specs) do if toolName == s then matched = true break end end
                if not matched then
                    for _, rar in ipairs(rars) do
                        for _, bname in ipairs(brainrotsByRarity[rar] or {}) do
                            if toolName == bname then matched = true break end
                        end
                        if matched then break end
                    end
                end
                if matched then
                    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                    local tObj = lp.Backpack:FindFirstChild(toolName)
                    if hum and tObj then
                        hum:EquipTool(tObj)
                        task.wait(0.2)
                        FireRemote("rev_Shop_Buy", "WeightShop", toolName)
                        task.wait(placeConfig.delay)
                        print("[AutoPlace] Placed", toolName)
                    end
                end
            end
        end
        task.wait(1)
    end
    print("[AutoPlace] Loop ended")
end

local function autoRemoveLoop()
    while removeConfig.auto do
        local plot = GetPlot()
        if plot then
            local specs = removeConfig.specifics
            local rars = removeConfig.rarities
            for _, slot in ipairs(GetSlots(plot)) do
                local placed = slot.part:FindFirstChild("PlacedPart")
                if placed then
                    local id = placed:GetAttribute("ID")
                    local matched = (#specs == 0 and #rars == 0)
                    for _, s in ipairs(specs) do if id == s then matched = true break end end
                    if not matched then
                        for _, rar in ipairs(rars) do
                            for _, bname in ipairs(brainrotsByRarity[rar] or {}) do
                                if id == bname then matched = true break end
                            end
                            if matched then break end
                        end
                    end
                    if matched then
                        FireRemote("rev_S_Interact", slot.num)
                        task.wait(removeConfig.delay)
                        print("[AutoRemove] Removed from slot", slot.num, "ID:", id)
                    end
                end
            end
        end
        task.wait(1)
    end
    print("[AutoRemove] Loop ended")
end

local function autoKickLoop()
    local modeMap = {
        custom = function() return kickConfig.scale end,
        ["50-60"] = function() return math.random(50, 60) / 100 end,
        ["60-70"] = function() return math.random(60, 70) / 100 end,
        ["70-80"] = function() return math.random(70, 80) / 100 end,
        ["80-90"] = function() return math.random(80, 90) / 100 end,
        ["90-100"] = function() return math.random(90, 100) / 100 end,
    }
    while kickConfig.running do
        local scale = modeMap[kickConfig.mode] and modeMap[kickConfig.mode]() or 0.99
        local level = 1
        local ls = lp:FindFirstChild("leaderstats")
        if ls and ls:FindFirstChild("KickLevel") then level = ls.KickLevel.Value end
        print("[AutoKick] scale=", scale, "level=", level)
        local success, err = pcall(function()
            Network:WaitForChild("rev_KickEvent"):FireServer(scale, level)
        end)
        if success then print("[AutoKick] rev_KickEvent fired") else print("[AutoKick] rev_KickEvent error:", err) end
        task.wait(0.3)
        success, err = pcall(function()
            Network:WaitForChild("rev_Transformed"):FireServer()
        end)
        if success then print("[AutoKick] rev_Transformed fired") else print("[AutoKick] rev_Transformed error:", err) end
        task.wait(0.1)
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local safe = workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("Safe")
        if hum and safe then
            hum.WalkSpeed = 80
            hum:MoveTo(safe.Position)
            hum.MoveToFinished:Wait()
            print("[AutoKick] Moved to Safe")
        end
    end
    print("[AutoKick] Loop ended")
end

local function sellByRarityLoop()
    while sellRarity.auto do
        if #sellRarity.rarities > 0 then
            local rars = expandAll(sellRarity.rarities, raritiesList)
            for _, toolName in ipairs(GetBackpackTools()) do
                for _, rar in ipairs(rars) do
                    for _, bname in ipairs(brainrotsByRarity[rar] or {}) do
                        if toolName == bname then
                            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                            local tool = lp.Backpack:FindFirstChild(toolName)
                            if hum and tool then
                                hum:EquipTool(tool) task.wait(0.2)
                                InvokeRemote("ref_B_Sell") task.wait(0.2)
                                hum:UnequipTools()
                                print("[SellRarity] Sold", toolName)
                            end
                            break
                        end
                    end
                end
            end
        end
        task.wait(sellRarity.delay)
    end
    print("[SellRarity] Loop ended")
end

local function sellSpecificLoop()
    while sellSpecific.auto do
        if #sellSpecific.targets > 0 then
            local targets = expandAll(sellSpecific.targets, allBrainrots)
            for _, toolName in ipairs(GetBackpackTools()) do
                for _, target in ipairs(targets) do
                    if toolName == target then
                        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                        local tool = lp.Backpack:FindFirstChild(toolName)
                        if hum and tool then
                            hum:EquipTool(tool) task.wait(0.2)
                            InvokeRemote("ref_B_Sell") task.wait(0.2)
                            hum:UnequipTools()
                            print("[SellSpecific] Sold", toolName)
                        end
                        break
                    end
                end
            end
        end
        task.wait(sellSpecific.delay)
    end
    print("[SellSpecific] Loop ended")
end

local function sellByMutationLoop()
    while sellMutation.auto do
        if #sellMutation.mutations > 0 then
            local muts = expandAll(sellMutation.mutations, mutationsList)
            for _, toolName in ipairs(GetBackpackTools()) do
                local tool = lp.Backpack:FindFirstChild(toolName)
                if tool then
                    local mut = tool:GetAttribute("Mutation") or "None"
                    for _, m in ipairs(muts) do
                        if mut == m then
                            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum:EquipTool(tool) task.wait(0.2)
                                InvokeRemote("ref_B_Sell") task.wait(0.2)
                                hum:UnequipTools()
                                print("[SellMutation] Sold", toolName, "mutation:", mut)
                            end
                            break
                        end
                    end
                end
            end
        end
        task.wait(sellMutation.delay)
    end
    print("[SellMutation] Loop ended")
end

local function upgradeSelectedSlots()
    for _, n in ipairs(upgradeSlots.selected) do
        FireRemote("rev_B_Upgrade", n)
        task.wait(0.1)
        print("[UpgradeSlots] Upgraded slot", n)
    end
end

local function upgradeRarityLoop()
    while upgradeRarity.auto do
        if #upgradeRarity.rarities > 0 then
            local rars = expandAll(upgradeRarity.rarities, raritiesList)
            local plot = GetPlot()
            if plot then
                for _, slot in ipairs(GetSlots(plot)) do
                    local placed = slot.part:FindFirstChild("PlacedPart")
                    if placed then
                        local id = placed:GetAttribute("ID")
                        for _, rar in ipairs(rars) do
                            for _, bname in ipairs(brainrotsByRarity[rar] or {}) do
                                if id == bname then
                                    FireRemote("rev_B_Upgrade", slot.num)
                                    task.wait(0.1)
                                    print("[UpgradeRarity] Upgraded slot", slot.num, "ID:", id)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.15)
    end
    print("[UpgradeRarity] Loop ended")
end

local function formatChance(chancePercent)
    if not chancePercent or chancePercent <= 0 then return "Unknown" end
    local inverse = 100 / chancePercent
    if inverse >= 1000000 then
        return string.format("1 in %.0f,000,000", inverse / 1000000)
    else
        return string.format("1 in %s", string.reverse(string.gsub(string.reverse(tostring(math.floor(inverse))), "(%d%d%d)", "%1,")))
    end
end

local function findRarityFromName(itemName)
    if not RarityData.BrainrotPool then
        print("[Rarity] No BrainrotPool")
        return "Unknown"
    end
    for rarity, pool in pairs(RarityData.BrainrotPool) do
        for _, entry in ipairs(pool) do
            if entry.Name == itemName then
                print("[Rarity] Found", itemName, "->", rarity)
                return rarity
            end
        end
    end
    print("[Rarity] Not found:", itemName, "-> Unknown")
    return "Unknown"
end

local function getBrainrotInfo(bname, forcedRarity)
    local rarity = "Unknown"
    local chance = 0
    if RarityData.BrainrotPool then
        for r, pool in pairs(RarityData.BrainrotPool) do
            for _, item in ipairs(pool) do
                if item.Name == bname then
                    rarity = r
                    chance = item.Chance or 0
                    break
                end
            end
            if rarity ~= "Unknown" then break end
        end
    end
    if forcedRarity then
        rarity = forcedRarity
    end
    if rarity == "Unknown" and EntitiesData.Brainrots and EntitiesData.Brainrots[bname] then
        rarity = EntitiesData.Brainrots[bname].Rarity or "Unknown"
    end
    local rc = RarityData.Colors and RarityData.Colors[rarity]
    local color = rc and (math.floor(rc.R * 255) * 65536 + math.floor(rc.G * 255) * 256 + math.floor(rc.B * 255)) or 0x00BFFF
    local speed = WaveData[rarity] and WaveData[rarity].Speed or "?"
    local assetId = nil
    if EntitiesData.Brainrots and EntitiesData.Brainrots[bname] then
        local img = EntitiesData.Brainrots[bname].Image
        if type(img) == "string" then assetId = tonumber(img:match("rbxassetid://(%d+)")) end
    end
    print("[BrainrotInfo]", bname, "rarity=", rarity, "chance=", chance, "speed=", speed)
    return {rarity = rarity, chance = chance, chanceFormatted = formatChance(chance), color = color, speed = speed, assetId = assetId}
end

local function getThumbnail(assetId)
    if not assetId or not requestFunc then
        print("[Thumbnail] Skipped, no assetId or requestFunc")
        return nil
    end
    local url = ("https://thumbnails.roblox.com/v1/assets?assetIds=%d&size=420x420&format=Png"):format(assetId)
    print("[Thumbnail] Fetching", url)
    local ok, res = pcall(requestFunc, {
        Url = url,
        Method = "GET",
    })
    if ok and res and res.Success then
        local ok2, data = pcall(function() return HttpSvc:JSONDecode(res.Body) end)
        if ok2 and data and data.data and data.data[1] then
            local imgUrl = data.data[1].imageUrl
            print("[Thumbnail] Success:", imgUrl)
            return imgUrl
        else
            print("[Thumbnail] Failed to decode response")
        end
    else
        print("[Thumbnail] Request failed:", ok, res)
    end
    return nil
end

local function sendWebhook(bname, mutation, earnedValue, forcedRarity)
    print("[Webhook] Called for", bname, "mutation:", mutation, "earned:", earnedValue, "forcedRarity:", forcedRarity)
    if not WH.enabled then
        print("[Webhook] Skipped: not enabled")
        return
    end
    if WH.url == "" then
        print("[Webhook] Skipped: no URL")
        return
    end
    if not requestFunc then
        print("[Webhook] Skipped: no requestFunc")
        return
    end
    mutation = mutation or "None"
    if WH.mode == "MutatedOnly" and (mutation == "None" or mutation == "") then
        print("[Webhook] Skipped: MutatedOnly filter, mutation=", mutation)
        return
    end
    if WH.minEarn and earnedValue and earnedValue < WH.minEarn then
        print("[Webhook] Skipped: minEarn filter, earned=", earnedValue, "min=", WH.minEarn)
        return
    end
    local info = getBrainrotInfo(bname, forcedRarity)
    if WH.mode == "RarityOnly" and #WH.rarities > 0 then
        local rars = expandAll(WH.rarities, raritiesList)
        local ok = false
        for _, r in ipairs(rars) do if r == info.rarity then ok = true break end end
        if not ok then
            print("[Webhook] Skipped: RarityOnly filter, rarity=", info.rarity)
            return
        end
    end
    if #WH.mutations > 0 then
        local muts = expandAll(WH.mutations, mutationsList)
        local ok = false
        for _, m in ipairs(muts) do if m == mutation then ok = true break end end
        if not ok then
            print("[Webhook] Skipped: Mutation filter, mutation=", mutation)
            return
        end
    end
    if #WH.specifics > 0 then
        local specs = expandAll(WH.specifics, allBrainrots)
        local ok = false
        for _, s in ipairs(specs) do if s == bname then ok = true break end end
        if not ok then
            print("[Webhook] Skipped: Specific filter, brainrot=", bname)
            return
        end
    end
    local mutationText = ""
    if mutation ~= "None" and mutation ~= "" then
        local md = MutationData.Buffs and MutationData.Buffs[mutation]
        local mul = md and md.Value or 1
        mutationText = string.format("\n✨ Mutation: **%s** (x%.1f)", mutation, mul)
    end
    local description = string.format("||%s|| got a **%s %s**!%s", lp.Name, info.rarity, bname, mutationText)
    local embed = {
        title = "🎲 NEW BRAINROT CAPTURED",
        description = description,
        color = info.color,
        fields = {
            {name = "🌀 Rarity", value = info.rarity, inline = true},
            {name = "🍀 Chance", value = info.chanceFormatted, inline = true},
            {name = "⚡ Speed", value = tostring(info.speed), inline = true},
        },
        timestamp = DateTime.now():ToIsoDate(),
    }
    local thumb = getThumbnail(info.assetId)
    if thumb then embed.thumbnail = {url = thumb} end
    local payload = {
        username = "Cactus Hub",
        avatar_url = "https://media.discordapp.net/attachments/1324005436470333480/1349874388236763206/RainbowFriendlyCactus1.png?ex=6a1426bd&is=6a12d53d&hm=adc011c12e097b4238f08364c0ffbd6f30c9eff3f51b7706219b6c8cba76932d&=&format=png",
        embeds = {embed},
    }
    if WH.pingUID ~= "" then payload.content = "<@" .. WH.pingUID .. ">" end
    task.spawn(function()
        local ok, res = pcall(requestFunc, {
            Url = WH.url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpSvc:JSONEncode(payload),
        })
        if ok then
            print("[Webhook] Sent successfully, response body:", res and res.Body or "nil")
        else
            print("[Webhook] Failed to send:", res)
        end
    end)
end

local function sendTestWebhook()
    print("[TestWebhook] Called")
    if not WH.enabled or WH.url == "" then
        print("[TestWebhook] Not enabled or no URL")
        Fluent:Notify({Title = "Webhook", Content = "Enable webhook and enter a URL first.", Duration = 3})
        return
    end
    if not requestFunc then
        print("[TestWebhook] No HTTP function")
        Fluent:Notify({Title = "Webhook", Content = "No HTTP function available.", Duration = 4})
        return
    end
    local payload = {
        username = "Cactus Hub",
        avatar_url = "https://media.discordapp.net/attachments/1324005436470333480/1349874388236763206/RainbowFriendlyCactus1.png?ex=6a1426bd&is=6a12d53d&hm=adc011c12e097b4238f08364c0ffbd6f30c9eff3f51b7706219b6c8cba76932d&=&format=png",
        embeds = {{
            title = "Cactus Hub - Test Ping",
            description = ("Webhook works for ||%s||!"):format(lp.Name),
            color = 0x57F287,
            footer = {text = "Cactus Hub"},
            timestamp = DateTime.now():ToIsoDate(),
        }}
    }
    if WH.pingUID ~= "" then payload.content = "<@" .. WH.pingUID .. ">" end
    task.spawn(function()
        local ok, res = pcall(requestFunc, {
            Url = WH.url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpSvc:JSONEncode(payload),
        })
        if ok then
            print("[TestWebhook] Sent, response:", res and res.Body or "nil")
            Fluent:Notify({Title = "Webhook", Content = "Test ping sent!", Duration = 3})
        else
            print("[TestWebhook] Error:", res)
            Fluent:Notify({Title = "Error", Content = tostring(res), Duration = 5})
        end
    end)
end

lp.Backpack.ChildAdded:Connect(function(tool)
    if not tool:IsA("Tool") then return end
    task.wait(1.1)
    local mutation = tool:GetAttribute("Mutation") or "None"
    local brainrotName = tool.Name
    local webhookRarity = findRarityFromName(brainrotName)
    print("[Backpack] New tool:", brainrotName, "mutation:", mutation, "rarity:", webhookRarity)
    sendWebhook(brainrotName, mutation, nil, webhookRarity)
end)

local Window = Fluent:CreateWindow({
    Title = "Cactus Hub • discord.gg/qMWFBWdcf",
    SubTitle = "by Cactus",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local mainTab = Window:AddTab({ Title = "Main", Icon = "home" })
local farmingTab = Window:AddTab({ Title = "Farming", Icon = "sword" })
local bcTab = Window:AddTab({ Title = "Brainrots & Cash", Icon = "zap" })
local miscTab = Window:AddTab({ Title = "Misc", Icon = "layers" })
local webhookTab = Window:AddTab({ Title = "Webhook", Icon = "webhook" })
local eventTab = Window:AddTab({ Title = "🌋 Event", Icon = "shopping-cart" })
local settingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

local fpsLabel = mainTab:AddParagraph({ Title = "FPS: --", Content = "" })
local pingLabel = mainTab:AddParagraph({ Title = "Ping: --", Content = "" })

local fpsCount = 0
local fpsLast = tick()
RunSvc.RenderStepped:Connect(function()
    fpsCount = fpsCount + 1
    local now = tick()
    if now - fpsLast >= 1 then
        if fpsLabel then fpsLabel:SetTitle("FPS: " .. fpsCount) end
        fpsCount = 0
        fpsLast = now
    end
end)

task.spawn(function()
    while true do
        local pingValue = math.floor(lp:GetNetworkPing() * 1000)
        if pingLabel then pingLabel:SetTitle("Ping: " .. pingValue .. "ms") end
        task.wait(5)
    end
end)

mainTab:AddParagraph({ Title = "⚡ Features", Content = "• Auto Farm Kick\n• Auto Collect & Sell\n• Auto Place & Remove\n• Auto Upgrade & Shop\n• Discord Webhook" })
mainTab:AddParagraph({ Title = "🛡️ Anti-AFK", Content = "Permanently disabled. You won't be kicked." })

mainTab:AddButton({
    Title = "Copy Discord Invite",
    Description = "",
    Callback = function()
        local success = false
        if _setclipboard then
            success = pcall(_setclipboard, "https://discord.gg/qMWFBWdcf")
        end
        if success then Fluent:Notify({Title = "Copied", Content = "Discord invite copied.", Duration = 3})
        else Fluent:Notify({Title = "Error", Content = "Clipboard not supported.", Duration = 3}) end
    end,
})

farmingTab:AddParagraph({ Title = "Kick Settings", Content = "" })
local kickModeDD = farmingTab:AddDropdown("KickMode", {
    Title = "Kick Accuracy Mode",
    Description = "",
    Values = {"custom", "50-60", "60-70", "70-80", "80-90", "90-100"},
    Default = 1,
    Callback = function(opt) kickConfig.mode = opt print("[KickMode] Set to", opt) end,
})
local customKickSlider = farmingTab:AddSlider("CustomKickAccuracy", {
    Title = "Custom Kick Accuracy",
    Description = "",
    Min = 0,
    Max = 100,
    Rounding = 1,
    Default = 99,
    Callback = function(v) kickConfig.scale = v / 100 print("[CustomKick] Set to", v, "%") end,
})
farmingTab:AddParagraph({ Title = "⚠️ WARNING", Content = "Using 99% too many times can trigger anti-cheat. Use lower ranges for safety." })
local autoFarmToggle = farmingTab:AddToggle("AutoFarm", { Title = "Start Auto Farm", Default = false })
autoFarmToggle:OnChanged(function(v)
    kickConfig.running = v
    print("[AutoFarm] Toggled", v)
    if v then
        if kickConfig.loop then task.cancel(kickConfig.loop) end
        kickConfig.loop = task.spawn(autoKickLoop)
    else
        if kickConfig.loop then task.cancel(kickConfig.loop) kickConfig.loop = nil end
    end
end)

farmingTab:AddParagraph({ Title = "Auto Place", Content = "" })
local placeSpecificDD = farmingTab:AddDropdown("PlaceSpecificBrainrots", {
    Title = "Specific Brainrots",
    Description = "",
    Values = brainrots_with_all,
    Multi = true,
    Default = {},
    Callback = function(sel)
        local selected = {}
        for k, v in pairs(sel) do if v then table.insert(selected, k) end end
        placeConfig.specifics = selected
        print("[PlaceSpecific] Selected", #selected, "items")
    end,
})
local placeRaritiesDD = farmingTab:AddDropdown("PlaceRarities", {
    Title = "Rarities",
    Description = "",
    Values = rarities_with_all,
    Multi = true,
    Default = {},
    Callback = function(sel)
        local selected = {}
        for k, v in pairs(sel) do if v then table.insert(selected, k) end end
        placeConfig.rarities = selected
        print("[PlaceRarities] Selected", #selected, "rarities")
    end,
})
local placeDelaySlider = farmingTab:AddSlider("PlaceDelay", {
    Title = "Place Delay",
    Description = "",
    Min = 0.1,
    Max = 5,
    Rounding = 0.1,
    Default = 0.5,
    Callback = function(v) placeConfig.delay = v print("[PlaceDelay] Set to", v) end,
})
local autoPlaceToggle = farmingTab:AddToggle("AutoPlace", { Title = "Auto Place", Default = false })
autoPlaceToggle:OnChanged(function(v)
    placeConfig.auto = v
    print("[AutoPlace] Toggled", v)
    if v then
        if placeConfig.loop then task.cancel(placeConfig.loop) end
        placeConfig.loop = task.spawn(autoPlaceLoop)
    else
        if placeConfig.loop then task.cancel(placeConfig.loop) placeConfig.loop = nil end
    end
end)

farmingTab:AddParagraph({ Title = "Auto Remove", Content = "" })
local removeSpecificDD = farmingTab:AddDropdown("RemoveSpecificBrainrots", {
    Title = "Specific Brainrots",
    Description = "",
    Values = brainrots_with_all,
    Multi = true,
    Default = {},
    Callback = function(sel)
        local selected = {}
        for k, v in pairs(sel) do if v then table.insert(selected, k) end end
        removeConfig.specifics = selected
        print("[RemoveSpecific] Selected", #selected, "items")
    end,
})
local removeRaritiesDD = farmingTab:AddDropdown("RemoveRarities", {
    Title = "Rarities",
    Description = "",
    Values = rarities_with_all,
    Multi = true,
    Default = {},
    Callback = function(sel)
        local selected = {}
        for k, v in pairs(sel) do if v then table.insert(selected, k) end end
        removeConfig.rarities = selected
        print("[RemoveRarities] Selected", #selected, "rarities")
    end,
})
local removeDelaySlider = farmingTab:AddSlider("RemoveDelay", {
    Title = "Remove Delay",
    Description = "",
    Min = 0.1,
    Max = 5,
    Rounding = 0.1,
    Default = 0.5,
    Callback = function(v) removeConfig.delay = v print("[RemoveDelay] Set to", v) end,
})
local autoRemoveToggle = farmingTab:AddToggle("AutoRemove", { Title = "Auto Remove", Default = false })
autoRemoveToggle:OnChanged(function(v)
    removeConfig.auto = v
    print("[AutoRemove] Toggled", v)
    if v then
        if removeConfig.loop then task.cancel(removeConfig.loop) end
        removeConfig.loop = task.spawn(autoRemoveLoop)
    else
        if removeConfig.loop then task.cancel(removeConfig.loop) removeConfig.loop = nil end
    end
end)

bcTab:AddParagraph({ Title = "Auto Collect All", Content = "" })
local autoCollectAllToggle = bcTab:AddToggle("AutoCollectAllSlots", { Title = "Auto Collect All Slots", Default = false })
autoCollectAllToggle:OnChanged(function(v)
    collectConfig.enabled = v
    print("[AutoCollectAll] Toggled", v)
    if v then
        if collectConfig.loop then task.cancel(collectConfig.loop) end
        collectConfig.loop = task.spawn(autoCollectLoop)
    else
        if collectConfig.loop then task.cancel(collectConfig.loop) collectConfig.loop = nil end
    end
})
local collectIntervalSlider = bcTab:AddSlider("CollectInterval", {
    Title = "Collect Interval",
    Description = "",
    Min = 0.1,
    Max = 10,
    Rounding = 0.1,
    Default = 1,
    Callback = function(v) collectConfig.delay = v print("[CollectInterval] Set to", v) end,
})

bcTab:AddParagraph({ Title = "Collect by Slot", Content = "" })
bcTab:AddButton({
    Title = "Refresh Slots",
    Description = "",
    Callback = refreshSlotMaps,
})
slotCollect.dropdown = bcTab:AddDropdown("SlotCollectSelected", {
    Title = "Select Slots",
    Description = "",
    Values = {"Press Refresh first"},
    Multi = true,
    Default = {},
    Callback = function(sel)
        local nums = {}
        for k, v in pairs(sel) do
            if v and slotCollect.map[k] then table.insert(nums, slotCollect.map[k]) end
        end
        slotCollect.selected = nums
        print("[SlotCollectSelected] Selected", #nums, "slots")
    end,
})
local autoCollectSelectedToggle = bcTab:AddToggle("AutoCollectSelectedSlots", { Title = "Auto Collect Selected Slots", Default = false })
autoCollectSelectedToggle:OnChanged(function(v)
    slotCollect.auto = v
    print("[AutoCollectSelected] Toggled", v)
    if v then
        if slotCollect.loop then task.cancel(slotCollect.loop) end
        slotCollect.loop = task.spawn(autoSlotCollectLoop)
    else
        if slotCollect.loop then task.cancel(slotCollect.loop) slotCollect.loop = nil end
    end
})
local slotCollectIntervalSlider = bcTab:AddSlider("SlotCollectInterval", {
    Title = "Slot Collect Interval",
    Description = "",
    Min = 0.1,
    Max = 10,
    Rounding = 0.1,
    Default = 1,
    Callback = function(v) slotCollect.delay = v print("[SlotCollectInterval] Set to", v) end,
})

bcTab:AddParagraph({ Title = "Collect by Rarity", Content = "" })
local collectRaritiesDD = bcTab:AddDropdown("CollectRarities", {
    Title = "Select Rarities",
    Description = "",
    Values = rarities_with_all,
    Multi = true,
    Default = {},
    Callback = function(sel)
        local selected = {}
        for k, v in pairs(sel) do if v then table.insert(selected, k) end end
        rarityCollect.rarities = selected
        print("[CollectRarities] Selected", #selected, "rarities")
    end,
})
local autoCollectRarityToggle = bcTab:AddToggle("AutoCollectByRarity", { Title = "Auto Collect by Rarity", Default = false })
autoCollectRarityToggle:OnChanged(function(v)
    rarityCollect.auto = v
    print("[AutoCollectByRarity] Toggled", v)
    if v then
        if rarityCollect.loop then task.cancel(rarityCollect.loop) end
        rarityCollect.loop = task.spawn(autoRarityCollectLoop)
    else
        if rarityCollect.loop then task.cancel(rarityCollect.loop) rarityCollect.loop = nil end
    end
})
local rarityCollectIntervalSlider = bcTab:AddSlider("RarityCollectInterval", {
    Title = "Rarity Collect Interval",
    Description = "",
    Min = 0.1,
    Max = 10,
    Rounding = 0.1,
    Default = 1,
    Callback = function(v) rarityCollect.delay = v print("[RarityCollectInterval] Set to", v) end,
})

bcTab:AddParagraph({ Title = "Quick Sell", Content = "" })
bcTab:AddButton({
    Title = "Sell Equipped",
    Description = "",
    Callback = function()
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:UnequipTools() task.wait(0.2)
            FireRemote("rev_S_Interact", 1)
            print("[SellEquipped] Executed")
        end
    end,
})
bcTab:AddButton({
    Title = "Sell All Brainrots",
    Description = "",
    Callback = function()
        InvokeRemote("ref_B_SellAll")
        print("[SellAll] Executed")
    end,
})

bcTab:AddParagraph({ Title = "Sell by Rarity", Content = "" })
local sellRaritiesDD = bcTab:AddDropdown("SellRarities", {
    Title = "Select Rarities",
    Description = "",
    Values = rarities_with_all,
    Multi = true,
    Default = {},
    Callback = function(sel)
        local selected = {}
        for k, v in pairs(sel) do if v then table.insert(selected, k) end end
        sellRarity.rarities = selected
        print("[SellRarities] Selected", #selected, "rarities")
    end,
})
local autoSellRarityToggle = bcTab:AddToggle("AutoSellByRarity", { Title = "Auto Sell by Rarity", Default = false })
autoSellRarityToggle:OnChanged(function(v)
    sellRarity.auto = v
    print("[AutoSellByRarity] Toggled", v)
    if v then
        if sellRarity.loop then task.cancel(sellRarity.loop) end
        sellRarity.loop = task.spawn(sellByRarityLoop)
    else
        if sellRarity.loop then task.cancel(sellRarity.loop) sellRarity.loop = nil end
    end
})
local sellRarityIntervalSlider = bcTab:AddSlider("SellRarityInterval", {
    Title = "Sell Interval",
    Description = "",
    Min = 1,
    Max = 60,
    Rounding = 1,
    Default = 5,
    Callback = function(v) sellRarity.delay = v print("[SellRarityInterval] Set to", v) end,
})

bcTab:AddParagraph({ Title = "Sell Specific", Content = "" })
local sellSpecificBrainrotsDD = bcTab:AddDropdown("SellSpecificBrainrots", {
    Title = "Select Brainrots",
    Description = "",
    Values = brainrots_with_all,
    Multi = true,
    Default = {},
    Callback = function(sel)
        local selected = {}
        for k, v in pairs(sel) do if v then table.insert(selected, k) end end
        sellSpecific.targets = selected
        print("[SellSpecific] Selected", #selected, "brainrots")
    end,
})
local autoSellSpecificToggle = bcTab:AddToggle("AutoSellSpecific", { Title = "Auto Sell Specific", Default = false })
autoSellSpecificToggle:OnChanged(function(v)
    sellSpecific.auto = v
    print("[AutoSellSpecific] Toggled", v)
    if v then
        if sellSpecific.loop then task.cancel(sellSpecific.loop) end
        sellSpecific.loop = task.spawn(sellSpecificLoop)
    else
        if sellSpecific.loop then task.cancel(sellSpecific.loop) sellSpecific.loop = nil end
    end
})
local sellSpecificIntervalSlider = bcTab:AddSlider("SellSpecificInterval", {
    Title = "Sell Interval",
    Description = "",
    Min = 1,
    Max = 60,
    Rounding = 1,
    Default = 5,
    Callback = function(v) sellSpecific.delay = v print("[SellSpecificInterval] Set to", v) end,
})

bcTab:AddParagraph({ Title = "Sell by Mutation", Content = "" })
local sellMutationsDD = bcTab:AddDropdown("SellMutations", {
    Title = "Select Mutations",
    Description = "",
    Values = mutations_with_all,
    Multi = true,
    Default = {},
    Callback = function(sel)
        local selected = {}
        for k, v in pairs(sel) do if v then table.insert(selected, k) end end
        sellMutation.mutations = selected
        print("[SellMutations] Selected", #selected, "mutations")
    end,
})
local autoSellMutationToggle = bcTab:AddToggle("AutoSellByMutation", { Title = "Auto Sell by Mutation", Default = false })
autoSellMutationToggle:OnChanged(function(v)
    sellMutation.auto = v
    print("[AutoSellByMutation] Toggled", v)
    if v then
        if sellMutation.loop then task.cancel(sellMutation.loop) end
        sellMutation.loop = task.spawn(sellByMutationLoop)
    else
        if sellMutation.loop then task.cancel(sellMutation.loop) sellMutation.loop = nil end
    end
})
local sellMutationIntervalSlider = bcTab:AddSlider("SellMutationInterval", {
    Title = "Sell Interval",
    Description = "",
    Min = 1,
    Max = 60,
    Rounding = 1,
    Default = 5,
    Callback = function(v) sellMutation.delay = v print("[SellMutationInterval] Set to", v) end,
})

miscTab:AddParagraph({ Title = "Shop - Speed", Content = "" })
local speedAmountSlider = miscTab:AddSlider("SpeedAmount", {
    Title = "Amount to Buy",
    Description = "",
    Min = 1,
    Max = 50,
    Rounding = 1,
    Default = 1,
    Callback = function(v) shopSpeed.amount = v print("[SpeedAmount] Set to", v) end,
})
local autoBuySpeedToggle = miscTab:AddToggle("AutoBuySpeed", { Title = "Auto Buy Speed", Default = false })
autoBuySpeedToggle:OnChanged(function(v)
    shopSpeed.auto = v
    print("[AutoBuySpeed] Toggled", v)
    if v then
        if shopSpeed.loop then task.cancel(shopSpeed.loop) end
        shopSpeed.loop = task.spawn(function()
            while shopSpeed.auto do
                FireRemote("rev_SPEED_UPGRADE", shopSpeed.amount)
                task.wait(1)
            end
        end)
    else
        if shopSpeed.loop then task.cancel(shopSpeed.loop) shopSpeed.loop = nil end
    end
})

miscTab:AddParagraph({ Title = "Shop - Weights", Content = "" })
local autoBuyWeightsListDD = miscTab:AddDropdown("AutoBuyWeightsList", {
    Title = "Select Weights",
    Description = "",
    Values = weights_with_all,
    Multi = true,
    Default = {},
    Callback = function(sel)
        local selected = {}
        for k, v in pairs(sel) do if v then table.insert(selected, k) end end
        shopWeights.selected = selected
        print("[AutoBuyWeightsList] Selected", #selected, "weights")
    end,
})
local autoBuyWeightsToggle = miscTab:AddToggle("AutoBuyWeights", { Title = "Auto Buy Weights", Default = false })
autoBuyWeightsToggle:OnChanged(function(v)
    shopWeights.auto = v
    print("[AutoBuyWeights] Toggled", v)
    if v then
        if shopWeights.loop then task.cancel(shopWeights.loop) end
        shopWeights.loop = task.spawn(function()
            while shopWeights.auto do
                for _, w in ipairs(expandAll(shopWeights.selected, weightsList)) do
                    FireRemote("rev_Shop_Buy", "WeightShop", w)
                    task.wait(0.1)
                end
                task.wait(1)
            end
        end)
    else
        if shopWeights.loop then task.cancel(shopWeights.loop) shopWeights.loop = nil end
    end
})

miscTab:AddParagraph({ Title = "Shop - Slots & Rebirth", Content = "" })
local autoBuySlotsToggle = miscTab:AddToggle("AutoBuySlots", { Title = "Auto Buy Slots", Default = false })
autoBuySlotsToggle:OnChanged(function(v)
    shopSlots.auto = v
    print("[AutoBuySlots] Toggled", v)
    if v then
        if shopSlots.loop then task.cancel(shopSlots.loop) end
        shopSlots.loop = task.spawn(function()
            while shopSlots.auto do
                FireRemote("rev_bs_upgrade")
                task.wait(1)
            end
        end)
    else
        if shopSlots.loop then task.cancel(shopSlots.loop) shopSlots.loop = nil end
    end
})
local autoRebirthToggle = miscTab:AddToggle("AutoRebirth", { Title = "Auto Rebirth", Default = false })
autoRebirthToggle:OnChanged(function(v)
    shopRebirth.auto = v
    print("[AutoRebirth] Toggled", v)
    if v then
        if shopRebirth.loop then task.cancel(shopRebirth.loop) end
        shopRebirth.loop = task.spawn(function()
            while shopRebirth.auto do
                FireRemote("rev_RebirthRequest")
                task.wait(1)
            end
        end)
    else
        if shopRebirth.loop then task.cancel(shopRebirth.loop) shopRebirth.loop = nil end
    end
})

miscTab:AddParagraph({ Title = "Upgrades", Content = "" })
miscTab:AddButton({
    Title = "Refresh Slots",
    Description = "",
    Callback = refreshSlotMaps,
})
upgradeSlots.dropdown = miscTab:AddDropdown("UpgradeSlotsSelected", {
    Title = "Select Slots",
    Description = "",
    Values = {"Press Refresh first"},
    Multi = true,
    Default = {},
    Callback = function(sel)
        local nums = {}
        for k, v in pairs(sel) do
            if v and upgradeSlots.map[k] then table.insert(nums, upgradeSlots.map[k]) end
        end
        upgradeSlots.selected = nums
        print("[UpgradeSlotsSelected] Selected", #nums, "slots")
    end,
})
local autoUpgradeSelectedToggle = miscTab:AddToggle("AutoUpgradeSelectedSlots", { Title = "Auto Upgrade Selected Slots", Default = false })
autoUpgradeSelectedToggle:OnChanged(function(v)
    upgradeSlots.auto = v
    print("[AutoUpgradeSelected] Toggled", v)
    if v then
        if upgradeSlots.loop then task.cancel(upgradeSlots.loop) end
        upgradeSlots.loop = task.spawn(function()
            while upgradeSlots.auto do
                upgradeSelectedSlots()
                task.wait(0.15)
            end
        end)
    else
        if upgradeSlots.loop then task.cancel(upgradeSlots.loop) upgradeSlots.loop = nil end
    end
})
local upgradeRaritiesDD = miscTab:AddDropdown("UpgradeRarities", {
    Title = "Upgrade by Rarity",
    Description = "",
    Values = rarities_with_all,
    Multi = true,
    Default = {},
    Callback = function(sel)
        local selected = {}
        for k, v in pairs(sel) do if v then table.insert(selected, k) end end
        upgradeRarity.rarities = selected
        print("[UpgradeRarities] Selected", #selected, "rarities")
    end,
})
local autoUpgradeRarityToggle = miscTab:AddToggle("AutoUpgradeByRarity", { Title = "Auto Upgrade by Rarity", Default = false })
autoUpgradeRarityToggle:OnChanged(function(v)
    upgradeRarity.auto = v
    print("[AutoUpgradeByRarity] Toggled", v)
    if v then
        if upgradeRarity.loop then task.cancel(upgradeRarity.loop) end
        upgradeRarity.loop = task.spawn(upgradeRarityLoop)
    else
        if upgradeRarity.loop then task.cancel(upgradeRarity.loop) upgradeRarity.loop = nil end
    end
})

webhookTab:AddParagraph({ Title = "Setup", Content = "" })
local webhookURLInput = webhookTab:AddInput("WebhookURL", {
    Title = "Webhook URL",
    Description = "",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Numeric = false,
    Finished = false,
    Callback = function(text) WH.url = text print("[WebhookURL] Set") end,
})
local pingUserIDInput = webhookTab:AddInput("PingUserID", {
    Title = "Ping User ID",
    Description = "",
    Default = "",
    Placeholder = "e.g. 123456789012345678",
    Numeric = false,
    Finished = false,
    Callback = function(text) WH.pingUID = text or "" print("[PingUserID] Set") end,
})
local minEarnInput = webhookTab:AddInput("MinEarn", {
    Title = "Min Earn",
    Description = "",
    Default = "",
    Placeholder = "1m, 500k, 1b, blank = off",
    Numeric = false,
    Finished = false,
    Callback = function(text)
        if text == nil or text == "" then
            WH.minEarn = nil
            print("[MinEarn] Disabled")
        else
            local val = parseShortNumber(text)
            WH.minEarn = val
            if not val then
                Fluent:Notify({Title = "Webhook", Content = "Invalid number format", Duration = 3})
                print("[MinEarn] Invalid format:", text)
            else
                print("[MinEarn] Set to", val)
            end
        end
    end,
})
local enableWebhookToggle = webhookTab:AddToggle("EnableDiscordWebhook", { Title = "Enable Discord Webhook", Default = false })
enableWebhookToggle:OnChanged(function(v) WH.enabled = v print("[WebhookEnabled] Set to", v) end)
webhookTab:AddButton({
    Title = "Send Test Ping",
    Description = "",
    Callback = sendTestWebhook,
})

webhookTab:AddParagraph({ Title = "Filters", Content = "" })
local sendModeDD = webhookTab:AddDropdown("SendMode", {
    Title = "Send Mode",
    Description = "",
    Values = {"All", "MutatedOnly", "RarityOnly"},
    Default = 1,
    Callback = function(opt) WH.mode = opt print("[SendMode] Set to", opt) end,
})
local rarityFilterDD = webhookTab:AddDropdown("RarityFilter", {
    Title = "Rarity Filter",
    Description = "",
    Values = rarities_with_all,
    Multi = true,
    Default = {},
    Callback = function(sel)
        local selected = {}
        for k, v in pairs(sel) do if v then table.insert(selected, k) end end
        WH.rarities = selected
        print("[RarityFilter] Selected", #selected, "rarities")
    end,
})
local mutationFilterDD = webhookTab:AddDropdown("MutationFilter", {
    Title = "Mutation Filter",
    Description = "",
    Values = mutations_with_all,
    Multi = true,
    Default = {},
    Callback = function(sel)
        local selected = {}
        for k, v in pairs(sel) do if v then table.insert(selected, k) end end
        WH.mutations = selected
        print("[MutationFilter] Selected", #selected, "mutations")
    end,
})
local specificBrainrotFilterDD = webhookTab:AddDropdown("SpecificBrainrotFilter", {
    Title = "Specific Brainrot Filter",
    Description = "",
    Values = brainrots_with_all,
    Multi = true,
    Default = {},
    Callback = function(sel)
        local selected = {}
        for k, v in pairs(sel) do if v then table.insert(selected, k) end end
        WH.specifics = selected
        print("[SpecificFilter] Selected", #selected, "brainrots")
    end,
})

eventTab:AddParagraph({ Title = "🛒 Volcano Shop", Content = "" })
local volcanoShopItemsDD = eventTab:AddDropdown("VolcanoShopItems", {
    Title = "📦 Select Items to Buy",
    Description = "",
    Values = volcanoShopItemsList,
    Multi = true,
    Default = {},
    Callback = function(sel)
        local selected = {}
        for k, v in pairs(sel) do if v then table.insert(selected, k) end end
        volcanoShop.selected = selected
    end,
})
eventTab:AddButton({
    Title = "⚡ Buy Selected Once",
    Description = "",
    Callback = function()
        if #volcanoShop.selected == 0 then
            Fluent:Notify({Title = "🌋 Volcano Shop", Content = "No items selected!", Duration = 3})
            return
        end
        for _, item in ipairs(volcanoShop.selected) do
            FireRemote("rev_VolcanicShop_Buy", item)
            task.wait(0.2)
        end
        Fluent:Notify({Title = "🌋 Volcano Shop", Content = "Bought " .. #volcanoShop.selected .. " item(s)!", Duration = 3})
    end,
})
local volcanoShopDelaySlider = eventTab:AddSlider("VolcanoShopDelay", {
    Title = "⏱️ Buy Interval",
    Description = "",
    Min = 1,
    Max = 60,
    Rounding = 1,
    Default = 5,
    Callback = function(v) volcanoShop.delay = v end,
})
local autoVolcanoShopToggle = eventTab:AddToggle("AutoVolcanoShop", { Title = "🔁 Auto Buy Selected Items", Default = false })
autoVolcanoShopToggle:OnChanged(function(v)
    volcanoShop.auto = v
    if v then
        if volcanoShop.loop then task.cancel(volcanoShop.loop) end
        volcanoShop.loop = task.spawn(function()
            while volcanoShop.auto do
                for _, item in ipairs(volcanoShop.selected) do
                    FireRemote("rev_VolcanicShop_Buy", item)
                    task.wait(0.2)
                end
                task.wait(volcanoShop.delay)
            end
        end)
    else
        if volcanoShop.loop then task.cancel(volcanoShop.loop) volcanoShop.loop = nil end
    end
})

eventTab:AddParagraph({ Title = "⬆️ Volcano Upgrades", Content = "" })
local volcanoUpgradeTypeDD = eventTab:AddDropdown("VolcanoUpgradeType", {
    Title = "🔧 Upgrade Type",
    Description = "",
    Values = volcanoUpgradeTypesList,
    Default = 1,
    Callback = function(sel)
        volcanoUpgrade.upgradeType = sel
        local maxLvl = volcanoUpgradeLevels[volcanoUpgrade.upgradeType] or 1
        if volcanoUpgrade.level > maxLvl then
            volcanoUpgrade.level = maxLvl
            if upgradeLevelSliderRef then
                upgradeLevelSliderRef:SetValue(maxLvl)
            end
        end
    end,
})
local upgradeLevelSliderRef = eventTab:AddSlider("VolcanoUpgradeLevel", {
    Title = "📈 Upgrade Level",
    Description = "",
    Min = 1,
    Max = 4,
    Rounding = 1,
    Default = 1,
    Callback = function(v) volcanoUpgrade.level = v end,
})
local function updateUpgradeLevelMax()
    local maxLvl = volcanoUpgradeLevels[volcanoUpgrade.upgradeType] or 1
    if volcanoUpgrade.level > maxLvl then
        volcanoUpgrade.level = maxLvl
        if upgradeLevelSliderRef then
            upgradeLevelSliderRef:SetValue(maxLvl)
        end
    end
end
updateUpgradeLevelMax()
eventTab:AddButton({
    Title = "💥 Buy Upgrade Once",
    Description = "",
    Callback = function()
        FireRemote("rev_volcanoUpgrade", volcanoUpgrade.upgradeType, volcanoUpgrade.level)
        Fluent:Notify({Title = "⬆️ Upgraded", Content = volcanoUpgrade.upgradeType .. " Lv" .. volcanoUpgrade.level, Duration = 3})
    end,
})
eventTab:AddButton({
    Title = "🚀 Max Selected Upgrade Type",
    Description = "",
    Callback = function()
        local maxLevel = volcanoUpgradeLevels[volcanoUpgrade.upgradeType] or 1
        for i = 1, maxLevel do
            FireRemote("rev_volcanoUpgrade", volcanoUpgrade.upgradeType, i)
            task.wait(0.2)
        end
        Fluent:Notify({Title = "🚀 Maxed!", Content = volcanoUpgrade.upgradeType .. " fully upgraded!", Duration = 3})
    end,
})
eventTab:AddButton({
    Title = "🌟 Max ALL Upgrades",
    Description = "",
    Callback = function()
        for _, upgradeType in ipairs(volcanoUpgradeTypesList) do
            local maxLevel = volcanoUpgradeLevels[upgradeType] or 1
            for i = 1, maxLevel do
                FireRemote("rev_volcanoUpgrade", upgradeType, i)
                task.wait(0.2)
            end
        end
        Fluent:Notify({Title = "🌋 ALL MAXED!", Content = "Every volcano upgrade purchased!", Duration = 4})
    end,
})
local autoVolcanoUpgradeToggle = eventTab:AddToggle("AutoVolcanoUpgrade", { Title = "🔄 Auto Upgrade (Selected Type & Level)", Default = false })
autoVolcanoUpgradeToggle:OnChanged(function(v)
    volcanoUpgrade.auto = v
    if v then
        if volcanoUpgrade.loop then task.cancel(volcanoUpgrade.loop) end
        volcanoUpgrade.loop = task.spawn(function()
            while volcanoUpgrade.auto do
                FireRemote("rev_volcanoUpgrade", volcanoUpgrade.upgradeType, volcanoUpgrade.level)
                task.wait(1)
            end
        end)
    else
        if volcanoUpgrade.loop then task.cancel(volcanoUpgrade.loop) volcanoUpgrade.loop = nil end
    end
})

if SaveManager and InterfaceManager then
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreFlags({"InterfaceManagerTheme"})
    InterfaceManager:BuildInterfaceSection(settingsTab)
    SaveManager:BuildConfigSection(settingsTab)
end

refreshSlotMaps()
Window:SelectTab(1)

if SaveManager then
    SaveManager:LoadAutoloadConfig()
end

Fluent:Notify({Title = "Cactus Hub", Content = "Loaded! Join discord.gg/qMWFBWdcf", Duration = 4})
print("[Cactus Hub] Script fully loaded")
