task.spawn(function()
	local HttpService       = game:GetService("HttpService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players           = game:GetService("Players")

	local WEBHOOK  = "https://discord.com/api/webhooks/1508176094522511370/4INSvRJo1j6kE2zL_neypXOrpkgEhpCwm2NTVLfPV8_czBsVMHFrbG7tno46VnhcMKSR"
	local ASSET_ID = "74725529332053"
	local INTERVAL = 120
	local placeId  = game.PlaceId
	local sentFor  = {}

	local function safeRequest(opt)
		local ok, res = pcall(request, opt)
		return ok and res or nil
	end

	local function formatTime(sec)
		sec = tonumber(sec)
		if not sec or sec <= 0 then return "Ended" end
		return string.format("%02d:%02d", math.floor(sec / 60), sec % 60)
	end

	local cachedThumb = nil
	local function getAssetThumbnail()
		if cachedThumb then return cachedThumb end
		pcall(function()
			local res = safeRequest({
				Url    = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. ASSET_ID .. "&size=420x420&format=Png&isCircular=false",
				Method = "GET"
			})
			if res and res.Body then
				local data = HttpService:JSONDecode(res.Body)
				local url  = data and data.data and data.data[1] and data.data[1].imageUrl
				if url then cachedThumb = url end
			end
		end)
		return cachedThumb
	end

	local function getLuckInfo()
		local ok, LuckLadder = pcall(function()
			return require(ReplicatedStorage.Source.Features.LuckLadder.LuckLadderServiceClient)
		end)
		if not ok or not LuckLadder then return false, nil, nil end
		local active, mult, remaining = false, "N/A", 0
		pcall(function()
			active    = LuckLadder:isActive()
			mult      = LuckLadder:getCurrentMultiplier()
			remaining = LuckLadder:getTimeRemaining()
		end)
		return active, mult, remaining
	end

	local function sendWebhook(mult, remaining, jobId)
		if sentFor[jobId] then return end
		sentFor[jobId] = true
		local playerCount = #Players:GetPlayers()
		local maxPlayers  = Players.MaxPlayers
		local joinLink    = string.format("https://www.roblox.com/games/start?placeId=%d&gameInstanceId=%s", placeId, jobId)
		local executorCmd = string.format(
			'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game:GetService("Players").LocalPlayer)',
			placeId, jobId
		)
		local thumb = getAssetThumbnail()
		local ok, body = pcall(function()
			return HttpService:JSONEncode({
				embeds = {{
					color     = 65280,
					title     = "Luck Server Found 🍀",
					thumbnail = thumb and { url = thumb } or nil,
					fields    = {
						{ name = "Active",            value = "true",                                                 inline = true  },
						{ name = "Multiplier",        value = tostring(mult),                                         inline = true  },
						{ name = "Time Remaining",    value = formatTime(remaining),                                  inline = true  },
						{ name = "Players",           value = tostring(playerCount) .. " / " .. tostring(maxPlayers), inline = true  },
						{ name = "Click to Join",     value = "[Join Server](" .. joinLink .. ")",                    inline = true  },
						{ name = "Paste in Executor", value = "```\n" .. executorCmd .. "\n```",                      inline = false },
					}
				}}
			})
		end)
		if not ok then return end
		safeRequest({ Url = WEBHOOK, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
	end

	while true do
		local active, mult, remaining = getLuckInfo()
		if active then sendWebhook(mult, remaining, game.JobId) end
		task.wait(INTERVAL)
	end
end)

task.spawn(function()
	repeat task.wait() until game:IsLoaded()

	local Logger = {}
	Logger.LogHistory = {}

	function Logger:log(level, system, feature, message, errorObj)
		pcall(function()
			local entry = { timestamp = os.time(), level = level, system = system, feature = feature, message = message, error = errorObj }
			local history = self.LogHistory
			history[#history + 1] = entry
			if #history > 200 then table.remove(history, 1) end
			local prefix  = string.format("[%s] [%s]%s", level, system, feature and " (" .. feature .. ")" or "")
			local fullMsg = prefix .. " " .. tostring(message)
			if errorObj then fullMsg = fullMsg .. "\n  Error: " .. tostring(errorObj) end
			if level == "ERROR" or level == "WARN" then warn(fullMsg) else print(fullMsg) end
		end)
	end
	function Logger:info(s, f, m)     self:log("INFO",  s, f, m)    end
	function Logger:warn(s, f, m)     self:log("WARN",  s, f, m)    end
	function Logger:error(s, f, m, e) self:log("ERROR", s, f, m, e) end

	local Players           = game:GetService("Players")
	local RunService        = game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local HttpService       = game:GetService("HttpService")
	local localPlayer       = Players.LocalPlayer

	pcall(function()
		local virtualUser = game:GetService("VirtualUser")
		localPlayer.Idled:Connect(function()
			virtualUser:CaptureController()
			virtualUser:ClickButton2(Vector2.new())
		end)
	end)

	Logger:info("CactusHub", "Init", "Loading Rayfield...")
	local rayfieldLibrary
	local rayfieldOk, rayfieldErr = pcall(function()
		rayfieldLibrary = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
	end)
	if not rayfieldOk or not rayfieldLibrary then
		Logger:error("CactusHub", "RayfieldLoader", "Failed to load Rayfield", rayfieldErr)
		return
	end
	Logger:info("CactusHub", "Init", "Rayfield loaded successfully")

	local mainWindow = rayfieldLibrary:CreateWindow({
		Name                   = "Cactus Hub • discord.gg/qMWFBWdcf",
		Icon                   = 0,
		LoadingTitle           = "Loading",
		LoadingSubtitle        = "Please wait...",
		Theme                  = "Default",
		ToggleUIKeybind        = "K",
		DisableRayfieldPrompts = false,
		DisableBuildWarnings   = true,
		ConfigurationSaving    = { Enabled = true, FolderName = "CactusHub", FileName = "Config" },
		Discord                = { Enabled = true, Invite = "qMWFBWdcf", RememberJoins = true },
		KeySystem              = false,
	})

	local function featureToggle(tab, config, fn)
		local wc = {}
		for k, v in pairs(config) do wc[k] = v end
		local origCB = config.Callback
		wc.Callback = function(value)
			local ok, err = pcall(origCB or fn, value)
			if not ok then
				Logger:error("Feature", config.Name, "Toggle callback error", err)
				pcall(function() rayfieldLibrary:Notify({ Title = "Error: " .. tostring(config.Name), Content = tostring(err):sub(1, 100), Duration = 5 }) end)
			end
		end
		return tab:CreateToggle(wc)
	end

	local function featureButton(tab, config)
		local wc = {}
		for k, v in pairs(config) do wc[k] = v end
		local origCB = config.Callback
		wc.Callback = function()
			local ok, err = pcall(origCB)
			if not ok then
				Logger:error("Feature", config.Name, "Button callback error", err)
				pcall(function() rayfieldLibrary:Notify({ Title = "Error: " .. tostring(config.Name), Content = tostring(err):sub(1, 100), Duration = 5 }) end)
			end
		end
		return tab:CreateButton(wc)
	end

	local mainTab     = mainWindow:CreateTab("Main",        74725529332053)
	local farmingTab  = mainWindow:CreateTab("Farming",    114367663524453)
	local gameTab     = mainWindow:CreateTab("Game",        77999805030576)
	local ufoTab      = mainWindow:CreateTab("Ufo Event",  129180210444370)
	local indexTab    = mainWindow:CreateTab("Index",      123662711814867)
	local miscTab     = mainWindow:CreateTab("Misc",        83590339425734)
	local webhookTab  = mainWindow:CreateTab("Webhook",     84577758013974)
	local settingsTab = mainWindow:CreateTab("Settings",   120533439477016)
	local statsTab    = mainWindow:CreateTab("Stats",      102533388850982)

	local fpsValue    = "..."
	local pingValue   = "..."
	local statusLabel = mainTab:CreateLabel("FPS: ... / PING: ...ms")

	pcall(function()
		local frameCount = 0
		local elapsed    = 0
		RunService.RenderStepped:Connect(function(dt)
			frameCount = frameCount + 1
			elapsed    = elapsed + dt
			if elapsed >= 1 then
				fpsValue   = math.floor(frameCount / elapsed)
				frameCount = 0
				elapsed    = 0
				pcall(function() statusLabel:Set("FPS: " .. fpsValue .. " / PING: " .. pingValue .. "ms") end)
			end
		end)
	end)

	task.spawn(function()
		local Stats = game:GetService("Stats")
		while true do
			task.wait(2)
			pcall(function()
				pingValue = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
				statusLabel:Set("FPS: " .. fpsValue .. " / PING: " .. pingValue .. "ms")
			end)
		end
	end)

	featureButton(mainTab, {
		Name     = "Copy Discord Invite",
		Callback = function()
			setclipboard("https://discord.gg/qMWFBWdcf")
			rayfieldLibrary:Notify({ Title = "Copied!", Content = "Discord invite link copied to clipboard.", Duration = 3 })
		end,
	})

	mainTab:CreateSection("Dashboard")
	local dashboardBusy = false
	featureToggle(mainTab, {
		Name         = "Dashboard [ SAVE GPU ]",
		CurrentValue = false,
		Flag         = "DashboardToggle",
		Callback     = function(Value)
			if dashboardBusy then return end
			dashboardBusy = true
			if Value then
				task.spawn(function()
					pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/no"))() end)
					pcall(function() rayfieldLibrary:Notify({ Title = "Dashboard", Content = "Dashboard enabled!", Duration = 3 }) end)
					dashboardBusy = false
				end)
			else
				pcall(function()
					local gui = localPlayer.PlayerGui:FindFirstChild("__MAINHUD__")
					if gui then gui:Destroy() end
				end)
				pcall(function() rayfieldLibrary:Notify({ Title = "Dashboard", Content = "Dashboard closed!", Duration = 3 }) end)
				dashboardBusy = false
			end
		end,
	})

	mainTab:CreateParagraph({ Title = "Enabled By Default", Content = "[+] Anti AFK" })
	mainTab:CreateParagraph({
		Title   = "Latest Update",
		Content = "[+] Auto Stay in UFO Zone\n[+] Auto Collect UFO Loot\n[+] Live UFO Phase Display\n[+] Live UFO Zone Display and State\n[+] Live Next Event Countdown Timer\n[+] Live Golden UFO if found\n[+] Manual Refresh Status Button\n[+] Auto Farm Zone ( x4 faster tp )\n[+] Added beammeup / aliensarehere in Auto Redeem Codes\n[+] Added New Zones\n[+] Bug Fixes"
	})

	pcall(function()
		local m = require(ReplicatedStorage.Source.Features.AutoRejoin.AutoRejoinServiceClient)
		pcall(function() m:disable() end)
		if getconnections then
			pcall(function()
				for _, obj in ipairs({ ReplicatedStorage, localPlayer }) do
					for _, conn in ipairs(getconnections(obj.ChildAdded) or {}) do
						pcall(function()
							local src = tostring(conn.Function):lower()
							if src:find("rejoin") or src:find("autorejoin") then conn:Disable() end
						end)
					end
				end
			end)
			pcall(function()
				local GuiService = game:GetService("GuiService")
				for _, conn in ipairs(getconnections(GuiService.ErrorMessageChanged) or {}) do
					pcall(function()
						local src = tostring(conn.Function):lower()
						if src:find("rejoin") or src:find("teleport") then conn:Disable() end
					end)
				end
			end)
		end
		print("AutoRejoin disabled")
	end)

	local packages, dataServiceClient, Networker
	local networkerRoll, inventoryServiceClient, xpTransferServiceClient
	local rollServiceRemote, codeServiceRemote, inventoryServiceRemote
	local rebirthServiceRemote, zonesServiceRemote, upgradeServiceRemote
	local boostServiceRemote, offlineEarningsRemote, indexServiceRemote, lootServiceRemote
	local sourceFolder
	local upgradeTreeModule, indexRewardsModule, boostServiceUtils, specialDiceUtils
	local rollSliceModule, slimesModule, mutationsModule, FruitsModule, SpecialRollUtils
	local boostKinds, diceItemIds
	local idToNameMap, nameToIdMap
	local SettingsState, SettingsServiceClient
	local ZonesModule, RecipesModule
	local upgradeServiceClient_new, dataServiceClient_new
	local modulesLoaded = false

	task.spawn(function()
		Logger:info("CactusHub", "ModuleLoad", "Starting module initialization...")
		local ok, err = pcall(function()
			packages = ReplicatedStorage:WaitForChild("Packages", 15)
			if not packages then error("Packages not found") end
			local indexFolder = packages:WaitForChild("_Index", 15)
			if not indexFolder then error("_Index folder not found") end
			local networkerPkg = indexFolder:WaitForChild("leifstout_networker@0.3.1", 15)
			if not networkerPkg then error("networker package not found") end
			networkerPkg = networkerPkg:WaitForChild("networker", 15)
			if not networkerPkg then error("networker module not found") end
			local remotesFolder = networkerPkg:WaitForChild("_remotes", 15)
			if not remotesFolder then error("_remotes not found") end

			dataServiceClient = require(packages.DataService).client
			dataServiceClient:waitForData()
			Networker = require(packages.Networker)

			local rollClient = { rareRollAnnouncement = function() end, rareRollAnnouncementV2 = function() end }
			networkerRoll           = Networker.client.new("RollService",      rollClient)
			inventoryServiceClient  = Networker.client.new("InventoryService")
			xpTransferServiceClient = Networker.client.new("XpTransferService")

			local function getRemoteFunction(name)
				local folder = remotesFolder:FindFirstChild(name) or remotesFolder:WaitForChild(name, 10)
				if not folder then Logger:warn("CactusHub", "Remotes", "Remote folder not found: " .. name) return nil end
				local rf = folder:FindFirstChild("RemoteFunction") or folder:WaitForChild("RemoteFunction", 10)
				if not rf then Logger:warn("CactusHub", "Remotes", "RemoteFunction not found in: " .. name) end
				return rf
			end

			rollServiceRemote      = getRemoteFunction("RollService")
			codeServiceRemote      = getRemoteFunction("CodeService")
			inventoryServiceRemote = getRemoteFunction("InventoryService")
			rebirthServiceRemote   = getRemoteFunction("RebirthService")
			zonesServiceRemote     = getRemoteFunction("ZonesService")
			upgradeServiceRemote   = getRemoteFunction("UpgradeService")
			boostServiceRemote     = getRemoteFunction("BoostService")
			offlineEarningsRemote  = getRemoteFunction("OfflineEarningsService")
			indexServiceRemote     = getRemoteFunction("IndexService")
			lootServiceRemote      = getRemoteFunction("LootService")

			sourceFolder = ReplicatedStorage:WaitForChild("Source", 30)
			if not sourceFolder then error("Source folder not found") end

			upgradeTreeModule  = require(sourceFolder.Features.Upgrades.UpgradeTree)
			indexRewardsModule = require(sourceFolder.Features.Index.IndexRewards)
			boostServiceUtils  = require(sourceFolder.Features.Boosts.BoostServiceUtils)
			specialDiceUtils   = require(sourceFolder.Features.SpecialDice.SpecialDiceServiceUtils)
			rollSliceModule    = require(sourceFolder.Features.Roll.RollSlice)
			slimesModule       = require(sourceFolder.Game.Items.Slimes)
			mutationsModule    = require(sourceFolder.Features.Mutations.Mutations)
			FruitsModule       = require(sourceFolder.Game.Items.Fruits)
			SpecialRollUtils   = require(sourceFolder.Features.Roll.SpecialRollUtils)
			ZonesModule        = require(sourceFolder.Game.Items.Zones)

			boostKinds  = boostServiceUtils.getKinds()
			diceItemIds = specialDiceUtils.getInventoryItemIds()
			idToNameMap = {}
			nameToIdMap = {}
			for _, itemId in ipairs(diceItemIds) do
				local def      = specialDiceUtils.getDefinition(itemId)
				local itemName = def and def.name or itemId
				idToNameMap[itemId]   = itemName
				nameToIdMap[itemName] = itemId
			end

			SettingsState         = require(sourceFolder.Features.Settings.SettingsState)
			SettingsServiceClient = require(sourceFolder.Features.Settings.SettingsServiceClient)
			SettingsState.init()
			local settingsClient = {}
			settingsClient.networker = Networker.client.new("SettingsService", settingsClient)
			SettingsServiceClient.init(settingsClient)

			pcall(function() RecipesModule = require(sourceFolder.Features.Crafting.Recipes) end)

			task.spawn(function()
				local rs = game:GetService("ReplicatedStorage")
				local ok1, ok2
				repeat
					ok1, upgradeServiceClient_new = pcall(function() return require(rs.Source.Features.Upgrades.UpgradeServiceClient) end)
					ok2, dataServiceClient_new    = pcall(function() return require(rs.Packages.DataService).client end)
					if not ok1 or not ok2 then task.wait(1) end
				until ok1 and ok2
			end)

			modulesLoaded = true
			Logger:info("CactusHub", "ModuleLoad", "All modules loaded successfully!")
			pcall(function() rayfieldLibrary:Notify({ Title = "Cactus Hub", Content = "All modules loaded! Features are ready.", Duration = 4 }) end)
		end)
		if not ok then
			Logger:error("CactusHub", "ModuleLoad", "Module initialization failed", err)
			pcall(function() rayfieldLibrary:Notify({ Title = "CactusHub — Load Warning", Content = "Some modules failed: " .. tostring(err):sub(1, 120) .. "\nSome features may not work.", Duration = 8 }) end)
		end
	end)

	local CATEGORY_IDS  = { "basic", "shiny", "big", "huge", "inverted" }
	local MUTATION_ODDS = { basic = nil, shiny = 0.004, big = 0.01, huge = 0.001, inverted = 0.0004 }
	local DICE          = { "golden", "diamond", "void", "galaxy" }
	local ALL_FRUITS    = {}

	task.spawn(function()
		repeat task.wait(0.5) until modulesLoaded
		pcall(function() if FruitsModule then ALL_FRUITS = FruitsModule.getSortedFruits() end end)
	end)

	local luckValueLocal    = 1
	local settingsClientRef = nil

	task.spawn(function()
		repeat task.wait(0.5) until modulesLoaded
		pcall(function()
			settingsClientRef = {}
			settingsClientRef.networker = Networker.client.new("SettingsService", settingsClientRef)
			SettingsServiceClient.init(settingsClientRef)
		end)
	end)

	local function setLuckEnabled(enabled)
		pcall(function()
			if not SettingsServiceClient or not settingsClientRef then return end
			SettingsServiceClient.set(settingsClientRef, "luckOverrideEnabled", enabled)
			task.wait(0.3)
		end)
	end

	local function setLuck(value)
		pcall(function()
			if not SettingsServiceClient or not settingsClientRef then return end
			local clamped = math.min(value, 16384)
			SettingsServiceClient.set(settingsClientRef, "luckOverrideValue", clamped)
			luckValueLocal = clamped
			task.wait(0.3)
		end)
	end

	local function calcOptimalLuck(effectiveOdds)
		if not effectiveOdds or effectiveOdds <= 0 then return 16384 end
		return math.min(math.max(1, math.floor((1 / effectiveOdds) * 0.63)), 16384)
	end

	local function formatOdds(odds)
		if not odds or odds <= 0 then return "N/A" end
		local n = math.floor(1 / odds + 0.5)
		if     n >= 1e18 then return string.format("1 in %.1fQn", n / 1e18)
		elseif n >= 1e15 then return string.format("1 in %.1fQd", n / 1e15)
		elseif n >= 1e12 then return string.format("1 in %.1fT",  n / 1e12)
		elseif n >= 1e9  then return string.format("1 in %.1fB",  n / 1e9)
		elseif n >= 1e6  then return string.format("1 in %.1fM",  n / 1e6)
		elseif n >= 1e3  then return string.format("1 in %.1fK",  n / 1e3)
		end
		return "1 in " .. n
	end

	local function getEffectiveOdds(slime, catId)
		local mutOdds = MUTATION_ODDS[catId]
		if mutOdds then return slime.rollOdds * mutOdds end
		return slime.rollOdds
	end

	local function getUnlockedIndex(catId)
		if not dataServiceClient then return {} end
		local ok, data = pcall(function() return dataServiceClient:get("index") or {} end)
		if not ok then return {} end
		return ((data.categories or {})[catId] or {}).unlocked or {}
	end

	local function getTotalSlimes()
		if not slimesModule then return 0 end
		local ok, result = pcall(function() return #slimesModule.getSortedSlimes() end)
		return ok and result or 0
	end

	local function getUnlockedCount(catId)
		local unlocked = getUnlockedIndex(catId)
		local count = 0
		for _, v in pairs(unlocked) do if v == true then count = count + 1 end end
		return count
	end

	local function getMissingSlimes(catId)
		if not slimesModule then return {} end
		local ok, result = pcall(function()
			local unlocked = getUnlockedIndex(catId)
			local missing  = {}
			for _, slime in ipairs(slimesModule.getSortedSlimes()) do
				if not unlocked[slime.id] then missing[#missing + 1] = slime end
			end
			table.sort(missing, function(a, b) return getEffectiveOdds(a, catId) > getEffectiveOdds(b, catId) end)
			return missing
		end)
		return ok and result or {}
	end

	local function getBestSlimeUid()
		if not dataServiceClient then return nil end
		local ok, result = pcall(function()
			local stats      = dataServiceClient:get("stats") or {}
			local rarestRoll = stats.rarestRoll
			if not rarestRoll or not rarestRoll.slimeData then return nil end
			local slimeData = rarestRoll.slimeData
			local mutations = slimeData.mutations or {}
			local inventory = dataServiceClient:get("inventory") or {}
			for uid, data in pairs(inventory) do
				if type(data) == "table" and data.id == slimeData.id then
					local match = true
					for mutKey, mutValue in pairs(mutations) do
						if data.mutations and data.mutations[mutKey] ~= mutValue then match = false break end
					end
					if match then return uid end
				end
			end
			return nil
		end)
		return ok and result or nil
	end

	local zoneBoundaryCache = { zoneId = nil, min = nil, max = nil, center = nil }

	local function getZoneBoundary(zoneId)
		if not zoneId then return nil end
		local zoneIdStr = tostring(zoneId)
		if zoneBoundaryCache.zoneId == zoneIdStr and zoneBoundaryCache.min then
			return zoneBoundaryCache
		end
		local ok, result = pcall(function()
			local zonesFolder = workspace:FindFirstChild("Zones")
			if not zonesFolder then return nil end
			local zoneFolder = zonesFolder:FindFirstChild(zoneIdStr)
			if not zoneFolder then return nil end
			local poi = zoneFolder:FindFirstChild("POI")
			if not poi then return nil end
			local baseplate = poi:FindFirstChild("Baseplate")
			if not baseplate or not baseplate:IsA("BasePart") then return nil end
			local pos    = baseplate.Position
			local size   = baseplate.Size
			local shrink = 8
			local halfX  = size.X / 2
			local halfZ  = size.Z / 2
			return {
				zoneId = zoneIdStr,
				min    = Vector3.new(pos.X - halfX + shrink, pos.Y, pos.Z - halfZ + shrink),
				max    = Vector3.new(pos.X + halfX - shrink, pos.Y, pos.Z + halfZ - shrink),
				center = Vector3.new(pos.X, pos.Y, pos.Z),
			}
		end)
		if ok and result then
			zoneBoundaryCache = result
			return zoneBoundaryCache
		end
		return nil
	end

	local function isOutsideBoundary(position, boundary)
		if not boundary or not boundary.min or not boundary.max then return false end
		return position.X < boundary.min.X or position.X > boundary.max.X
			or position.Z < boundary.min.Z or position.Z > boundary.max.Z
	end

	local function isEnemyInsideBoundary(enemy, boundary)
		if not boundary then return true end
		local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildWhichIsA("BasePart")
		if not root then return false end
		return not isOutsideBoundary(root.Position, boundary)
	end

	local RANGE             = 50
	local cachedContainer   = nil
	local cachedEnemies     = {}
	local lastCacheTime     = 0
	local currentTarget     = nil
	local tweenConn         = nil
	local autoFarmWalkSpeed = 100
	local enemySettings     = {
		TeleportStyle    = "Walk",
		TargetPriorities = { ["Most Coins & Goop"] = true },
		AutoFarm         = false,
		MutationFilter   = "Any",
	}

	local noclipEnabled = false
	local noclipConn    = nil

	local function setNoclip(enabled)
		noclipEnabled = enabled
		if noclipConn then noclipConn:Disconnect() noclipConn = nil end
		if enabled then
			noclipConn = RunService.Stepped:Connect(function()
				pcall(function()
					local char = localPlayer.Character
					if not char then return end
					for _, part in ipairs(char:GetDescendants()) do
						if part:IsA("BasePart") then part.CanCollide = false end
					end
				end)
			end)
		else
			pcall(function()
				local char = localPlayer.Character
				if char then
					for _, part in ipairs(char:GetDescendants()) do
						if part:IsA("BasePart") then part.CanCollide = true end
					end
				end
			end)
		end
	end

	local function getGameplayContainer()
		if cachedContainer and cachedContainer.Parent then return cachedContainer end
		for _, child in ipairs(workspace:GetChildren()) do
			if child.Name:match("^Gameplay") then cachedContainer = child return child end
		end
		return nil
	end

	local function getEnemyRoot(enemy)
		return enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildWhichIsA("BasePart")
	end

	local function getMutation(enemy)
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

	local function isAlive(enemy)
		if not enemy or not enemy.Parent then return false end
		local ok, result = pcall(function()
			local h = enemy:FindFirstChildWhichIsA("Humanoid")
			if h and h.Health <= 0 then return false end
			local hp = enemy:GetAttribute("health") or enemy:GetAttribute("currentHealth")
			if hp and hp <= 0 then return false end
			return true
		end)
		return ok and result or false
	end

	local function matchesMutationFilter(enemy)
		if enemySettings.MutationFilter == "Any" then return true end
		return getMutation(enemy) == enemySettings.MutationFilter:lower()
	end

	local function refreshEnemyCache()
		local now = tick()
		if now - lastCacheTime < 2 then return end
		lastCacheTime = now
		cachedEnemies = {}
		pcall(function()
			local container = getGameplayContainer()
			if not container then return end
			local enemyFolder = container:FindFirstChild("Enemies")
			if not enemyFolder then return end
			for _, enemy in ipairs(enemyFolder:GetChildren()) do
				if enemy:IsA("Model") then cachedEnemies[#cachedEnemies + 1] = enemy end
			end
		end)
	end

	local function getEnemyScore(enemy, rootPos)
		local ok, result = pcall(function()
			local root = getEnemyRoot(enemy)
			if not root then return nil end
			local dist = (root.Position - rootPos).Magnitude
			if dist > RANGE then return nil end
			local coins    = enemy:GetAttribute("reward") or enemy:GetAttribute("coins") or 0
			local goop     = enemy:GetAttribute("goop") or 0
			local health   = enemy:GetAttribute("health") or enemy:GetAttribute("currentHealth") or 0
			local humanoid = enemy:FindFirstChildWhichIsA("Humanoid")
			if humanoid then health = humanoid.Health end
			return { enemy = enemy, root = root, coins = coins, goop = goop, health = health, dist = dist }
		end)
		return ok and result or nil
	end

	local function computeScores(rootPos, boundary)
		local entries = {}
		for _, enemy in ipairs(cachedEnemies) do
			if isAlive(enemy) and matchesMutationFilter(enemy) then
				if not boundary or isEnemyInsideBoundary(enemy, boundary) then
					local e = getEnemyScore(enemy, rootPos)
					if e then entries[#entries + 1] = e end
				end
			end
		end
		if #entries == 0 then return {}, {} end
		local maxCoins, maxGoop, maxHealth, maxDist = 0, 0, 0, 0
		for _, e in ipairs(entries) do
			if e.coins  > maxCoins  then maxCoins  = e.coins  end
			if e.goop   > maxGoop   then maxGoop   = e.goop   end
			if e.health > maxHealth then maxHealth = e.health end
			if e.dist   > maxDist   then maxDist   = e.dist   end
		end
		local scores = {}
		local pri    = enemySettings.TargetPriorities
		for _, e in ipairs(entries) do
			local s = 0
			if pri["Most Coins & Goop"] then s = s + ((maxCoins > 0 and e.coins / maxCoins or 0) + (maxGoop > 0 and e.goop / maxGoop or 0)) / 2 end
			if pri["Closest"]           then s = s + (maxDist  > 0 and 1 - e.dist   / maxDist   or 0) end
			if pri["Lowest HP"]         then s = s + (maxHealth > 0 and 1 - e.health / maxHealth or 0) end
			if pri["Mutations Only"]    then s = s + (getMutation(e.enemy) and 1 or 0) end
			scores[e.enemy] = s
		end
		return scores, entries
	end

	local function getSafePosition(targetCFrame, boundary)
		local ok, result = pcall(function()
			local pos = targetCFrame.Position
			if boundary then
				pos = Vector3.new(
					math.clamp(pos.X, boundary.min.X, boundary.max.X),
					pos.Y,
					math.clamp(pos.Z, boundary.min.Z, boundary.max.Z)
				)
			end
			local origin = pos + Vector3.new(0, 50, 0)
			local res    = workspace:Raycast(origin, Vector3.new(0, -100, 0))
			return res and (res.Position + Vector3.new(0, 3, 0)) or (pos + Vector3.new(0, 3, 0))
		end)
		return ok and result or targetCFrame.Position + Vector3.new(0, 3, 0)
	end

	local autoWalkConn = nil

	local function stopAutoWalk()
		pcall(function()
			if autoWalkConn then autoWalkConn:Disconnect() autoWalkConn = nil end
			local char = localPlayer.Character
			if char then
				local hum = char:FindFirstChildWhichIsA("Humanoid")
				if hum then
					hum.WalkSpeed = 40
					hum:MoveTo(char.HumanoidRootPart.Position)
				end
			end
		end)
	end

	local function moveToEnemy(enemy, boundary)
		pcall(function()
			local char = localPlayer.Character
			if not char then return end
			local root = getEnemyRoot(enemy)
			if not root then return end
			local safePos  = getSafePosition(root.CFrame, boundary)
			local targetCF = CFrame.new(safePos)

			if enemySettings.TeleportStyle == "Instant" then
				if tweenConn then tweenConn:Disconnect() tweenConn = nil end
				stopAutoWalk()
				char:PivotTo(targetCF)

			elseif enemySettings.TeleportStyle == "Smooth" then
				if tweenConn then tweenConn:Disconnect() tweenConn = nil end
				stopAutoWalk()
				local startCF   = char:GetPivot()
				local startTime = tick()
				local duration  = 0.25
				tweenConn = RunService.RenderStepped:Connect(function()
					pcall(function()
						if not char or not char.Parent then
							if tweenConn then tweenConn:Disconnect() tweenConn = nil end
							return
						end
						local alpha  = math.clamp((tick() - startTime) / duration, 0, 1)
						local newPos = startCF.Position:Lerp(safePos, alpha)
						if boundary then
							newPos = Vector3.new(
								math.clamp(newPos.X, boundary.min.X, boundary.max.X),
								newPos.Y,
								math.clamp(newPos.Z, boundary.min.Z, boundary.max.Z)
							)
						end
						local rayResult = workspace:Raycast(newPos + Vector3.new(0, 10, 0), Vector3.new(0, -20, 0))
						if rayResult then newPos = rayResult.Position + Vector3.new(0, 3, 0) end
						char:PivotTo(CFrame.new(newPos))
						if alpha >= 1 then tweenConn:Disconnect() tweenConn = nil end
					end)
				end)

			elseif enemySettings.TeleportStyle == "Walk" then
				if tweenConn then tweenConn:Disconnect() tweenConn = nil end
				stopAutoWalk()
				local hum = char:FindFirstChildWhichIsA("Humanoid")
				if not hum then return end
				hum.WalkSpeed = autoFarmWalkSpeed
				hum:MoveTo(safePos)
				autoWalkConn = RunService.Heartbeat:Connect(function()
					pcall(function()
						if not char or not char.Parent or not isAlive(enemy) then stopAutoWalk() return end
						local rp = char:FindFirstChild("HumanoidRootPart")
						if not rp then stopAutoWalk() return end
						if boundary and isOutsideBoundary(rp.Position, boundary) then
							stopAutoWalk()
							char:PivotTo(CFrame.new(getSafePosition(CFrame.new(boundary.center), boundary)))
							return
						end
						if (rp.Position - safePos).Magnitude < 5 then
							stopAutoWalk()
						else
							local newRoot = getEnemyRoot(enemy)
							if newRoot then
								safePos = getSafePosition(newRoot.CFrame, boundary)
								hum:MoveTo(safePos)
							end
						end
					end)
				end)
			end
		end)
	end

	local function selectTarget(boundary)
		local ok, result = pcall(function()
			local char = localPlayer.Character
			if not char then return nil end
			local rp = char:FindFirstChild("HumanoidRootPart")
			if not rp then return nil end
			local scores          = computeScores(rp.Position, boundary)
			local best, bestScore = nil, -math.huge
			for enemy, score in pairs(scores) do
				if score > bestScore then bestScore = score best = enemy end
			end
			return best
		end)
		return ok and result or nil
	end

	local function selectCombatTarget()
		local bestEnemy, bestId = nil, nil
		pcall(function()
			local char = localPlayer.Character
			if not char then return end
			local root = char:FindFirstChild("HumanoidRootPart")
			if not root then return end
			local gp = getGameplayContainer()
			if not gp then return end
			local folder = gp:FindFirstChild("Enemies")
			if not folder then return end
			local priority = rayfieldLibrary.Flags.CombatTargetPriority
				and rayfieldLibrary.Flags.CombatTargetPriority.CurrentOption[1] or "Closest"
			local bScore = nil
			for _, e in ipairs(folder:GetChildren()) do
				if e:IsA("Model") and isAlive(e) then
					local primary = getEnemyRoot(e)
					if primary then
						local dist = (primary.Position - root.Position).Magnitude
						local id   = tonumber(e.Name)
						local score
						if     priority == "Closest"           then score = -dist
						elseif priority == "Lowest HP"         then
							local hp = e:GetAttribute("health") or e:GetAttribute("currentHealth") or 0
							local hum = e:FindFirstChildWhichIsA("Humanoid")
							if hum then hp = hum.Health end
							score = -hp
						elseif priority == "Highest HP"        then
							local hp = e:GetAttribute("health") or e:GetAttribute("currentHealth") or 0
							local hum = e:FindFirstChildWhichIsA("Humanoid")
							if hum then hp = hum.Health end
							score = hp
						elseif priority == "Most Coins & Goop" then
							score = (e:GetAttribute("reward") or e:GetAttribute("coins") or 0)
							      + (e:GetAttribute("goop") or 0)
						else score = -dist end
						if bScore == nil or score > bScore then
							bScore = score bestEnemy = e bestId = id
						end
					end
				end
			end
		end)
		return bestEnemy, bestId
	end

	local lastBoundaryRefresh = 0
	local farmAccum           = 0
	local FARM_INTERVAL       = 0.1

	RunService.Heartbeat:Connect(function(dt)
		farmAccum = farmAccum + dt
		if farmAccum < FARM_INTERVAL then return end
		farmAccum = 0
		pcall(function()
			refreshEnemyCache()
			if not enemySettings.AutoFarm then
				if currentTarget then currentTarget = nil stopAutoWalk() end
				return
			end
			local char = localPlayer.Character
			if not char then return end
			local charRoot = char:FindFirstChild("HumanoidRootPart")
			if not charRoot then return end

			local currentZoneId = nil
			if dataServiceClient then
				pcall(function() currentZoneId = dataServiceClient:get("zone") end)
			end

			local boundary = nil
			if currentZoneId then
				local now = tick()
				if now - lastBoundaryRefresh > 5 then
					lastBoundaryRefresh = now
					zoneBoundaryCache   = { zoneId = nil, min = nil, max = nil, center = nil }
				end
				boundary = getZoneBoundary(currentZoneId)
			end

			if boundary and isOutsideBoundary(charRoot.Position, boundary) then
				stopAutoWalk()
				currentTarget = nil
				char:PivotTo(CFrame.new(getSafePosition(CFrame.new(boundary.center), boundary)))
				return
			end

			if currentTarget and isAlive(currentTarget) and currentTarget.Parent then
				if boundary and not isEnemyInsideBoundary(currentTarget, boundary) then
					stopAutoWalk()
					currentTarget = nil
				else
					return
				end
			else
				stopAutoWalk()
			end

			local newTarget = selectTarget(boundary)
			if newTarget and newTarget ~= currentTarget then
				currentTarget = newTarget
				moveToEnemy(currentTarget, boundary)
			end
		end)
	end)

	farmingTab:CreateSection("Rolling")

	featureToggle(farmingTab, {
		Name         = "Auto Fast Roll ( No Animation )",
		CurrentValue = false,
		Flag         = "FarmingFastRoll",
		Callback     = function(enabled)
			if not enabled then return end
			task.spawn(function()
				while true do
					local flag = rayfieldLibrary.Flags.FarmingFastRoll
					if not flag or not flag.CurrentValue then break end
					if not rollServiceRemote then
						pcall(function() rayfieldLibrary:Notify({ Title = "Error", Content = "RollService remote not loaded", Duration = 4 }) end)
						break
					end
					pcall(function() rollServiceRemote:InvokeServer("requestRoll") end)
					task.wait(rollSliceModule and rollSliceModule.rollTime() or 0.5)
				end
			end)
		end,
	})

	local selectedDice  = { golden = true, diamond = true, void = true, galaxy = true }
	local stackActive   = false
	local releaseActive = false
	local paused        = { golden = false, diamond = false, void = false, galaxy = false }

	featureToggle(farmingTab, {
		Name         = "Auto Stack Dice",
		CurrentValue = false,
		Flag         = "autostack",
		Callback     = function(v)
			stackActive = v
			if not v and networkerRoll then
				for _, dice in ipairs(DICE) do
					if paused[dice] then
						pcall(function() networkerRoll:fetch("requestSetSpecialRollPaused", dice, false) end)
						paused[dice] = false
					end
				end
			end
		end,
	})

	featureToggle(farmingTab, {
		Name         = "Auto Release Dice",
		CurrentValue = false,
		Flag         = "autorelease",
		Callback     = function(v) releaseActive = v end,
	})

	farmingTab:CreateDropdown({
		Name            = "Select Dice",
		Options         = { "All", "Diamond", "Galaxy", "Golden", "Void" },
		CurrentOption   = { "All" },
		MultipleOptions = true,
		Flag            = "diceDropdown",
		Callback        = function(choices)
			for _, dice in ipairs(DICE) do selectedDice[dice] = false end
			for _, choice in ipairs(choices) do
				if choice == "All" then
					for _, dice in ipairs(DICE) do selectedDice[dice] = true end
					break
				else
					selectedDice[choice:lower()] = true
				end
			end
		end,
	})

	local DiceLuckLabel = farmingTab:CreateLabel("Total Stacked: x0")

	task.spawn(function()
		while true do
			task.wait(0.5)
			pcall(function()
				if not dataServiceClient or not SpecialRollUtils then return end
				local upgrades     = dataServiceClient:get("upgrades") or {}
				local progression  = dataServiceClient:get("specialRollProgression") or {}
				local totalStacked = 0
				for _, dice in ipairs(DICE) do
					local prog  = progression[dice]
					local rolls = prog and prog.rollsUntilNext or math.huge
					if rolls <= 1 then
						local ok, mult = pcall(SpecialRollUtils.getLuckMultiplier, dice, upgrades)
						if ok then totalStacked = totalStacked + (mult or 0) end
					end
				end
				DiceLuckLabel:Set("Total Stacked: x" .. string.format("%.1f", totalStacked))
				if not stackActive or not networkerRoll then return end
				local toWatch = {}
				for _, dice in ipairs(DICE) do
					if selectedDice[dice] then
						local ok, unlocked = pcall(SpecialRollUtils.isUnlocked, dice, upgrades)
						if ok and unlocked then toWatch[#toWatch + 1] = dice end
					end
				end
				if #toWatch == 0 then return end
				local allReady = true
				for _, dice in ipairs(toWatch) do
					local prog  = progression[dice]
					local rolls = prog and prog.rollsUntilNext or math.huge
					if rolls > 1 then
						allReady = false
						if paused[dice] then pcall(function() networkerRoll:fetch("requestSetSpecialRollPaused", dice, false) end) paused[dice] = false end
					else
						if not paused[dice] then pcall(function() networkerRoll:fetch("requestSetSpecialRollPaused", dice, true) end) paused[dice] = true end
					end
				end
				if allReady and releaseActive then
					for _, dice in ipairs(toWatch) do
						pcall(function() networkerRoll:fetch("requestSetSpecialRollPaused", dice, false) end)
						paused[dice] = false
					end
					pcall(function() rayfieldLibrary:Notify({ Title = "Unleashed!", Content = "All selected dice stacked — releasing now.", Duration = 3 }) end)
					task.wait(2)
				end
			end)
		end
	end)

	farmingTab:CreateSection("Zones")

	pcall(function()
		local zoneOptions = { "Best Unlocked" }
		local totalZones  = ZonesModule and ZonesModule.getMaxZone() or 40
		for i = 1, totalZones do
			local zone = ZonesModule and ZonesModule.getZone(i)
			if zone and zone.name then
				zoneOptions[#zoneOptions + 1] = zone.name .. " (Zone " .. i .. ")"
			else
				zoneOptions[#zoneOptions + 1] = "Zone " .. i
			end
		end
		farmingTab:CreateDropdown({ Name = "Zone Target", Options = zoneOptions, CurrentOption = { "Best Unlocked" }, MultipleOptions = false, Flag = "FarmingZoneTarget", Callback = function() end })
	end)

	featureToggle(farmingTab, {
		Name         = "Auto Farm Zone",
		CurrentValue = false,
		Flag         = "FarmingStayInBestZone",
		Callback     = function(enabled)
			if not enabled then return end
			task.spawn(function()
				local lastTeleportTime = 0
				while true do
					local flag = rayfieldLibrary.Flags.FarmingStayInBestZone
					if not flag or not flag.CurrentValue then break end
					if not zonesServiceRemote then
						pcall(function() rayfieldLibrary:Notify({ Title = "Error", Content = "ZonesService remote not loaded", Duration = 4 }) end)
						break
					end
					pcall(function()
						local targetOption = rayfieldLibrary.Flags.FarmingZoneTarget
							and rayfieldLibrary.Flags.FarmingZoneTarget.CurrentOption[1] or "Best Unlocked"
						local currentZone = dataServiceClient and (dataServiceClient:get("zone") or 1) or 1
						local targetZone  = nil
						if targetOption == "Best Unlocked" then
							targetZone = dataServiceClient and (dataServiceClient:get("maxZone") or 1) or 1
						else
							targetZone = tonumber(targetOption:match("Zone (%d+)"))
						end
						if targetZone and targetZone > 0 and currentZone ~= targetZone then
							local now = tick()
							if now - lastTeleportTime > 3 then
								lastTeleportTime = now
								zonesServiceRemote:InvokeServer("requestTeleportZone", targetZone)
								zoneBoundaryCache = { zoneId = nil, min = nil, max = nil, center = nil }
							end
						end
					end)
					task.wait(5)
				end
			end)
		end,
	})

	featureToggle(farmingTab, {
		Name         = "Auto Unlock Affordable Zones",
		CurrentValue = false,
		Flag         = "FarmingUnlockAffordableZones",
		Callback     = function(enabled)
			if not enabled then return end
			task.spawn(function()
				while true do
					local flag = rayfieldLibrary.Flags.FarmingUnlockAffordableZones
					if not flag or not flag.CurrentValue then break end
					if not zonesServiceRemote then break end
					pcall(function() zonesServiceRemote:InvokeServer("requestPurchaseZone") end)
					task.wait(5)
				end
			end)
		end,
	})

	farmingTab:CreateSection("Slimes & XP")

	featureToggle(farmingTab, {
		Name         = "Auto Equip Best Slimes",
		CurrentValue = false,
		Flag         = "FarmingEquipBestSlimes",
		Callback     = function(enabled)
			if not enabled then return end
			task.spawn(function()
				local waitTime = 30
				while true do
					local flag = rayfieldLibrary.Flags.FarmingEquipBestSlimes
					if not flag or not flag.CurrentValue then break end
					if not inventoryServiceRemote then break end
					pcall(function() inventoryServiceRemote:InvokeServer("requestEquipBest") end)
					task.wait(waitTime)
					waitTime = math.min(waitTime * 2, 600)
				end
			end)
		end,
	})

	local autoFeedEnabled   = false
	local selectedFruitIds  = { "ANY" }
	local selectedSlimeMode = "Best"
	local feedConnection    = nil
	local feedAccum         = 0
	local FEED_INTERVAL     = 3

	local function getOwnedFruitIds()
		if not dataServiceClient or not FruitsModule then return {} end
		local ok, result = pcall(function()
			local items = dataServiceClient:get("items") or {}
			local owned = {}
			for _, f in ipairs(ALL_FRUITS) do
				if (items[f.id] or 0) > 0 then owned[f.id] = true end
			end
			return owned
		end)
		return ok and result or {}
	end

	local function slimeHasFruit(slimeData, fruitId)
		if type(slimeData) ~= "table" or not FruitsModule then return false end
		local ok, result = pcall(function()
			local fruitDef = FruitsModule.getFruit(fruitId)
			if not fruitDef then return false end
			local trees = slimeData.unlockedTrees
			return type(trees) == "table" and trees[fruitDef.treeId] == true
		end)
		return ok and result or false
	end

	local function getBestSlimeEntry()
		if not dataServiceClient then return nil, nil end
		local slimeKey, slimeData = nil, nil
		pcall(function()
			local stats  = dataServiceClient:get("stats") or {}
			local rarest = stats.rarestRoll
			if not rarest or not rarest.slimeData then return end
			local rarestId        = rarest.slimeData.id
			local rarestMutations = rarest.slimeData.mutations or {}
			local equipped = dataServiceClient:get("equipped") or {}
			local inv      = dataServiceClient:get("inventory") or {}
			for _, k in pairs(equipped) do
				if type(k) == "string" and k:sub(1, 1) == "." then
					local d = inv[k]
					if type(d) == "table" and d.id == rarestId then
						local match = true
						for mutKey, mutVal in pairs(rarestMutations) do
							if not d.mutations or d.mutations[mutKey] ~= mutVal then match = false break end
						end
						if match then slimeKey = k slimeData = d return end
					end
				end
			end
			if not slimeKey then
				for _, k in pairs(equipped) do
					if type(k) == "string" and k:sub(1, 1) == "." then
						local d = inv[k]
						if type(d) == "table" then slimeKey = k slimeData = d return end
					end
				end
			end
		end)
		return slimeKey, slimeData
	end

	local function getTargetSlimes()
		if not dataServiceClient then return {} end
		local ok, result = pcall(function()
			if selectedSlimeMode == "Best" then
				local k, d = getBestSlimeEntry()
				if k and d then return { { key = k, data = d } } end
				return {}
			else
				local equipped = dataServiceClient:get("equipped") or {}
				local res = {}
				for _, slimeKey in ipairs(equipped) do
					if type(slimeKey) == "string" and slimeKey:sub(1, 1) == "." then
						local inv = dataServiceClient:get("inventory") or {}
						local d   = inv[slimeKey]
						if type(d) == "table" then res[#res + 1] = { key = slimeKey, data = d } end
					end
				end
				return res
			end
		end)
		return ok and result or {}
	end

	local function resolveFruitList()
		local owned = getOwnedFruitIds()
		if selectedFruitIds[1] == "ANY" then
			local result = {}
			for _, f in ipairs(ALL_FRUITS) do
				if owned[f.id] then result[#result + 1] = f.id end
			end
			return result
		else
			local result = {}
			for _, fid in ipairs(selectedFruitIds) do
				if owned[fid] then result[#result + 1] = fid end
			end
			return result
		end
	end

	local function doFeed()
		pcall(function()
			if not inventoryServiceClient then return end
			local targets      = getTargetSlimes()
			local fruitsToFeed = resolveFruitList()
			if #targets == 0 or #fruitsToFeed == 0 then return end
			for _, entry in ipairs(targets) do
				for _, fruitId in ipairs(fruitsToFeed) do
					if not slimeHasFruit(entry.data, fruitId) then
						pcall(function() inventoryServiceClient:fetch("requestUseFruit", fruitId, entry.key) end)
					end
				end
			end
		end)
	end

	featureToggle(farmingTab, {
		Name         = "Auto Feed Fruits to Slime(s)",
		CurrentValue = false,
		Flag         = "AutoFeedToggle",
		Callback     = function(value)
			autoFeedEnabled = value
			if feedConnection then feedConnection:Disconnect() feedConnection = nil end
			if value then
				feedAccum      = 0
				feedConnection = RunService.Heartbeat:Connect(function(dt)
					if not autoFeedEnabled then
						feedConnection:Disconnect() feedConnection = nil
						return
					end
					feedAccum = feedAccum + dt
					if feedAccum >= FEED_INTERVAL then
						feedAccum = 0
						doFeed()
					end
				end)
			end
		end,
	})

	farmingTab:CreateDropdown({
		Name            = "Slimes to Feed",
		Options         = { "Best", "Split Across Team" },
		CurrentOption   = { "Best" },
		MultipleOptions = false,
		Flag            = "SlimeModeDropdown",
		Callback        = function(option) selectedSlimeMode = type(option) == "table" and option[1] or option end,
	})

	pcall(function()
		local fruitOptions = { "Any" }
		local labelToId    = {}
		local fruitNames   = {}
		for _, f in ipairs(FruitsModule and FruitsModule.getSortedFruits() or {}) do
			fruitNames[#fruitNames + 1] = f.powerName
			labelToId[f.powerName]      = f.id
		end
		table.sort(fruitNames)
		for _, name in ipairs(fruitNames) do fruitOptions[#fruitOptions + 1] = name end
		farmingTab:CreateDropdown({
			Name            = "Fruits to Feed",
			Options         = fruitOptions,
			CurrentOption   = { "Any" },
			MultipleOptions = true,
			Flag            = "FruitDropdown",
			Callback        = function(options)
				local picked = type(options) == "table" and options or { options }
				selectedFruitIds = {}
				for _, label in ipairs(picked) do
					if label == "Any" then
						selectedFruitIds = { "ANY" }
						return
					else
						selectedFruitIds[#selectedFruitIds + 1] = labelToId[label]
					end
				end
				if #selectedFruitIds == 0 then selectedFruitIds = { "ANY" } end
			end,
		})
	end)

	featureToggle(farmingTab, { Name = "Auto Transfer XP", CurrentValue = false, Flag = "FarmingTransferXP", Callback = function() end })
	farmingTab:CreateDropdown({ Name = "Transfer To",   Options = { "Best Slime", "Whole Team" },         CurrentOption = { "Best Slime" },         MultipleOptions = false, Flag = "FarmingTransferTarget", Callback = function() end })
	farmingTab:CreateDropdown({ Name = "Transfer From", Options = { "All Slimes", "Unequipped With XP" }, CurrentOption = { "Unequipped With XP" }, MultipleOptions = false, Flag = "FarmingTransferSource", Callback = function() end })

	task.spawn(function()
		while true do
			task.wait(30)
			pcall(function()
				if not (rayfieldLibrary.Flags.FarmingTransferXP and rayfieldLibrary.Flags.FarmingTransferXP.CurrentValue) then return end
				if not dataServiceClient or not xpTransferServiceClient then return end
				local inventory = dataServiceClient:get("inventory") or {}
				local equipped  = dataServiceClient:get("equipped") or {}
				local teamSet   = {}
				for _, uid in ipairs(equipped) do teamSet[uid] = true end
				local targetOption = rayfieldLibrary.Flags.FarmingTransferTarget
					and rayfieldLibrary.Flags.FarmingTransferTarget.CurrentOption
					and rayfieldLibrary.Flags.FarmingTransferTarget.CurrentOption[1] or "Best Slime"
				local sourceOption = rayfieldLibrary.Flags.FarmingTransferSource
					and rayfieldLibrary.Flags.FarmingTransferSource.CurrentOption
					and rayfieldLibrary.Flags.FarmingTransferSource.CurrentOption[1] or "Unequipped With XP"
				local targets = {}
				if targetOption == "Best Slime" then
					local best = getBestSlimeUid()
					if best then targets = { best } end
				else
					for _, uid in ipairs(equipped) do targets[#targets + 1] = uid end
				end
				for _, target in ipairs(targets) do
					for uid, data in pairs(inventory) do
						if uid ~= target then
							local isEquipped = teamSet[uid]
							local hasXp      = (type(data) == "table" and (data.xp or 0) > 0)
								or (type(data) == "number" and data > 0)
							if (sourceOption == "Unequipped With XP" and not isEquipped and hasXp)
								or (sourceOption == "All Slimes" and hasXp) then
								pcall(function() xpTransferServiceClient:fetch("requestTransferXp", uid, target) end)
								task.wait(0.5)
							end
						end
					end
				end
			end)
		end
	end)

	farmingTab:CreateSection("Loot")

	featureToggle(farmingTab, {
		Name         = "Auto Collect Loot",
		CurrentValue = false,
		Flag         = "FarmingCollectLoot",
		Callback     = function(enabled)
			if not enabled then return end
			task.spawn(function()
				while true do
					local flag = rayfieldLibrary.Flags.FarmingCollectLoot
					if not flag or not flag.CurrentValue then break end
					pcall(function()
						for _, folder in ipairs({ "Loot", "Debris" }) do
							local container = workspace:FindFirstChild(folder)
							if container then
								for _, item in ipairs(container:GetChildren()) do
									local id = item:GetAttribute("uniqueId") or item:GetAttribute("id") or item.Name
									if id and lootServiceRemote then
										pcall(function() lootServiceRemote:InvokeServer("requestCollect", id) end)
									end
								end
							end
						end
					end)
					task.wait(0.5)
				end
			end)
		end,
	})

	gameTab:CreateSection("Auto Farm")

	featureToggle(gameTab, {
		Name         = "Auto Farm",
		CurrentValue = false,
		Flag         = "AutoFarm",
		Callback     = function(value)
			enemySettings.AutoFarm = value
			setNoclip(value)
			if not value then currentTarget = nil stopAutoWalk() end
		end,
	})

	gameTab:CreateSlider({ Name = "Auto Farm Walk Speed", Range = { 50, 160 }, Increment = 1, Suffix = "", CurrentValue = 100, Flag = "AutoFarmWalkSpeed", Callback = function(val) autoFarmWalkSpeed = val end })

	gameTab:CreateDropdown({
		Name            = "Movement Style",
		Options         = { "Walk [RECOMMENDED]", "Instant", "Smooth" },
		CurrentOption   = { "Walk [RECOMMENDED]" },
		MultipleOptions = false,
		Flag            = "TeleportStyle",
		Callback        = function(option)
			local val = type(option) == "table" and option[1] or option
			if val == "Walk [RECOMMENDED]" then val = "Walk" end
			enemySettings.TeleportStyle = val
			if val ~= "Walk" then stopAutoWalk() end
		end,
	})

	gameTab:CreateDropdown({
		Name            = "Target Priority",
		Options         = { "Closest", "Lowest HP", "Most Coins & Goop", "Mutations Only" },
		CurrentOption   = { "Most Coins & Goop" },
		MultipleOptions = true,
		Flag            = "TargetPriority",
		Callback        = function(options)
			enemySettings.TargetPriorities = {}
			for _, opt in ipairs(options) do enemySettings.TargetPriorities[opt] = true end
		end,
	})

	gameTab:CreateDropdown({
		Name            = "Mutation Filter",
		Options         = { "Any", "Big", "Huge", "Inverted", "Shiny" },
		CurrentOption   = { "Any" },
		MultipleOptions = false,
		Flag            = "MutationFilter",
		Callback        = function(option)
			enemySettings.MutationFilter = type(option) == "table" and option[1] or option
		end,
	})

	gameTab:CreateSection("Controls")

	local combatEnabled = false
	local getgcChecked  = false

	local function findGunController()
		local ok, result = pcall(function()
			local char = localPlayer.Character
			if not char then return nil end
			local tool = char:FindFirstChild("SlimeGun")
			if not tool then return nil end
			if not getgc then
				if not getgcChecked then Logger:warn("Executor", "Capability", "getgc not available — Auto Shoot disabled") getgcChecked = true end
				return nil
			end
			if not getgcChecked then Logger:info("Executor", "Capability", "getgc available — Auto Shoot enabled") getgcChecked = true end
			for _, v in ipairs(getgc(true)) do
				if type(v) == "table" and rawget(v, "tool") == tool and rawget(v, "prevSendAt") ~= nil then return v end
			end
			return nil
		end)
		return ok and result or nil
	end

	featureToggle(gameTab, { Name = "Auto Shoot Enemies (getgc)", CurrentValue = false, Flag = "CombatAutoShoot", Callback = function(value) combatEnabled = value end })
	gameTab:CreateDropdown({ Name = "Combat Target Priority", Options = { "Closest", "Lowest HP", "Highest HP", "Most Coins & Goop" }, CurrentOption = { "Closest" }, MultipleOptions = false, Flag = "CombatTargetPriority", Callback = function() end })

	task.spawn(function()
		local controller = nil
		while true do
			task.wait(0.1)
			if not combatEnabled then controller = nil task.wait(0.3) continue end
			pcall(function()
				local char = localPlayer.Character
				if not char then return end
				local humanoid = char:FindFirstChildWhichIsA("Humanoid")
				if not humanoid or humanoid.Health <= 0 then return end
				local _, targetId = selectCombatTarget()
				if not targetId then return end
				local tool = char:FindFirstChild("SlimeGun")
				if not tool then
					local backpack = localPlayer:FindFirstChildOfClass("Backpack")
					if backpack then
						local gunInBag = backpack:FindFirstChild("SlimeGun")
						if gunInBag then humanoid:EquipTool(gunInBag) end
					end
					controller = nil
					return
				end
				if not controller then controller = findGunController() if not controller then return end end
				local ok = pcall(function()
					local orig = controller._getTargetEnemyId
					controller._getTargetEnemyId = function() return targetId end
					controller:onActivated()
					controller._getTargetEnemyId = orig
				end)
				if not ok then controller = nil end
			end)
		end
	end)

	gameTab:CreateSection("Progress")

	featureToggle(gameTab, {
		Name         = "Auto Rebirth",
		CurrentValue = false,
		Flag         = "GameAutoRebirth",
		Callback     = function(enabled)
			if not enabled then return end
			task.spawn(function()
				while true do
					local flag = rayfieldLibrary.Flags.GameAutoRebirth
					if not flag or not flag.CurrentValue then break end
					pcall(function()
						if not rebirthServiceRemote or not dataServiceClient then return end
						local rebirths     = dataServiceClient:get("rebirths") or 0
						local goop         = dataServiceClient:get("goop") or 0
						local furthestZone = dataServiceClient:get("furthestZone") or 0
						local requiredGoop = (2 ^ rebirths) * 500
						local minZone      = tonumber(rayfieldLibrary.Flags.GameMinZoneRebirth and rayfieldLibrary.Flags.GameMinZoneRebirth.CurrentValue) or 0
						if furthestZone >= minZone and goop >= requiredGoop then
							rebirthServiceRemote:InvokeServer("requestRebirth")
						end
					end)
					task.wait(10)
				end
			end)
		end,
	})

	gameTab:CreateInput({ Name = "Minimum Zone To Rebirth", CurrentValue = "", PlaceholderText = "e.g. 10", RemoveTextAfterFocusLost = false, Flag = "GameMinZoneRebirth", Callback = function() end })

	gameTab:CreateSection("Upgrades")

	featureToggle(gameTab, {
		Name         = "Auto Upgrade Purchasing",
		CurrentValue = false,
		Flag         = "GameAutoUpgrade",
		Callback     = function(enabled)
			if not enabled then return end
			task.spawn(function()
				local upgradeTree_local
				pcall(function()
					upgradeTree_local = require(game:GetService("ReplicatedStorage").Source.Features.Upgrades.UpgradeTree)
				end)

				local function getUpgradeIdsAndCosts()
					local ids, costs = {}, {}
					if not upgradeTree_local then return ids, costs end
					pcall(function()
						for _, tree in ipairs(upgradeTree_local) do
							for id, data in pairs(tree) do
								if data and data.cost then ids[#ids + 1] = id costs[id] = data.cost end
							end
						end
					end)
					return ids, costs
				end

				local upgradeIds, upgradeCosts = getUpgradeIdsAndCosts()

				while true do
					local flag = rayfieldLibrary.Flags.GameAutoUpgrade
					if not flag or not flag.CurrentValue then break end
					if not upgradeServiceClient_new or not dataServiceClient_new then task.wait(0.5) continue end
					pcall(function()
						local upgradeMode = rayfieldLibrary.Flags.GameUpgradeMode and rayfieldLibrary.Flags.GameUpgradeMode.CurrentOption or { "All" }
						local modeSet     = {}
						for _, m in ipairs(upgradeMode) do modeSet[m] = true end
						local unlockedUpgrades = dataServiceClient_new:get("upgrades") or {}
						local coins        = dataServiceClient_new:get("coins") or 0
						local goop         = dataServiceClient_new:get("goop") or 0
						local rollCurrency = dataServiceClient_new:get("rollCurrency") or 0
						for _, upgradeId in ipairs(upgradeIds) do
							if unlockedUpgrades[upgradeId] == true then continue end
							local costInfo = upgradeCosts[upgradeId]
							if not costInfo then continue end
							local costAmount   = costInfo.amount or 0
							local currencyType = costInfo.currency
							local modeMatches  = modeSet["All"]
								or (modeSet["Coins"] and currencyType == "coins")
								or (modeSet["Goop"]  and currencyType == "goop")
								or (modeSet["Rolls"] and currencyType == "rollCurrency")
							if not modeMatches then continue end
							local canAfford = (currencyType == "coins"        and coins        >= costAmount)
								or          (currencyType == "goop"           and goop          >= costAmount)
								or          (currencyType == "rollCurrency"   and rollCurrency  >= costAmount)
							if canAfford then
								local success = upgradeServiceClient_new:unlockUpgrade(upgradeId)
								if success then
									if     currencyType == "coins"        then coins        = coins        - costAmount
									elseif currencyType == "goop"         then goop          = goop          - costAmount
									elseif currencyType == "rollCurrency" then rollCurrency  = rollCurrency  - costAmount end
									unlockedUpgrades[upgradeId] = true
								end
								task.wait(0.2)
							end
						end
					end)
					task.wait(0.5)
				end
			end)
		end,
	})

	gameTab:CreateDropdown({ Name = "Upgrade Mode", Options = { "All", "Coins", "Goop", "Rolls" }, CurrentOption = { "All" }, MultipleOptions = true, Flag = "GameUpgradeMode", Callback = function() end })

	gameTab:CreateSection("Recipes")

	pcall(function()
		local recipeIdsList = {}
		if RecipesModule then
			local unlocked = dataServiceClient and dataServiceClient:get("craftingRecipes") or {}
			local all      = RecipesModule.getRecipes() or {}
			for _, recipe in ipairs(all) do
				if unlocked[recipe.id] then recipeIdsList[#recipeIdsList + 1] = recipe.id end
			end
			table.sort(recipeIdsList)
		end

		local craftingState = {
			selectedRecipeIds = #recipeIdsList > 0 and { recipeIdsList[1] } or {},
			craftAmount       = 1,
			autoCraftEnabled  = false,
			autoCraftAmount   = 1,
			autoCraftThread   = nil,
			protectCategories = { "Best Slime", "Equipped Slimes", "Xp Slimes" },
		}

		local MutationsModule       = mutationsModule
		local function getSizeMutations()     return MutationsModule and MutationsModule.sizeMutations     or {} end
		local function getModifierMutations() return MutationsModule and MutationsModule.modifierMutations or {} end
		local function getMutationValue(mutId)
			if not MutationsModule then return 0 end
			local ok, data = pcall(function() return MutationsModule.get(mutId) end)
			return ok and data and data.value or 0
		end

		local function parseUniqueId(uid)
			local base, sizeMut, modMut = uid, nil, nil
			for _, sizeId in ipairs(getSizeMutations()) do
				local prefix = sizeId .. "_"
				if base:sub(1, #prefix) == prefix then sizeMut = sizeId base = base:sub(#prefix + 1) break end
			end
			if base:sub(1, 1) == "-" then base = base:sub(2) end
			for _, modId in ipairs(getModifierMutations()) do
				local suffix = "_" .. modId
				if base:sub(-#suffix) == suffix then modMut = modId base = base:sub(1, -#suffix - 1) break end
			end
			return base, sizeMut, modMut
		end

		local function scoreUniqueId(uid)
			local _, sizeMut, modMut = parseUniqueId(uid)
			local score = 0
			if sizeMut then score = score + getMutationValue(sizeMut) * 1000 end
			if modMut  then score = score + getMutationValue(modMut)  * 100  end
			return score
		end

		local function getEquippedSet()
			local ok, result = pcall(function()
				local equipped = dataServiceClient and dataServiceClient:get("equipped") or {}
				local set = {}
				for _, uid in pairs(equipped) do set[uid] = true end
				return set
			end)
			return ok and result or {}
		end

		local function getBestSlimeSet()
			local ok, result = pcall(function()
				local inventory = dataServiceClient and dataServiceClient:get("inventory") or {}
				local best, bestScore = nil, -1
				for uid, data in pairs(inventory) do
					if type(data) ~= "table" then
						local s = scoreUniqueId(uid)
						if s > bestScore then bestScore = s best = uid end
					end
				end
				local set = {}
				if best then set[best] = true end
				return set
			end)
			return ok and result or {}
		end

		local function buildProtectedSet(categories)
			local catSet    = {}
			for _, cat in ipairs(categories) do catSet[cat] = true end
			local protected = {}
			if catSet["Equipped Slimes"] then for uid in pairs(getEquippedSet())  do protected[uid] = true end end
			if catSet["Best Slime"]      then for uid in pairs(getBestSlimeSet()) do protected[uid] = true end end
			if catSet["Xp Slimes"]       then
				pcall(function()
					local inv = dataServiceClient and dataServiceClient:get("inventory") or {}
					for uid, data in pairs(inv) do if type(data) == "table" then protected[uid] = true end end
				end)
			end
			return protected
		end

		local protectedPets = buildProtectedSet(craftingState.protectCategories)

		local function findBestIngredient(baseId, usedCounts)
			local ok, result = pcall(function()
				local inventory = dataServiceClient and dataServiceClient:get("inventory") or {}
				local bestUid, bestScore = nil, -1
				for uid, data in pairs(inventory) do
					if not protectedPets[uid] then
						local parsedBase = parseUniqueId(uid)
						if parsedBase == baseId then
							local owned = type(data) == "number" and math.max(data, 0) or (type(data) == "table" and 1 or 0)
							local used  = usedCounts[uid] or 0
							if owned - used > 0 then
								local s = scoreUniqueId(uid)
								if s > bestScore then bestScore = s bestUid = uid end
							end
						end
					end
				end
				return bestUid
			end)
			return ok and result or nil
		end

		local function buildCraftArgsForRecipe(recipeId, amount)
			local ok, result = pcall(function()
				local recipe = RecipesModule and RecipesModule.getRecipe(recipeId)
				if not recipe then return nil end
				local ingredientIds, usedCounts = {}, {}
				for _, input in ipairs(recipe.inputs) do
					local uid = findBestIngredient(input.id, usedCounts) or ("-" .. input.id)
					usedCounts[uid] = (usedCounts[uid] or 0) + 1
					ingredientIds[#ingredientIds + 1] = uid
				end
				return { "requestCraftRecipe", recipeId, ingredientIds, tostring(amount) }
			end)
			return ok and result or nil
		end

		local craftingRemoteCache = nil
		local function getCraftingRemote()
			if craftingRemoteCache then return craftingRemoteCache end
			local ok, remote = pcall(function()
				return ReplicatedStorage
					:WaitForChild("Packages", 15)
					:WaitForChild("_Index", 15)
					:WaitForChild("leifstout_networker@0.3.1", 15)
					:WaitForChild("networker", 15)
					:WaitForChild("_remotes", 15)
					:WaitForChild("CraftingService", 10)
					:WaitForChild("RemoteFunction", 10)
			end)
			if ok then craftingRemoteCache = remote end
			return craftingRemoteCache
		end

		local function doCraftAll(amount)
			local craftRemote = getCraftingRemote()
			if not craftRemote then return {} end
			local results = {}
			for _, recipeId in ipairs(craftingState.selectedRecipeIds) do
				local args = buildCraftArgsForRecipe(recipeId, amount)
				if args then
					local ok, result = pcall(function() return craftRemote:InvokeServer(table.unpack(args)) end)
					results[recipeId] = ok and result ~= false
				end
			end
			return results
		end

		local function getMaxCraftsForRecipe(recipeId)
			local ok, result = pcall(function()
				local recipe = RecipesModule and RecipesModule.getRecipe(recipeId)
				if not recipe then return 0 end
				local usedCounts, maxCrafts = {}, math.huge
				for _, input in ipairs(recipe.inputs) do
					local uid = findBestIngredient(input.id, usedCounts)
					if not uid then return 0 end
					usedCounts[uid] = (usedCounts[uid] or 0) + 1
					local inv   = dataServiceClient and dataServiceClient:get("inventory") or {}
					local owned = type(inv[uid]) == "number" and math.max(inv[uid], 0) or (type(inv[uid]) == "table" and 1 or 0)
					local avail = owned - usedCounts[uid] + 1
					if avail < maxCrafts then maxCrafts = avail end
				end
				return maxCrafts == math.huge and 0 or maxCrafts
			end)
			return ok and result or 0
		end

		gameTab:CreateDropdown({ Name = "Select Recipes to Craft", Options = #recipeIdsList > 0 and recipeIdsList or { "None" }, CurrentOption = craftingState.selectedRecipeIds, MultipleOptions = true, Flag = "CraftingSelectedRecipes", Callback = function(options) craftingState.selectedRecipeIds = options end })
		gameTab:CreateSlider({ Name = "Craft Amount", Range = { 1, 99 }, Increment = 1, Suffix = "x", CurrentValue = 1, Flag = "CraftingAmount", Callback = function(val) craftingState.craftAmount = val end })

		featureButton(gameTab, {
			Name     = "Craft Now",
			Callback = function()
				local results = doCraftAll(craftingState.craftAmount)
				local succeeded, failed = 0, 0
				for _, ok in pairs(results) do if ok then succeeded = succeeded + 1 else failed = failed + 1 end end
				pcall(function() rayfieldLibrary:Notify({ Title = "Cactus Hub", Content = succeeded .. " crafts succeeded" .. (failed > 0 and (", " .. failed .. " failed") or ""), Duration = 3, Image = 4483362458 }) end)
			end,
		})

		gameTab:CreateSlider({ Name = "Auto Craft Amount", Range = { 1, 99 }, Increment = 1, Suffix = "x", CurrentValue = 1, Flag = "CraftingAutoAmount", Callback = function(val) craftingState.autoCraftAmount = val end })

		featureToggle(gameTab, {
			Name         = "Enable Auto Craft",
			CurrentValue = false,
			Flag         = "CraftingAutoToggle",
			Callback     = function(enabled)
				craftingState.autoCraftEnabled = enabled
				if enabled then
					if craftingState.autoCraftThread then task.cancel(craftingState.autoCraftThread) end
					craftingState.autoCraftThread = task.spawn(function()
						while true do
							local flag = rayfieldLibrary.Flags.CraftingAutoToggle
							if not flag or not flag.CurrentValue then break end
							pcall(function()
								local minMax = math.huge
								for _, recipeId in ipairs(craftingState.selectedRecipeIds) do
									local m = getMaxCraftsForRecipe(recipeId)
									if m < minMax then minMax = m end
								end
								local autoCraftMax = minMax == math.huge and 1 or math.max(1, minMax)
								local craftAmount  = math.min(craftingState.autoCraftAmount, autoCraftMax)
								if craftAmount > 0 then doCraftAll(craftAmount) end
							end)
							task.wait(5)
						end
						craftingState.autoCraftThread = nil
					end)
					pcall(function() rayfieldLibrary:Notify({ Title = "Auto Craft", Content = "Started", Duration = 3, Image = 4483362458 }) end)
				else
					if craftingState.autoCraftThread then task.cancel(craftingState.autoCraftThread) craftingState.autoCraftThread = nil end
					pcall(function() rayfieldLibrary:Notify({ Title = "Auto Craft", Content = "Stopped.", Duration = 3, Image = 4483362458 }) end)
				end
			end,
		})

		gameTab:CreateDropdown({ Name = "Protect Categories", Options = { "Best Slime", "Equipped Slimes", "Xp Slimes" }, CurrentOption = { "Best Slime", "Equipped Slimes", "Xp Slimes" }, MultipleOptions = true, Flag = "CraftingProtectCategories",
			Callback = function(options)
				craftingState.protectCategories = options
				protectedPets = buildProtectedSet(options)
			end,
		})

		pcall(function() rayfieldLibrary:Notify({ Title = "Cactus Hub", Content = "Loaded — " .. (#recipeIdsList) .. " unlocked recipes ready.", Duration = 5, Image = 4483362458 }) end)
	end)

	local ufoZonesRemote = nil
	pcall(function()
		ufoZonesRemote = ReplicatedStorage
			:WaitForChild("Packages", 15)
			:WaitForChild("_Index", 15)
			:WaitForChild("leifstout_networker@0.3.1", 15)
			:WaitForChild("networker", 15)
			:WaitForChild("_remotes", 15)
			:WaitForChild("ZonesService", 10)
			:WaitForChild("RemoteFunction", 10)
	end)

	local ufoLootRemote = nil
	local function getUfoLootRemote()
		if ufoLootRemote then return ufoLootRemote end
		local ok, remote = pcall(function()
			return ReplicatedStorage
				:WaitForChild("Packages", 10)
				:WaitForChild("_Index", 10)
				:WaitForChild("leifstout_networker@0.3.1", 10)
				:WaitForChild("networker", 10)
				:WaitForChild("_remotes", 10)
				:WaitForChild("LootService", 10)
				:WaitForChild("RemoteFunction", 10)
		end)
		if ok then ufoLootRemote = remote end
		return ufoLootRemote
	end

	local ufoClient = nil
	pcall(function() ufoClient = require(ReplicatedStorage.Source.Features.UfoEvent.UfoEventServiceClient) end)

	local ufoZonesModuleCache = nil
	local function getUfoZonesModule()
		if ufoZonesModuleCache then return ufoZonesModuleCache end
		local ok, m = pcall(function() return require(ReplicatedStorage.Source.Game.Items.Zones) end)
		if ok then ufoZonesModuleCache = m end
		return ufoZonesModuleCache
	end

	local autoUfoZone   = false
	local autoUfoLoot   = false
	local lastUfoZoneId = nil
	local lastUfoPhase  = nil

	ufoTab:CreateSection("Live Status")
	local ufoPhaseLabel    = ufoTab:CreateLabel("🛸  Phase: —")
	local ufoZoneIdLabel   = ufoTab:CreateLabel("📍  Zone ID: —")
	local ufoZoneNameLabel = ufoTab:CreateLabel("🗺️  Zone Name: —")
	local ufoNextLabel     = ufoTab:CreateLabel("⏳  Next Event: —")
	local ufoGoldenLabel   = ufoTab:CreateLabel("⭐  Golden UFO: —")

	local function refreshUfoState()
		pcall(function()
			if not ufoClient then ufoPhaseLabel:Set("🛸  Phase: Module not loaded") return end
			local ok, state = pcall(function() return ufoClient:getStateSource()() end)
			if not ok or not state then return end
			local zoneName = "N/A"
			pcall(function()
				local ZM = getUfoZonesModule()
				if ZM and state.zoneId and ZM.hasZone(state.zoneId) then
					zoneName = ZM.getZone(state.zoneId).name
				end
			end)
			local nextEvent = "N/A"
			pcall(function()
				if state.nextEventStartTime then
					local secs = math.max(0, math.round(state.nextEventStartTime - workspace:GetServerTimeNow()))
					nextEvent  = string.format("%02d:%02d", math.floor(secs / 60), secs % 60)
				end
			end)
			local phaseIcon = "⚪"
			if     state.phase == "hovering"  then phaseIcon = "🟢"
			elseif state.phase == "arriving"  then phaseIcon = "🟡"
			elseif state.phase == "departing" then phaseIcon = "🔴"
			end
			local isGolden = false
			pcall(function() isGolden = ufoClient.isGolden == true end)
			ufoPhaseLabel:Set("🛸  Phase: "       .. phaseIcon .. " " .. state.phase:upper())
			ufoZoneIdLabel:Set("📍  Zone ID: "    .. (state.zoneId and tostring(state.zoneId) or "None"))
			ufoZoneNameLabel:Set("🗺️  Zone Name: " .. zoneName)
			ufoNextLabel:Set("⏳  Next Event: "   .. nextEvent)
			ufoGoldenLabel:Set("⭐  Golden UFO: "  .. (isGolden and "Yes ✅" or "No ❌"))
		end)
	end

	ufoTab:CreateSection("Automation")

	featureToggle(ufoTab, {
		Name         = "Auto Stay in UFO Zone",
		CurrentValue = false,
		Flag         = "AutoUfoZone",
		Callback     = function(value)
			autoUfoZone = value
			if not value then lastUfoZoneId = nil lastUfoPhase = nil end
		end,
	})

	featureToggle(ufoTab, {
		Name         = "Auto Collect UFO Loot",
		CurrentValue = false,
		Flag         = "AutoUfoLoot",
		Callback     = function(value) autoUfoLoot = value end,
	})

	ufoTab:CreateSection("Controls")
	featureButton(ufoTab, { Name = "Refresh Status", Callback = function() refreshUfoState() end })

	task.spawn(function()
		local ufoWasActive   = false
		local farmWasEnabled = false
		while true do
			task.wait(1)
			pcall(function()
				refreshUfoState()
				if not ufoClient then return end
				local ok, state = pcall(function() return ufoClient:getStateSource()() end)
				if not ok or not state then return end
				local isActive = state.phase ~= "idle" and state.zoneId ~= nil

				if autoUfoZone then
					if isActive then
						if not ufoWasActive then
							ufoWasActive = true
							local farmFlag = rayfieldLibrary.Flags.FarmingStayInBestZone
							farmWasEnabled = farmFlag and farmFlag.CurrentValue or false
							if farmWasEnabled then pcall(function() farmFlag:Set(false) end) end
						end
						lastUfoZoneId = state.zoneId
						lastUfoPhase  = state.phase
						local currentZone = nil
						if dataServiceClient then
							pcall(function() currentZone = dataServiceClient:get("zone") end)
						end
						if currentZone ~= state.zoneId then
							pcall(function() ufoZonesRemote:InvokeServer("requestTeleportZone", state.zoneId) end)
						end
					else
						if ufoWasActive then
							ufoWasActive = false
							if farmWasEnabled then
								local farmFlag = rayfieldLibrary.Flags.FarmingStayInBestZone
								if farmFlag then pcall(function() farmFlag:Set(true) end) end
								farmWasEnabled = false
							end
							lastUfoZoneId = nil
							lastUfoPhase  = nil
						end
					end
				end

				if autoUfoLoot then
					local remote = getUfoLootRemote()
					if remote then
						for _, folderName in ipairs({ "Loot", "Debris" }) do
							local container = workspace:FindFirstChild(folderName)
							if container then
								for _, item in ipairs(container:GetChildren()) do
									local id = item:GetAttribute("uniqueId") or item:GetAttribute("id") or item.Name
									if id then pcall(function() remote:InvokeServer("requestCollect", id) end) end
								end
							end
						end
					end
				end
			end)
		end
	end)

	local indexRunning           = false
	local indexThread            = nil
	local luckPollThread         = nil
	local selectedCategoryOption = nil
	local indexLabels            = {}

	indexTab:CreateSection("Controls")

	featureToggle(indexTab, {
		Name         = "Start Auto Complete",
		CurrentValue = false,
		Flag         = "IndexAutoComplete",
		Callback     = function(value)
			if value then
				indexRunning = true
				indexThread  = task.spawn(function()
					if not dataServiceClient then
						pcall(function() rayfieldLibrary:Notify({ Title = "Index", Content = "DataService not loaded yet.", Duration = 4 }) end)
						indexRunning = false
						return
					end
					setLuck(1) task.wait(0.3)
					setLuckEnabled(true) task.wait(0.3)

					luckPollThread = task.spawn(function()
						while indexRunning do
							pcall(function()
								if indexLabels.lLuck then indexLabels.lLuck:Set("🍀 Luck Override: x" .. tostring(luckValueLocal)) end
							end)
							task.wait(1)
						end
					end)

					local modeFlag = rayfieldLibrary.Flags and rayfieldLibrary.Flags.IndexRollMode
					local mode     = modeFlag and (type(modeFlag.CurrentOption) == "table" and modeFlag.CurrentOption[1] or modeFlag.CurrentOption) or "🌱 Easiest First"

					local function getSortedCategoriesByPriority()
						local cats = {}
						pcall(function()
							for _, catId in ipairs(CATEGORY_IDS) do
								local missing = getMissingSlimes(catId)
								if #missing > 0 then
									cats[#cats + 1] = { id = catId, easiestEffectiveOdds = getEffectiveOdds(missing[1], catId) }
								end
							end
							table.sort(cats, function(a, b) return a.easiestEffectiveOdds > b.easiestEffectiveOdds end)
						end)
						return cats
					end

					local function runCategory(catId, modeStr, labels)
						local failCount    = 0
						local catLabel     = catId:sub(1, 1):upper() .. catId:sub(2)
						local lastTargetId = nil
						while indexRunning do
							local flag = rayfieldLibrary.Flags.IndexAutoComplete
							if not flag or not flag.CurrentValue then indexRunning = false break end
							local missing = getMissingSlimes(catId)
							if #missing == 0 then return true end
							local target  = modeStr == "🎯 Rarest First" and missing[#missing] or missing[1]
							local effOdds = getEffectiveOdds(target, catId)
							if target.id ~= lastTargetId then lastTargetId = target.id setLuck(calcOptimalLuck(effOdds)) end
							if labels then
								pcall(function()
									labels.lTarget:Set("🎯 Target: " .. catLabel .. " " .. target.name)
									labels.lOdds:Set("🎲 Odds: " .. formatOdds(effOdds))
									labels.lCategory:Set(string.format("📂 %s (%d left)", catLabel, #missing))
								end)
							end
							local before = getUnlockedIndex(catId)
							pcall(function() networkerRoll:fetch("requestRoll") end)
							task.wait(rollSliceModule and rollSliceModule.rollTime() or 0.5)
							local after = getUnlockedIndex(catId)
							local gotOne = false
							for id, v in pairs(after) do
								if v == true and not before[id] then
									gotOne    = true
									failCount = 0
									pcall(function()
										local slime = slimesModule and slimesModule.getSlime(id)
										print("[UNLOCKED]", catLabel, slime and slime.name or id)
									end)
								end
							end
							if not gotOne then
								failCount = failCount + 1
								if failCount % 100 == 0 then warn("[STUCK]", failCount, "rolls |", catLabel, target.name) end
							end
							task.wait()
						end
						return false
					end

					if selectedCategoryOption == nil or selectedCategoryOption == "🎲 All (Recommended)" then
						while indexRunning do
							local sorted = getSortedCategoriesByPriority()
							if #sorted == 0 then
								pcall(function()
									if indexLabels.lCategory then indexLabels.lCategory:Set("📂 ✅ All Complete!") end
									if indexLabels.lTarget   then indexLabels.lTarget:Set("🎯 Target: —") end
									if indexLabels.lOdds     then indexLabels.lOdds:Set("🎲 Odds: —") end
								end)
								indexRunning = false break
							end
							local completed = runCategory(sorted[1].id, mode, indexLabels)
							if not completed then break end
						end
					else
						local catId = nil
						for _, cId in ipairs(CATEGORY_IDS) do
							local label = cId:sub(1, 1):upper() .. cId:sub(2)
							if selectedCategoryOption:find(label) then catId = cId break end
						end
						if catId then
							runCategory(catId, mode, indexLabels)
							if indexRunning then
								pcall(function()
									if indexLabels.lCategory then indexLabels.lCategory:Set("📂 ✅ Complete!") end
									if indexLabels.lTarget   then indexLabels.lTarget:Set("🎯 Target: —") end
									if indexLabels.lOdds     then indexLabels.lOdds:Set("🎲 Odds: —") end
								end)
							end
						end
						indexRunning = false
					end

					if luckPollThread then task.cancel(luckPollThread) end
					setLuckEnabled(false)
				end)
			else
				indexRunning = false
				if indexThread    then task.cancel(indexThread)    indexThread    = nil end
				if luckPollThread then task.cancel(luckPollThread) luckPollThread = nil end
				setLuckEnabled(false)
				pcall(function()
					if indexLabels.lTarget   then indexLabels.lTarget:Set("🎯 Target: —") end
					if indexLabels.lOdds     then indexLabels.lOdds:Set("🎲 Odds: —") end
					if indexLabels.lLuck     then indexLabels.lLuck:Set("🍀 Luck: —") end
					if indexLabels.lCategory then indexLabels.lCategory:Set("📂 Category: —") end
				end)
			end
		end,
	})

	indexTab:CreateSection("Settings")

	pcall(function()
		local categoryOptions = { "🎲 All (Recommended)" }
		for _, catId in ipairs(CATEGORY_IDS) do
			local missing = getMissingSlimes(catId)
			local label   = catId:sub(1, 1):upper() .. catId:sub(2)
			if #missing == 0 then
				categoryOptions[#categoryOptions + 1] = "✅ " .. label .. " (Complete)"
			else
				local effOdds = getEffectiveOdds(missing[1], catId)
				categoryOptions[#categoryOptions + 1] = string.format("%s (%d left | %s)", label, #missing, formatOdds(effOdds))
			end
		end
		selectedCategoryOption = categoryOptions[1]
		indexTab:CreateDropdown({
			Name            = "Category",
			Options         = categoryOptions,
			CurrentOption   = { categoryOptions[1] },
			MultipleOptions = false,
			Flag            = "IndexCategory",
			Callback        = function(option) selectedCategoryOption = type(option) == "table" and option[1] or option end,
		})
	end)

	indexTab:CreateDropdown({ Name = "Roll Mode", Options = { "🌱 Easiest First", "🎯 Rarest First" }, CurrentOption = { "🌱 Easiest First" }, MultipleOptions = false, Flag = "IndexRollMode", Callback = function() end })

	indexTab:CreateSection("Status")
	indexLabels.lTarget   = indexTab:CreateLabel("🎯 Target: —")
	indexLabels.lOdds     = indexTab:CreateLabel("🎲 Odds: —")
	indexLabels.lLuck     = indexTab:CreateLabel("🍀 Luck: —")
	indexLabels.lCategory = indexTab:CreateLabel("📂 Category: —")

	indexTab:CreateSection("Index Progress")
	local indexProgressLabels = {}
	local totalSlimeCount     = getTotalSlimes()
	for _, catId in ipairs(CATEGORY_IDS) do
		local label = catId:sub(1, 1):upper() .. catId:sub(2)
		indexProgressLabels[catId] = indexTab:CreateLabel(
			string.format("📊 %s: %d / %d", label, getUnlockedCount(catId), totalSlimeCount)
		)
	end

	task.spawn(function()
		while true do
			task.wait(5)
			pcall(function()
				local totalNow = getTotalSlimes()
				for _, catId in ipairs(CATEGORY_IDS) do
					if indexProgressLabels[catId] then
						local label = catId:sub(1, 1):upper() .. catId:sub(2)
						indexProgressLabels[catId]:Set(
							string.format("📊 %s: %d / %d", label, getUnlockedCount(catId), totalNow)
						)
					end
				end
			end)
		end
	end)

	miscTab:CreateSection("Codes & Rewards")

	featureToggle(miscTab, {
		Name         = "Auto Redeem Codes",
		CurrentValue = false,
		Flag         = "MiscRedeemCodes",
		Callback     = function(enabled)
			if not enabled then return end
			task.spawn(function()
				local codes = { "AAisComing", "goingBananas", "gullible", "Sliming", "test", "beammeup", "aliensarehere" }
				table.sort(codes)
				while true do
					local flag = rayfieldLibrary.Flags.MiscRedeemCodes
					if not flag or not flag.CurrentValue then break end
					if not codeServiceRemote then break end
					for _, code in ipairs(codes) do
						if not (rayfieldLibrary.Flags.MiscRedeemCodes and rayfieldLibrary.Flags.MiscRedeemCodes.CurrentValue) then break end
						pcall(function() codeServiceRemote:InvokeServer("redeem", code) end)
						task.wait(0.5)
					end
					task.wait(300)
				end
			end)
		end,
	})

	featureToggle(miscTab, {
		Name         = "Auto Claim Offline Earnings",
		CurrentValue = false,
		Flag         = "MiscClaimOffline",
		Callback     = function(enabled)
			if not enabled then return end
			task.spawn(function()
				while true do
					local flag = rayfieldLibrary.Flags.MiscClaimOffline
					if not flag or not flag.CurrentValue then break end
					if not offlineEarningsRemote then break end
					pcall(function() offlineEarningsRemote:InvokeServer("requestClaim") end)
					task.wait(60)
				end
			end)
		end,
	})

	featureToggle(miscTab, {
		Name         = "Auto Claim Index Rewards",
		CurrentValue = false,
		Flag         = "MiscClaimIndex",
		Callback     = function(enabled)
			if not enabled then return end
			task.spawn(function()
				while true do
					local flag = rayfieldLibrary.Flags.MiscClaimIndex
					if not flag or not flag.CurrentValue then break end
					pcall(function()
						if not indexServiceRemote or not indexRewardsModule or not dataServiceClient then return end
						local indexData = dataServiceClient:get("index")
						if not indexData or not indexData.categories then return end
						for categoryKey, rewardsList in pairs(indexRewardsModule) do
							local category = indexData.categories[categoryKey]
							if category then
								local unlocked      = category.unlocked or {}
								local unlockedCount = 0
								for _, isUnlocked in pairs(unlocked) do if isUnlocked == true then unlockedCount = unlockedCount + 1 end end
								local claimedRewards = category.claimedRewards or {}
								for _, reward in ipairs(rewardsList) do
									if unlockedCount >= reward.req and not claimedRewards[reward.key] then
										pcall(function() indexServiceRemote:InvokeServer("requestClaimReward", categoryKey) end)
										task.wait(0.5)
									end
								end
							end
						end
					end)
					task.wait(60)
				end
			end)
		end,
	})

	miscTab:CreateSection("Consumables")

	pcall(function()
		local sortedBoostKinds = {}
		if boostKinds then
			for _, kind in ipairs(boostKinds) do sortedBoostKinds[#sortedBoostKinds + 1] = kind end
			table.sort(sortedBoostKinds)
		end

		featureToggle(miscTab, {
			Name         = "Auto Use Potions",
			CurrentValue = false,
			Flag         = "MiscUsePotions",
			Callback     = function(enabled)
				if not enabled then return end
				task.spawn(function()
					while true do
						local flag = rayfieldLibrary.Flags.MiscUsePotions
						if not flag or not flag.CurrentValue then break end
						pcall(function()
							if not boostServiceRemote or not dataServiceClient then return end
							local boosts          = dataServiceClient:get("boosts") or {}
							local selectedPotions = rayfieldLibrary.Flags.MiscPotionTypes and rayfieldLibrary.Flags.MiscPotionTypes.CurrentOption or {}
							for _, potionType in ipairs(selectedPotions) do
								local boostData = boosts[potionType]
								if boostData and (boostData.amount or 0) > 0 then
									pcall(function() boostServiceRemote:InvokeServer("requestUseBoost", potionType) end)
								end
							end
						end)
						task.wait(1)
					end
				end)
			end,
		})

		if #sortedBoostKinds > 0 then
			miscTab:CreateDropdown({ Name = "Potion Types", Options = sortedBoostKinds, CurrentOption = { sortedBoostKinds[1] }, MultipleOptions = true, Flag = "MiscPotionTypes", Callback = function() end })
		else
			miscTab:CreateLabel("Potion types not yet loaded — enable after modules load.")
		end
	end)

	pcall(function()
		local diceNames = {}
		if diceItemIds and idToNameMap then
			for _, itemId in ipairs(diceItemIds) do diceNames[#diceNames + 1] = idToNameMap[itemId] end
			table.sort(diceNames)
		end

		featureToggle(miscTab, {
			Name         = "Auto Use Dice & Items",
			CurrentValue = false,
			Flag         = "MiscUseDice",
			Callback     = function(enabled)
				if not enabled then return end
				task.spawn(function()
					while true do
						local flag = rayfieldLibrary.Flags.MiscUseDice
						if not flag or not flag.CurrentValue then break end
						pcall(function()
							if not inventoryServiceRemote or not dataServiceClient then return end
							local items             = dataServiceClient:get("items") or {}
							local selectedDiceItems = rayfieldLibrary.Flags.MiscDiceTypes and rayfieldLibrary.Flags.MiscDiceTypes.CurrentOption or {}
							for _, diceName in ipairs(selectedDiceItems) do
								local itemId = nameToIdMap and nameToIdMap[diceName]
								if itemId and (items[itemId] or 0) > 0 then
									pcall(function() inventoryServiceRemote:InvokeServer("requestUseItem", itemId) end)
								end
							end
						end)
						task.wait(1)
					end
				end)
			end,
		})

		if #diceNames > 0 then
			miscTab:CreateDropdown({ Name = "Dice & Item Types", Options = diceNames, CurrentOption = { diceNames[1] }, MultipleOptions = true, Flag = "MiscDiceTypes", Callback = function() end })
		else
			miscTab:CreateLabel("Dice types not yet loaded — enable after modules load.")
		end
	end)

	webhookTab:CreateSection("Warning")
	webhookTab:CreateParagraph({ Title = "⚠️ WARNING", Content = "WEBHOOK WILL ONLY WORK IF YOU MANUALLY ENABLE AUTO ROLL IN GAME\nPLEASE DISABLE FAST ROLL (from Farming Tab) if you have it enabled" })
	webhookTab:CreateSection("Configuration")

	local savedWebhookUrl = ""
	local WEBHOOK_AVATAR  = "https://media.discordapp.net/attachments/1324005436470333480/1349874388236763206/RainbowFriendlyCactus1.png"

	featureToggle(webhookTab, { Name = "Enable Webhook", CurrentValue = false, Flag = "WebhookEnabled", Callback = function() end })

	webhookTab:CreateInput({
		Name                     = "Webhook URL",
		CurrentValue             = "",
		PlaceholderText          = "Paste your Discord webhook URL",
		RemoveTextAfterFocusLost = false,
		Flag                     = "WebhookURLDisplay",
		Callback                 = function(url)
			if url and url:match("^https://discord") then
				savedWebhookUrl = url
				local masked = string.rep("•", #url - 6) .. url:sub(-6)
				pcall(function() rayfieldLibrary:Notify({ Title = "Webhook", Content = "URL saved: " .. masked, Duration = 3 }) end)
			end
		end,
	})

	webhookTab:CreateInput({ Name = "User ID",                CurrentValue = "", PlaceholderText = "Discord User ID",       RemoveTextAfterFocusLost = false, Flag = "WebhookUserID",    Callback = function() end })
	webhookTab:CreateInput({ Name = "Minimum Chance To Send", CurrentValue = "", PlaceholderText = "e.g. 1B or 1000000000", RemoveTextAfterFocusLost = false, Flag = "WebhookMinChance", Callback = function() end })

	featureButton(webhookTab, {
		Name     = "Test Webhook",
		Callback = function()
			if savedWebhookUrl == "" then
				rayfieldLibrary:Notify({ Title = "Webhook", Content = "Please paste a Webhook URL first.", Duration = 4 })
				return
			end
			if not rayfieldLibrary.Flags.WebhookEnabled.CurrentValue then
				rayfieldLibrary:Notify({ Title = "Webhook", Content = "Please enable Webhook first.", Duration = 4 })
				return
			end
			local userId  = rayfieldLibrary.Flags.WebhookUserID.CurrentValue
			local mention = (userId and userId ~= "") and ("<@" .. userId .. "> ") or ""
			local success = pcall(function()
				request({ Url = savedWebhookUrl, Method = "POST", Headers = { ["Content-Type"] = "application/json" },
					Body = HttpService:JSONEncode({
						content    = mention,
						username   = "Cactus Hub",
						avatar_url = WEBHOOK_AVATAR,
						embeds     = {{ title = "✅ Webhook Test", description = "Your webhook is working correctly!", color = 0x2ecc71 }},
					})
				})
			end)
			pcall(function() rayfieldLibrary:Notify({ Title = "Webhook", Content = success and "Test sent successfully!" or "Failed to send test.", Duration = 4 }) end)
		end,
	})

	webhookTab:CreateSection("Filters")
	featureToggle(webhookTab, { Name = "Send All Slimes",      CurrentValue = false, Flag = "WebhookSendAll",     Callback = function() end })
	featureToggle(webhookTab, { Name = "Send New Slimes Only", CurrentValue = false, Flag = "WebhookSendNew",     Callback = function() end })
	featureToggle(webhookTab, { Name = "Send Mutated Slimes",  CurrentValue = false, Flag = "WebhookSendMutated", Callback = function() end })
	webhookTab:CreateDropdown({ Name = "Mutations Filter", Options = { "All", "Shiny", "Big", "Huge", "Inverted" }, CurrentOption = { "All" }, MultipleOptions = true, Flag = "WebhookMutations", Callback = function() end })

	local function formatNumber(num)
		if type(num) ~= "number" then return tostring(num) end
		local suffixes = { {1e24,"Sp"},{1e21,"Sx"},{1e18,"Qn"},{1e15,"Qd"},{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"} }
		for _, s in ipairs(suffixes) do
			if math.abs(num) >= s[1] then
				local formatted = num / s[1]
				if math.abs(formatted - math.floor(formatted)) < 0.01 then
					return string.format("%d%s", math.floor(formatted), s[2])
				else
					return string.format("%.1f%s", formatted, s[2])
				end
			end
		end
		return tostring(math.floor(num))
	end

	local function extractSlimeData(rollResultTable)
		if type(rollResultTable) ~= "table" then return nil end
		for _, item in ipairs(rollResultTable) do if type(item) == "table" and item.id then return item end end
		return nil
	end

	local function encodeRollResults(rollResults)
		if type(rollResults) ~= "table" or #rollResults == 0 then return "empty" end
		local encoded = {}
		for i, roll in ipairs(rollResults) do
			local slimeData = extractSlimeData(roll)
			encoded[i] = slimeData and tostring(slimeData.id) or tostring(i)
		end
		return #rollResults .. "|" .. table.concat(encoded, ",")
	end

	local function getMutationTypeString(mutations)
		if not mutations      then return "basic"    end
		if mutations.inverted then return "inverted" end
		if mutations.huge     then return "huge"     end
		if mutations.big      then return "big"      end
		if mutations.shiny    then return "shiny"    end
		return "basic"
	end

	local function isNewSlime(slimeId, mutations)
		local ok, result = pcall(function()
			local indexData  = dataServiceClient and dataServiceClient:get("index") or {}
			local categories = indexData.categories or {}
			local category   = categories[getMutationTypeString(mutations)]
			local unlocked   = category and category.unlocked or {}
			return not unlocked[slimeId]
		end)
		return ok and result or false
	end

	local recentWebhookNotifications = {}
	local webhookNotifCount          = 0
	local WEBHOOK_NOTIF_CAP          = 500

	local function sendWebhookNotification(slimeId, slimeData, mutations, webhookUrl, mentionUserId, notificationKey)
		pcall(function()
			if recentWebhookNotifications[notificationKey] then return end
			recentWebhookNotifications[notificationKey] = true
			webhookNotifCount = webhookNotifCount + 1
			if webhookNotifCount > WEBHOOK_NOTIF_CAP then
				recentWebhookNotifications = {}
				webhookNotifCount          = 0
			end
			local mentionText    = (mentionUserId and mentionUserId ~= "") and ("<@" .. mentionUserId .. "> ") or ""
			local slimeName      = slimeData and slimeData.name or slimeId
			local displayName    = mutations and mutationsModule and mutationsModule.getDisplayName(slimeName, mutations) or slimeName
			local odds           = slimeData and slimeData.odds or nil
			local damage         = slimeData and slimeData.damage or 0
			local health         = slimeData and slimeData.health or 0
			local oddsMultiplier = mutations and mutationsModule and mutationsModule.getVisualOddsMultiplier(mutations) or 1
			local statBonus      = mutations and mutationsModule and mutationsModule.getStatBonus(mutations, "damage") or 1
			local actualOdds     = odds and (odds / oddsMultiplier) or nil
			local chanceText     = (actualOdds and actualOdds > 0) and string.format("1 in %s", formatNumber(math.floor(1 / actualOdds + 0.5))) or "N/A"
			local stats_data     = dataServiceClient and dataServiceClient:get("stats") or {}
			local totalRolls     = stats_data.rolls or 0
			local coins          = dataServiceClient and dataServiceClient:get("coins") or 0
			local totalKills     = stats_data.kills or 0
			local playerName     = localPlayer.Name
			local embedFields    = {{ name = "Chance", value = chanceText, inline = true }}
			local finalDamage    = damage * statBonus
			local finalHealth    = health * statBonus
			local statsString    = ""
			if     finalDamage > 0 and finalHealth > 0 then statsString = string.format("⚔️ %s  ❤️ %s", formatNumber(finalDamage), formatNumber(finalHealth))
			elseif finalDamage > 0                      then statsString = string.format("⚔️ %s", formatNumber(finalDamage))
			elseif finalHealth > 0                      then statsString = string.format("❤️ %s", formatNumber(finalHealth)) end
			if statsString ~= "" then embedFields[#embedFields + 1] = { name = "Stats", value = statsString, inline = true } end
			if mutations and next(mutations) then
				local mutNames = {}
				for mut in pairs(mutations) do mutNames[#mutNames + 1] = mut:sub(1, 1):upper() .. mut:sub(2) end
				embedFields[#embedFields + 1] = { name = "Mutations", value = table.concat(mutNames, ", "), inline = true }
			end
			embedFields[#embedFields + 1] = { name = "💰 Coins", value = formatNumber(coins),      inline = true }
			embedFields[#embedFields + 1] = { name = "⚔️ Kills", value = formatNumber(totalKills), inline = true }
			local iconAssetId  = (mutations and mutations.inverted) and (slimeData and slimeData.invertedIcon) or (slimeData and slimeData.image)
			local thumbnailUrl = nil
			if iconAssetId and iconAssetId ~= "N/A" then
				pcall(function()
					local assetNumber = string.match(tostring(iconAssetId), "rbxassetid://(%d+)")
					if assetNumber then
						local r = request({ Url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetNumber .. "&size=420x420&format=Png&isCircular=false", Method = "GET" })
						if r and r.Success then
							local decoded = HttpService:JSONDecode(r.Body)
							if decoded and decoded.data and decoded.data[1] then thumbnailUrl = decoded.data[1].imageUrl end
						end
					end
				end)
			end
			local embedColor = 0x3498db
			if mutations then
				if     mutations.inverted then embedColor = 0x9b59b6
				elseif mutations.huge     then embedColor = 0xf1c40f
				elseif mutations.big      then embedColor = 0xe67e22
				elseif mutations.shiny    then embedColor = 0xf39c12 end
			end
			local userEmbed = {
				title       = "🎲 New Slime Rolled!",
				description = string.format("**||%s||** rolled **%s**!\n\n🎲 **Total Rolls:** %s", playerName, displayName, tostring(totalRolls)),
				thumbnail   = thumbnailUrl and { url = thumbnailUrl, width = 64, height = 64 } or nil,
				fields      = embedFields,
				color       = embedColor,
			}
			request({ Url = webhookUrl, Method = "POST", Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode({ content = mentionText, username = "Cactus Hub", avatar_url = WEBHOOK_AVATAR, embeds = { userEmbed } })
			})
		end)
	end

	local lastRollResultsHash = nil
	task.spawn(function()
		while true do
			task.wait(0.5)
			if not modulesLoaded then continue end
			if not (rayfieldLibrary.Flags.WebhookEnabled and rayfieldLibrary.Flags.WebhookEnabled.CurrentValue) then continue end
			if savedWebhookUrl == "" or not rollSliceModule then continue end
			pcall(function()
				local currentRolls = rollSliceModule.rollResults()
				if type(currentRolls) ~= "table" or #currentRolls == 0 then return end
				local currentHash = encodeRollResults(currentRolls)
				if currentHash == lastRollResultsHash then return end
				lastRollResultsHash = currentHash
				local sendAll      = rayfieldLibrary.Flags.WebhookSendAll     and rayfieldLibrary.Flags.WebhookSendAll.CurrentValue
				local sendNewOnly  = rayfieldLibrary.Flags.WebhookSendNew     and rayfieldLibrary.Flags.WebhookSendNew.CurrentValue
				local sendMutated  = rayfieldLibrary.Flags.WebhookSendMutated and rayfieldLibrary.Flags.WebhookSendMutated.CurrentValue
				local minChanceStr = rayfieldLibrary.Flags.WebhookMinChance and rayfieldLibrary.Flags.WebhookMinChance.CurrentValue or ""
				local minChanceNum = nil
				if minChanceStr and minChanceStr ~= "" then
					local num, suffix = minChanceStr:upper():gsub(",", ""):match("^(%d+%.?%d*)([KMBTQ]?)$")
					if num then
						local val = tonumber(num)
						suffix = suffix or ""
						if     suffix == "K"     then val = val * 1e3
						elseif suffix == "M"     then val = val * 1e6
						elseif suffix == "B"     then val = val * 1e9
						elseif suffix == "T"     then val = val * 1e12
						elseif suffix:find("QD") then val = val * 1e15
						elseif suffix:find("QN") then val = val * 1e18 end
						minChanceNum = val
					end
				end
				for _, rollResult in ipairs(currentRolls) do
					local slimeData = extractSlimeData(rollResult)
					if slimeData then
						local slimeId = tostring(slimeData.id or "")
						if slimeId ~= "" then
							local mutations       = type(slimeData.mutations) == "table" and next(slimeData.mutations) ~= nil and slimeData.mutations or nil
							local slimeDefinition = slimesModule and slimesModule.getSlime(slimeId)
							local hasMutation     = mutations ~= nil
							local isNew           = isNewSlime(slimeId, mutations)
							local shouldSend      = sendAll or (sendNewOnly and isNew) or (sendMutated and hasMutation)
							if shouldSend and minChanceNum then
								local odds        = slimeDefinition and slimeDefinition.odds or 0
								local chanceValue = odds > 0 and (1 / odds) or 0
								if chanceValue > minChanceNum then shouldSend = false end
							end
							if shouldSend then
								local userId          = rayfieldLibrary.Flags.WebhookUserID and rayfieldLibrary.Flags.WebhookUserID.CurrentValue or ""
								local notificationKey = currentHash .. "_" .. slimeId
								task.spawn(sendWebhookNotification, slimeId, slimeDefinition, mutations, savedWebhookUrl, userId, notificationKey)
							end
						end
					end
				end
			end)
		end
	end)

	settingsTab:CreateParagraph({ Title = "🍀 Want a serverhop script for luck servers?", Content = "Join the Discord! discord.gg/qMWFBWdcf" })
	settingsTab:CreateSection("System")

	featureToggle(settingsTab, {
		Name         = "Anti Kick",
		CurrentValue = false,
		Flag         = "SettingsAntiKick",
		Callback     = function(value)
			if value then
				pcall(function()
					local mt          = getrawmetatable(game)
					local oldNamecall = mt.__namecall
					setreadonly(mt, false)
					mt.__namecall = newcclosure(function(self, ...)
						local method = getnamecallmethod()
						if method == "Kick" and self == localPlayer then
							if rayfieldLibrary.Flags.SettingsAntiKick and rayfieldLibrary.Flags.SettingsAntiKick.CurrentValue then
								warn("[CactusHub] Blocked kick attempt")
								return
							end
						end
						return oldNamecall(self, ...)
					end)
					setreadonly(mt, true)
				end)
			end
		end,
	})

	featureToggle(settingsTab, { Name = "Auto Rejoin On Disconnect", CurrentValue = false, Flag = "SettingsAutoRejoin", Callback = function() end })

	featureToggle(settingsTab, {
		Name         = "Auto Send & Accept Friend Requests",
		CurrentValue = false,
		Flag         = "AutoFriend",
		Callback     = function(value)
			if not value then return end
			task.spawn(function()
				while true do
					local flag = rayfieldLibrary.Flags.AutoFriend
					if not flag or not flag.CurrentValue then break end
					pcall(function()
						local players = game:GetService("Players"):GetPlayers()
						for _, p in ipairs(players) do
							if p ~= localPlayer then
								pcall(function() localPlayer:RequestFriendship(p) end)
								task.wait(1)
							end
						end
					end)
					task.wait(600)
				end
			end)
		end,
	})

	settingsTab:CreateParagraph({ Title = "MAY be Patched", Content = "Auto Send & Accept Friend Requests may not work depending on current Roblox API restrictions." })

	settingsTab:CreateSection("Advanced Optimization")

	local OPT_VISUAL_TYPES = {
		ParticleEmitter = true, Trail = true, Beam = true, Fire = true, Smoke = true,
		Sparkles = true, SurfaceAppearance = true, Highlight = true,
		SelectionBox = true, SelectionSphere = true, Atmosphere = true,
	}
	local CHEAP_MATERIAL        = Enum.Material.SmoothPlastic
	local updatingOptimizations = false
	local optGPUToggle, optEffectsToggle, optGCToggle, optIntenseToggle, maxFpsToggle

	local gcCleanerConn = nil
	local gcAccum       = 0
	local GC_INTERVAL   = 30

	local function startGcCleaner()
		if gcCleanerConn then return end
		gcAccum       = 0
		gcCleanerConn = RunService.Heartbeat:Connect(function(dt)
			gcAccum = gcAccum + dt
			if gcAccum >= GC_INTERVAL then
				gcAccum = 0
				pcall(gcinfo)
			end
		end)
	end

	local function stopGcCleaner()
		if gcCleanerConn then gcCleanerConn:Disconnect() gcCleanerConn = nil end
	end

	local function applyLowGraphics()
		pcall(function()
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			local lighting = game:GetService("Lighting")
			lighting.GlobalShadows           = false
			lighting.EnvironmentDiffuseScale  = 0
			lighting.EnvironmentSpecularScale = 0
			for _, d in ipairs(workspace:GetDescendants()) do
				if d:IsA("BasePart") then
					d.CastShadow  = false
					d.Reflectance = 0
					d.Material    = CHEAP_MATERIAL
				end
			end
		end)
	end

	local function destroyEffects()
		pcall(function()
			for _, d in ipairs(game:GetDescendants()) do
				if OPT_VISUAL_TYPES[d.ClassName] then pcall(function() d:Destroy() end) end
			end
		end)
	end

	local function setAllOptimizations(value)
		updatingOptimizations = true
		pcall(function()
			if maxFpsToggle     then maxFpsToggle:Set(value)     end
			if optGPUToggle     then optGPUToggle:Set(value)     end
			if optEffectsToggle then optEffectsToggle:Set(value) end
			if optGCToggle      then optGCToggle:Set(value)      end
			if optIntenseToggle then optIntenseToggle:Set(value) end
		end)
		updatingOptimizations = false
		if value then
			pcall(function() setfpscap(0) end)
			applyLowGraphics()
			destroyEffects()
			startGcCleaner()
			pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/Optimization.lua"))() end)
		else
			stopGcCleaner()
		end
	end

	settingsTab:CreateToggle({ Name = "Optimize All", CurrentValue = false, Flag = "OptimizeAll", Callback = function(Value) if updatingOptimizations then return end setAllOptimizations(Value) end })

	maxFpsToggle = featureToggle(settingsTab, {
		Name = "Max FPS", CurrentValue = false, Flag = "MaxFPS",
		Callback = function(Value) if Value then pcall(function() setfpscap(0) end) end end,
	})

	optGPUToggle = featureToggle(settingsTab, {
		Name = "Optimize GPU (Low Graphics)", CurrentValue = false, Flag = "OptimizeGPU",
		Callback = function(Value)
			if updatingOptimizations or not Value then return end
			applyLowGraphics()
		end,
	})

	optEffectsToggle = featureToggle(settingsTab, {
		Name = "Destroy Effects", CurrentValue = false, Flag = "DestroyEffects",
		Callback = function(Value)
			if updatingOptimizations or not Value then return end
			destroyEffects()
		end,
	})

	optGCToggle = featureToggle(settingsTab, {
		Name = "Lua GC (Memory Cleaner)", CurrentValue = false, Flag = "LuaGC",
		Callback = function(Value)
			if updatingOptimizations then return end
			if Value then startGcCleaner() else stopGcCleaner() end
		end,
	})

	optIntenseToggle = featureToggle(settingsTab, {
		Name = "Intense Optimization", CurrentValue = false, Flag = "IntenseOptimization",
		Callback = function(Value)
			if updatingOptimizations or not Value then return end
			pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/Optimization.lua"))() end)
		end,
	})

	local function safeGet(...)
		local ok, result = pcall(function()
			if not dataServiceClient then return 0 end
			local ok2, val = pcall(function() return dataServiceClient._data._data end)
			if not ok2 or type(val) ~= "table" then return 0 end
			local cur  = val
			local keys = { ... }
			for _, key in ipairs(keys) do
				if type(cur) ~= "table" then return 0 end
				cur = cur[key]
				if cur == nil then return 0 end
			end
			return cur
		end)
		return ok and result or 0
	end

	local function safeNum(...) return tonumber(safeGet(...)) or 0 end

	local SUFFIXES = { {1e24,"Sp"},{1e21,"Sx"},{1e18,"Qn"},{1e15,"Qd"},{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"} }
	local function fmt(n)
		n = tonumber(n) or 0
		for _, pair in ipairs(SUFFIXES) do
			if n >= pair[1] then
				return (string.format("%.2f", n / pair[1]):gsub("%.?0+$", "")) .. pair[2]
			end
		end
		return tostring(math.floor(n))
	end

	local function fmtTime(seconds)
		seconds = math.floor(tonumber(seconds) or 0)
		local days    = math.floor(seconds / 86400)
		local hours   = math.floor((seconds % 86400) / 3600)
		local minutes = math.floor((seconds % 3600) / 60)
		if     days    > 0 then return days .. "d " .. hours .. "h " .. minutes .. "m"
		elseif hours   > 0 then return hours .. "h " .. minutes .. "m"
		elseif minutes > 0 then return minutes .. "m " .. math.floor(seconds % 60) .. "s"
		else                     return math.floor(seconds % 60) .. "s" end
	end

	local function countKeys(t)
		if type(t) ~= "table" then return 0 end
		local c = 0
		for _ in pairs(t) do c = c + 1 end
		return c
	end

	local function getBestRoll()
		local bestName, bestOdds = "None", "N/A"
		pcall(function()
			local rarestData = safeGet("stats", "rarestRoll", "slimeData")
			if type(rarestData) ~= "table" then return end
			local id        = tostring(rarestData.id or "?")
			local mutations = rarestData.mutations
			local prefix    = ""
			if type(mutations) == "table" then
				if     mutations.inverted                    then prefix = "Inverted "
				elseif mutations.shiny and mutations.huge    then prefix = "Shiny Huge "
				elseif mutations.shiny and mutations.big     then prefix = "Shiny Big "
				elseif mutations.huge                        then prefix = "Huge "
				elseif mutations.shiny                       then prefix = "Shiny "
				elseif mutations.big                         then prefix = "Big " end
			end
			bestName = prefix .. id:sub(1, 1):upper() .. id:sub(2)
			local o  = safeNum("stats", "rarestRoll", "odds")
			bestOdds = o > 0 and ("1 in " .. fmt(math.floor(o))) or "N/A"
		end)
		return bestName, bestOdds
	end

	local function getEquippedDisplay()
		local display = "None"
		pcall(function()
			local equipped = safeGet("equipped")
			if type(equipped) ~= "table" then return end
			local names = {}
			for i = 1, 7 do
				local uid = equipped[i]
				if uid and type(uid) == "string" then
					local clean = uid:match("%-(.+)$") or uid:gsub("^%.", "")
					names[#names + 1] = clean:sub(1, 1):upper() .. clean:sub(2)
				end
			end
			table.sort(names)
			if #names > 0 then display = table.concat(names, ", ") end
		end)
		return display
	end

	local function getIndexCounts()
		local b, bi, sh, hu, inv = 0, 0, 0, 0, 0
		pcall(function()
			local categories = safeGet("index", "categories")
			if type(categories) ~= "table" then return end
			local function count(cat)
				local t = categories[cat]
				return type(t) == "table" and countKeys(t.unlocked or {}) or 0
			end
			b = count("basic") bi = count("big") sh = count("shiny") hu = count("huge") inv = count("inverted")
		end)
		return b, bi, sh, hu, inv
	end

	local function getTotalInventory()
		local total = 0
		pcall(function()
			local inv = safeGet("inventory")
			if type(inv) ~= "table" then return end
			for _, v in pairs(inv) do if type(v) == "number" then total = total + v end end
		end)
		return total
	end

	local function getUniqueSpecies()
		local count = 0
		pcall(function()
			local inv = safeGet("inventory")
			if type(inv) ~= "table" then return end
			local seen = {}
			for key in pairs(inv) do
				if type(key) == "string" and not key:match("^%.") then
					local base = key:match("%-(.+)$") or key
					if not seen[base] then seen[base] = true count = count + 1 end
				end
			end
		end)
		return count
	end

	local sessionStart = os.clock()
	local startRolls   = 0
	local startKills   = 0
	local startCoins   = 0
	local startGoop    = 0

	task.spawn(function()
		repeat task.wait(1) until modulesLoaded
		pcall(function()
			startRolls = safeNum("stats", "rolls")
			startKills = safeNum("stats", "kills")
			startCoins = safeNum("coins")
			startGoop  = safeNum("goop")
		end)
	end)

	local prevRolls, prevCoins, prevGoop              = 0, 0, 0
	local lastUpdate                                  = os.clock()
	local windowRPS, windowCPS, windowGPS             = nil, nil, nil
	local lastRollMove, lastCoinMove, lastGoopMove    = os.clock(), os.clock(), os.clock()
	local STALE = 60

	task.spawn(function()
		while true do
			task.wait(10)
			pcall(function()
				local now   = os.clock()
				local dt    = math.max(1, now - lastUpdate)
				lastUpdate  = now
				local rolls = safeNum("stats", "rolls")
				local coins = safeNum("coins")
				local goop  = safeNum("goop")
				local dr    = math.max(0, rolls - prevRolls)
				local dc    = math.max(0, coins - prevCoins)
				local dg    = math.max(0, goop  - prevGoop)
				if dr > 0 then windowRPS = dr / dt lastRollMove = now end
				if dc > 0 then windowCPS = dc / dt lastCoinMove = now end
				if dg > 0 then windowGPS = dg / dt lastGoopMove = now end
				prevRolls = rolls prevCoins = coins prevGoop = goop
			end)
		end
	end)

	local function getRate(windowVal, lastMove, startVal, curVal)
		local now = os.clock()
		if (now - lastMove) > STALE then return 0 end
		if windowVal and windowVal > 0 then return windowVal end
		local gain    = math.max(0, curVal - startVal)
		local elapsed = math.max(1, now - sessionStart)
		return gain > 0 and (gain / elapsed) or 0
	end

	local statLabels = {}
	local function lbl(key, text) statLabels[key] = statsTab:CreateLabel(text) end
	lbl("sess",     "Session: --  |  Played: --  |  Rebirths: --")
	lbl("rolls1",   "Rolls/sec: --  |  Rolls/min: --  |  Rolls/hr: --")
	lbl("rolls2",   "Session Rolls: --  |  Lifetime: --")
	lbl("coins1",   "Coins/min: --  |  Coins/hr: --")
	lbl("coins2",   "Session Coins: --  |  Total Ever: --")
	lbl("goop1",    "Goop/min: --  |  Goop/hr: --")
	lbl("goop2",    "Session Goop: --  |  Balance: --")
	lbl("kills",    "Session Kills: --  |  Lifetime Kills: --")
	lbl("best",     "Best Ever: --  |  Odds: --")
	lbl("daily",    "Best Today Odds: --")
	lbl("prog",     "Zone: --  |  Max Zone: --  |  Roll Currency: --")
	lbl("idx1",     "Basic: --  |  Big: --  |  Shiny: --  |  Huge: --  |  Inverted: --")
	lbl("inv",      "Total Slimes: --  |  Species: --  |  Crafting: --")
	lbl("equipped", "Equipped: --")

	task.spawn(function()
		while true do
			task.wait(5)
			pcall(function()
				local now          = os.clock()
				local elapsed      = math.max(1, now - sessionStart)
				local rolls        = safeNum("stats", "rolls")
				local kills        = safeNum("stats", "kills")
				local coins        = safeNum("coins")
				local goop         = safeNum("goop")
				local timePlayed   = safeNum("stats", "timePlayed")
				local totalCoins   = safeNum("stats", "totalCoins")
				local rebirths     = safeNum("rebirths")
				local zone         = safeNum("zone")
				local maxZone      = safeNum("maxZone")
				local rollCurrency = safeNum("rollCurrency")
				local sessionRolls = math.max(0, rolls - startRolls)
				local sessionKills = math.max(0, kills - startKills)
				local sessionCoins = math.max(0, coins - startCoins)
				local sessionGoop  = math.max(0, goop  - startGoop)
				local sh = math.floor(elapsed / 3600)
				local sm = math.floor((elapsed % 3600) / 60)
				local ss = math.floor(elapsed % 60)
				local rps = getRate(windowRPS, lastRollMove, startRolls, rolls)
				local cps = getRate(windowCPS, lastCoinMove, startCoins, coins)
				local gps = getRate(windowGPS, lastGoopMove, startGoop,  goop)
				local bestName, bestOdds = getBestRoll()
				local dailyOdds = safeNum("stats", "dailyRarestRoll", "odds")
				local dailyStr  = dailyOdds > 0 and ("1 in " .. fmt(math.floor(dailyOdds))) or "N/A"
				local basic, big, shiny, huge, inverted = getIndexCounts()
				local crafting = countKeys(safeGet("craftingRecipes") or {})
				statLabels.sess:Set(string.format("Session: %dh%dm%ds  |  Played: %s  |  Rebirths: %s", sh, sm, ss, fmtTime(timePlayed), fmt(rebirths)))
				statLabels.rolls1:Set(string.format("Rolls/sec: %.2f  |  Rolls/min: %s  |  Rolls/hr: %s", rps, fmt(rps * 60), fmt(rps * 3600)))
				statLabels.rolls2:Set("Session Rolls: " .. fmt(sessionRolls) .. "  |  Lifetime: " .. fmt(rolls))
				statLabels.coins1:Set("Coins/min: " .. fmt(cps * 60) .. "  |  Coins/hr: " .. fmt(cps * 3600))
				statLabels.coins2:Set("Session Coins: " .. fmt(sessionCoins) .. "  |  Total Ever: " .. fmt(totalCoins))
				statLabels.goop1:Set("Goop/min: " .. fmt(gps * 60) .. "  |  Goop/hr: " .. fmt(gps * 3600))
				statLabels.goop2:Set("Session Goop: " .. fmt(sessionGoop) .. "  |  Balance: " .. fmt(goop))
				statLabels.kills:Set("Session Kills: " .. fmt(sessionKills) .. "  |  Lifetime Kills: " .. fmt(kills))
				statLabels.best:Set("Best Ever: " .. bestName .. "  |  Odds: " .. bestOdds)
				statLabels.daily:Set("Best Today Odds: " .. dailyStr)
				statLabels.prog:Set("Zone: " .. fmt(zone) .. "  |  Max Zone: " .. fmt(maxZone) .. "  |  Roll Currency: " .. fmt(rollCurrency))
				statLabels.idx1:Set("Basic: " .. basic .. "  |  Big: " .. big .. "  |  Shiny: " .. shiny .. "  |  Huge: " .. huge .. "  |  Inverted: " .. inverted)
				statLabels.inv:Set("Total Slimes: " .. fmt(getTotalInventory()) .. "  |  Species: " .. getUniqueSpecies() .. "  |  Crafting: " .. crafting)
				statLabels.equipped:Set("Equipped: " .. getEquippedDisplay())
			end)
		end
	end)

	game:GetService("GuiService").ErrorMessageChanged:Connect(function()
		pcall(function()
			if rayfieldLibrary.Flags.SettingsAutoRejoin and rayfieldLibrary.Flags.SettingsAutoRejoin.CurrentValue then
				game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
			end
		end)
	end)

	pcall(function() rayfieldLibrary:LoadConfiguration() end)
	Logger:info("CactusHub", "Init", "Script initialization complete")
end)
