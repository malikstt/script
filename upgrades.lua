local UpgradeAutoBuyer = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(ReplicatedStorage.Packages.DataService).client
local UpgradeService = require(ReplicatedStorage.Source.Features.Upgrades.UpgradeServiceClient)
local UpgradeTree = require(ReplicatedStorage.Source.Features.Upgrades.UpgradeTree)

local categoryOrder = {
"backpack",
"auto",
"enemy",
"slot",
"coin",
"overkill",
"luck",
"roll",
"goop",
"slime",
"loot",
"offline",
"player",
"teleport",
"magnet",
"speed",
"friend"
}

local cachedUpgradeList = nil

local function getNumericSuffix(name)
local num = name:match("(%d+)$")
return num and tonumber(num) or nil
end

local function buildUpgradeList()
local allUpgrades = {}
local mainTree = UpgradeTree.main

for upgradeId, upgradeData in pairs(mainTree) do  
    if upgradeData and upgradeData.cost then  
        table.insert(allUpgrades, upgradeId)  
    end  
end  
  
local orderedList = {}  
local seen = {}  
  
for _, category in ipairs(categoryOrder) do  
    local matched = {}  
    for _, upgradeId in ipairs(allUpgrades) do  
        if not seen[upgradeId] and string.find(string.lower(upgradeId), category, 1, true) then  
            table.insert(matched, upgradeId)  
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
    for _, upgradeId in ipairs(matched) do  
        table.insert(orderedList, upgradeId)  
        seen[upgradeId] = true  
    end  
end  
  
for _, upgradeId in ipairs(allUpgrades) do  
    if not seen[upgradeId] then  
        table.insert(orderedList, upgradeId)  
    end  
end  
  
return orderedList

end

local function getUpgradeList()
if not cachedUpgradeList then
cachedUpgradeList = buildUpgradeList()
end
return cachedUpgradeList
end

function UpgradeAutoBuyer:canAfford(upgradeId)
local upgrades = DataService:get("upgrades") or {}
local mainTree = UpgradeTree.main
local upgradeData = mainTree[upgradeId]
if not upgradeData or not upgradeData.cost then
return false
end
if UpgradeService.ownsUpgrade(upgradeId) then
return false
end
local dependencies = upgradeData.dependency
if dependencies and dependencies ~= "origin" then
if type(dependencies) == "string" then
if not UpgradeService.ownsUpgrade(dependencies) then
return false
end
elseif type(dependencies) == "table" then
for _, dep in pairs(dependencies) do
if not UpgradeService.ownsUpgrade(dep) then
return false
end
end
end
end
local currencyType = upgradeData.cost.currency
local requiredAmount = upgradeData.cost.amount
local currencyAmount = 0
if currencyType == "coins" then
local success, result = pcall(function() return DataService:get("coins") end)
currencyAmount = (success and result) or 0
elseif currencyType == "rollCurrency" then
local success, result = pcall(function() return DataService:get("rollCurrency") end)
currencyAmount = (success and result) or 0
elseif currencyType == "goop" then
local success, result = pcall(function() return DataService:get("goop") end)
currencyAmount = (success and result) or 0
end
return currencyAmount >= requiredAmount
end

function UpgradeAutoBuyer:buyNext()
local upgradeList = getUpgradeList()
for _, upgradeId in ipairs(upgradeList) do
local canAfford, affordError = pcall(function() return self:canAfford(upgradeId) end)
if canAfford and affordError then
local buySuccess, unlockError = pcall(function() return UpgradeService.unlockUpgrade(upgradeId) end)
if buySuccess and unlockError then
print("PURCHASED: " .. upgradeId)
task.wait(0.1)
return true
elseif buySuccess and not unlockError then
print("FAILED TO PURCHASE: " .. upgradeId .. " (unlock returned false)")
else
print("ERROR BUYING: " .. upgradeId .. " - " .. tostring(unlockError))
end
end
end
return false
end

function UpgradeAutoBuyer:start()
print("=== UPGRADE AUTO BUYER STARTED ===")
print("Waiting for data to load...")
task.wait(3)

local function getCurrency(name)
local success, value = pcall(function() return DataService:get(name) end)
if success then
return value or 0
else
print("Warning: Could not get " .. name)
return 0
end
end

local coins = getCurrency("coins")
local rollCurrency = getCurrency("rollCurrency")
local goop = getCurrency("goop")

print("Coins: " .. tostring(coins))
print("Roll Currency: " .. tostring(rollCurrency))
print("Goop: " .. tostring(goop))

local upgradeCount = #getUpgradeList()
print("Total upgrades in buy list: " .. upgradeCount)
print("===================================")

while task.wait(1) do
local bought = self:buyNext()
if bought then
-- Print updated currency after purchase
local newCoins = getCurrency("coins")
local newRoll = getCurrency("rollCurrency")
local newGoop = getCurrency("goop")
print("  Current - Coins: " .. newCoins .. " | Roll: " .. newRoll .. " | Goop: " .. newGoop)
end
end
end

return UpgradeAutoBuyer
