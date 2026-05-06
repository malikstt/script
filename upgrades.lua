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
currencyAmount = DataService:get("coins") or 0
elseif currencyType == "rollCurrency" then
currencyAmount = DataService:get("rollCurrency") or 0
elseif currencyType == "goop" then
currencyAmount = DataService:get("goop") or 0
end
return currencyAmount >= requiredAmount
end

function UpgradeAutoBuyer:buyNext()
local upgradeList = getUpgradeList()
for _, upgradeId in ipairs(upgradeList) do
if self:canAfford(upgradeId) then
local success = UpgradeService.unlockUpgrade(upgradeId)
if success then
print("PURCHASED: " .. upgradeId)
task.wait(0.1)
return true
end
end
end
return false
end

function UpgradeAutoBuyer:start()
print("=== UPGRADE AUTO BUYER STARTED ===")
print("Coins: " .. tostring(DataService:get("coins") or 0))
print("Roll Currency: " .. tostring(DataService:get("rollCurrency") or 0))
print("Goop: " .. tostring(DataService:get("goop") or 0))
print("===================================")
while task.wait(1) do
self:buyNext()
end
end

-- ACTUALLY START THE SCRIPT
UpgradeAutoBuyer:start()

return UpgradeAutoBuyer
