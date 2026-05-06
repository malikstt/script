local UpgradeAutoBuyer = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpgradeRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("UpgradeService"):WaitForChild("RemoteFunction")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function getOwnedUpgrades()
    local owned = {}
    local success, result = pcall(function()
        local args = { "getOwned" }
        return UpgradeRemote:InvokeServer(unpack(args))
    end)
    if success and type(result) == "table" then
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
    local upgradeNames = {
        "backpack", "autoRoll", "rollSpeed", "cloverRolls", "bonusRolls", "extraRollChance",
        "slots", "enemyCount", "enemySpawnSpeed", "slimeTargetRange", "bigSlimes", "hugeSlimes",
        "shinySlimes", "invertedSlimes", "bigEnemies", "shinyEnemies", "hugeEnemies", "invertedEnemies",
        "goop", "goopDropRate", "goldenRolls", "diamondRolls", "voidRolls", "luck",
        "friendLuck", "friendLuckBoost", "coinIncome", "overkill", "offlineLootAmount",
        "lootApple", "lootCarrot", "lootCherries", "lootGrapes", "lootBanana", "lootWatermelon",
        "lootPizza", "lootChicken", "lootDrumstick", "lootLuck", "lootCurrency", "lootRollSpeed", "lootUltraLuck",
        "walkSpeed", "teleporter", "magnet"
    }
    for _, name in ipairs(upgradeNames) do
        for i = 1, 15 do
            table.insert(allUpgrades, name .. i)
        end
    end
end

local categoryOrder = {
    "backpack", "auto", "enemy", "slot", "coin", "overkill", "luck", "roll",
    "goop", "slime", "loot", "offline", "player", "teleport", "magnet", "speed", "friend"
}

local function getNumericSuffix(name)
    local num = name:match("(%d+)$")
    return num and tonumber(num) or nil
}

local function buildOrderedUpgradeList()
    local seen = {}
    local ordered = {}
    
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
    local success, result = pcall(function()
        return UpgradeRemote:InvokeServer(unpack(args))
    end)
    if success and result == true then
        print("PURCHASED: " .. upgradeId)
        return true
    end
    return false
end

function UpgradeAutoBuyer:start()
    repeat task.wait() until LocalPlayer:FindFirstChild("leaderstats")
    
    print("Upgrade Auto Buyer Started")
    
    while task.wait(0.5) do
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
