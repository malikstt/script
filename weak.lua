task.spawn(function()
	local ok, err = pcall(function()
		repeat task.wait() until game:IsLoaded()

		-- ─────────────────────────────────────────────
		-- LOGGER
		-- ─────────────────────────────────────────────
		local Logger = {}
		Logger.LogHistory = {}

		function Logger:log(level, system, feature, message, errorObj)
			local ok2, logErr = pcall(function()
				local logEntry = {
					timestamp = os.time(),
					level = level,
					system = system,
					feature = feature,
					message = message,
					error = errorObj,
				}
				table.insert(self.LogHistory, logEntry)
				if #self.LogHistory > 200 then
					table.remove(self.LogHistory, 1)
				end
				local prefix = string.format(
					"[%s] [%s]%s",
					level,
					system,
					feature and " (" .. feature .. ")" or ""
				)
				local fullMsg = prefix .. " " .. tostring(message)
				if errorObj then
					fullMsg = fullMsg .. "\n  Error: " .. tostring(errorObj)
				end
				if level == "ERROR" or level == "WARN" then
					warn(fullMsg)
				else
					print(fullMsg)
				end
			end)
			if not ok2 then
				warn("[Logger] Internal logging error: " .. tostring(logErr))
			end
		end

		function Logger:info(system, feature, message)
			self:log("INFO", system, feature, message)
		end
		function Logger:warn(system, feature, message)
			self:log("WARN", system, feature, message)
		end
		function Logger:error(system, feature, message, err2)
			self:log("ERROR", system, feature, message, err2)
		end

		-- ─────────────────────────────────────────────
		-- SERVICES
		-- ─────────────────────────────────────────────
		local function getService(name)
			local s, svc = pcall(function() return game:GetService(name) end)
			if not s then
				Logger:warn("Services", name, "GetService failed: " .. tostring(svc))
				return nil
			end
			return svc
		end

		local Players         = getService("Players")
		local RunService      = getService("RunService")
		local ReplicatedStorage = getService("ReplicatedStorage")
		local HttpService     = getService("HttpService")
		local TweenService    = getService("TweenService") -- kept for potential future use
		local StatsService    = getService("Stats")
		local GuiService      = getService("GuiService")
		local TeleportService = getService("TeleportService")

		if not Players then
			warn("[CactusHub] Players service unavailable — aborting")
			return
		end

		local localPlayer = Players.LocalPlayer
		if not localPlayer then
			warn("[CactusHub] LocalPlayer not available — aborting")
			return
		end

		-- ─────────────────────────────────────────────
		-- EXECUTOR CAPABILITY FLAGS
		-- ─────────────────────────────────────────────
		local HAS_SETCLIPBOARD     = type(setclipboard) == "function"
		local HAS_GETGC            = type(getgc) == "function"
		local HAS_SETREADONLY      = type(setreadonly) == "function"
		local HAS_GETRAWMETA       = type(getrawmetatable) == "function"
		local HAS_NEWCCLOSURE      = type(newcclosure) == "function"
		local HAS_GETNAMECALL      = type(getnamecallmethod) == "function"
		local HAS_SETFPSCAP        = type(setfpscap) == "function"
		local HAS_REQUEST          = type(request) == "function" or type(http_request) == "function"
		local HAS_GETCONNECTIONS   = type(getconnections) == "function"
		local doRequest            = type(request) == "function" and request
			or type(http_request) == "function" and http_request
			or nil

		-- ─────────────────────────────────────────────
		-- ANTI-AFK
		-- ─────────────────────────────────────────────
		pcall(function()
			local virtualUser = game:GetService("VirtualUser")
			if virtualUser then
				localPlayer.Idled:Connect(function()
					pcall(function()
						virtualUser:CaptureController()
						virtualUser:ClickButton2(Vector2.new())
					end)
				end)
			end
		end)

		-- ─────────────────────────────────────────────
		-- RAYFIELD LOADER
		-- ─────────────────────────────────────────────
		Logger:info("CactusHub", "Init", "Loading Rayfield...")
		local rayfieldLibrary
		local rayfieldOk, rayfieldErr = pcall(function()
			rayfieldLibrary = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
		end)
		if not rayfieldOk or not rayfieldLibrary then
			Logger:error("CactusHub", "RayfieldLoader", "Failed to load Rayfield", rayfieldErr)
			warn("[CactusHub] Rayfield failed: " .. tostring(rayfieldErr))
			return
		end
		Logger:info("CactusHub", "Init", "Rayfield loaded successfully")

		-- ─────────────────────────────────────────────
		-- SAFE NOTIFY HELPER
		-- ─────────────────────────────────────────────
		local function safeNotify(cfg)
			pcall(function() rayfieldLibrary:Notify(cfg) end)
		end

		-- ─────────────────────────────────────────────
		-- WINDOW
		-- ─────────────────────────────────────────────
		local mainWindow = rayfieldLibrary:CreateWindow({
			Name = "Cactus Hub • discord.gg/qMWFBWdcf",
			Icon = 0,
			LoadingTitle = "Loading",
			LoadingSubtitle = "Please wait...",
			Theme = "Default",
			ToggleUIKeybind = "K",
			DisableRayfieldPrompts = false,
			DisableBuildWarnings = true,
			ConfigurationSaving = {
				Enabled = true,
				FolderName = "CactusHub",
				FileName = "Config",
			},
			Discord = {
				Enabled = true,
				Invite = "qMWFBWdcf",
				RememberJoins = true,
			},
			KeySystem = false,
		})

		-- ─────────────────────────────────────────────
		-- FEATURE WRAPPERS
		-- ─────────────────────────────────────────────
		local function featureToggle(tab, config, fn)
			if not tab then return nil end
			local wrappedConfig = {}
			for k, v in pairs(config) do wrappedConfig[k] = v end
			local originalCallback = config.Callback or fn
			wrappedConfig.Callback = function(value)
				local cbOk, cbErr = pcall(originalCallback, value)
				if not cbOk then
					Logger:error("Feature", tostring(config.Name), "Toggle callback error", cbErr)
					safeNotify({
						Title = "Error: " .. tostring(config.Name),
						Content = tostring(cbErr):sub(1, 100),
						Duration = 5,
					})
				end
			end
			local created
			pcall(function() created = tab:CreateToggle(wrappedConfig) end)
			return created
		end

		local function featureButton(tab, config)
			if not tab then return nil end
			local wrappedConfig = {}
			for k, v in pairs(config) do wrappedConfig[k] = v end
			local originalCallback = config.Callback
			wrappedConfig.Callback = function()
				local cbOk, cbErr = pcall(originalCallback)
				if not cbOk then
					Logger:error("Feature", tostring(config.Name), "Button callback error", cbErr)
					safeNotify({
						Title = "Error: " .. tostring(config.Name),
						Content = tostring(cbErr):sub(1, 100),
						Duration = 5,
					})
				end
			end
			local created
			pcall(function() created = tab:CreateButton(wrappedConfig) end)
			return created
		end

		-- ─────────────────────────────────────────────
		-- TABS
		-- ─────────────────────────────────────────────
		local function safeCreateTab(name, icon)
			local t
			pcall(function() t = mainWindow:CreateTab(name, icon) end)
			return t
		end

		local mainTab     = safeCreateTab("Main",     74725529332053)
		local farmingTab  = safeCreateTab("Farming",  114367663524453)
		local gameTab     = safeCreateTab("Game",     77999805030576)
		local ufoTab      = safeCreateTab("Ufo Event",129180210444370)
		local indexTab    = safeCreateTab("Index",    123662711814867)
		local miscTab     = safeCreateTab("Misc",     83590339425734)
		local webhookTab  = safeCreateTab("Webhook",  84577758013974)
		local settingsTab = safeCreateTab("Settings", 120533439477016)
		local statsTab    = safeCreateTab("Stats",    102533388850982)

		-- ─────────────────────────────────────────────
		-- LABEL HELPERS (guard against nil tabs)
		-- ─────────────────────────────────────────────
		local function safeCreateLabel(tab, text)
			if not tab then return nil end
			local lbl
			pcall(function() lbl = tab:CreateLabel(text) end)
			return lbl
		end

		local function safeSetLabel(lbl, text)
			if not lbl then return end
			pcall(function() lbl:Set(text) end)
		end

		-- ─────────────────────────────────────────────
		-- STATUS LABEL (FPS / PING)
		-- ─────────────────────────────────────────────
		local fpsValue   = "..."
		local pingValue  = "..."
		local statusLabel = safeCreateLabel(mainTab, "FPS: ... / PING: ...ms")

		pcall(function()
			if not RunService then return end
			local frameCount = 0
			local lastTime   = tick()
			RunService.RenderStepped:Connect(function()
				frameCount = frameCount + 1
				local now = tick()
				if now - lastTime >= 1 then
					fpsValue   = math.floor(frameCount / (now - lastTime))
					frameCount = 0
					lastTime   = now
					safeSetLabel(
						statusLabel,
						"FPS: " .. tostring(fpsValue) .. " / PING: " .. tostring(pingValue) .. "ms"
					)
				end
			end)
		end)

		task.spawn(function()
			while true do
				pcall(function()
					if not StatsService then return end
					local item = StatsService.Network.ServerStatsItem["Data Ping"]
					if item then
						pingValue = math.floor(item:GetValue())
						safeSetLabel(
							statusLabel,
							"FPS: " .. tostring(fpsValue) .. " / PING: " .. tostring(pingValue) .. "ms"
						)
					end
				end)
				task.wait(1)
			end
		end)

		-- ─────────────────────────────────────────────
		-- MAIN TAB UI
		-- ─────────────────────────────────────────────
		featureButton(mainTab, {
			Name = "Copy Discord Invite",
			Callback = function()
				if HAS_SETCLIPBOARD then
					setclipboard("https://discord.gg/qMWFBWdcf")
					safeNotify({ Title = "Copied!", Content = "Discord invite link copied to clipboard.", Duration = 3 })
				else
					safeNotify({ Title = "Unsupported", Content = "setclipboard not available in this executor.", Duration = 3 })
				end
			end,
		})

		if mainTab then
			pcall(function() mainTab:CreateSection("Dashboard") end)
		end

		local dashboardBusy = false
		featureToggle(mainTab, {
			Name = "Dashboard [ SAVE GPU ]",
			CurrentValue = false,
			Flag = "DashboardToggle",
			Callback = function(Value)
				if dashboardBusy then return end
				dashboardBusy = true
				if Value then
					task.spawn(function()
						pcall(function()
							loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/no"))()
						end)
						safeNotify({ Title = "Dashboard", Content = "Dashboard enabled!", Duration = 3 })
						dashboardBusy = false
					end)
				else
					pcall(function()
						local gui = localPlayer.PlayerGui:FindFirstChild("__MAINHUD__")
						if gui then gui:Destroy() end
					end)
					safeNotify({ Title = "Dashboard", Content = "Dashboard closed!", Duration = 3 })
					dashboardBusy = false
				end
			end,
		})

		if mainTab then
			pcall(function()
				mainTab:CreateParagraph({ Title = "Enabled By Default", Content = "[+] Anti AFK" })
				mainTab:CreateParagraph({
					Title = "Latest Update",
					Content = "[+] Auto unlock machines \nMachines to unlock [] \n[+] Auto remove fruits from slimes \n[+] Fruits to remove []\n[+] Advanced slime gun bypass cooldown\n[+] Fixed Auto Send & Accept requests \n[+] Fixed Auto Upgrade not working \n[+] Auto stack mode [ Smart ] \nNormal : just stacks whenever selected reaches 1\nSmart : start stacking once rarest dice reaches 1\n[+] Specific Position ( Auto farm zone ), Save pos, clear pos\n[+] better potion use (now only uses if u run out)\n[+] better dices use (now only uses if u run out) \n[+] Improved Optimization & whatever caused memory leaks \n[+] Bug fixes",
				})
			end)
		end

		-- ─────────────────────────────────────────────
		-- AUTO REJOIN DISABLE
		-- ─────────────────────────────────────────────
		pcall(function()
			local m = require(ReplicatedStorage.Source.Features.AutoRejoin.AutoRejoinServiceClient)
			pcall(function() m:disable() end)
			if HAS_GETCONNECTIONS then
				pcall(function()
					for _, obj in ipairs({ ReplicatedStorage, localPlayer }) do
						for _, conn in ipairs(getconnections(obj.ChildAdded) or {}) do
							pcall(function()
								local src = tostring(conn.Function)
								if src:lower():find("rejoin") or src:lower():find("autorejoin") then
									conn:Disable()
								end
							end)
						end
					end
				end)
				pcall(function()
					if GuiService then
						for _, conn in ipairs(getconnections(GuiService.ErrorMessageChanged) or {}) do
							pcall(function()
								local src = tostring(conn.Function)
								if src:lower():find("rejoin") or src:lower():find("teleport") then
									conn:Disable()
								end
							end)
						end
					end
				end)
			end
			print("AutoRejoin disabled")
		end)

		-- ─────────────────────────────────────────────
		-- MODULE REFERENCES
		-- ─────────────────────────────────────────────
		local packages, dataServiceClient, Networker
		local networkerRoll, inventoryServiceClient, xpTransferServiceClient
		local rollServiceRemote, codeServiceRemote, inventoryServiceRemote
		local rebirthServiceRemote, zonesServiceRemote, upgradeServiceRemote
		local boostServiceRemote, offlineEarningsRemote, indexServiceRemote, lootServiceRemote
		local craftingServiceRemote, xpTransferMachineRemote, fruitExtractorRemote
		local sourceFolder
		local upgradeTreeModule, indexRewardsModule, boostServiceUtils, specialDiceUtils
		local rollSliceModule, slimesModule, mutationsModule, FruitsModule, SpecialRollUtils
		local boostKinds, diceItemIds
		local idToNameMap, nameToIdMap
		local SettingsState, SettingsServiceClient
		local ZonesModule, RecipesModule
		local upgradeServiceClient_new, dataServiceClient_new
		local modulesLoaded      = false
		local modulesLoadFailed  = false

		-- ─────────────────────────────────────────────
		-- MODULE LOADER
		-- ─────────────────────────────────────────────
		task.spawn(function()
			Logger:info("CactusHub", "ModuleLoad", "Starting module initialization...")
			local loadOk, loadErr = pcall(function()

				-- Packages
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

				-- DataService
				dataServiceClient = require(packages.DataService).client
				dataServiceClient:waitForData()

				-- Networker
				Networker = require(packages.Networker)

				-- Roll client
				local rollClient = {
					rareRollAnnouncement = function() end,
					rareRollAnnouncementV2 = function() end,
				}
				networkerRoll           = Networker.client.new("RollService", rollClient)
				inventoryServiceClient  = Networker.client.new("InventoryService")
				xpTransferServiceClient = Networker.client.new("XpTransferService")

				-- Remote function resolver
				local function getRemoteFunction(name)
					local folder = remotesFolder:FindFirstChild(name)
						or remotesFolder:WaitForChild(name, 10)
					if not folder then
						Logger:warn("CactusHub", "Remotes", "Remote folder not found: " .. name)
						return nil
					end
					local rf = folder:FindFirstChild("RemoteFunction")
						or folder:WaitForChild("RemoteFunction", 10)
					if not rf then
						Logger:warn("CactusHub", "Remotes", "RemoteFunction not found in: " .. name)
					end
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
				craftingServiceRemote  = getRemoteFunction("CraftingService")
				xpTransferMachineRemote = getRemoteFunction("XpTransferService")
				fruitExtractorRemote   = getRemoteFunction("FruitExtractorService")

				-- Source folder + modules
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

				pcall(function()
					RecipesModule = require(sourceFolder.Features.Crafting.Recipes)
				end)

				-- UpgradeServiceClient (deferred)
				task.spawn(function()
					local rs   = game:GetService("ReplicatedStorage")
					local ok1, ok2
					local attempts = 0
					repeat
						attempts = attempts + 1
						ok1, upgradeServiceClient_new = pcall(function()
							return require(rs.Source.Features.Upgrades.UpgradeServiceClient)
						end)
						ok2, dataServiceClient_new = pcall(function()
							return require(rs.Packages.DataService).client
						end)
						if not ok1 or not ok2 then
							task.wait(1)
						end
					until (ok1 and ok2) or attempts > 30

					if ok1 and ok2 then
						pcall(function()
							local upgradeClientInstance = {}
							upgradeClientInstance.networker = Networker.client.new(
								"UpgradeService",
								upgradeClientInstance
							)
							upgradeServiceClient_new.init(upgradeClientInstance)
							upgradeServiceClient_new = upgradeClientInstance
						end)
					else
						Logger:warn("CactusHub", "ModuleLoad", "UpgradeServiceClient deferred load timed out")
					end
				end)
			end)

			if not loadOk then
				modulesLoadFailed = true
				Logger:error("CactusHub", "ModuleLoad", "Module initialization failed", loadErr)
				safeNotify({
					Title   = "CactusHub — Load Warning",
					Content = "Some modules failed: " .. tostring(loadErr):sub(1, 120) .. "\nSome features may not work.",
					Duration = 8,
				})
			else
				Logger:info("CactusHub", "ModuleLoad", "All modules loaded successfully!")
				safeNotify({
					Title    = "Cactus Hub",
					Content  = "All modules loaded! Features are ready.",
					Duration = 4,
				})
			end

			-- Set flag regardless so consumers don't hang
			modulesLoaded = true
		end)

		-- ─────────────────────────────────────────────
		-- CONSTANTS & SHARED STATE
		-- ─────────────────────────────────────────────
		local CATEGORY_IDS  = { "basic", "shiny", "big", "huge", "inverted" }
		local MUTATION_ODDS = { basic = nil, shiny = 0.004, big = 0.01, huge = 0.001, inverted = 0.0004 }
		local DICE          = { "golden", "diamond", "void", "galaxy" }
		local ALL_FRUITS    = {}

		task.spawn(function()
			repeat task.wait(0.5) until modulesLoaded
			if FruitsModule then
				pcall(function() ALL_FRUITS = FruitsModule.getSortedFruits() end)
			end
		end)

		local luckValueLocal    = 1
		local settingsClientRef = nil

		task.spawn(function()
			repeat task.wait(0.5) until modulesLoaded
			if not Networker or not SettingsServiceClient then return end
			pcall(function()
				settingsClientRef = {}
				settingsClientRef.networker = Networker.client.new("SettingsService", settingsClientRef)
				SettingsServiceClient.init(settingsClientRef)
			end)
		end)

		local function setLuckEnabled(enabled)
			if not SettingsServiceClient or not settingsClientRef then return end
			pcall(SettingsServiceClient.set, settingsClientRef, "luckOverrideEnabled", enabled)
			task.wait(0.3)
		end

		local function setLuck(value)
			if not SettingsServiceClient or not settingsClientRef then return end
			local clamped = math.min(value, 16384)
			pcall(SettingsServiceClient.set, settingsClientRef, "luckOverrideValue", clamped)
			luckValueLocal = clamped
			task.wait(0.3)
		end

		local function calcOptimalLuck(effectiveOdds)
			if not effectiveOdds or effectiveOdds <= 0 then return 16384 end
			return math.min(math.max(1, math.floor((1 / effectiveOdds) * 0.63)), 16384)
		end

		local function formatOdds(odds)
			if not odds or odds <= 0 then return "N/A" end
			local n = math.floor(1 / odds + 0.5)
			if n >= 1e18 then return string.format("1 in %.1fQn", n / 1e18)
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
			local data = dataServiceClient:get("index") or {}
			return ((data.categories or {})[catId] or {}).unlocked or {}
		end

		local function getTotalSlimes()
			if not slimesModule then return 0 end
			local ok2, sorted = pcall(function() return slimesModule.getSortedSlimes() end)
			return (ok2 and sorted) and #sorted or 0
		end

		local function getUnlockedCount(catId)
			local unlocked = getUnlockedIndex(catId)
			local count = 0
			for _, v in pairs(unlocked) do
				if v == true then count = count + 1 end
			end
			return count
		end

		local function getMissingSlimes(catId)
			if not slimesModule then return {} end
			local ok2, allSlimes = pcall(function() return slimesModule.getSortedSlimes() end)
			if not ok2 or not allSlimes then return {} end
			local unlocked = getUnlockedIndex(catId)
			local missing  = {}
			for _, slime in ipairs(allSlimes) do
				if not unlocked[slime.id] then
					table.insert(missing, slime)
				end
			end
			table.sort(missing, function(a, b)
				return getEffectiveOdds(a, catId) > getEffectiveOdds(b, catId)
			end)
			return missing
		end

		local function getBestSlimeUid()
			if not dataServiceClient then return nil end
			local stats    = dataServiceClient:get("stats") or {}
			local rarestRoll = stats.rarestRoll
			if not rarestRoll or not rarestRoll.slimeData then return nil end
			local slimeData = rarestRoll.slimeData
			local mutations = slimeData.mutations or {}
			local inventory = dataServiceClient:get("inventory") or {}
			for uid, data in pairs(inventory) do
				if type(data) == "table" and data.id == slimeData.id then
					local match = true
					for mutKey, mutValue in pairs(mutations) do
						if data.mutations and data.mutations[mutKey] ~= mutValue then
							match = false
							break
						end
					end
					if match then return uid end
				end
			end
			return nil
		end

		-- ─────────────────────────────────────────────
		-- ZONE BOUNDARY (with mutex-style lock)
		-- ─────────────────────────────────────────────
		local zoneBoundaryCache  = { zoneId = nil, min = nil, max = nil, center = nil }
		local zoneCacheLock      = false -- simple busy-flag guard

		local function getZoneBoundary(zoneId)
			if not zoneId then return nil end
			local zoneIdStr = tostring(zoneId)
			if zoneBoundaryCache.zoneId == zoneIdStr and zoneBoundaryCache.min then
				return zoneBoundaryCache
			end
			if zoneCacheLock then return zoneBoundaryCache end
			zoneCacheLock = true
			local resultCache
			local ok2, result = pcall(function()
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
				local halfX  = size.X / 2
				local halfZ  = size.Z / 2
				local shrink = 8
				local minPos = Vector3.new(pos.X - halfX + shrink, pos.Y, pos.Z - halfZ + shrink)
				local maxPos = Vector3.new(pos.X + halfX - shrink, pos.Y, pos.Z + halfZ - shrink)
				local center = Vector3.new(pos.X, pos.Y, pos.Z)
				return { zoneId = zoneIdStr, min = minPos, max = maxPos, center = center }
			end)
			if ok2 and result then
				zoneBoundaryCache = result
				resultCache = result
			end
			zoneCacheLock = false
			return resultCache or zoneBoundaryCache
		end

		local function isOutsideBoundary(position, boundary)
			if not boundary or not boundary.min or not boundary.max then return false end
			return position.X < boundary.min.X or position.X > boundary.max.X
				or position.Z < boundary.min.Z or position.Z > boundary.max.Z
		end

		local function isEnemyInsideBoundary(enemy, boundary)
			if not boundary then return true end
			local root = enemy:FindFirstChild("HumanoidRootPart")
				or enemy.PrimaryPart
				or enemy:FindFirstChildWhichIsA("BasePart")
			if not root then return false end
			return not isOutsideBoundary(root.Position, boundary)
		end

		-- ─────────────────────────────────────────────
		-- ENEMY / AUTO-FARM STATE
		-- ─────────────────────────────────────────────
		local RANGE = 50
		local cachedContainer, cachedEnemies, lastCacheTime = nil, {}, 0
		local currentTarget, tweenConn = nil, nil
		local autoFarmWalkSpeed = 100
		local enemySettings = {
			TeleportStyle     = "Walk",
			TargetPriorities  = { ["Most Coins & Goop"] = true },
			AutoFarm          = false,
			MutationFilter    = "Any",
		}

		local noclipEnabled = false
		local noclipConn    = nil

		local function setNoclip(enabled)
			noclipEnabled = enabled
			if noclipConn then
				pcall(function() noclipConn:Disconnect() end)
				noclipConn = nil
			end
			if enabled then
				noclipConn = RunService.Stepped:Connect(function()
					local char = localPlayer.Character
					if not char then return end
					pcall(function()
						for _, part in ipairs(char:GetDescendants()) do
							if part:IsA("BasePart") then
								part.CanCollide = false
							end
						end
					end)
				end)
			else
				pcall(function()
					local char = localPlayer.Character
					if char then
						for _, part in ipairs(char:GetDescendants()) do
							if part:IsA("BasePart") then
								part.CanCollide = true
							end
						end
					end
				end)
			end
		end

		local function getGameplayContainer()
			if cachedContainer and cachedContainer.Parent then return cachedContainer end
			for _, child in ipairs(workspace:GetChildren()) do
				if child.Name:match("^Gameplay") then
					cachedContainer = child
					return child
				end
			end
			return nil
		end

		local function getEnemyRoot(enemy)
			return enemy:FindFirstChild("HumanoidRootPart")
				or enemy.PrimaryPart
				or enemy:FindFirstChildWhichIsA("BasePart")
		end

		local function getMutation(enemy)
			for _, mut in ipairs({ "inverted", "huge", "shiny", "big" }) do
				local ok2, val = pcall(function() return enemy:GetAttribute(mut) end)
				if ok2 and val then return mut end
				if enemy:FindFirstChild(mut) then return mut end
				local m = enemy:FindFirstChild("Mutation")
				if m and m.Value == mut then return mut end
				if enemy.Name:lower():find(mut) then return mut end
			end
			return nil
		end

		local function isAlive(enemy)
			if not enemy or not enemy.Parent then return false end
			local h = enemy:FindFirstChildWhichIsA("Humanoid")
			if h and h.Health <= 0 then return false end
			local hp = enemy:GetAttribute("health") or enemy:GetAttribute("currentHealth")
			if hp and hp <= 0 then return false end
			return true
		end

		local function matchesMutationFilter(enemy)
			if enemySettings.MutationFilter == "Any" then return true end
			return getMutation(enemy) == enemySettings.MutationFilter:lower()
		end

		local function refreshEnemyCache()
			if tick() - lastCacheTime < 2 then return end
			lastCacheTime = tick()
			cachedEnemies = {}
			local container = getGameplayContainer()
			if not container then return end
			local enemyFolder = container:FindFirstChild("Enemies")
			if not enemyFolder then return end
			for _, enemy in ipairs(enemyFolder:GetChildren()) do
				if enemy:IsA("Model") then
					table.insert(cachedEnemies, enemy)
				end
			end
		end

		local function getEnemyScore(enemy, rootPos)
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
		end

		local function computeScores(rootPos, boundary)
			local entries = {}
			for _, enemy in ipairs(cachedEnemies) do
				if isAlive(enemy) and matchesMutationFilter(enemy) then
					if not boundary or isEnemyInsideBoundary(enemy, boundary) then
						local e = getEnemyScore(enemy, rootPos)
						if e then table.insert(entries, e) end
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
			local pri = enemySettings.TargetPriorities
			for _, e in ipairs(entries) do
				local s = 0
				if pri["Most Coins & Goop"] then
					s = s + ((maxCoins > 0 and e.coins / maxCoins or 0) + (maxGoop > 0 and e.goop / maxGoop or 0)) / 2
				end
				if pri["Closest"]  then s = s + (maxDist   > 0 and 1 - e.dist   / maxDist   or 0) end
				if pri["Lowest HP"] then s = s + (maxHealth > 0 and 1 - e.health / maxHealth or 0) end
				if pri["Mutations Only"] then s = s + (getMutation(e.enemy) and 1 or 0) end
				scores[e.enemy] = s
			end
			return scores, entries
		end

		local function getSafePosition(targetCFrame, boundary)
			local pos = targetCFrame.Position
			if boundary then
				pos = Vector3.new(
					math.clamp(pos.X, boundary.min.X, boundary.max.X),
					pos.Y,
					math.clamp(pos.Z, boundary.min.Z, boundary.max.Z)
				)
			end
			local origin = pos + Vector3.new(0, 50, 0)
			local result = workspace:Raycast(origin, Vector3.new(0, -100, 0))
			if result then return result.Position + Vector3.new(0, 3, 0) end
			return pos + Vector3.new(0, 3, 0)
		end

		local autoWalkConn = nil

		local function stopAutoWalk()
			if autoWalkConn then
				pcall(function() autoWalkConn:Disconnect() end)
				autoWalkConn = nil
			end
			pcall(function()
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
			local char = localPlayer.Character
			if not char then return end
			local root = getEnemyRoot(enemy)
			if not root then return end
			local safePos  = getSafePosition(root.CFrame, boundary)
			local targetCF = CFrame.new(safePos)

			if enemySettings.TeleportStyle == "Instant" then
				if tweenConn then pcall(function() tweenConn:Disconnect() end) tweenConn = nil end
				stopAutoWalk()
				pcall(function() char:PivotTo(targetCF) end)

			elseif enemySettings.TeleportStyle == "Smooth" then
				if tweenConn then pcall(function() tweenConn:Disconnect() end) tweenConn = nil end
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
						if alpha >= 1 then
							if tweenConn then tweenConn:Disconnect() tweenConn = nil end
						end
					end)
				end)

			elseif enemySettings.TeleportStyle == "Walk" then
				if tweenConn then pcall(function() tweenConn:Disconnect() end) tweenConn = nil end
				stopAutoWalk()
				local hum = char:FindFirstChildWhichIsA("Humanoid")
				if not hum then return end
				hum.WalkSpeed = autoFarmWalkSpeed
				hum:MoveTo(safePos)
				autoWalkConn = RunService.Heartbeat:Connect(function()
					pcall(function()
						if not char or not char.Parent or not isAlive(enemy) then
							stopAutoWalk()
							return
						end
						local rp = char:FindFirstChild("HumanoidRootPart")
						if not rp then stopAutoWalk() return end
						if boundary and isOutsideBoundary(rp.Position, boundary) then
							stopAutoWalk()
							local safeCenter = getSafePosition(CFrame.new(boundary.center), boundary)
							char:PivotTo(CFrame.new(safeCenter))
							return
						end
						local dist = (rp.Position - safePos).Magnitude
						if dist < 5 then
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
		end

		local function selectTarget(boundary)
			local char = localPlayer.Character
			if not char then return nil end
			local rp = char:FindFirstChild("HumanoidRootPart")
			if not rp then return nil end
			local scores    = computeScores(rp.Position, boundary)
			local best, bestScore = nil, -math.huge
			for enemy, score in pairs(scores) do
				if score > bestScore then bestScore = score best = enemy end
			end
			return best
		end

		local function selectCombatTarget()
			local char = localPlayer.Character
			if not char then return nil, nil end
			local root = char:FindFirstChild("HumanoidRootPart")
			if not root then return nil, nil end
			local gp = getGameplayContainer()
			if not gp then return nil, nil end
			local folder = gp:FindFirstChild("Enemies")
			if not folder then return nil, nil end
			local priorityFlag = rayfieldLibrary.Flags.CombatTargetPriority
			local priority = priorityFlag
				and type(priorityFlag.CurrentOption) == "table"
				and priorityFlag.CurrentOption[1]
				or "Closest"
			local bestEnemy, bestId, bestScore = nil, nil, nil
			for _, e in ipairs(folder:GetChildren()) do
				if e:IsA("Model") and isAlive(e) then
					local primary = getEnemyRoot(e)
					if primary then
						local dist = (primary.Position - root.Position).Magnitude
						local id   = tonumber(e.Name)
						local score
						if priority == "Closest" then
							score = -dist
						elseif priority == "Lowest HP" then
							local hp  = e:GetAttribute("health") or e:GetAttribute("currentHealth") or 0
							local hum = e:FindFirstChildWhichIsA("Humanoid")
							if hum then hp = hum.Health end
							score = -hp
						elseif priority == "Highest HP" then
							local hp  = e:GetAttribute("health") or e:GetAttribute("currentHealth") or 0
							local hum = e:FindFirstChildWhichIsA("Humanoid")
							if hum then hp = hum.Health end
							score = hp
						elseif priority == "Most Coins & Goop" then
							local coins = e:GetAttribute("reward") or e:GetAttribute("coins") or 0
							local goop  = e:GetAttribute("goop") or 0
							score = coins + goop
						else
							score = -dist
						end
						if bestScore == nil or score > bestScore then
							bestScore = score
							bestEnemy = e
							bestId    = id
						end
					end
				end
			end
			return bestEnemy, bestId
		end

		local lastBoundaryRefresh = 0

		if RunService then
			RunService.Heartbeat:Connect(function()
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
					local currentZoneId = dataServiceClient and dataServiceClient:get("zone") or nil
					local boundary      = nil
					if currentZoneId then
						if tick() - lastBoundaryRefresh > 5 then
							lastBoundaryRefresh = tick()
							-- reset cache safely (not mid-read)
							if not zoneCacheLock then
								zoneBoundaryCache = { zoneId = nil, min = nil, max = nil, center = nil }
							end
						end
						boundary = getZoneBoundary(currentZoneId)
					end
					if boundary and isOutsideBoundary(charRoot.Position, boundary) then
						stopAutoWalk()
						currentTarget = nil
						local safeCenter = getSafePosition(CFrame.new(boundary.center), boundary)
						char:PivotTo(CFrame.new(safeCenter))
						task.wait(0.5)
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
		end

		-- ─────────────────────────────────────────────
		-- FARMING TAB — ROLLING
		-- ─────────────────────────────────────────────
		if farmingTab then
			pcall(function() farmingTab:CreateSection("Rolling") end)
		end

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
							safeNotify({ Title = "Error", Content = "RollService remote not loaded", Duration = 4 })
							break
						end
						pcall(function() rollServiceRemote:InvokeServer("requestRoll") end)
						task.wait(rollSliceModule and pcall(function() return rollSliceModule.rollTime() end) and rollSliceModule.rollTime() or 0.5)
					end
				end)
			end,
		})

		local selectedDice  = { golden = true, diamond = true, void = true, galaxy = true }
		local stackActive   = false
		local releaseActive = false
		local paused        = { golden = false, diamond = false, void = false, galaxy = false }
		local stackMode     = "Normal"

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

		if farmingTab then
			pcall(function()
				farmingTab:CreateDropdown({
					Name            = "Stack Mode",
					Options         = { "Normal", "Smart" },
					CurrentOption   = { "Normal" },
					MultipleOptions = false,
					Flag            = "StackMode",
					Callback        = function(opt)
						stackMode = type(opt) == "table" and opt[1] or opt
					end,
				})
			end)
		end

		featureToggle(farmingTab, {
			Name = "Auto Release Dice", CurrentValue = false, Flag = "autorelease",
			Callback = function(v) releaseActive = v end,
		})

		if farmingTab then
			pcall(function()
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
			end)
		end

		local DiceLuckLabel = safeCreateLabel(farmingTab, "Total Stacked: x0")

		task.spawn(function()
			while true do
				task.wait(0.5)
				pcall(function()
					if not dataServiceClient or not SpecialRollUtils then return end
					local upgrades   = dataServiceClient:get("upgrades") or {}
					local progression = dataServiceClient:get("specialRollProgression") or {}
					local totalStacked = 0
					for _, dice in ipairs(DICE) do
						local prog  = progression[dice]
						local rolls = prog and prog.rollsUntilNext or math.huge
						if rolls <= 1 then
							local ok2, mult = pcall(SpecialRollUtils.getLuckMultiplier, dice, upgrades)
							if ok2 then totalStacked = totalStacked + (mult or 0) end
						end
					end
					safeSetLabel(DiceLuckLabel, "Total Stacked: x" .. string.format("%.1f", totalStacked))
					if not stackActive or not networkerRoll then return end
					local toWatch = {}
					for _, dice in ipairs(DICE) do
						if selectedDice[dice] then
							local ok2, unlocked = pcall(SpecialRollUtils.isUnlocked, dice, upgrades)
							if ok2 and unlocked then table.insert(toWatch, dice) end
						end
					end
					if #toWatch == 0 then return end
					local currentMode = (rayfieldLibrary.Flags.StackMode
						and rayfieldLibrary.Flags.StackMode.CurrentOption
						and rayfieldLibrary.Flags.StackMode.CurrentOption[1]) or "Normal"
					if currentMode == "Normal" then
						local allReady = true
						for _, dice in ipairs(toWatch) do
							local prog  = progression[dice]
							local rolls = prog and prog.rollsUntilNext or math.huge
							if rolls > 1 then
								allReady = false
								if paused[dice] then
									pcall(function() networkerRoll:fetch("requestSetSpecialRollPaused", dice, false) end)
									paused[dice] = false
								end
							else
								if not paused[dice] then
									pcall(function() networkerRoll:fetch("requestSetSpecialRollPaused", dice, true) end)
									paused[dice] = true
								end
							end
						end
						if allReady and releaseActive then
							for _, dice in ipairs(toWatch) do
								pcall(function() networkerRoll:fetch("requestSetSpecialRollPaused", dice, false) end)
								paused[dice] = false
							end
							safeNotify({ Title = "Unleashed!", Content = "All selected dice stacked — releasing now.", Duration = 3 })
							task.wait(2)
						end
					elseif currentMode == "Smart" then
						local smartOrder = { "galaxy", "void", "diamond", "golden" }
						local readyMap = {}
						for _, dice in ipairs(toWatch) do
							local prog  = progression[dice]
							local rolls = prog and prog.rollsUntilNext or math.huge
							readyMap[dice] = rolls <= 1
						end
						local galaxyInWatch = false
						for _, d in ipairs(toWatch) do if d == "galaxy" then galaxyInWatch = true break end end
						local galaxyPaused = galaxyInWatch and paused["galaxy"]
						if galaxyInWatch and not galaxyPaused then
							for _, dice in ipairs(toWatch) do
								if dice ~= "galaxy" then
									if paused[dice] then
										pcall(function() networkerRoll:fetch("requestSetSpecialRollPaused", dice, false) end)
										paused[dice] = false
									end
								end
							end
							if readyMap["galaxy"] and not paused["galaxy"] then
								pcall(function() networkerRoll:fetch("requestSetSpecialRollPaused", "galaxy", true) end)
								paused["galaxy"] = true
							end
						else
							for _, dice in ipairs(smartOrder) do
								local inWatch = false
								for _, d in ipairs(toWatch) do if d == dice then inWatch = true break end end
								if inWatch then
									if not paused[dice] then
										local prevPaused = true
										for _, prev in ipairs(smartOrder) do
											if prev == dice then break end
											local prevInWatch = false
											for _, d in ipairs(toWatch) do if d == prev then prevInWatch = true break end end
											if prevInWatch and not paused[prev] then prevPaused = false break end
										end
										if prevPaused and readyMap[dice] then
											pcall(function() networkerRoll:fetch("requestSetSpecialRollPaused", dice, true) end)
											paused[dice] = true
										elseif not readyMap[dice] then
											if paused[dice] then
												pcall(function() networkerRoll:fetch("requestSetSpecialRollPaused", dice, false) end)
												paused[dice] = false
											end
										end
									end
								end
							end
							local allPaused = true
							for _, dice in ipairs(toWatch) do
								if not paused[dice] then allPaused = false break end
							end
							if allPaused and releaseActive then
								for _, dice in ipairs(toWatch) do
									pcall(function() networkerRoll:fetch("requestSetSpecialRollPaused", dice, false) end)
									paused[dice] = false
								end
								safeNotify({ Title = "Unleashed!", Content = "Smart stack complete — releasing now.", Duration = 3 })
								task.wait(2)
							end
						end
					end
				end)
			end
		end)

		-- ─────────────────────────────────────────────
		-- FARMING TAB — ZONES
		-- ─────────────────────────────────────────────
		if farmingTab then
			pcall(function() farmingTab:CreateSection("Zones") end)
		end

		local savedFarmPosition      = nil
		local savedFarmPositionLabel = nil

		pcall(function()
			if not farmingTab then return end
			local zoneOptions = { "Best Unlocked", "Saved Position" }
			local totalZones  = 40
			if ZonesModule then
				pcall(function() totalZones = ZonesModule.getMaxZone() end)
			end
			for i = 1, totalZones do
				local zoneName = "Zone " .. i
				if ZonesModule then
					pcall(function()
						local zone = ZonesModule.getZone(i)
						if zone and zone.name then
							zoneName = zone.name .. " (Zone " .. i .. ")"
						end
					end)
				end
				table.insert(zoneOptions, zoneName)
			end
			farmingTab:CreateDropdown({
				Name            = "Zone Target",
				Options         = zoneOptions,
				CurrentOption   = { "Best Unlocked" },
				MultipleOptions = false,
				Flag            = "FarmingZoneTarget",
				Callback        = function() end,
			})
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
						pcall(function()
							local targetOption = "Best Unlocked"
							if rayfieldLibrary.Flags.FarmingZoneTarget
								and rayfieldLibrary.Flags.FarmingZoneTarget.CurrentOption
							then
								targetOption = rayfieldLibrary.Flags.FarmingZoneTarget.CurrentOption[1] or "Best Unlocked"
							end
							if targetOption == "Saved Position" and savedFarmPosition then
								local char = localPlayer.Character
								local root = char and char:FindFirstChild("HumanoidRootPart")
								if root then char:PivotTo(CFrame.new(savedFarmPosition)) end
								return
							end
							if not zonesServiceRemote then return end
							local currentZone = dataServiceClient and (dataServiceClient:get("zone") or 1) or 1
							local targetZone
							if targetOption == "Best Unlocked" then
								targetZone = dataServiceClient and (dataServiceClient:get("maxZone") or 1) or 1
							else
								targetZone = tonumber(targetOption:match("Zone (%d+)"))
							end
							if targetZone and targetZone > 0 and currentZone ~= targetZone then
								if tick() - lastTeleportTime > 3 then
									pcall(function() zonesServiceRemote:InvokeServer("requestTeleportZone", targetZone) end)
									lastTeleportTime = tick()
									if not zoneCacheLock then
										zoneBoundaryCache = { zoneId = nil, min = nil, max = nil, center = nil }
									end
								end
							end
						end)
						task.wait(5)
					end
				end)
			end,
		})

		savedFarmPositionLabel = safeCreateLabel(farmingTab, "Saved Position: None")

		featureButton(farmingTab, {
			Name = "Save Current Position",
			Callback = function()
				local char = localPlayer.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if not root then
					safeNotify({ Title = "Error", Content = "HumanoidRootPart not found", Duration = 3 })
					return
				end
				savedFarmPosition = root.Position
				safeSetLabel(
					savedFarmPositionLabel,
					string.format("Saved: %.1f, %.1f, %.1f", root.Position.X, root.Position.Y, root.Position.Z)
				)
				safeNotify({ Title = "Position Saved", Content = "Select Saved Position in Zone Target", Duration = 4 })
			end,
		})

		featureButton(farmingTab, {
			Name = "Clear Saved Position",
			Callback = function()
				savedFarmPosition = nil
				safeSetLabel(savedFarmPositionLabel, "Saved Position: None")
				safeNotify({ Title = "Position Cleared", Content = "Normal zone targeting restored", Duration = 3 })
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

		-- ─────────────────────────────────────────────
		-- FARMING TAB — MACHINES
		-- ─────────────────────────────────────────────
		if farmingTab then
			pcall(function() farmingTab:CreateSection("Machines") end)
			pcall(function()
				farmingTab:CreateDropdown({
					Name            = "Machines to Unlock",
					Options         = { "All", "Crafting Machine", "XP Transfer Machine", "Fruit Extractor" },
					CurrentOption   = { "All" },
					MultipleOptions = true,
					Flag            = "MachineUnlockTarget",
					Callback        = function() end,
				})
			end)
		end

		featureToggle(farmingTab, {
			Name         = "Auto Unlock Machines",
			CurrentValue = false,
			Flag         = "FarmingAutoUnlockMachines",
			Callback     = function(enabled)
				if not enabled then return end
				task.spawn(function()
					while true do
						local flag = rayfieldLibrary.Flags.FarmingAutoUnlockMachines
						if not flag or not flag.CurrentValue then break end
						pcall(function()
							local selected = rayfieldLibrary.Flags.MachineUnlockTarget
								and rayfieldLibrary.Flags.MachineUnlockTarget.CurrentOption
								or { "All" }
							local selSet = {}
							for _, s in ipairs(selected) do selSet[s] = true end
							local unlockAll = selSet["All"]
							if (unlockAll or selSet["Crafting Machine"]) and craftingServiceRemote then
								pcall(function() craftingServiceRemote:InvokeServer("requestUnlockMachine") end)
							end
							if (unlockAll or selSet["XP Transfer Machine"]) and xpTransferMachineRemote then
								pcall(function() xpTransferMachineRemote:InvokeServer("requestUnlockMachine") end)
							end
							if (unlockAll or selSet["Fruit Extractor"]) and fruitExtractorRemote then
								pcall(function() fruitExtractorRemote:InvokeServer("requestUnlockMachine") end)
							end
						end)
						task.wait(10)
					end
				end)
			end,
		})

		-- ─────────────────────────────────────────────
		-- FARMING TAB — SLIMES & XP
		-- ─────────────────────────────────────────────
		if farmingTab then
			pcall(function() farmingTab:CreateSection("Slimes & XP") end)
		end

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

		local function getOwnedFruitIds()
			if not dataServiceClient or not FruitsModule then return {} end
			local items  = dataServiceClient:get("items") or {}
			local owned  = {}
			for _, f in ipairs(ALL_FRUITS) do
				if (items[f.id] or 0) > 0 then owned[f.id] = true end
			end
			return owned
		end

		local function slimeHasFruit(slimeData, fruitId)
			if type(slimeData) ~= "table" or not FruitsModule then return false end
			local fruitDef = FruitsModule.getFruit(fruitId)
			if not fruitDef then return false end
			local trees = slimeData.unlockedTrees
			return type(trees) == "table" and trees[fruitDef.treeId] == true
		end

		local function getBestSlimeEntry()
			if not dataServiceClient then return nil, nil end
			local stats   = dataServiceClient:get("stats") or {}
			local rarest  = stats.rarestRoll
			if not rarest or not rarest.slimeData then return nil, nil end
			local rarestId        = rarest.slimeData.id
			local rarestMutations = rarest.slimeData.mutations or {}
			local equipped = dataServiceClient:get("equipped") or {}
			local inv      = dataServiceClient:get("inventory") or {}
			for _, slimeKey in pairs(equipped) do
				if type(slimeKey) == "string" and slimeKey:sub(1, 1) == "." then
					local data = inv[slimeKey]
					if type(data) == "table" and data.id == rarestId then
						local match = true
						for mutKey, mutVal in pairs(rarestMutations) do
							if not data.mutations or data.mutations[mutKey] ~= mutVal then
								match = false break
							end
						end
						if match then return slimeKey, data end
					end
				end
			end
			for _, slimeKey in pairs(equipped) do
				if type(slimeKey) == "string" and slimeKey:sub(1, 1) == "." then
					local data = inv[slimeKey]
					if type(data) == "table" then return slimeKey, data end
				end
			end
			return nil, nil
		end

		local function getTargetSlimes()
			if not dataServiceClient then return {} end
			if selectedSlimeMode == "Best" then
				local key, data = getBestSlimeEntry()
				if key and data then return { { key = key, data = data } } end
				return {}
			else
				local equipped = dataServiceClient:get("equipped") or {}
				local result   = {}
				for _, slimeKey in ipairs(equipped) do
					if type(slimeKey) == "string" and slimeKey:sub(1, 1) == "." then
						local inv  = dataServiceClient:get("inventory") or {}
						local data = inv[slimeKey]
						if type(data) == "table" then table.insert(result, { key = slimeKey, data = data }) end
					end
				end
				return result
			end
		end

		local function resolveFruitList()
			local owned = getOwnedFruitIds()
			if selectedFruitIds[1] == "ANY" then
				local result = {}
				for _, f in ipairs(ALL_FRUITS) do if owned[f.id] then table.insert(result, f.id) end end
				return result
			else
				local result = {}
				for _, fid in ipairs(selectedFruitIds) do if owned[fid] then table.insert(result, fid) end end
				return result
			end
		end

		local function doFeed()
			if not inventoryServiceClient then return end
			local targets     = getTargetSlimes()
			local fruitsToFeed = resolveFruitList()
			if #targets == 0 or #fruitsToFeed == 0 then return end
			for _, entry in ipairs(targets) do
				for _, fruitId in ipairs(fruitsToFeed) do
					if not slimeHasFruit(entry.data, fruitId) then
						pcall(function() inventoryServiceClient:fetch("requestUseFruit", fruitId, entry.key) end)
					end
				end
			end
		end

		featureToggle(farmingTab, {
			Name         = "Auto Feed Fruits to Slime(s)",
			CurrentValue = false,
			Flag         = "AutoFeedToggle",
			Callback     = function(value)
				autoFeedEnabled = value
				if feedConnection then
					pcall(function() feedConnection:Disconnect() end)
					feedConnection = nil
				end
				if value then
					task.spawn(function()
						while autoFeedEnabled do
							pcall(doFeed)
							task.wait(1)
						end
					end)
				end
			end,
		})

		if farmingTab then
			pcall(function()
				farmingTab:CreateDropdown({
					Name = "Slimes to Feed", Options = { "Best", "Split Across Team" },
					CurrentOption = { "Best" }, MultipleOptions = false, Flag = "SlimeModeDropdown",
					Callback = function(option)
						selectedSlimeMode = type(option) == "table" and option[1] or option
					end,
				})
			end)
		end

		pcall(function()
			if not farmingTab then return end
			local fruitOptions = { "Any" }
			local labelToId    = {}
			local fruitNames   = {}
			for _, f in ipairs(FruitsModule and FruitsModule.getSortedFruits() or {}) do
				table.insert(fruitNames, f.powerName)
				labelToId[f.powerName] = f.id
			end
			table.sort(fruitNames)
			for _, name in ipairs(fruitNames) do table.insert(fruitOptions, name) end
			farmingTab:CreateDropdown({
				Name = "Fruits to Feed", Options = fruitOptions, CurrentOption = { "Any" },
				MultipleOptions = true, Flag = "FruitDropdown",
				Callback = function(options)
					local picked = type(options) == "table" and options or { options }
					selectedFruitIds = {}
					for _, label in ipairs(picked) do
						if label == "Any" then
							selectedFruitIds = { "ANY" }
							return
						else
							table.insert(selectedFruitIds, labelToId[label])
						end
					end
					if #selectedFruitIds == 0 then selectedFruitIds = { "ANY" } end
				end,
			})
		end)

		if farmingTab then
			pcall(function()
				farmingTab:CreateToggle({
					Name = "Auto Transfer XP", CurrentValue = false,
					Flag = "FarmingTransferXP", Callback = function() end,
				})
				farmingTab:CreateDropdown({
					Name = "Transfer To", Options = { "Best Slime", "Whole Team" },
					CurrentOption = { "Best Slime" }, MultipleOptions = false,
					Flag = "FarmingTransferTarget", Callback = function() end,
				})
				farmingTab:CreateDropdown({
					Name = "Transfer From", Options = { "All Slimes", "Unequipped With XP" },
					CurrentOption = { "Unequipped With XP" }, MultipleOptions = false,
					Flag = "FarmingTransferSource", Callback = function() end,
				})
			end)
		end

		task.spawn(function()
			while true do
				task.wait(30)
				pcall(function()
					if not (rayfieldLibrary.Flags.FarmingTransferXP
						and rayfieldLibrary.Flags.FarmingTransferXP.CurrentValue) then return end
					if not dataServiceClient or not xpTransferServiceClient then return end
					local inventory = dataServiceClient:get("inventory") or {}
					local equipped  = dataServiceClient:get("equipped") or {}
					local teamSet   = {}
					for _, uid in ipairs(equipped) do teamSet[uid] = true end
					local targetOption = rayfieldLibrary.Flags.FarmingTransferTarget
						and rayfieldLibrary.Flags.FarmingTransferTarget.CurrentOption
						and rayfieldLibrary.Flags.FarmingTransferTarget.CurrentOption[1]
						or "Best Slime"
					local sourceOption = rayfieldLibrary.Flags.FarmingTransferSource
						and rayfieldLibrary.Flags.FarmingTransferSource.CurrentOption
						and rayfieldLibrary.Flags.FarmingTransferSource.CurrentOption[1]
						or "Unequipped With XP"
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
								local hasXp = (type(data) == "table" and (data.xp or 0) > 0)
									or (type(data) == "number" and data > 0)
								if (sourceOption == "Unequipped With XP" and not isEquipped and hasXp)
									or (sourceOption == "All Slimes" and hasXp)
								then
									pcall(function()
										xpTransferServiceClient:fetch("requestTransferXp", uid, target)
									end)
									task.wait(0.5)
								end
							end
						end
					end
				end)
			end
		end)

		-- ─────────────────────────────────────────────
		-- FARMING TAB — LOOT
		-- ─────────────────────────────────────────────
		if farmingTab then
			pcall(function() farmingTab:CreateSection("Loot") end)
		end

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
										local id = item:GetAttribute("uniqueId")
											or item:GetAttribute("id")
											or item.Name
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

		-- ─────────────────────────────────────────────
		-- FARMING TAB — FRUIT EXTRACTOR
		-- ─────────────────────────────────────────────
		pcall(function()
			if not farmingTab then return end
			farmingTab:CreateSection("Fruit Extractor")

			local autoExtractEnabled        = false
			local selectedExtractFruitIds   = { "ANY" }
			local selectedExtractSlimeMode  = "Best"

			local function getTargetSlimesForExtract()
				if not dataServiceClient then return {} end
				if selectedExtractSlimeMode == "Best" then
					local key, data = getBestSlimeEntry()
					if key and data then return { { key = key, data = data } } end
					return {}
				else
					local equipped = dataServiceClient:get("equipped") or {}
					local result   = {}
					for _, slimeKey in ipairs(equipped) do
						if type(slimeKey) == "string" and slimeKey:sub(1, 1) == "." then
							local inv  = dataServiceClient:get("inventory") or {}
							local data = inv[slimeKey]
							if type(data) == "table" then table.insert(result, { key = slimeKey, data = data }) end
						end
					end
					return result
				end
			end

			local function resolveExtractFruitList()
				local ok2, owned = pcall(getOwnedFruitIds)
				if not ok2 or not owned then return {} end
				if selectedExtractFruitIds[1] == "ANY" then
					local result = {}
					for _, f in ipairs(ALL_FRUITS or {}) do
						if owned[f.id] then table.insert(result, f.id) end
					end
					return result
				else
					local result = {}
					for _, fid in ipairs(selectedExtractFruitIds) do
						if owned[fid] then table.insert(result, fid) end
					end
					return result
				end
			end

			local function doExtract()
				if not fruitExtractorRemote then return end
				local targets = getTargetSlimesForExtract()
				if #targets == 0 then return end
				for _, entry in ipairs(targets) do
					local shouldExtract = false
					if selectedExtractFruitIds[1] == "ANY" then
						shouldExtract = true
					else
						local fruitsToExtract = resolveExtractFruitList()
						for _, fruitId in ipairs(fruitsToExtract) do
							local ok2, has = pcall(slimeHasFruit, entry.data, fruitId)
							if ok2 and has then shouldExtract = true break end
						end
					end
					if shouldExtract then
						pcall(function() fruitExtractorRemote:InvokeServer("requestExtractFruits", entry.key) end)
						task.wait(0.3)
					end
				end
			end

			featureToggle(farmingTab, {
				Name         = "Auto Extract Fruits from Slime(s)",
				CurrentValue = false,
				Flag         = "AutoExtractToggle",
				Callback     = function(value)
					autoExtractEnabled = value
					if value then
						task.spawn(function()
							while autoExtractEnabled do
								local flag = rayfieldLibrary.Flags and rayfieldLibrary.Flags.AutoExtractToggle
								if not flag or not flag.CurrentValue then break end
								pcall(doExtract)
								task.wait(2)
							end
						end)
					end
				end,
			})

			farmingTab:CreateDropdown({
				Name = "Extract From", Options = { "Best", "Equipped Team" },
				CurrentOption = { "Best" }, MultipleOptions = false, Flag = "ExtractSlimeModeDropdown",
				Callback = function(option)
					selectedExtractSlimeMode = type(option) == "table" and option[1] or option
				end,
			})

			pcall(function()
				local extractFruitOptions = { "Any" }
				local extractLabelToId    = {}
				local extractFruitNames   = {}
				local fruits = (FruitsModule and FruitsModule.getSortedFruits)
					and FruitsModule.getSortedFruits() or {}
				for _, f in ipairs(fruits) do
					table.insert(extractFruitNames, f.powerName)
					extractLabelToId[f.powerName] = f.id
				end
				table.sort(extractFruitNames)
				for _, name in ipairs(extractFruitNames) do table.insert(extractFruitOptions, name) end
				farmingTab:CreateDropdown({
					Name = "Fruits to Extract", Options = extractFruitOptions,
					CurrentOption = { "Any" }, MultipleOptions = true, Flag = "ExtractFruitDropdown",
					Callback = function(options)
						local picked = type(options) == "table" and options or { options }
						selectedExtractFruitIds = {}
						for _, label in ipairs(picked) do
							if label == "Any" then
								selectedExtractFruitIds = { "ANY" }
								return
							else
								table.insert(selectedExtractFruitIds, extractLabelToId[label])
							end
						end
						if #selectedExtractFruitIds == 0 then selectedExtractFruitIds = { "ANY" } end
					end,
				})
			end)
		end)

		-- ─────────────────────────────────────────────
		-- GAME TAB — AUTO FARM
		-- ─────────────────────────────────────────────
		if gameTab then
			pcall(function() gameTab:CreateSection("Auto Farm") end)
		end

		featureToggle(gameTab, {
			Name         = "Auto Farm",
			CurrentValue = false,
			Flag         = "AutoFarm",
			Callback     = function(value)
				enemySettings.AutoFarm = value
				setNoclip(value)
				if not value then
					currentTarget = nil
					stopAutoWalk()
				end
			end,
		})

		if gameTab then
			pcall(function()
				gameTab:CreateSlider({
					Name = "Auto Farm Walk Speed", Range = { 50, 160 }, Increment = 1, Suffix = "",
					CurrentValue = 100, Flag = "AutoFarmWalkSpeed",
					Callback = function(val) autoFarmWalkSpeed = val end,
				})
				gameTab:CreateDropdown({
					Name = "Movement Style",
					Options = { "Walk [RECOMMENDED]", "Instant", "Smooth" },
					CurrentOption = { "Walk [RECOMMENDED]" },
					MultipleOptions = false, Flag = "TeleportStyle",
					Callback = function(option)
						local val = type(option) == "table" and option[1] or option
						if val == "Walk [RECOMMENDED]" then val = "Walk" end
						enemySettings.TeleportStyle = val
						if val ~= "Walk" then stopAutoWalk() end
					end,
				})
				gameTab:CreateDropdown({
					Name = "Target Priority",
					Options = { "Closest", "Lowest HP", "Most Coins & Goop", "Mutations Only" },
					CurrentOption = { "Most Coins & Goop" }, MultipleOptions = true, Flag = "TargetPriority",
					Callback = function(options)
						enemySettings.TargetPriorities = {}
						for _, opt in ipairs(options) do enemySettings.TargetPriorities[opt] = true end
					end,
				})
				gameTab:CreateDropdown({
					Name = "Mutation Filter",
					Options = { "Any", "Big", "Huge", "Inverted", "Shiny" },
					CurrentOption = { "Any" }, MultipleOptions = false, Flag = "MutationFilter",
					Callback = function(option)
						enemySettings.MutationFilter = type(option) == "table" and option[1] or option
					end,
				})
			end)
		end

		-- ─────────────────────────────────────────────
		-- GAME TAB — CONTROLS / COMBAT
		-- ─────────────────────────────────────────────
		if gameTab then
			pcall(function() gameTab:CreateSection("Controls") end)
		end

		local combatEnabled = false
		local getgcChecked  = false

		local function findGunController()
			local char = localPlayer.Character
			if not char then return nil end
			local tool = char:FindFirstChild("SlimeGun")
			if not tool then return nil end
			if not HAS_GETGC then
				if not getgcChecked then
					Logger:warn("Executor", "Capability", "getgc not available — Auto Shoot disabled")
					getgcChecked = true
				end
				return nil
			end
			if not getgcChecked then
				Logger:info("Executor", "Capability", "getgc available — Auto Shoot enabled")
				getgcChecked = true
			end
			for _, v in ipairs(getgc(true)) do
				if type(v) == "table"
					and rawget(v, "tool") == tool
					and rawget(v, "prevSendAt") ~= nil
				then
					return v
				end
			end
			return nil
		end

		if gameTab then
			pcall(function()
				gameTab:CreateDropdown({
					Name = "Slime Gun Mode",
					Options = { "Normal (uses getgc)", "Advanced (bypass cooldown)" },
					CurrentOption = { "Normal (uses getgc)" },
					MultipleOptions = false, Flag = "SlimeGunMode", Callback = function() end,
				})
			end)
		end

		featureToggle(gameTab, {
			Name = "Auto Shoot Enemies", CurrentValue = false, Flag = "CombatAutoShoot",
			Callback = function(value) combatEnabled = value end,
		})

		if gameTab then
			pcall(function()
				gameTab:CreateDropdown({
					Name = "Combat Target Priority",
					Options = { "Closest", "Lowest HP", "Highest HP", "Most Coins & Goop" },
					CurrentOption = { "Closest" }, MultipleOptions = false,
					Flag = "CombatTargetPriority", Callback = function() end,
				})
			end)
		end

		task.spawn(function()
			local controller  = nil
			local advHeartbeat = nil
			while true do
				task.wait(0.1)
				if not combatEnabled then
					controller = nil
					if advHeartbeat then
						pcall(function() advHeartbeat:Disconnect() end)
						advHeartbeat = nil
					end
					task.wait(0.3)
					continue
				end
				pcall(function()
					local modeFlag = rayfieldLibrary.Flags.SlimeGunMode
					local rawMode  = modeFlag
						and (type(modeFlag.CurrentOption) == "table"
							and modeFlag.CurrentOption[1]
							or modeFlag.CurrentOption)
						or "Normal (uses getgc)"
					local mode = rawMode:match("^(%S+)") or rawMode
					if mode == "Advanced" then
						if advHeartbeat then return end
						pcall(function()
							local R = game:GetService("ReplicatedStorage")
							local U = require(R.Source.Features.Upgrades.UpgradeServiceUtils)
							local G = require(R.Source.Features.GoopGun.GoopGunServiceClient)
							local O = U.getUpgradeValue
							U.getUpgradeValue = function(N, L)
								if N == "slimeGunFireRate" then return 0 end
								return O(N, L)
							end
							advHeartbeat = RunService.Heartbeat:Connect(function()
								pcall(function()
									local flag2 = rayfieldLibrary.Flags.CombatAutoShoot
									if not flag2 or not flag2.CurrentValue then return end
									local mf = rayfieldLibrary.Flags.SlimeGunMode
									local rawM = mf
										and (type(mf.CurrentOption) == "table" and mf.CurrentOption[1] or mf.CurrentOption)
										or "Normal (uses getgc)"
									local m = rawM:match("^(%S+)") or rawM
									if m ~= "Advanced" then return end
									local W = G.wrapper
									if W then
										W.prevSendAt    = 0
										W.isHoldingInput = true
										W:onActivated()
									end
								end)
							end)
						end)
					else
						if advHeartbeat then
							pcall(function() advHeartbeat:Disconnect() end)
							advHeartbeat = nil
						end
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
								if gunInBag then pcall(function() humanoid:EquipTool(gunInBag) end) end
							end
							controller = nil
							return
						end
						if not controller then
							controller = findGunController()
							if not controller then return end
						end
						local cbOk = pcall(function()
							local orig = controller._getTargetEnemyId
							controller._getTargetEnemyId = function() return targetId end
							controller:onActivated()
							controller._getTargetEnemyId = orig
						end)
						if not cbOk then controller = nil end
					end
				end)
			end
		end)

		-- ─────────────────────────────────────────────
		-- GAME TAB — PROGRESS / REBIRTH
		-- ─────────────────────────────────────────────
		if gameTab then
			pcall(function() gameTab:CreateSection("Progress") end)
		end

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
							local minZoneVal   = tonumber(
								rayfieldLibrary.Flags.GameMinZoneRebirth
								and rayfieldLibrary.Flags.GameMinZoneRebirth.CurrentValue
							) or 0
							if furthestZone >= minZoneVal and goop >= requiredGoop then
								rebirthServiceRemote:InvokeServer("requestRebirth")
							end
						end)
						task.wait(10)
					end
				end)
			end,
		})

		if gameTab then
			pcall(function()
				gameTab:CreateInput({
					Name = "Minimum Zone To Rebirth", CurrentValue = "",
					PlaceholderText = "e.g. 10", RemoveTextAfterFocusLost = false,
					Flag = "GameMinZoneRebirth", Callback = function() end,
				})
			end)
		end

		-- ─────────────────────────────────────────────
		-- GAME TAB — UPGRADES
		-- ─────────────────────────────────────────────
		if gameTab then
			pcall(function() gameTab:CreateSection("Upgrades") end)
		end

		local UpgradeService = nil
		task.spawn(function()
			repeat task.wait(1) until modulesLoaded and dataServiceClient
			local rs = game:GetService("ReplicatedStorage")
			local ok2, upgradeSvc = pcall(function()
				return require(rs.Source.Features.Upgrades.UpgradeServiceClient)
			end)
			if ok2 and upgradeSvc and Networker then
				pcall(function()
					local dummyClient = {}
					dummyClient.networker = Networker.client.new("UpgradeService", dummyClient)
					upgradeSvc.init(dummyClient)
					UpgradeService = upgradeSvc
				end)
			else
				Logger:warn("CactusHub", "Upgrades", "UpgradeServiceClient failed to load for purchasing")
			end
		end)

		featureToggle(gameTab, {
			Name         = "Auto Upgrade Purchasing",
			CurrentValue = false,
			Flag         = "GameAutoUpgrade",
			Callback     = function(enabled)
				if not enabled then return end
				task.spawn(function()
					while true do
						local flag = rayfieldLibrary.Flags.GameAutoUpgrade
						if not flag or not flag.CurrentValue then break end
						if not UpgradeService or not dataServiceClient or not upgradeTreeModule then
							task.wait(2)
							continue
						end
						pcall(function()
							local upgradeMode = rayfieldLibrary.Flags.GameUpgradeMode
								and rayfieldLibrary.Flags.GameUpgradeMode.CurrentOption
								or { "All" }
							local modeSet = {}
							for _, m in ipairs(upgradeMode) do modeSet[m] = true end
							local unlockedUpgrades = dataServiceClient:get("upgrades") or {}
							local coins        = dataServiceClient:get("coins") or 0
							local goop         = dataServiceClient:get("goop") or 0
							local rollCurrency = dataServiceClient:get("rollCurrency") or 0
							local anyPurchased = false
							for _, tree in pairs(upgradeTreeModule) do
								for upgradeId, data in pairs(tree) do
									if data.cost and not unlockedUpgrades[upgradeId] then
										local cost     = data.cost.amount or 0
										local currency = data.cost.currency
										local canBuy   = false
										if currency == "coins" and (modeSet["All"] or modeSet["Coins"]) then
											canBuy = coins >= cost
										elseif currency == "goop" and (modeSet["All"] or modeSet["Goop"]) then
											canBuy = goop >= cost
										elseif currency == "rollCurrency" and (modeSet["All"] or modeSet["Rolls"]) then
											canBuy = rollCurrency >= cost
										end
										if canBuy then
											local success
											pcall(function() success = UpgradeService:unlockUpgrade(upgradeId) end)
											if success then
												anyPurchased = true
												if currency == "coins" then coins = coins - cost
												elseif currency == "goop" then goop = goop - cost
												elseif currency == "rollCurrency" then rollCurrency = rollCurrency - cost
												end
												unlockedUpgrades[upgradeId] = true
											end
											task.wait(0.1)
										end
									end
								end
							end
							if not anyPurchased then task.wait(5) end
						end)
						task.wait(0.5)
					end
				end)
			end,
		})

		if gameTab then
			pcall(function()
				gameTab:CreateDropdown({
					Name = "Upgrade Mode", Options = { "All", "Coins", "Goop", "Rolls" },
					CurrentOption = { "All" }, MultipleOptions = true,
					Flag = "GameUpgradeMode", Callback = function() end,
				})
			end)
		end

		-- ─────────────────────────────────────────────
		-- GAME TAB — RECIPES / CRAFTING
		-- ─────────────────────────────────────────────
		if gameTab then
			pcall(function() gameTab:CreateSection("Recipes") end)
		end

		pcall(function()
			if not gameTab then return end
			local recipeIdsList = {}
			if RecipesModule and dataServiceClient then
				local unlocked = dataServiceClient:get("craftingRecipes") or {}
				local ok2, all = pcall(function() return RecipesModule.getRecipes() end)
				if ok2 and all then
					for _, recipe in ipairs(all) do
						if unlocked[recipe.id] then table.insert(recipeIdsList, recipe.id) end
					end
					table.sort(recipeIdsList)
				end
			end

			local craftingState = {
				selectedRecipeIds  = #recipeIdsList > 0 and { recipeIdsList[1] } or {},
				craftAmount        = 1,
				autoCraftEnabled   = false,
				autoCraftAmount    = 1,
				autoCraftThread    = nil,
				protectCategories  = { "Best Slime", "Equipped Slimes", "Xp Slimes" },
			}

			local MutationsModule = mutationsModule
			local function getSizeMutations()
				return MutationsModule and MutationsModule.sizeMutations or {}
			end
			local function getModifierMutations()
				return MutationsModule and MutationsModule.modifierMutations or {}
			end
			local function getMutationValue(mutId)
				if not MutationsModule then return 0 end
				local data = MutationsModule.get(mutId)
				return data and data.value or 0
			end

			local function parseUniqueId(uid)
				local base, sizeMut, modMut = uid, nil, nil
				for _, sizeId in ipairs(getSizeMutations()) do
					local prefix = sizeId .. "_"
					if base:sub(1, #prefix) == prefix then
						sizeMut = sizeId
						base    = base:sub(#prefix + 1)
						break
					end
				end
				if base:sub(1, 1) == "-" then base = base:sub(2) end
				for _, modId in ipairs(getModifierMutations()) do
					local suffix = "_" .. modId
					if base:sub(-#suffix) == suffix then
						modMut = modId
						base   = base:sub(1, -#suffix - 1)
						break
					end
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
				local equipped = dataServiceClient and dataServiceClient:get("equipped") or {}
				local set = {}
				for _, uid in pairs(equipped) do set[uid] = true end
				return set
			end

			local function getBestSlimeSet()
				if not dataServiceClient then return {} end
				local inventory = dataServiceClient:get("inventory") or {}
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
			end

			local function buildProtectedSet(categories)
				local catSet = {}
				for _, cat in ipairs(categories) do catSet[cat] = true end
				local protected = {}
				if catSet["Equipped Slimes"] then
					for uid in pairs(getEquippedSet()) do protected[uid] = true end
				end
				if catSet["Best Slime"] then
					for uid in pairs(getBestSlimeSet()) do protected[uid] = true end
				end
				if catSet["Xp Slimes"] and dataServiceClient then
					local inv = dataServiceClient:get("inventory") or {}
					for uid, data in pairs(inv) do
						if type(data) == "table" then protected[uid] = true end
					end
				end
				return protected
			end

			local protectedPets = buildProtectedSet(craftingState.protectCategories)

			local function findBestIngredient(baseId, usedCounts)
				if not dataServiceClient then return nil end
				local inventory = dataServiceClient:get("inventory") or {}
				local bestUid, bestScore = nil, -1
				for uid, data in pairs(inventory) do
					if not protectedPets[uid] then
						local parsedBase = parseUniqueId(uid)
						if parsedBase == baseId then
							local owned = type(data) == "number" and math.max(data, 0)
								or (type(data) == "table" and 1 or 0)
							local used = usedCounts[uid] or 0
							if owned - used > 0 then
								local s = scoreUniqueId(uid)
								if s > bestScore then bestScore = s bestUid = uid end
							end
						end
					end
				end
				return bestUid
			end

			local function buildCraftArgsForRecipe(recipeId, amount)
				if not RecipesModule then return nil end
				local recipe = RecipesModule.getRecipe(recipeId)
				if not recipe then return nil end
				local ingredientIds, usedCounts = {}, {}
				for _, input in ipairs(recipe.inputs) do
					local uid = findBestIngredient(input.id, usedCounts) or ("-" .. input.id)
					usedCounts[uid] = (usedCounts[uid] or 0) + 1
					table.insert(ingredientIds, uid)
				end
				return { "requestCraftRecipe", recipeId, ingredientIds, tostring(amount) }
			end

			local function getCraftingRemote()
				return ReplicatedStorage
					:WaitForChild("Packages", 15)
					:WaitForChild("_Index", 15)
					:WaitForChild("leifstout_networker@0.3.1", 15)
					:WaitForChild("networker", 15)
					:WaitForChild("_remotes", 15)
					:WaitForChild("CraftingService", 10)
					:WaitForChild("RemoteFunction", 10)
			end

			local function doCraftAll(amount)
				local craftRemote
				local ok2 = pcall(function() craftRemote = getCraftingRemote() end)
				if not ok2 or not craftRemote then
					Logger:warn("Crafting", "Remote", "CraftingService remote unavailable")
					return {}
				end
				local results = {}
				for _, recipeId in ipairs(craftingState.selectedRecipeIds) do
					local args = buildCraftArgsForRecipe(recipeId, amount)
					if args then
						local callOk, result = pcall(function()
							return craftRemote:InvokeServer(table.unpack(args))
						end)
						results[recipeId] = callOk and result ~= false
					end
				end
				return results
			end

			local function getMaxCraftsForRecipe(recipeId)
				if not RecipesModule or not dataServiceClient then return 0 end
				local recipe = RecipesModule.getRecipe(recipeId)
				if not recipe then return 0 end
				local usedCounts, maxCrafts = {}, math.huge
				for _, input in ipairs(recipe.inputs) do
					local uid = findBestIngredient(input.id, usedCounts)
					if not uid then return 0 end
					usedCounts[uid] = (usedCounts[uid] or 0) + 1
					local inv   = dataServiceClient:get("inventory") or {}
					local owned = type(inv[uid]) == "number" and math.max(inv[uid], 0)
						or (type(inv[uid]) == "table" and 1 or 0)
					local avail = owned - usedCounts[uid] + 1
					if avail < maxCrafts then maxCrafts = avail end
				end
				return maxCrafts == math.huge and 0 or maxCrafts
			end

			pcall(function()
				gameTab:CreateDropdown({
					Name = "Select Recipes to Craft",
					Options = #recipeIdsList > 0 and recipeIdsList or { "None" },
					CurrentOption = craftingState.selectedRecipeIds,
					MultipleOptions = true, Flag = "CraftingSelectedRecipes",
					Callback = function(options) craftingState.selectedRecipeIds = options end,
				})
				gameTab:CreateSlider({
					Name = "Craft Amount", Range = { 1, 99 }, Increment = 1, Suffix = "x",
					CurrentValue = 1, Flag = "CraftingAmount",
					Callback = function(val) craftingState.craftAmount = val end,
				})
			end)

			featureButton(gameTab, {
				Name = "Craft Now",
				Callback = function()
					local results = doCraftAll(craftingState.craftAmount)
					local succeeded, failed = 0, 0
					for _, ok2 in pairs(results) do
						if ok2 then succeeded = succeeded + 1 else failed = failed + 1 end
					end
					safeNotify({
						Title    = "Cactus Hub",
						Content  = succeeded .. " crafts succeeded" .. (failed > 0 and (", " .. failed .. " failed") or ""),
						Duration = 3,
						Image    = 4483362458,
					})
				end,
			})

			pcall(function()
				gameTab:CreateSlider({
					Name = "Auto Craft Amount", Range = { 1, 99 }, Increment = 1, Suffix = "x",
					CurrentValue = 1, Flag = "CraftingAutoAmount",
					Callback = function(val) craftingState.autoCraftAmount = val end,
				})
			end)

			featureToggle(gameTab, {
				Name         = "Enable Auto Craft",
				CurrentValue = false,
				Flag         = "CraftingAutoToggle",
				Callback     = function(enabled)
					craftingState.autoCraftEnabled = enabled
					if enabled then
						if craftingState.autoCraftThread then
							pcall(function() task.cancel(craftingState.autoCraftThread) end)
						end
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
						safeNotify({ Title = "Auto Craft", Content = "Started", Duration = 3, Image = 4483362458 })
					else
						if craftingState.autoCraftThread then
							pcall(function() task.cancel(craftingState.autoCraftThread) end)
							craftingState.autoCraftThread = nil
						end
						safeNotify({ Title = "Auto Craft", Content = "Stopped.", Duration = 3, Image = 4483362458 })
					end
				end,
			})

			pcall(function()
				gameTab:CreateDropdown({
					Name = "Protect Categories",
					Options = { "Best Slime", "Equipped Slimes", "Xp Slimes" },
					CurrentOption = { "Best Slime", "Equipped Slimes", "Xp Slimes" },
					MultipleOptions = true, Flag = "CraftingProtectCategories",
					Callback = function(options)
						craftingState.protectCategories = options
						protectedPets = buildProtectedSet(options)
					end,
				})
			end)

			safeNotify({
				Title    = "Cactus Hub",
				Content  = "Loaded — " .. (#recipeIdsList) .. " unlocked recipes ready.",
				Duration = 5,
				Image    = 4483362458,
			})
		end)

		-- ─────────────────────────────────────────────
		-- UFO TAB
		-- ─────────────────────────────────────────────
		local ufoClient     = nil
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
			local ok2, remote = pcall(function()
				return ReplicatedStorage
					:WaitForChild("Packages", 10)
					:WaitForChild("_Index", 10)
					:WaitForChild("leifstout_networker@0.3.1", 10)
					:WaitForChild("networker", 10)
					:WaitForChild("_remotes", 10)
					:WaitForChild("LootService", 10)
					:WaitForChild("RemoteFunction", 10)
			end)
			if ok2 then ufoLootRemote = remote end
			return ufoLootRemote
		end

		pcall(function()
			ufoClient = require(ReplicatedStorage.Source.Features.UfoEvent.UfoEventServiceClient)
		end)

		local autoUfoZone  = false
		local autoUfoLoot  = false
		local lastUfoZoneId = nil
		local lastUfoPhase  = nil

		if ufoTab then
			pcall(function() ufoTab:CreateSection("Live Status") end)
		end

		local ufoPhaseLabel    = safeCreateLabel(ufoTab, "🛸  Phase: —")
		local ufoZoneIdLabel   = safeCreateLabel(ufoTab, "📍  Zone ID: —")
		local ufoZoneNameLabel = safeCreateLabel(ufoTab, "🗺️  Zone Name: —")
		local ufoNextLabel     = safeCreateLabel(ufoTab, "⏳  Next Event: —")
		local ufoGoldenLabel   = safeCreateLabel(ufoTab, "⭐  Golden UFO: —")

		local function refreshUfoState()
			if not ufoClient then
				safeSetLabel(ufoPhaseLabel, "🛸  Phase: Module not loaded")
				return
			end
			local ok2, state = pcall(function() return ufoClient:getStateSource()() end)
			if not ok2 or not state then return end
			local zoneName = "N/A"
			pcall(function()
				local ZM = require(ReplicatedStorage.Source.Game.Items.Zones)
				if state.zoneId and ZM.hasZone(state.zoneId) then
					zoneName = ZM.getZone(state.zoneId).name
				end
			end)
			local nextEvent = "N/A"
			if state.nextEventStartTime then
				local secs = math.max(0, math.round(state.nextEventStartTime - workspace:GetServerTimeNow()))
				nextEvent = string.format("%02d:%02d", math.floor(secs / 60), secs % 60)
			end
			local phaseIcon = "⚪"
			if state.phase == "hovering"  then phaseIcon = "🟢"
			elseif state.phase == "arriving"  then phaseIcon = "🟡"
			elseif state.phase == "departing" then phaseIcon = "🔴"
			end
			local isGolden = false
			pcall(function() isGolden = ufoClient.isGolden == true end)
			safeSetLabel(ufoPhaseLabel,    "🛸  Phase: " .. phaseIcon .. " " .. state.phase:upper())
			safeSetLabel(ufoZoneIdLabel,   "📍  Zone ID: " .. (state.zoneId and tostring(state.zoneId) or "None"))
			safeSetLabel(ufoZoneNameLabel, "🗺️  Zone Name: " .. zoneName)
			safeSetLabel(ufoNextLabel,     "⏳  Next Event: " .. nextEvent)
			safeSetLabel(ufoGoldenLabel,   "⭐  Golden UFO: " .. (isGolden and "Yes ✅" or "No ❌"))
		end

		if ufoTab then
			pcall(function() ufoTab:CreateSection("Automation") end)
		end

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
			Name = "Auto Collect UFO Loot", CurrentValue = false, Flag = "AutoUfoLoot",
			Callback = function(value) autoUfoLoot = value end,
		})

		if ufoTab then
			pcall(function() ufoTab:CreateSection("Controls") end)
		end

		featureButton(ufoTab, {
			Name     = "Refresh Status",
			Callback = function() refreshUfoState() end,
		})

		task.spawn(function()
			local ufoWasActive  = false
			local farmWasEnabled = false
			while true do
				task.wait(1)
				pcall(function()
					refreshUfoState()
					if not ufoClient then return end
					local ok2, state = pcall(function() return ufoClient:getStateSource()() end)
					if not ok2 or not state then return end
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
							local currentZone = dataServiceClient and dataServiceClient:get("zone") or nil
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
										local id = item:GetAttribute("uniqueId")
											or item:GetAttribute("id")
											or item.Name
										if id then
											pcall(function() remote:InvokeServer("requestCollect", id) end)
										end
									end
								end
							end
						end
					end
				end)
			end
		end)

		-- ─────────────────────────────────────────────
		-- INDEX TAB
		-- ─────────────────────────────────────────────
		local indexRunning    = false
		local indexThread     = nil
		local luckPollThread  = nil
		local selectedCategoryOption = nil
		local indexLabels = {}

		if indexTab then
			pcall(function() indexTab:CreateSection("Controls") end)
		end

		featureToggle(indexTab, {
			Name         = "Start Auto Complete",
			CurrentValue = false,
			Flag         = "IndexAutoComplete",
			Callback     = function(value)
				if value then
					indexRunning = true
					indexThread  = task.spawn(function()
						if not dataServiceClient then
							safeNotify({ Title = "Index", Content = "DataService not loaded yet.", Duration = 4 })
							indexRunning = false
							return
						end
						setLuck(1)
						task.wait(0.3)
						setLuckEnabled(true)
						task.wait(0.3)
						luckPollThread = task.spawn(function()
							while indexRunning do
								safeSetLabel(indexLabels.lLuck, "🍀 Luck Override: x" .. tostring(luckValueLocal))
								task.wait(1)
							end
						end)
						local modeFlag = rayfieldLibrary.Flags and rayfieldLibrary.Flags.IndexRollMode
						local mode = modeFlag
							and (type(modeFlag.CurrentOption) == "table" and modeFlag.CurrentOption[1] or modeFlag.CurrentOption)
							or "🌱 Easiest First"
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
						local function runCategory(catId, modeStr, labels)
							local failCount    = 0
							local catLabel     = catId:sub(1, 1):upper() .. catId:sub(2)
							local lastTargetId = nil
							while indexRunning do
								local flag = rayfieldLibrary.Flags.IndexAutoComplete
								if not flag or not flag.CurrentValue then
									indexRunning = false
									break
								end
								local missing = getMissingSlimes(catId)
								if #missing == 0 then return true end
								local target   = modeStr == "🎯 Rarest First" and missing[#missing] or missing[1]
								local effOdds  = getEffectiveOdds(target, catId)
								if target.id ~= lastTargetId then
									lastTargetId = target.id
									setLuck(calcOptimalLuck(effOdds))
								end
								if labels then
									safeSetLabel(labels.lTarget, "🎯 Target: " .. catLabel .. " " .. target.name)
									safeSetLabel(labels.lOdds, "🎲 Odds: " .. formatOdds(effOdds))
									safeSetLabel(labels.lCategory, string.format("📂 %s (%d left)", catLabel, #missing))
								end
								local before = getUnlockedIndex(catId)
								pcall(function() networkerRoll:fetch("requestRoll") end)
								task.wait(rollSliceModule and rollSliceModule.rollTime() or 0.5)
								local after  = getUnlockedIndex(catId)
								local gotOne = false
								for id, v in pairs(after) do
									if v == true and not before[id] then
										gotOne   = true
										failCount = 0
										local slime = slimesModule and slimesModule.getSlime(id)
										print("[UNLOCKED]", catLabel, slime and slime.name or id)
									end
								end
								if not gotOne then
									failCount = failCount + 1
									if failCount % 100 == 0 then
										warn("[STUCK]", failCount, "rolls |", catLabel, target.name)
									end
								end
								task.wait()
							end
							return false
						end
						if selectedCategoryOption == nil or selectedCategoryOption == "🎲 All (Recommended)" then
							while indexRunning do
								local sorted = getSortedCategoriesByPriority()
								if #sorted == 0 then
									safeSetLabel(indexLabels.lCategory, "📂 ✅ All Complete!")
									safeSetLabel(indexLabels.lTarget,   "🎯 Target: —")
									safeSetLabel(indexLabels.lOdds,     "🎲 Odds: —")
									indexRunning = false
									break
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
									safeSetLabel(indexLabels.lCategory, "📂 ✅ Complete!")
									safeSetLabel(indexLabels.lTarget,   "🎯 Target: —")
									safeSetLabel(indexLabels.lOdds,     "🎲 Odds: —")
								end
							end
							indexRunning = false
						end
						if luckPollThread then
							pcall(function() task.cancel(luckPollThread) end)
							luckPollThread = nil
						end
						setLuckEnabled(false)
					end)
				else
					indexRunning = false
					if indexThread then
						pcall(function() task.cancel(indexThread) end)
						indexThread = nil
					end
					if luckPollThread then
						pcall(function() task.cancel(luckPollThread) end)
						luckPollThread = nil
					end
					setLuckEnabled(false)
					safeSetLabel(indexLabels.lTarget,   "🎯 Target: —")
					safeSetLabel(indexLabels.lOdds,     "🎲 Odds: —")
					safeSetLabel(indexLabels.lLuck,     "🍀 Luck: —")
					safeSetLabel(indexLabels.lCategory, "📂 Category: —")
				end
			end,
		})

		if indexTab then
			pcall(function() indexTab:CreateSection("Settings") end)
		end

		pcall(function()
			if not indexTab then return end
			local categoryOptions = { "🎲 All (Recommended)" }
			for _, catId in ipairs(CATEGORY_IDS) do
				local missing = getMissingSlimes(catId)
				local label   = catId:sub(1, 1):upper() .. catId:sub(2)
				if #missing == 0 then
					table.insert(categoryOptions, "✅ " .. label .. " (Complete)")
				else
					local effOdds = getEffectiveOdds(missing[1], catId)
					table.insert(
						categoryOptions,
						string.format("%s (%d left | %s)", label, #missing, formatOdds(effOdds))
					)
				end
			end
			selectedCategoryOption = categoryOptions[1]
			indexTab:CreateDropdown({
				Name = "Category", Options = categoryOptions, CurrentOption = { categoryOptions[1] },
				MultipleOptions = false, Flag = "IndexCategory",
				Callback = function(option)
					selectedCategoryOption = type(option) == "table" and option[1] or option
				end,
			})
		end)

		if indexTab then
			pcall(function()
				indexTab:CreateDropdown({
					Name = "Roll Mode", Options = { "🌱 Easiest First", "🎯 Rarest First" },
					CurrentOption = { "🌱 Easiest First" }, MultipleOptions = false,
					Flag = "IndexRollMode", Callback = function() end,
				})
				indexTab:CreateSection("Status")
			end)
		end

		indexLabels.lTarget   = safeCreateLabel(indexTab, "🎯 Target: —")
		indexLabels.lOdds     = safeCreateLabel(indexTab, "🎲 Odds: —")
		indexLabels.lLuck     = safeCreateLabel(indexTab, "🍀 Luck: —")
		indexLabels.lCategory = safeCreateLabel(indexTab, "📂 Category: —")

		if indexTab then
			pcall(function() indexTab:CreateSection("Index Progress") end)
		end

		local indexProgressLabels = {}
		local totalSlimeCount     = getTotalSlimes()
		for _, catId in ipairs(CATEGORY_IDS) do
			local label = catId:sub(1, 1):upper() .. catId:sub(2)
			indexProgressLabels[catId] = safeCreateLabel(
				indexTab,
				string.format("📊 %s: %d / %d", label, getUnlockedCount(catId), totalSlimeCount)
			)
		end

		task.spawn(function()
			while true do
				task.wait(2)
				pcall(function()
					local totalNow = getTotalSlimes()
					for _, catId in ipairs(CATEGORY_IDS) do
						if indexProgressLabels[catId] then
							local label = catId:sub(1, 1):upper() .. catId:sub(2)
							safeSetLabel(
								indexProgressLabels[catId],
								string.format("📊 %s: %d / %d", label, getUnlockedCount(catId), totalNow)
							)
						end
					end
				end)
			end
		end)

		-- ─────────────────────────────────────────────
		-- MISC TAB — CODES & REWARDS
		-- ─────────────────────────────────────────────
		if miscTab then
			pcall(function() miscTab:CreateSection("Codes & Rewards") end)
		end

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
							if not (rayfieldLibrary.Flags.MiscRedeemCodes
								and rayfieldLibrary.Flags.MiscRedeemCodes.CurrentValue) then break end
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
									for _, isUnlocked in pairs(unlocked) do
										if isUnlocked == true then unlockedCount = unlockedCount + 1 end
									end
									local claimedRewards = category.claimedRewards or {}
									for _, reward in ipairs(rewardsList) do
										if unlockedCount >= reward.req and not claimedRewards[reward.key] then
											pcall(function()
												indexServiceRemote:InvokeServer("requestClaimReward", categoryKey)
											end)
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

		-- ─────────────────────────────────────────────
		-- MISC TAB — CONSUMABLES (POTIONS)
		-- ─────────────────────────────────────────────
		if miscTab then
			pcall(function() miscTab:CreateSection("Consumables") end)
		end

		pcall(function()
			if not miscTab then return end
			local sortedBoostKinds = {}
			if boostKinds then
				for _, kind in ipairs(boostKinds) do table.insert(sortedBoostKinds, kind) end
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
								if not boostServiceRemote or not dataServiceClient or not boostServiceUtils then return end
								local boosts = dataServiceClient:get("boosts") or {}
								local selectedPotions = rayfieldLibrary.Flags.MiscPotionTypes
									and rayfieldLibrary.Flags.MiscPotionTypes.CurrentOption
									or {}
								local serverTime = workspace:GetServerTimeNow()
								for _, potionType in ipairs(selectedPotions) do
									local boostData = boosts[potionType]
									if boostData and (boostData.amount or 0) > 0 then
										local remaining = boostServiceUtils.getTimeRemaining(boostData, serverTime)
										if remaining <= 0 then
											pcall(function()
												boostServiceRemote:InvokeServer("requestUseBoost", potionType)
											end)
											task.wait(0.5)
										end
									end
								end
							end)
							task.wait(1)
						end
					end)
				end,
			})

			if #sortedBoostKinds > 0 then
				pcall(function()
					miscTab:CreateDropdown({
						Name = "Potion Types", Options = sortedBoostKinds,
						CurrentOption = sortedBoostKinds, MultipleOptions = true,
						Flag = "MiscPotionTypes", Callback = function() end,
					})
				end)
				featureButton(miscTab, {
					Name = "Use All Selected Potions",
					Callback = function()
						task.spawn(function()
							pcall(function()
								if not boostServiceRemote or not dataServiceClient then
									safeNotify({ Title = "Error", Content = "Boost service not ready", Duration = 3 })
									return
								end
								local selectedPotions = rayfieldLibrary.Flags.MiscPotionTypes
									and rayfieldLibrary.Flags.MiscPotionTypes.CurrentOption
									or {}
								for _, potionType in ipairs(selectedPotions) do
									local boosts  = dataServiceClient:get("boosts") or {}
									local amount  = (boosts[potionType] or {}).amount or 0
									for _ = 1, amount do
										pcall(function()
											boostServiceRemote:InvokeServer("requestUseBoost", potionType)
										end)
										task.wait(0.2)
									end
								end
								safeNotify({ Title = "Potions", Content = "Used all selected potions", Duration = 3 })
							end)
						end)
					end,
				})
			else
				safeCreateLabel(miscTab, "Potion types not yet loaded — enable after modules load.")
			end
		end)

		-- ─────────────────────────────────────────────
		-- MISC TAB — CONSUMABLES (DICE)
		-- ─────────────────────────────────────────────
		pcall(function()
			if not miscTab then return end
			local diceNames = {}
			if diceItemIds and idToNameMap then
				for _, itemId in ipairs(diceItemIds) do
					table.insert(diceNames, idToNameMap[itemId])
				end
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
								local queue  = dataServiceClient:get("specialDiceQueue") or {}
								local active = queue[1]
								if active then task.wait(1) return end
								local items = dataServiceClient:get("items") or {}
								local selectedDiceItems = rayfieldLibrary.Flags.MiscDiceTypes
									and rayfieldLibrary.Flags.MiscDiceTypes.CurrentOption
									or {}
								for _, diceName in ipairs(selectedDiceItems) do
									local itemId = nameToIdMap and nameToIdMap[diceName]
									if itemId and (items[itemId] or 0) > 0 then
										pcall(function()
											inventoryServiceRemote:InvokeServer("requestUseItem", itemId)
										end)
										task.wait(0.5)
									end
								end
							end)
							task.wait(1)
						end
					end)
				end,
			})

			if #diceNames > 0 then
				pcall(function()
					miscTab:CreateDropdown({
						Name = "Dice & Item Types", Options = diceNames,
						CurrentOption = diceNames, MultipleOptions = true,
						Flag = "MiscDiceTypes", Callback = function() end,
					})
				end)
				featureButton(miscTab, {
					Name = "Use All Selected Dice",
					Callback = function()
						task.spawn(function()
							pcall(function()
								if not inventoryServiceRemote or not dataServiceClient then
									safeNotify({ Title = "Error", Content = "Inventory service not ready", Duration = 3 })
									return
								end
								local selectedDiceItems = rayfieldLibrary.Flags.MiscDiceTypes
									and rayfieldLibrary.Flags.MiscDiceTypes.CurrentOption
									or {}
								for _, diceName in ipairs(selectedDiceItems) do
									local itemId = nameToIdMap and nameToIdMap[diceName]
									if itemId then
										local items  = dataServiceClient:get("items") or {}
										local amount = items[itemId] or 0
										for _ = 1, amount do
											pcall(function()
												inventoryServiceRemote:InvokeServer("requestUseItem", itemId)
											end)
											task.wait(0.2)
										end
									end
								end
								safeNotify({ Title = "Dice", Content = "Used all selected dice/items", Duration = 3 })
							end)
						end)
					end,
				})
			else
				safeCreateLabel(miscTab, "Dice types not yet loaded — enable after modules load.")
			end
		end)

		-- ─────────────────────────────────────────────
		-- WEBHOOK TAB
		-- ─────────────────────────────────────────────
		if webhookTab then
			pcall(function()
				webhookTab:CreateSection("Warning")
				webhookTab:CreateParagraph({
					Title   = "⚠️ WARNING",
					Content = "WEBHOOK WILL ONLY WORK IF YOU MANUALLY ENABLE AUTO ROLL IN GAME\nPLEASE DISABLE FAST ROLL (from Farming Tab) if you have it enabled",
				})
				webhookTab:CreateSection("Configuration")
			end)
		end

		local savedWebhookUrl  = ""
		local WEBHOOK_AVATAR   = "https://media.discordapp.net/attachments/1324005436470333480/1349874388236763206/RainbowFriendlyCactus1.png"

		featureToggle(webhookTab, {
			Name = "Enable Webhook", CurrentValue = false, Flag = "WebhookEnabled",
			Callback = function() end,
		})

		if webhookTab then
			pcall(function()
				webhookTab:CreateInput({
					Name = "Webhook URL", CurrentValue = "",
					PlaceholderText = "Paste your Discord webhook URL",
					RemoveTextAfterFocusLost = false, Flag = "WebhookURLDisplay",
					Callback = function(url)
						if url and url:match("^https://discord") then
							savedWebhookUrl = url
							local masked = string.rep("•", math.max(0, #url - 6)) .. url:sub(-6)
							safeNotify({ Title = "Webhook", Content = "URL saved: " .. masked, Duration = 3 })
						end
					end,
				})
				webhookTab:CreateInput({
					Name = "User ID", CurrentValue = "", PlaceholderText = "Discord User ID",
					RemoveTextAfterFocusLost = false, Flag = "WebhookUserID", Callback = function() end,
				})
				webhookTab:CreateInput({
					Name = "Minimum Chance To Send", CurrentValue = "",
					PlaceholderText = "e.g. 1B or 1000000000",
					RemoveTextAfterFocusLost = false, Flag = "WebhookMinChance", Callback = function() end,
				})
			end)
		end

		featureButton(webhookTab, {
			Name = "Test Webhook",
			Callback = function()
				if savedWebhookUrl == "" then
					safeNotify({ Title = "Webhook", Content = "Please paste a Webhook URL first.", Duration = 4 })
					return
				end
				if not (rayfieldLibrary.Flags.WebhookEnabled
					and rayfieldLibrary.Flags.WebhookEnabled.CurrentValue) then
					safeNotify({ Title = "Webhook", Content = "Please enable Webhook first.", Duration = 4 })
					return
				end
				if not doRequest then
					safeNotify({ Title = "Webhook", Content = "HTTP request not available in this executor.", Duration = 4 })
					return
				end
				local userId  = rayfieldLibrary.Flags.WebhookUserID
					and rayfieldLibrary.Flags.WebhookUserID.CurrentValue or ""
				local mention = (userId and userId ~= "") and ("<@" .. userId .. "> ") or ""
				local success = pcall(function()
					doRequest({
						Url    = savedWebhookUrl,
						Method = "POST",
						Headers = { ["Content-Type"] = "application/json" },
						Body    = HttpService:JSONEncode({
							content    = mention,
							username   = "Cactus Hub",
							avatar_url = WEBHOOK_AVATAR,
							embeds     = { {
								title       = "✅ Webhook Test",
								description = "Your webhook is working correctly!",
								color       = 0x2ecc71,
							} },
						}),
					})
				end)
				safeNotify({
					Title   = "Webhook",
					Content = success and "Test sent successfully!" or "Failed to send test.",
					Duration = 4,
				})
			end,
		})

		if webhookTab then
			pcall(function()
				webhookTab:CreateSection("Filters")
				webhookTab:CreateToggle({ Name="Send All Slimes",    CurrentValue=false, Flag="WebhookSendAll",     Callback=function() end })
				webhookTab:CreateToggle({ Name="Send New Slimes Only", CurrentValue=false, Flag="WebhookSendNew",   Callback=function() end })
				webhookTab:CreateToggle({ Name="Send Mutated Slimes", CurrentValue=false, Flag="WebhookSendMutated", Callback=function() end })
				webhookTab:CreateDropdown({
					Name = "Mutations Filter",
					Options = { "All", "Shiny", "Big", "Huge", "Inverted" },
					CurrentOption = { "All" }, MultipleOptions = true,
					Flag = "WebhookMutations", Callback = function() end,
				})
			end)
		end

		local function formatNumber(num)
			if type(num) ~= "number" then return tostring(num) end
			local suffixes = {
				{ 1e24, "Sp" }, { 1e21, "Sx" }, { 1e18, "Qn" }, { 1e15, "Qd" },
				{ 1e12, "T"  }, { 1e9,  "B"  }, { 1e6,  "M"  }, { 1e3,  "K"  },
			}
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
			for _, item in ipairs(rollResultTable) do
				if type(item) == "table" and item.id then return item end
			end
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
			if not mutations then return "basic" end
			if mutations.inverted then return "inverted" end
			if mutations.huge     then return "huge"     end
			if mutations.big      then return "big"      end
			if mutations.shiny    then return "shiny"    end
			return "basic"
		end

		local function isNewSlime(slimeId, mutations)
			if not dataServiceClient then return false end
			local indexData  = dataServiceClient:get("index") or {}
			local categories = indexData.categories or {}
			local category   = categories[getMutationTypeString(mutations)]
			local unlocked   = category and category.unlocked or {}
			return not unlocked[slimeId]
		end

		-- Bounded notification cache (prevents unbounded growth)
		local recentWebhookNotifications = {}
		local webhookNotifCount          = 0
		local WEBHOOK_NOTIF_MAX          = 500

		local function sendWebhookNotification(slimeId, slimeDataArg, mutations, webhookUrl, mentionUserId, notificationKey)
			if recentWebhookNotifications[notificationKey] then return end
			-- Evict oldest entries when limit reached
			if webhookNotifCount >= WEBHOOK_NOTIF_MAX then
				recentWebhookNotifications = {}
				webhookNotifCount          = 0
			end
			recentWebhookNotifications[notificationKey] = true
			webhookNotifCount = webhookNotifCount + 1

			if not doRequest or not HttpService then return end

			local mentionText  = (mentionUserId and mentionUserId ~= "") and ("<@" .. mentionUserId .. "> ") or ""
			local slimeName    = slimeDataArg and slimeDataArg.name or slimeId
			local displayName  = mutations and mutationsModule
				and mutationsModule.getDisplayName(slimeName, mutations)
				or slimeName
			local odds         = slimeDataArg and slimeDataArg.odds or nil
			local damage       = slimeDataArg and slimeDataArg.damage or 0
			local health       = slimeDataArg and slimeDataArg.health or 0
			local oddsMultiplier = mutations and mutationsModule
				and mutationsModule.getVisualOddsMultiplier(mutations) or 1
			local statBonus = mutations and mutationsModule
				and mutationsModule.getStatBonus(mutations, "damage") or 1
			local actualOdds   = odds and (odds / math.max(oddsMultiplier, 1e-9)) or nil
			local chanceText   = (actualOdds and actualOdds > 0)
				and string.format("1 in %s", formatNumber(math.floor(1 / actualOdds + 0.5)))
				or "N/A"
			local stats = dataServiceClient and dataServiceClient:get("stats") or {}
			local totalRolls = stats.rolls or 0
			local coins      = dataServiceClient and dataServiceClient:get("coins") or 0
			local totalKills = stats.kills or 0
			local playerName = localPlayer.Name
			local embedFields = { { name = "Chance", value = chanceText, inline = true } }
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
			if statsString ~= "" then
				table.insert(embedFields, { name = "Stats", value = statsString, inline = true })
			end
			if mutations and next(mutations) then
				local mutNames = {}
				for mut in pairs(mutations) do
					table.insert(mutNames, mut:sub(1, 1):upper() .. mut:sub(2))
				end
				table.insert(embedFields, { name = "Mutations", value = table.concat(mutNames, ", "), inline = true })
			end
			table.insert(embedFields, { name = "💰 Coins", value = formatNumber(coins),      inline = true })
			table.insert(embedFields, { name = "⚔️ Kills", value = formatNumber(totalKills), inline = true })

			local iconAssetId = (mutations and mutations.inverted)
				and (slimeDataArg and slimeDataArg.invertedIcon)
				or  (slimeDataArg and slimeDataArg.image)
			local thumbnailUrl = nil
			if iconAssetId and iconAssetId ~= "N/A" then
				local assetNumber = string.match(tostring(iconAssetId), "rbxassetid://(%d+)")
				if assetNumber then
					pcall(function()
						local r = doRequest({
							Url    = "https://thumbnails.roblox.com/v1/assets?assetIds="
								.. assetNumber .. "&size=420x420&format=Png&isCircular=false",
							Method = "GET",
						})
						if r and r.Success and HttpService then
							local decoded = HttpService:JSONDecode(r.Body)
							if decoded and decoded.data and decoded.data[1] then
								thumbnailUrl = decoded.data[1].imageUrl
							end
						end
					end)
				end
			end

			local embedColor = 0x3498db
			if mutations then
				if mutations.inverted then embedColor = 0x9b59b6
				elseif mutations.huge  then embedColor = 0xf1c40f
				elseif mutations.big   then embedColor = 0xe67e22
				elseif mutations.shiny then embedColor = 0xf39c12
				end
			end

			local userEmbed = {
				title       = "🎲 New Slime Rolled!",
				description = string.format(
					"**||%s||** rolled **%s**!\n\n🎲 **Total Rolls:** %s",
					playerName, displayName, tostring(totalRolls)
				),
				thumbnail   = thumbnailUrl and { url = thumbnailUrl, width = 64, height = 64 } or nil,
				fields      = embedFields,
				color       = embedColor,
			}

			pcall(function()
				doRequest({
					Url     = webhookUrl,
					Method  = "POST",
					Headers = { ["Content-Type"] = "application/json" },
					Body    = HttpService:JSONEncode({
						content    = mentionText,
						username   = "Cactus Hub",
						avatar_url = WEBHOOK_AVATAR,
						embeds     = { userEmbed },
					}),
				})
			end)
		end

		local lastRollResultsHash = nil
		task.spawn(function()
			while true do
				task.wait(0.1)
				if not modulesLoaded then task.wait(1) continue end
				if not (rayfieldLibrary.Flags.WebhookEnabled
					and rayfieldLibrary.Flags.WebhookEnabled.CurrentValue) then
					task.wait(1)
					continue
				end
				if savedWebhookUrl == "" or not rollSliceModule then task.wait(0.5) continue end
				pcall(function()
					local currentRolls = rollSliceModule.rollResults()
					if type(currentRolls) ~= "table" or #currentRolls == 0 then return end
					local currentHash = encodeRollResults(currentRolls)
					if currentHash == lastRollResultsHash then return end
					lastRollResultsHash = currentHash
					local sendAll     = rayfieldLibrary.Flags.WebhookSendAll
						and rayfieldLibrary.Flags.WebhookSendAll.CurrentValue
					local sendNewOnly = rayfieldLibrary.Flags.WebhookSendNew
						and rayfieldLibrary.Flags.WebhookSendNew.CurrentValue
					local sendMutated = rayfieldLibrary.Flags.WebhookSendMutated
						and rayfieldLibrary.Flags.WebhookSendMutated.CurrentValue
					local minChanceStr = rayfieldLibrary.Flags.WebhookMinChance
						and rayfieldLibrary.Flags.WebhookMinChance.CurrentValue
						or ""
					local minChanceNum = nil
					if minChanceStr and minChanceStr ~= "" then
						local num, suffix = minChanceStr:upper():gsub(",", ""):match("^(%d+%.?%d*)([KMBTQ]?)$")
						if num then
							local val    = tonumber(num) or 0
							suffix       = suffix or ""
							if     suffix == "K"          then val = val * 1e3
							elseif suffix == "M"          then val = val * 1e6
							elseif suffix == "B"          then val = val * 1e9
							elseif suffix == "T"          then val = val * 1e12
							elseif suffix:find("QD")      then val = val * 1e15
							elseif suffix:find("QN")      then val = val * 1e18
							end
							minChanceNum = val
						end
					end
					for _, rollResult in ipairs(currentRolls) do
						local slimeData = extractSlimeData(rollResult)
						if slimeData then
							local slimeId = tostring(slimeData.id or "")
							if slimeId ~= "" then
								local mutations       = type(slimeData.mutations) == "table"
									and next(slimeData.mutations) ~= nil
									and slimeData.mutations
									or nil
								local slimeDefinition = slimesModule and slimesModule.getSlime(slimeId)
								local hasMutation     = mutations ~= nil
								local isNew           = isNewSlime(slimeId, mutations)
								local shouldSend      = sendAll
									or (sendNewOnly and isNew)
									or (sendMutated and hasMutation)
								if shouldSend and minChanceNum then
									local odds2 = slimeDefinition and slimeDefinition.odds or 0
									local chanceValue = odds2 > 0 and (1 / odds2) or 0
									if chanceValue > minChanceNum then shouldSend = false end
								end
								if shouldSend then
									local userId2 = rayfieldLibrary.Flags.WebhookUserID
										and rayfieldLibrary.Flags.WebhookUserID.CurrentValue
										or ""
									local notificationKey = currentHash .. "_" .. slimeId
									task.spawn(
										sendWebhookNotification,
										slimeId, slimeDefinition, mutations,
										savedWebhookUrl, userId2, notificationKey
									)
								end
							end
						end
					end
				end)
			end
		end)

		-- ─────────────────────────────────────────────
		-- SETTINGS TAB
		-- ─────────────────────────────────────────────
		if settingsTab then
			pcall(function()
				settingsTab:CreateParagraph({
					Title   = "🍀 Want a serverhop script for luck servers?",
					Content = "Join the Discord! discord.gg/qMWFBWdcf",
				})
				settingsTab:CreateSection("System")
			end)
		end

		featureToggle(settingsTab, {
			Name         = "Anti Kick",
			CurrentValue = false,
			Flag         = "SettingsAntiKick",
			Callback     = function(value)
				if value then
					if not HAS_GETRAWMETA or not HAS_SETREADONLY or not HAS_NEWCCLOSURE or not HAS_GETNAMECALL then
						safeNotify({
							Title   = "Anti Kick",
							Content = "Required executor APIs unavailable (getrawmetatable / setreadonly / newcclosure / getnamecallmethod).",
							Duration = 5,
						})
						-- Flip the toggle back so user is not misled
						pcall(function()
							local f = rayfieldLibrary.Flags.SettingsAntiKick
							if f then f:Set(false) end
						end)
						return
					end
					pcall(function()
						local mt          = getrawmetatable(game)
						local oldNamecall = mt.__namecall
						setreadonly(mt, false)
						mt.__namecall = newcclosure(function(self, ...)
							local method = getnamecallmethod()
							if method == "Kick" and self == localPlayer then
								if rayfieldLibrary.Flags.SettingsAntiKick
									and rayfieldLibrary.Flags.SettingsAntiKick.CurrentValue
								then
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

		featureToggle(settingsTab, {
			Name = "Auto Rejoin On Disconnect", CurrentValue = false,
			Flag = "SettingsAutoRejoin", Callback = function() end,
		})

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
							local lp = Players.LocalPlayer
							for _, player in ipairs(Players:GetPlayers()) do
								if player ~= lp then
									local ok2, status = pcall(function()
										return lp:GetFriendStatus(player)
									end)
									if ok2 and (
										status == Enum.FriendStatus.NotFriend
										or status == Enum.FriendStatus.Unknown
									) then
										pcall(function() lp:RequestFriendship(player) end)
										task.wait(0.5)
									end
								end
							end
						end)
						task.wait(600)
					end
				end)
			end,
		})

		if settingsTab then
			pcall(function()
				settingsTab:CreateParagraph({
					Title   = "Friend Requests",
					Content = "NOTE : works based on your executor",
				})
				settingsTab:CreateSection("Advanced Optimization")
			end)
		end

		local OPT_VISUAL_TYPES = {
			ParticleEmitter=true, Trail=true, Beam=true, Fire=true, Smoke=true,
			Sparkles=true, SurfaceAppearance=true, Highlight=true,
			SelectionBox=true, SelectionSphere=true, Atmosphere=true,
		}
		local CHEAP_MATERIAL     = Enum.Material.SmoothPlastic
		local updatingOptimizations = false
		local optGPUToggle, optEffectsToggle, optGCToggle, maxFpsToggle

		-- Isolated per-script GC handle (avoids _G collision)
		local _memoryCleaner = nil

		local function setAllOptimizations(value)
			updatingOptimizations = true
			pcall(function() if maxFpsToggle     then maxFpsToggle:Set(value)     end end)
			pcall(function() if optGPUToggle     then optGPUToggle:Set(value)     end end)
			pcall(function() if optEffectsToggle then optEffectsToggle:Set(value) end end)
			pcall(function() if optGCToggle      then optGCToggle:Set(value)      end end)
			updatingOptimizations = false
			if value then
				if HAS_SETFPSCAP then pcall(function() setfpscap(0) end) end
				pcall(function()
					settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
					local lighting = game:GetService("Lighting")
					lighting.GlobalShadows             = false
					lighting.EnvironmentDiffuseScale   = 0
					lighting.EnvironmentSpecularScale  = 0
					for _, d in ipairs(workspace:GetDescendants()) do
						if d:IsA("BasePart") then
							d.CastShadow  = false
							d.Reflectance = 0
							d.Material    = CHEAP_MATERIAL
						end
					end
					if RunService then RunService:Set3dRenderingEnabled(false) end
				end)
				pcall(function()
					for _, d in ipairs(game:GetDescendants()) do
						if OPT_VISUAL_TYPES[d.ClassName] or d:IsA("Fire") then
							pcall(function() d:Destroy() end)
						end
					end
				end)
				if _memoryCleaner then pcall(function() _memoryCleaner:Disconnect() end) end
				if RunService then
					_memoryCleaner = RunService.Heartbeat:Connect(function() gcinfo() end)
				end
			else
				if _memoryCleaner then
					pcall(function() _memoryCleaner:Disconnect() end)
					_memoryCleaner = nil
				end
			end
		end

		if settingsTab then
			pcall(function()
				settingsTab:CreateToggle({
					Name = "Optimize All", CurrentValue = false, Flag = "OptimizeAll",
					Callback = function(Value)
						if updatingOptimizations then return end
						setAllOptimizations(Value)
					end,
				})
			end)
		end

		maxFpsToggle = featureToggle(settingsTab, {
			Name         = "Max FPS",
			CurrentValue = false,
			Flag         = "MaxFPS",
			Callback     = function(Value)
				if Value then
					if HAS_SETFPSCAP then
						pcall(function() setfpscap(0) end)
					else
						safeNotify({ Title = "Max FPS", Content = "setfpscap not available in this executor.", Duration = 3 })
					end
				end
			end,
		})

		optGPUToggle = featureToggle(settingsTab, {
			Name         = "Optimize GPU (Low Graphics)",
			CurrentValue = false,
			Flag         = "OptimizeGPU",
			Callback     = function(Value)
				if updatingOptimizations or not Value then return end
				pcall(function()
					settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
					local lighting = game:GetService("Lighting")
					lighting.GlobalShadows            = false
					lighting.EnvironmentDiffuseScale  = 0
					lighting.EnvironmentSpecularScale = 0
					for _, d in ipairs(workspace:GetDescendants()) do
						if d:IsA("BasePart") then
							d.CastShadow  = false
							d.Reflectance = 0
							d.Material    = CHEAP_MATERIAL
						end
					end
					if RunService then RunService:Set3dRenderingEnabled(false) end
				end)
			end,
		})

		optEffectsToggle = featureToggle(settingsTab, {
			Name         = "Destroy Effects",
			CurrentValue = false,
			Flag         = "DestroyEffects",
			Callback     = function(Value)
				if updatingOptimizations or not Value then return end
				pcall(function()
					for _, d in ipairs(game:GetDescendants()) do
						if OPT_VISUAL_TYPES[d.ClassName] or d:IsA("Fire") then
							pcall(function() d:Destroy() end)
						end
					end
				end)
			end,
		})

		optGCToggle = featureToggle(settingsTab, {
			Name         = "Lua GC (Memory Cleaner)",
			CurrentValue = false,
			Flag         = "LuaGC",
			Callback     = function(Value)
				if updatingOptimizations then return end
				if Value then
					if _memoryCleaner then pcall(function() _memoryCleaner:Disconnect() end) end
					if RunService then
						_memoryCleaner = RunService.Heartbeat:Connect(function() gcinfo() end)
					end
				else
					if _memoryCleaner then
						pcall(function() _memoryCleaner:Disconnect() end)
						_memoryCleaner = nil
					end
				end
			end,
		})

		-- ─────────────────────────────────────────────
		-- STATS TAB
		-- ─────────────────────────────────────────────
		local function safeGet(...)
			local ok2, data = pcall(function() return dataServiceClient._data._data end)
			if not ok2 or type(data) ~= "table" then return 0 end
			local cur = data
			for _, key in ipairs({ ... }) do
				if type(cur) ~= "table" then return 0 end
				cur = cur[key]
				if cur == nil then return 0 end
			end
			return cur
		end

		local function safeNum(...)
			return tonumber(safeGet(...)) or 0
		end

		local SUFFIXES = {
			{ 1e24, "Sp" }, { 1e21, "Sx" }, { 1e18, "Qn" }, { 1e15, "Qd" },
			{ 1e12, "T"  }, { 1e9,  "B"  }, { 1e6,  "M"  }, { 1e3,  "K"  },
		}

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
			if days    > 0 then return days .. "d " .. hours .. "h " .. minutes .. "m"
			elseif hours > 0 then return hours .. "h " .. minutes .. "m"
			elseif minutes > 0 then return minutes .. "m " .. math.floor(seconds % 60) .. "s"
			else return math.floor(seconds % 60) .. "s"
			end
		end

		local function countKeys(t)
			if type(t) ~= "table" then return 0 end
			local c = 0
			for _ in pairs(t) do c = c + 1 end
			return c
		end

		local function getBestRoll()
			local rarestData = safeGet("stats", "rarestRoll", "slimeData")
			if type(rarestData) ~= "table" then return "None", "N/A" end
			local id        = tostring(rarestData.id or "?")
			local mutations = rarestData.mutations
			local prefix    = ""
			if type(mutations) == "table" then
				if mutations.inverted then prefix = "Inverted "
				elseif mutations.shiny and mutations.huge then prefix = "Shiny Huge "
				elseif mutations.shiny and mutations.big  then prefix = "Shiny Big "
				elseif mutations.huge  then prefix = "Huge "
				elseif mutations.shiny then prefix = "Shiny "
				elseif mutations.big   then prefix = "Big "
				end
			end
			local name = prefix .. id:sub(1, 1):upper() .. id:sub(2)
			local odds = safeNum("stats", "rarestRoll", "odds")
			return name, odds > 0 and ("1 in " .. fmt(math.floor(odds))) or "N/A"
		end

		local function getEquippedDisplay()
			local equipped = safeGet("equipped")
			if type(equipped) ~= "table" then return "None" end
			local names = {}
			for i = 1, 7 do
				local uid = equipped[i]
				if uid and type(uid) == "string" then
					local clean = uid:match("%-(.+)$") or uid:gsub("^%.", "")
					table.insert(names, clean:sub(1, 1):upper() .. clean:sub(2))
				end
			end
			table.sort(names)
			return #names > 0 and table.concat(names, ", ") or "None"
		end

		local function getIndexCounts()
			local categories = safeGet("index", "categories")
			if type(categories) ~= "table" then return 0, 0, 0, 0, 0 end
			local function count(cat)
				local t = categories[cat]
				return type(t) == "table" and countKeys(t.unlocked or {}) or 0
			end
			return count("basic"), count("big"), count("shiny"), count("huge"), count("inverted")
		end

		local function getTotalInventory()
			local inv = safeGet("inventory")
			if type(inv) ~= "table" then return 0 end
			local total = 0
			for _, v in pairs(inv) do if type(v) == "number" then total = total + v end end
			return total
		end

		local function getUniqueSpecies()
			local inv = safeGet("inventory")
			if type(inv) ~= "table" then return 0 end
			local seen, count = {}, 0
			for key in pairs(inv) do
				if type(key) == "string" and not key:match("^%.") then
					local base = key:match("%-(.+)$") or key
					if not seen[base] then seen[base] = true count = count + 1 end
				end
			end
			return count
		end

		local sessionStart = os.clock()
		local startRolls   = safeNum("stats", "rolls")
		local startKills   = safeNum("stats", "kills")
		local startCoins   = safeNum("coins")
		local startGoop    = safeNum("goop")
		local prevRolls, prevCoins, prevGoop = startRolls, startCoins, startGoop
		local lastUpdateTime = os.clock()
		local windowRPS, windowCPS, windowGPS = nil, nil, nil
		local lastRollMove, lastCoinMove, lastGoopMove = os.clock(), os.clock(), os.clock()
		local STALE = 60

		task.spawn(function()
			while true do
				task.wait(10)
				pcall(function()
					local now = os.clock()
					local dt  = math.max(1, now - lastUpdateTime)
					lastUpdateTime = now
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
		local function lbl(key, text)
			statLabels[key] = safeCreateLabel(statsTab, text)
		end
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
				task.wait(2)
				pcall(function()
					local now     = os.clock()
					local elapsed = math.max(1, now - sessionStart)
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
					safeSetLabel(statLabels.sess,
						string.format("Session: %dh%dm%ds  |  Played: %s  |  Rebirths: %s",
							sh, sm, ss, fmtTime(timePlayed), fmt(rebirths)))
					safeSetLabel(statLabels.rolls1,
						string.format("Rolls/sec: %.2f  |  Rolls/min: %s  |  Rolls/hr: %s",
							rps, fmt(rps * 60), fmt(rps * 3600)))
					safeSetLabel(statLabels.rolls2,
						"Session Rolls: " .. fmt(sessionRolls) .. "  |  Lifetime: " .. fmt(rolls))
					safeSetLabel(statLabels.coins1,
						"Coins/min: " .. fmt(cps * 60) .. "  |  Coins/hr: " .. fmt(cps * 3600))
					safeSetLabel(statLabels.coins2,
						"Session Coins: " .. fmt(sessionCoins) .. "  |  Total Ever: " .. fmt(totalCoins))
					safeSetLabel(statLabels.goop1,
						"Goop/min: " .. fmt(gps * 60) .. "  |  Goop/hr: " .. fmt(gps * 3600))
					safeSetLabel(statLabels.goop2,
						"Session Goop: " .. fmt(sessionGoop) .. "  |  Balance: " .. fmt(goop))
					safeSetLabel(statLabels.kills,
						"Session Kills: " .. fmt(sessionKills) .. "  |  Lifetime Kills: " .. fmt(kills))
					safeSetLabel(statLabels.best,  "Best Ever: " .. bestName .. "  |  Odds: " .. bestOdds)
					safeSetLabel(statLabels.daily, "Best Today Odds: " .. dailyStr)
					safeSetLabel(statLabels.prog,
						"Zone: " .. fmt(zone) .. "  |  Max Zone: " .. fmt(maxZone) .. "  |  Roll Currency: " .. fmt(rollCurrency))
					safeSetLabel(statLabels.idx1,
						"Basic: " .. basic .. "  |  Big: " .. big .. "  |  Shiny: " .. shiny
						.. "  |  Huge: " .. huge .. "  |  Inverted: " .. inverted)
					safeSetLabel(statLabels.inv,
						"Total Slimes: " .. fmt(getTotalInventory())
						.. "  |  Species: " .. getUniqueSpecies()
						.. "  |  Crafting: " .. crafting)
					safeSetLabel(statLabels.equipped, "Equipped: " .. getEquippedDisplay())
				end)
			end
		end)

		-- ─────────────────────────────────────────────
		-- AUTO REJOIN ON DISCONNECT
		-- ─────────────────────────────────────────────
		if GuiService then
			GuiService.ErrorMessageChanged:Connect(function()
				pcall(function()
					if rayfieldLibrary.Flags.SettingsAutoRejoin
						and rayfieldLibrary.Flags.SettingsAutoRejoin.CurrentValue
						and TeleportService
					then
						TeleportService:TeleportToPlaceInstance(
							game.PlaceId,
							game.JobId,
							localPlayer
						)
					end
				end)
			end)
		end

		-- ─────────────────────────────────────────────
		-- FINALIZE
		-- ─────────────────────────────────────────────
		pcall(function() rayfieldLibrary:LoadConfiguration() end)
		Logger:info("CactusHub", "Init", "Script initialization complete")
	end)

	if not ok then
		warn("[CactusHub] Fatal error: " .. tostring(err))
	end
end)
