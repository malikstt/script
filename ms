local cfg = getgenv().slime_rng_cfg or {}

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local Packages = RS:WaitForChild("Packages")
local Index = Packages:WaitForChild("_Index")
local Networker = Index:WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker")
local Remotes = Networker:WaitForChild("_remotes")

local DataClient = require(Packages.DataService).client
DataClient:waitForData()

local RollRemote = Remotes:WaitForChild("RollService"):WaitForChild("RemoteFunction")
local CodeRemote = Remotes:WaitForChild("CodeService"):WaitForChild("RemoteFunction")
local InventoryRemote = Remotes:WaitForChild("InventoryService"):WaitForChild("RemoteFunction")
local RebirthRemote = Remotes:WaitForChild("RebirthService"):WaitForChild("RemoteFunction")
local ZonesRemote = Remotes:WaitForChild("ZonesService"):WaitForChild("RemoteFunction")
local UpgradeRemote = Remotes:WaitForChild("UpgradeService"):WaitForChild("RemoteFunction")
local BoostRemote = Remotes:WaitForChild("BoostService"):WaitForChild("RemoteFunction")
local OfflineRemote = Remotes:WaitForChild("OfflineEarningsService"):WaitForChild("RemoteFunction")
local IndexRemote = Remotes:WaitForChild("IndexService"):WaitForChild("RemoteFunction")

local Source = RS:WaitForChild("Source", 30)
local Items = Source and Source:WaitForChild("Game"):WaitForChild("Items")
local Roll = Source and Source:WaitForChild("Features"):WaitForChild("Roll")
local MutationsFolder = Source and Source:WaitForChild("Features"):WaitForChild("Mutations")

local RollSlice = Roll and require(Roll:WaitForChild("RollSlice"))
local SlimeData = Items and require(Items:WaitForChild("Slimes"))
local RarityTiers = Items and require(Items:WaitForChild("RarityTiers"))
local Mutations = MutationsFolder and require(MutationsFolder:WaitForChild("Mutations"))
local Zones = require(RS.Source.Game.Items.Zones)
local UpgradeTree = require(RS.Source.Features.Upgrades.UpgradeTree)
local IndexRewards = require(RS.Source.Features.Index.IndexRewards)

-- Config validation
local expectedConfigs = {
    "OFFLINE_EARNINGS", "FAST_ROLL", "REDEEM_CODES", "CODES",
    "EQUIP_BEST_SLIMES", "AUTO_REBIRTH", "REQUIRED_ZONE_TO_REBIRTH",
    "UNLOCK_AFFORDABLE_ZONES", "AUTOFARM_BEST_ZONE", "AUTO_BUY_UPGRADES",
    "USE_POTIONS", "POTIONS_TO_USE", "USE_DICES", "DICES_TO_USE",
    "AUTO_CLAIM_INDEX_REWARDS", "OPTIMIZATION", "WEBHOOK_URL", "MINIMUM_LUCK_SENT"
}

print("[Slime RNG] Script started")
print("[Slime RNG] Loading config...")

local found = 0
for _, key in ipairs(expectedConfigs) do
    if cfg[key] ~= nil then
        found = found + 1
    else
        warn("[Slime RNG] Missing " .. key .. " config, skipping it (runs as false / nil)")
    end
end

print(string.format("[Slime RNG] Found %d/%d configs", found, #expectedConfigs))
print("[Slime RNG] Starting features...")

local function fmt(num)
	if type(num) ~= "number" then return tostring(num) end
	local abs = math.abs(num)
	local function clean(val, suffix)
		local s = string.format("%.2f", val)
		s = s:gsub("%.?0+$", "")
		return s .. suffix
	end
	if abs >= 1e18 then return clean(num / 1e18, "Qn")
	elseif abs >= 1e15 then return clean(num / 1e15, "Qd")
	elseif abs >= 1e12 then return clean(num / 1e12, "T")
	elseif abs >= 1e9 then return clean(num / 1e9, "B")
	elseif abs >= 1e6 then return clean(num / 1e6, "M")
	elseif abs >= 1e3 then return clean(num / 1e3, "K")
	end
	return tostring(math.floor(num))
end

local function parseLuck(str)
	if type(str) ~= "string" then return 0 end
	local num, suffix = str:match("^([%d%.]+)(%a*)$")
	if not num then return 0 end
	num = tonumber(num) or 0
	suffix = suffix:upper()
	if suffix == "QN" then return num * 1e18
	elseif suffix == "QD" then return num * 1e15
	elseif suffix == "T" then return num * 1e12
	elseif suffix == "B" then return num * 1e9
	elseif suffix == "M" then return num * 1e6
	elseif suffix == "K" then return num * 1e3
	end
	return num
end

local function getMutationMultiplier(mutations)
	if not mutations then return 1 end
	local huge = mutations.huge == true
	local shiny = mutations.shiny == true
	local inverted = mutations.inverted == true
	local big = mutations.big == true
	if huge and shiny and inverted then return 625000000
	elseif big and shiny and inverted then return 62500000
	elseif huge and inverted then return 2500000
	elseif shiny and inverted then return 625000
	elseif huge and shiny then return 250000
	elseif big and inverted then return 250000
	elseif shiny and big then return 25000
	elseif inverted then return 2500
	elseif huge then return 1000
	elseif shiny then return 250
	elseif big then return 100
	end
	return 1
end

local function getRarityName(odds)
	if not odds or odds <= 0 then return "Unknown" end
	local ok, tier = pcall(RarityTiers.getTier, odds)
	return (ok and tier and tier.name) or "Unknown"
end

local function getActualItem(result)
	if type(result) ~= "table" then return nil end
	for _, entry in ipairs(result) do
		if type(entry) == "table" and entry.id then return entry end
	end
	return nil
end

local function getResultsFingerprint(results)
	if type(results) ~= "table" then return "nil" end
	local count = #results
	if count == 0 then return "empty" end
	local parts = {}
	for i, result in ipairs(results) do
		local item = getActualItem(result)
		parts[i] = item and tostring(item.id) or tostring(i)
	end
	return count .. "|" .. table.concat(parts, ",")
end

local function ordinal(n)
	local s = tostring(n)
	local last = n % 10
	local tens = n % 100
	if tens >= 11 and tens <= 13 then return s .. "th" end
	if last == 1 then return s .. "st" end
	if last == 2 then return s .. "nd" end
	if last == 3 then return s .. "rd" end
	return s .. "th"
end

local function getAssetImageUrl(assetId)
	if not assetId then return nil end
	local url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetId .. "&size=420x420&format=Png&isCircular=false"
	local ok, response = pcall(function()
		return request({Url = url, Method = "GET"})
	end)
	if ok and response and response.Success then
		local data = HttpService:JSONDecode(response.Body)
		if data and data.data and data.data[1] then
			return data.data[1].imageUrl
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
	if not mutations then return nil end
	if mutations.inverted then return 0x9b59b6
	elseif mutations.huge then return 0xf1c40f
	elseif mutations.big then return 0xe67e22
	elseif mutations.shiny then return 0xf39c12 end
	return nil
end

local function sendWebhook(webhookUrl, playerName, displayName, rarity, chanceText, statsText, mutations, mutList, imageUrl, totalRolls, coins, kills)
	local finalImageUrl = nil
	local thumbnailSize = getThumbnailSize(mutations)
	if imageUrl and imageUrl ~= "N/A" then
		local assetId = string.match(imageUrl, "rbxassetid://(%d+)")
		if assetId then finalImageUrl = getAssetImageUrl(assetId) end
	end
	local hiddenName = "||" .. playerName .. "||"
	local description = string.format("**%s** rolled **%s**!\n\n🎲 **Total Rolls:** %s", hiddenName, displayName, ordinal(totalRolls))
	local fields = {
		{name = "Rarity", value = rarity, inline = true},
		{name = "Chance", value = chanceText, inline = true},
	}
	if statsText and statsText ~= "" then
		table.insert(fields, {name = "Stats", value = statsText, inline = true})
	end
	if mutList and #mutList > 0 then
		table.insert(fields, {name = "Mutations", value = table.concat(mutList, ", "), inline = true})
	end
	table.insert(fields, {name = "🪙 Coins", value = fmt(coins), inline = true})
	table.insert(fields, {name = "⚔️ Kills", value = fmt(kills), inline = true})
	local payload = {
		username = "makik",
		embeds = {{
			title = "New Slime Rolled!",
			description = description,
			thumbnail = finalImageUrl and {url = finalImageUrl, width = thumbnailSize, height = thumbnailSize} or nil,
			fields = fields,
			color = getEmbedColor(mutations),
		}}
	}
	pcall(function()
		request({
			Url = webhookUrl,
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = HttpService:JSONEncode(payload),
		})
	end)
end

if cfg.OPTIMIZATION then
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/Optimization.lua"))()
	end)
end

if cfg.OFFLINE_EARNINGS then
	pcall(OfflineRemote.InvokeServer, OfflineRemote, "requestClaim")
end

if cfg.EQUIP_BEST_SLIMES then
	task.spawn(function()
		local delay = 30
		while true do
			pcall(InventoryRemote.InvokeServer, InventoryRemote, "requestEquipBest")
			task.wait(delay)
			delay = math.min(delay * 2, 600)
		end
	end)
end

if cfg.REDEEM_CODES then
	task.spawn(function()
		local codes = DataClient._data._data._codes or {}
		for _, code in ipairs(cfg.CODES) do
			if not codes[code] then
				pcall(CodeRemote.InvokeServer, CodeRemote, "redeem", code)
				task.wait(0.5)
			end
		end
	end)
end

if cfg.AUTO_REBIRTH then
	task.spawn(function()
		while true do
			local rebirths = DataClient:get("rebirths") or 0
			local goop = DataClient:get("goop") or 0
			local furthestZone = DataClient:get("furthestZone") or 0
			local nextCost = (2 ^ rebirths) * 500
			if furthestZone >= cfg.REQUIRED_ZONE_TO_REBIRTH and goop >= nextCost then
				pcall(RebirthRemote.InvokeServer, RebirthRemote, "requestRebirth")
			end
			task.wait(10)
		end
	end)
end

if cfg.UNLOCK_AFFORDABLE_ZONES or cfg.AUTOFARM_BEST_ZONE then
	task.spawn(function()
		while true do
			local furthestZone = DataClient:get("furthestZone") or 1
			local currentZone = DataClient:get("zone") or 1
			local coins = DataClient:get("coins") or 0

			if cfg.UNLOCK_AFFORDABLE_ZONES then
				local nextZone = Zones.getZone(furthestZone + 1)
				local nextZoneCost = nextZone and nextZone.price or 0
				if coins >= nextZoneCost and nextZone then
					pcall(ZonesRemote.InvokeServer, ZonesRemote, "requestPurchaseZone")
				end
			end

			if cfg.AUTOFARM_BEST_ZONE and currentZone ~= furthestZone then
				pcall(ZonesRemote.InvokeServer, ZonesRemote, "requestTeleportZone", furthestZone)
			end

			task.wait(60)
		end
	end)
end

if cfg.AUTO_BUY_UPGRADES then
	task.spawn(function()
		local function collectUpgrades(tbl, ids)
			if type(tbl) ~= "table" then return end
			for id, data in pairs(tbl) do
				if type(data) == "table" and data.cost then
					table.insert(ids, id)
				end
			end
		end

		local allUpgrades = {}
		collectUpgrades(UpgradeTree.main, allUpgrades)
		if UpgradeTree.main.lootTree and UpgradeTree.main.lootTree.subTree then
			collectUpgrades(UpgradeTree.main.lootTree.subTree, allUpgrades)
		end
		if UpgradeTree.main.playerTree and UpgradeTree.main.playerTree.subTree then
			collectUpgrades(UpgradeTree.main.playerTree.subTree, allUpgrades)
		end

		local function getCost(id)
			local function findIn(tbl)
				if type(tbl) ~= "table" then return nil end
				for k, data in pairs(tbl) do
					if k == id and type(data) == "table" then return data.cost end
				end
			end
			return findIn(UpgradeTree.main)
				or findIn(UpgradeTree.main.lootTree and UpgradeTree.main.lootTree.subTree)
				or findIn(UpgradeTree.main.playerTree and UpgradeTree.main.playerTree.subTree)
		end

		repeat task.wait() until LocalPlayer:FindFirstChild("leaderstats")

		while task.wait(0.5) do
			local owned = DataClient:get("upgrades") or {}
			local coins = DataClient:get("coins") or 0
			local goop = DataClient:get("goop") or 0
			local rollCurrency = DataClient:get("rollCurrency") or 0

			for _, id in ipairs(allUpgrades) do
				if not owned[id] then
					local cost = getCost(id)
					if cost then
						local amount = cost.amount or 0
						local currency = cost.currency
						local canAfford = (currency == "coins" and coins >= amount)
							or (currency == "goop" and goop >= amount)
							or (currency == "rollCurrency" and rollCurrency >= amount)
						if canAfford then
							local ok = pcall(UpgradeRemote.InvokeServer, UpgradeRemote, "requestUnlock", id)
							if ok then task.wait(0.2) end
						end
					end
				end
			end
		end
	end)
end

if cfg.USE_POTIONS or cfg.USE_DICES then
	task.spawn(function()
		while task.wait(1) do
			local boosts = DataClient:get("boosts") or {}
			local items = DataClient:get("items") or {}

			if cfg.USE_POTIONS then
				for _, potion in ipairs(cfg.POTIONS_TO_USE) do
					local data = boosts[potion]
					if data and (data.amount or 0) > 0 then
						pcall(BoostRemote.InvokeServer, BoostRemote, "requestUseBoost", potion)
					end
				end
			end

			if cfg.USE_DICES then
				for _, dice in ipairs(cfg.DICES_TO_USE) do
					if (items[dice] or 0) > 0 then
						pcall(InventoryRemote.InvokeServer, InventoryRemote, "requestUseItem", dice)
					end
				end
			end
		end
	end)
end

if cfg.AUTO_CLAIM_INDEX_REWARDS then
	task.spawn(function()
		local function checkRewards()
			local data = DataService and DataClient:get("index")
			if not data or not data.categories then return end
			for category, rewards in pairs(IndexRewards) do
				local catData = data.categories[category]
				if catData then
					local unlocked = catData.unlocked or {}
					local count = 0
					for _, v in pairs(unlocked) do
						if v == true then count += 1 end
					end
					local claimed = catData.claimedRewards or {}
					for _, reward in ipairs(rewards) do
						if count >= reward.req and not claimed[reward.key] then
							pcall(IndexRemote.InvokeServer, IndexRemote, "requestClaimReward", category)
							task.wait(0.5)
						end
					end
				end
			end
		end
		while true do
			checkRewards()
			task.wait(60)
		end
	end)
end

if cfg.FAST_ROLL then
	task.spawn(function()
		local minLuck = parseLuck(cfg.MINIMUM_LUCK_SENT)
		local webhooks = cfg.WEBHOOK_URL
		local hasWebhooks = type(webhooks) == "table" and #webhooks > 0
		local sentMessages = {}
		local lastFingerprint = nil
		local myPlayer = LocalPlayer

		while true do
			pcall(RollRemote.InvokeServer, RollRemote, "requestRoll")
			task.wait()

			if hasWebhooks and RollSlice then
				local ok, results = pcall(RollSlice.rollResults)
				if ok then
					local fingerprint = getResultsFingerprint(results)
					if fingerprint ~= lastFingerprint then
						lastFingerprint = fingerprint
						if type(results) == "table" and #results > 0 then
							local stats = DataClient:get("stats") or {}
							local totalRolls = stats.rolls or 0
							local kills = stats.kills or 0
							local coins = DataClient:get("coins") or 0

							for _, result in ipairs(results) do
								local item = getActualItem(result)
								if not item then continue end

								local id = tostring(item.id or "unknown")
								local sok, slime = pcall(SlimeData.getSlime, id)
								slime = sok and slime or nil

								local mutations = type(item.mutations) == "table" and next(item.mutations) ~= nil and item.mutations or nil
								local isInverted = mutations and mutations.inverted == true
								local image = isInverted and (slime and slime.invertedIcon or "N/A") or (slime and slime.image or "N/A")

								local name = slime and slime.name or id
								local baseOdds = slime and slime.odds or nil
								local baseDmg = slime and slime.damage or 0
								local baseHp = slime and slime.health or 0
								local rarity = baseOdds and getRarityName(baseOdds) or "Unknown"

								local oddsMultiplier = getMutationMultiplier(mutations)
								local statBonus = mutations and Mutations.getStatBonus(mutations, "damage") or 1
								local finalOdds = baseOdds and (baseOdds / oddsMultiplier) or nil
								local finalDmg = baseDmg * statBonus
								local finalHp = baseHp * statBonus

								local effectiveLuck = finalOdds and (1 / finalOdds) or 0
								if effectiveLuck < minLuck then continue end

								local chanceText = finalOdds and string.format("1 in %s", fmt(math.floor(1 / finalOdds + 0.5))) or "N/A"
								local displayName = mutations and Mutations.getDisplayName(name, mutations) or name
								local mutList = mutations and Mutations.getIds(mutations) or {}

								local statsText = ""
								if finalDmg > 0 and finalHp > 0 then
									statsText = string.format("⚔️ %s  ❤️ %s", fmt(finalDmg), fmt(finalHp))
								elseif finalDmg > 0 then
									statsText = string.format("⚔️ %s", fmt(finalDmg))
								elseif finalHp > 0 then
									statsText = string.format("❤️ %s", fmt(finalHp))
								end

								local playerName = myPlayer and myPlayer.Name or "Someone"
								local dupKey = playerName .. "_" .. displayName .. "_" .. tostring(os.time())

								if not sentMessages[dupKey] then
									sentMessages[dupKey] = true
									for _, url in ipairs(webhooks) do
										task.spawn(function()
											sendWebhook(url, playerName, displayName, rarity, chanceText, statsText, mutations, mutList, image, totalRolls, coins, kills)
										end)
									end
								end
							end
						end
					end
				end
			end
		end
	end)
end
