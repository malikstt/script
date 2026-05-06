local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local UpgradeRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("UpgradeService"):WaitForChild("RemoteFunction")

local DataClient = require(ReplicatedStorage.Packages.DataService).client
local UpgradeTree = require(ReplicatedStorage.Source.Features.Upgrades.UpgradeTree)

local function getAllUpgradeIds()
	local ids = {}
	local function collectFrom(tbl)
		if type(tbl) ~= "table" then return end
		for id, data in pairs(tbl) do
			if type(data) == "table" and data.cost then
				table.insert(ids, id)
			end
		end
	end
	collectFrom(UpgradeTree.main)
	if UpgradeTree.main.lootTree and UpgradeTree.main.lootTree.subTree then
		collectFrom(UpgradeTree.main.lootTree.subTree)
	end
	if UpgradeTree.main.playerTree and UpgradeTree.main.playerTree.subTree then
		collectFrom(UpgradeTree.main.playerTree.subTree)
	end
	return ids
end

local allUpgrades = getAllUpgradeIds()
local totalUpgrades = #allUpgrades

local function getOwned()
	return DataClient:get("upgrades") or {}
end

local function getCurrencies()
	return DataClient:get("coins") or 0, DataClient:get("goop") or 0, DataClient:get("rollCurrency") or 0
end

local function getCost(upgradeId)
	local function findIn(tbl)
		if type(tbl) ~= "table" then return nil end
		for id, data in pairs(tbl) do
			if id == upgradeId and type(data) == "table" then
				return data.cost
			end
		end
	end
	return findIn(UpgradeTree.main)
		or findIn(UpgradeTree.main.lootTree and UpgradeTree.main.lootTree.subTree)
		or findIn(UpgradeTree.main.playerTree and UpgradeTree.main.playerTree.subTree)
end

local function canAfford(upgradeId)
	local cost = getCost(upgradeId)
	if not cost then return false end
	local coins, goop, roll = getCurrencies()
	local currency = cost.currency
	local amount = cost.amount or 0
	if currency == "coins" then return coins >= amount end
	if currency == "goop" then return goop >= amount end
	if currency == "rollCurrency" then return roll >= amount end
	return false
end

local function buyUpgrade(upgradeId)
	local ok, result = pcall(function()
		return UpgradeRemote:InvokeServer("requestUnlock", upgradeId)
	end)
	return ok and result == true
end

repeat task.wait() until LocalPlayer:FindFirstChild("leaderstats")

while task.wait(0.5) do
	local owned = getOwned()
	local ownedCount = 0
	for _, id in ipairs(allUpgrades) do
		if owned[id] then ownedCount += 1 end
	end
	local coins, goop, roll = getCurrencies()
	print(string.format("Upgrades: %d/%d | Coins: %d | Goop: %d | Roll: %d", ownedCount, totalUpgrades, coins, goop, roll))

	for _, upgradeId in ipairs(allUpgrades) do
		if not owned[upgradeId] and canAfford(upgradeId) then
			if buyUpgrade(upgradeId) then
				print("Purchased: " .. upgradeId)
				task.wait(0.2)
			end
		end
	end
end
