local UpgradeAutoBuyer = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpgradeRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("UpgradeService"):WaitForChild("RemoteFunction")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function getCurrency()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if not leaderstats then
        return 0, 0, 0
    end
    local coins = leaderstats:FindFirstChild("Coins") and leaderstats.Coins.Value or 0
    local rollCurrency = leaderstats:FindFirstChild("RollCurrency") and leaderstats.RollCurrency.Value or 0
    local goop = leaderstats:FindFirstChild("Goop") and leaderstats.Goop.Value or 0
    return coins, rollCurrency, goop
end

local function getOwnedUpgrades()
    local owned = {}
    local success, result = pcall(function()
        local args = { "getOwned" }
        local data = UpgradeRemote:InvokeServer(unpack(args))
        if type(data) == "table" then
            return data
        end
    end)
    if success and result then
        return result
    end
    return owned
end

local UpgradeTree = nil
local success, result = pcall(function()
    return require(ReplicatedStorage.Source.Features.Upgrades.UpgradeTree)
end)
if success then
    UpgradeTree = result
end

local allUpgrades = {}
if UpgradeTree and UpgradeTree.main then
    for upgradeId, upgradeData in pairs(UpgradeTree.main) do
        if upgradeData and upgradeData.cost then
            table.insert(allUpgrades, upgradeId)
        end
    end
else
    for i = 1, 50 do
        table.insert(allUpgrades, "backpack"..i)
        table.insert(allUpgrades, "auto"..i)
        table.insert(allUpgrades, "enemy"..i)
        table.insert(allUpgrades, "slot"..i)
        table.insert(allUpgrades, "coin"..i)
        table.insert(allUpgrades, "overkill"..i)
        table.insert(allUpgrades, "luck"..i)
        table.insert(allUpgrades, "roll"..i)
        table.insert(allUpgrades, "goop"..i)
        table.insert(allUpgrades, "slime"..i)
        table.insert(allUpgrades, "loot"..i)
        table.insert(allUpgrades, "offline"..i)
        table.insert(allUpgrades, "player"..i)
        table.insert(allUpgrades, "teleport"..i)
        table.insert(allUpgrades, "magnet"..i)
        table.insert(allUpgrades, "speed"..i)
        table.insert(allUpgrades, "friend"..i)
    end
end

local categoryOrder = {
"backpack", "auto", "enemy", "slot", "coin", "overkill", "luck", "roll",
"goop", "slime", "loot", "offline", "player", "teleport", "magnet", "speed", "friend"
}

local function getNumericSuffix(name)
    local num = name:match("(%d+)$")
    return num and tonumber(num) or nil
end

local function buildOrderedUpgradeList()
    local all = {}
    for _, id in ipairs(allUpgrades) do
        all[id] = true
    end
    
    local ordered = {}
    local seen = {}
    
    for _, category in ipairs(categoryOrder) do
        local matched = {}
        for _, id in ipairs(allUpgrades) do
            if not seen[id] and string.find(string.lower(id), category, 1, true) then
                table.insert(matched, id)
            end
        end
        table.sort(matched, function(a, b)
            local numA = getNumericSuffix(a)
            local numB = getNumericSuffix(b)
            if numA and numB then
                return numA < numB
            end
            return a < b
        end)
        for _, id in ipairs(matched) do
            table.insert(ordered, id)
            seen[id] = true
        end
    end
    
    for _, id in ipairs(allUpgrades) do
        if not seen[id] then
            table.insert(ordered, id)
        end
    end
    
    return ordered
end

local orderedUpgrades = buildOrderedUpgradeList()
local totalUpgrades = #orderedUpgrades

function UpgradeAutoBuyer:buyUpgrade(upgradeId)
    local args = { "requestUnlock", upgradeId }
    local success = pcall(function()
        return UpgradeRemote:InvokeServer(unpack(args))
    end)
    if success then
        print("PURCHASED: " .. upgradeId)
        return true
    end
    return false
end

function UpgradeAutoBuyer:start()
    repeat task.wait() until LocalPlayer:FindFirstChild("leaderstats")
    
    local coins, rollCurrency, goop = getCurrency()
    print("Coins: " .. coins)
    print("Roll Currency: " .. rollCurrency)
    print("Goop: " .. goop)
    
    while task.wait(1) do
        local owned = getOwnedUpgrades()
        local ownedCount = 0
        for _, id in ipairs(orderedUpgrades) do
            if owned[id] then
                ownedCount = ownedCount + 1
            end
        end
        print(ownedCount .. "/" .. totalUpgrades)
        
        for _, upgradeId in ipairs(orderedUpgrades) do
            if not owned[upgradeId] then
                self:buyUpgrade(upgradeId)
                task.wait(0.2)
                break
            end
        end
    end
end

UpgradeAutoBuyer:start()

return UpgradeAutoBuyer
