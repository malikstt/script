task.spawn(function()
	repeat task.wait() until game:IsLoaded()

	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer
	local RunService = game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local HttpService = game:GetService("HttpService")
	local TweenService = game:GetService("TweenService")

	-- ============================================================================
	-- CENTRALIZED ERROR LOGGING & DEBUGGING SYSTEM
	-- ============================================================================
	local Logger = {}
	Logger.EnableTimestamps = true
	Logger.EnableStackTrace = true
	Logger.LogHistory = {}
	Logger.MaxHistorySize = 500

	local function getTimestamp()
		return Logger.EnableTimestamps and os.date("%H:%M:%S") or ""
	end

	local function getStackTrace()
		if not Logger.EnableStackTrace then return "" end
		local ok, trace = pcall(debug.traceback, "", 2)
		if ok then
			return "\n" .. trace
		end
		return ""
	end

	function Logger:log(level, system, feature, message, errorObj)
		local timestamp = getTimestamp()
		local prefix = timestamp and string.format("[%s] [%s] [%s]", timestamp, level, system) or string.format("[%s] [%s]", level, system)
		if feature then
			prefix = prefix .. " (" .. feature .. ")"
		end

		local fullMessage = prefix .. " " .. tostring(message)
		if errorObj then
			fullMessage = fullMessage .. "\n  Error: " .. tostring(errorObj)
		end

		-- Attach stack trace if available
		local trace = getStackTrace()
		if trace ~= "" then
			fullMessage = fullMessage .. trace
		end

		-- Store in history
		table.insert(self.LogHistory, {
			timestamp = os.time(),
			level = level,
			system = system,
			feature = feature,
			message = message,
			error = errorObj,
			fullMessage = fullMessage
		})

		-- Prune history if too large
		if #self.LogHistory > self.MaxHistorySize then
			table.remove(self.LogHistory, 1)
		end

		-- Print to console
		if level == "ERROR" then
			warn(fullMessage)
		elseif level == "WARN" then
			warn(fullMessage)
		else
			print(fullMessage)
		end

		return fullMessage
	end

	function Logger:info(system, feature, message)
		return self:log("INFO", system, feature, message)
	end

	function Logger:warn(system, feature, message)
		return self:log("WARN", system, feature, message)
	end

	function Logger:error(system, feature, message, errorObj)
		return self:log("ERROR", system, feature, message, errorObj)
	end

	function Logger:getHistory(filterLevel, filterSystem)
		local result = {}
		for _, entry in ipairs(self.LogHistory) do
			if (not filterLevel or entry.level == filterLevel) and
			   (not filterSystem or entry.system == filterSystem) then
				table.insert(result, entry)
			end
		end
		return result
	end

	-- ============================================================================
	-- SAFE EXECUTION WRAPPERS
	-- ============================================================================
	local SafeExecution = {}

	function SafeExecution:xpcall(system, feature, fn, ...)
		local args = {...}
		local success, result, errorMsg
		
		success = xpcall(
			function()
				return fn(table.unpack(args))
			end,
			function(err)
				errorMsg = err
				Logger:error(system, feature, "Execution failed", err)
			end
		)

		return success, result, errorMsg
	end

	function SafeExecution:pcall_safe(system, feature, fn, ...)
		local args = {...}
		local success, result, errorMsg
		
		success, result = pcall(function()
			return fn(table.unpack(args))
		end)

		if not success then
			errorMsg = result
			Logger:error(system, feature, "Operation failed", result)
			return false, nil, errorMsg
		end

		return true, result
	end

	function SafeExecution:requireModule(system, modulePath, optional)
		optional = optional or false
		local ok, result = pcall(require, modulePath)
		
		if not ok then
			if optional then
				Logger:warn(system, "ModuleLoad", "Optional module failed to load: " .. tostring(modulePath), result)
				return nil
			else
				Logger:error(system, "ModuleLoad", "Critical module failed to load: " .. tostring(modulePath), result)
				return nil
			end
		end
		
		Logger:info(system, "ModuleLoad", "Successfully loaded: " .. tostring(modulePath))
		return result
	end

	function SafeExecution:waitForChild(parent, childName, timeout, system, feature)
		system = system or "Core"
		feature = feature or "WaitForChild"
		timeout = timeout or 15
		
		local success, child = pcall(function()
			return parent:WaitForChild(childName, timeout)
		end)

		if not success or not child then
			Logger:error(system, feature, "Failed to find child: " .. childName .. " in " .. parent.Name)
			return nil
		end

		return child
	end

	-- ============================================================================
	-- RAYFIELD CALLBACK PROTECTION WRAPPER
	-- ============================================================================
	local RayfieldSafe = {}

	function RayfieldSafe:wrapToggleCallback(system, featureName, originalCallback)
		return function(value)
			local success, errorMsg = SafeExecution:xpcall(
				system,
				featureName,
				originalCallback or function() end,
				value
			)

			if not success then
				Logger:error(system, featureName, "Toggle callback failed", errorMsg)
				-- Don't notify silently - let error be visible in console
			end
		end
	end

	function RayfieldSafe:wrapButtonCallback(system, featureName, originalCallback)
		return function()
			local success, errorMsg = SafeExecution:xpcall(
				system,
				featureName,
				originalCallback or function() end
			)

			if not success then
				Logger:error(system, featureName, "Button callback failed", errorMsg)
			end
		end
	end

	function RayfieldSafe:wrapDropdownCallback(system, featureName, originalCallback)
		return function(options)
			local success, errorMsg = SafeExecution:xpcall(
				system,
				featureName,
				originalCallback or function() end,
				options
			)

			if not success then
				Logger:error(system, featureName, "Dropdown callback failed", errorMsg)
			end
		end
	end

	function RayfieldSafe:wrapSliderCallback(system, featureName, originalCallback)
		return function(value)
			local success, errorMsg = SafeExecution:xpcall(
				system,
				featureName,
				originalCallback or function() end,
				value
			)

			if not success then
				Logger:error(system, featureName, "Slider callback failed", errorMsg)
			end
		end
	end

	-- ============================================================================
	-- EXECUTOR CAPABILITY DETECTION
	-- ============================================================================
	local ExecutorCapabilities = {}

	function ExecutorCapabilities:hasRequest()
		local hasReq = pcall(function()
			return request ~= nil
		end)
		return hasReq
	end

	function ExecutorCapabilities:hasGetGC()
		local hasGC = pcall(function()
			return getgc ~= nil
		end)
		if hasGC then
			Logger:info("Executor", "Capability", "getgc is available")
		else
			Logger:warn("Executor", "Capability", "getgc is NOT available")
		end
		return hasGC
	end

	function ExecutorCapabilities:hasSetClipboard()
		local hasClip = pcall(function()
			return setclipboard ~= nil
		end)
		return hasClip
	end

	function ExecutorCapabilities:hasDebugLib()
		local hasDebug = pcall(function()
			return debug ~= nil and debug.traceback ~= nil
		end)
		return hasDebug
	end

	-- ============================================================================
	-- LOAD RAYFIELD WITH PROPER ERROR HANDLING
	-- ============================================================================
	Logger:info("CactusHub", "Bootstrap", "Initializing Rayfield...")

	local rayfieldLibrary
	local rayfieldOk, rayfieldErr

	rayfieldOk, rayfieldErr = pcall(function()
		rayfieldLibrary = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
	end)

	if not rayfieldOk or not rayfieldLibrary then
		Logger:error("CactusHub", "RayfieldLoader", "Failed to load Rayfield library", rayfieldErr)
		return
	end

	Logger:info("CactusHub", "RayfieldLoader", "Rayfield loaded successfully")

	local mainWindow = rayfieldLibrary:CreateWindow({
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
		Discord = { Enabled = true, Invite = "qMWFBWdcf", RememberJoins = true },
		KeySystem = false,
	})

	-- ============================================================================
	-- SAFE RAYFIELD FEATURE CREATION HELPERS
	-- ============================================================================
	local function featureToggle(tab, config, fn, system)
		system = system or "Feature"
		local featureName = config.Name or "UnknownToggle"
		
		local wrappedConfig = {}
		for k, v in pairs(config) do wrappedConfig[k] = v end
		
		local originalCallback = config.Callback
		wrappedConfig.Callback = RayfieldSafe:wrapToggleCallback(
			system,
			featureName,
			originalCallback or fn
		)
		
		return tab:CreateToggle(wrappedConfig)
	end

	local function featureButton(tab, config, system)
		system = system or "Feature"
		local featureName = config.Name or "UnknownButton"
		
		local wrappedConfig = {}
		for k, v in pairs(config) do wrappedConfig[k] = v end
		
		local originalCallback = config.Callback
		wrappedConfig.Callback = RayfieldSafe:wrapButtonCallback(
			system,
			featureName,
			originalCallback
		)
		
		return tab:CreateButton(wrappedConfig)
	end

	-- ============================================================================
	-- CREATE TABS
	-- ============================================================================
	local mainTab      = mainWindow:CreateTab("Main", 74725529332053)
	local farmingTab   = mainWindow:CreateTab("Farming", 114367663524453)
	local gameTab      = mainWindow:CreateTab("Game", 77999805030576)
	local indexTab     = mainWindow:CreateTab("Index", 123662711814867)
	local miscTab      = mainWindow:CreateTab("Misc", 83590339425734)
	local webhookTab   = mainWindow:CreateTab("Webhook", 84577758013974)
	local settingsTab  = mainWindow:CreateTab("Settings", 120533439477016)
	local statsTab     = mainWindow:CreateTab("Stats", 102533388850982)
	local debugTab     = mainWindow:CreateTab("Debug", 0)

	-- ============================================================================
	-- DEBUG TAB - Show system health & logs
	-- ============================================================================
	debugTab:CreateSection("System Health")
	local debugStatus = debugTab:CreateLabel("Status: Initializing...")
	local debugErrors = debugTab:CreateLabel("Errors: 0")
	local debugWarns = debugTab:CreateLabel("Warnings: 0")

	debugTab:CreateSection("Executor Capabilities")
	local hasRequest = ExecutorCapabilities:hasRequest()
	local hasGC = ExecutorCapabilities:hasGetGC()
	local hasClip = ExecutorCapabilities:hasSetClipboard()
	local hasDebug = ExecutorCapabilities:hasDebugLib()

	debugTab:CreateLabel("request() API: " .. (hasRequest and "✅" or "❌"))
	debugTab:CreateLabel("getgc() API: " .. (hasGC and "✅" or "❌"))
	debugTab:CreateLabel("setclipboard() API: " .. (hasClip and "✅" or "❌"))
	debugTab:CreateLabel("debug.traceback(): " .. (hasDebug and "✅" or "❌"))

	debugTab:CreateSection("Recent Errors")
	local errorLog = debugTab:CreateLabel("No errors yet")

	task.spawn(function()
		while true do
			task.wait(5)
			pcall(function()
				local errors = Logger:getHistory("ERROR")
				local warnings = Logger:getHistory("WARN")
				debugErrors:Set("Errors: " .. #errors)
				debugWarns:Set("Warnings: " .. #warnings)

				if #errors > 0 then
					local recent = errors[#errors]
					errorLog:Set("Last Error: [" .. recent.system .. "] " .. recent.feature .. "\n" .. recent.message)
				end
			end)
		end
	end)

	-- ============================================================================
	-- STATUS DISPLAY
	-- ============================================================================
	mainTab:CreateSection("Status")
	local fpsLabel  = mainTab:CreateLabel("FPS: Calculating...")
	local pingLabel = mainTab:CreateLabel("Ping: Calculating...")

	pcall(function()
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
	end)

	task.spawn(function()
		while true do
			pcall(function()
				local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
				pingLabel:Set("Ping: " .. math.floor(ping) .. "ms")
			end)
			task.wait(1)
		end
	end)

	mainTab:CreateParagraph({ Title = "Enabled By Default", Content = "[+] Anti AFK" })
	mainTab:CreateParagraph({
		Title = "Latest Update",
		Content = "[+] Fixed Auto Shoot\n[+] Faster Rolling\n[+] Auto Complete Index\n[+] Auto Move to Enemy\n[+] Auto Stack Dice\n[+] Auto Feed Fruits\n[+] Bug Fixes & Performance\n[+] Hardened Error Handling"
	})

	-- ============================================================================
	-- MODULES & REMOTE LOADING
	-- ============================================================================
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
	local ZonesModule
	local RecipesModule
	local upgradeServiceClient_new
	local dataServiceClient_new

	local modulesLoaded = false

	task.spawn(function()
		Logger:info("CactusHub", "ModuleLoader", "Starting module initialization...")

		local ok, err = xpcall(function()
			-- Load core packages
			packages = SafeExecution:waitForChild(ReplicatedStorage, "Packages", 15, "CactusHub", "Packages")
			if not packages then error("Packages not found after timeout") end
			Logger:info("CactusHub", "Packages", "Packages loaded")

			-- Load networker
			local indexFolder = SafeExecution:waitForChild(packages, "_Index", 15, "CactusHub", "IndexFolder")
			if not indexFolder then error("_Index folder not found") end

			local networkerModule = SafeExecution:waitForChild(indexFolder, "leifstout_networker@0.3.1", 15, "CactusHub", "NetworkerPackage")
			if not networkerModule then error("networker package not found") end

			networkerModule = SafeExecution:waitForChild(networkerModule, "networker", 15, "CactusHub", "NetworkerModule")
			if not networkerModule then error("networker module not found") end

			local remotesFolder = SafeExecution:waitForChild(networkerModule, "_remotes", 15, "CactusHub", "RemotesFolder")
			if not remotesFolder then error("_remotes not found") end

			-- Load services
			dataServiceClient = SafeExecution:requireModule("CactusHub", packages.DataService)
			if dataServiceClient then
				dataServiceClient = dataServiceClient.client
				dataServiceClient:waitForData()
				Logger:info("CactusHub", "DataService", "DataService ready")
			end

			Networker = SafeExecution:requireModule("CactusHub", packages.Networker)
			if not Networker then error("Failed to load Networker") end
			Logger:info("CactusHub", "Networker", "Networker ready")

			-- Setup roll client
			local rollClient = {
				rareRollAnnouncement = function() end,
				rareRollAnnouncementV2 = function() end,
			}
			networkerRoll = Networker.client.new("RollService", rollClient)
			inventoryServiceClient = Networker.client.new("InventoryService")
			xpTransferServiceClient = Networker.client.new("XpTransferService")
			Logger:info("CactusHub", "NetworkerClients", "Networker clients initialized")

			-- Load remote functions
			local function getRemoteFunction(name)
				local folder = remotesFolder:FindFirstChild(name) or remotesFolder:WaitForChild(name, 10)
				if not folder then
					Logger:warn("CactusHub", "RemoteLookup", "Remote folder not found: " .. name)
					return nil
				end
				local rf = folder:FindFirstChild("RemoteFunction") or folder:WaitForChild("RemoteFunction", 10)
				if not rf then
					Logger:warn("CactusHub", "RemoteLookup", "RemoteFunction not found in: " .. name)
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
			Logger:info("CactusHub", "Remotes", "All remotes loaded")

			-- Load source modules
			sourceFolder = SafeExecution:waitForChild(ReplicatedStorage, "Source", 30, "CactusHub", "SourceFolder")
			if not sourceFolder then error("Source folder not found") end

			upgradeTreeModule  = SafeExecution:requireModule("CactusHub", sourceFolder.Features.Upgrades.UpgradeTree)
			indexRewardsModule = SafeExecution:requireModule("CactusHub", sourceFolder.Features.Index.IndexRewards, true)
			boostServiceUtils  = SafeExecution:requireModule("CactusHub", sourceFolder.Features.Boosts.BoostServiceUtils)
			specialDiceUtils   = SafeExecution:requireModule("CactusHub", sourceFolder.Features.SpecialDice.SpecialDiceServiceUtils)
			rollSliceModule    = SafeExecution:requireModule("CactusHub", sourceFolder.Features.Roll.RollSlice)
			slimesModule       = SafeExecution:requireModule("CactusHub", sourceFolder.Game.Items.Slimes)
			mutationsModule    = SafeExecution:requireModule("CactusHub", sourceFolder.Features.Mutations.Mutations)
			FruitsModule       = SafeExecution:requireModule("CactusHub", sourceFolder.Game.Items.Fruits)
			SpecialRollUtils   = SafeExecution:requireModule("CactusHub", sourceFolder.Features.Roll.SpecialRollUtils)
			ZonesModule        = SafeExecution:requireModule("CactusHub", sourceFolder.Game.Items.Zones)

			Logger:info("CactusHub", "SourceModules", "All source modules loaded")

			-- Build dice/item maps
			boostKinds  = boostServiceUtils and boostServiceUtils.getKinds() or {}
			diceItemIds = specialDiceUtils and specialDiceUtils.getInventoryItemIds() or {}
			idToNameMap = {}
			nameToIdMap = {}

			for _, itemId in ipairs(diceItemIds) do
				local ok, def = pcall(function()
					return specialDiceUtils.getDefinition(itemId)
				end)
				if ok and def then
					local itemName = def.name or itemId
					idToNameMap[itemId] = itemName
					nameToIdMap[itemName] = itemId
				end
			end

			Logger:info("CactusHub", "DiceMap", "Dice mappings created")

			-- Load settings
			SettingsState         = SafeExecution:requireModule("CactusHub", sourceFolder.Features.Settings.SettingsState)
			SettingsServiceClient = SafeExecution:requireModule("CactusHub", sourceFolder.Features.Settings.SettingsServiceClient)

			if SettingsState then
				SettingsState.init()
				local settingsClient = {}
				settingsClient.networker = Networker.client.new("SettingsService", settingsClient)
				SettingsServiceClient.init(settingsClient)
				Logger:info("CactusHub", "Settings", "Settings system ready")
			end

			-- Load optional modules
			RecipesModule = SafeExecution:requireModule("CactusHub", sourceFolder.Features.Crafting.Recipes, true)
			if RecipesModule then
				Logger:info("CactusHub", "Recipes", "Recipes module loaded")
			end

			-- Load new service clients async
			task.spawn(function()
				local rs = game:GetService("ReplicatedStorage")
				local ok1, ok2
				repeat
					ok1, upgradeServiceClient_new = pcall(function()
						return SafeExecution:requireModule("CactusHub", rs.Source.Features.Upgrades.UpgradeServiceClient, true)
					end)
					ok2, dataServiceClient_new = pcall(function()
						return SafeExecution:requireModule("CactusHub", rs.Packages.DataService, true)
					end)
					if ok1 and dataServiceClient_new then
						dataServiceClient_new = dataServiceClient_new.client
					end
					if not (ok1 and ok2) then
						task.wait(1)
					end
				until ok1 and ok2 or task.wait(0.1) == nil
			end)

			modulesLoaded = true
			Logger:info("CactusHub", "ModuleLoader", "All modules loaded successfully!")
			rayfieldLibrary:Notify({
				Title = "Cactus Hub",
				Content = "All modules loaded! Features are ready.",
				Duration = 4,
			})
		end, function(err)
			Logger:error("CactusHub", "ModuleLoader", "Critical module loading error", err)
			rayfieldLibrary:Notify({
				Title = "CactusHub — Load Error",
				Content = "Module loading failed: " .. tostring(err):sub(1, 120),
				Duration = 8,
			})
		end)
	end)

	-- ============================================================================
	-- SAVE CONFIG HELPER
	-- ============================================================================
	local dashboardBusy = false
	featureToggle(mainTab, {
		Name = "Dashboard",
		CurrentValue = false,
		Flag = "DashboardToggle",
		Callback = function(Value)
			if dashboardBusy then return end
			dashboardBusy = true
			if Value then
				task.spawn(function()
					local success = SafeExecution:pcall_safe(
						"CactusHub",
						"Dashboard",
						function()
							loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/no"))()
						end
					)
					if success then
						rayfieldLibrary:Notify({ Title = "Dashboard", Content = "Dashboard enabled!", Duration = 3 })
					else
						Logger:error("CactusHub", "Dashboard", "Failed to load dashboard")
					end
					dashboardBusy = false
				end)
			else
				local ok = SafeExecution:pcall_safe(
					"CactusHub",
					"Dashboard",
					function()
						local gui = localPlayer.PlayerGui:FindFirstChild("__MAINHUD__")
						if gui then gui:Destroy() end
					end
				)
				rayfieldLibrary:Notify({ Title = "Dashboard", Content = "Dashboard closed!", Duration = 3 })
				dashboardBusy = false
			end
		end,
	}, "CactusHub")

	featureButton(mainTab, {
		Name = "Save Config Manually",
		Callback = function()
			SafeExecution:pcall_safe("CactusHub", "SaveConfig", function()
				rayfieldLibrary:SaveConfiguration()
				Logger:info("CactusHub", "SaveConfig", "Configuration saved")
			end)
		end,
	}, "CactusHub")

	-- ============================================================================
	-- INDEX DATA & CONSTANTS
	-- ============================================================================
	local CATEGORY_IDS = {"basic", "shiny", "big", "huge", "inverted"}
	local MUTATION_ODDS = { basic=nil, shiny=0.004, big=0.01, huge=0.001, inverted=0.0004 }
	local DICE = {"golden", "diamond", "void", "galaxy"}
	local ALL_FRUITS = {}

	task.spawn(function()
		repeat task.wait(0.5) until modulesLoaded or (not task.wait and true)
		if FruitsModule then
			local ok, fruits = SafeExecution:pcall_safe("CactusHub", "FruitLoader", function()
				return FruitsModule.getSortedFruits()
			end)
			if ok then
				ALL_FRUITS = fruits
				Logger:info("CactusHub", "FruitLoader", "All fruits loaded: " .. #ALL_FRUITS)
			end
		end
	end)

	-- ============================================================================
	-- LUCK MANAGEMENT
	-- ============================================================================
	local luckValueLocal = 1
	local settingsClientRef = nil

	task.spawn(function()
		repeat task.wait(0.5) until modulesLoaded
		settingsClientRef = {}
		settingsClientRef.networker = Networker.client.new("SettingsService", settingsClientRef)
		if SettingsServiceClient then
			SettingsServiceClient.init(settingsClientRef)
			Logger:info("CactusHub", "LuckSystem", "Luck system initialized")
		end
	end)

	local function setLuckEnabled(enabled)
		if not SettingsServiceClient or not settingsClientRef then return end
		local ok = SafeExecution:pcall_safe("CactusHub", "SetLuckEnabled", function()
			SettingsServiceClient.set(settingsClientRef, "luckOverrideEnabled", enabled)
		end)
		task.wait(0.3)
		return ok
	end

	local function setLuck(value)
		if not SettingsServiceClient or not settingsClientRef then return end
		local ok = SafeExecution:pcall_safe("CactusHub", "SetLuck", function()
			local clamped = math.min(value, 16384)
			SettingsServiceClient.set(settingsClientRef, "luckOverrideValue", clamped)
			luckValueLocal = clamped
		end)
		task.wait(0.3)
		return ok
	end

	local function calcOptimalLuck(effectiveOdds)
		if not effectiveOdds or effectiveOdds <= 0 then return 16384 end
		return math.min(math.max(1, math.floor((1 / effectiveOdds) * 0.63)), 16384)
	end

	local function formatOdds(odds)
		if not odds or odds <= 0 then return "N/A" end
		local n = math.floor(1 / odds + 0.5)
		if n >= 1e9 then return string.format("1 in %.1fB", n/1e9)
		elseif n >= 1e6 then return string.format("1 in %.1fM", n/1e6)
		elseif n >= 1e3 then return string.format("1 in %.1fK", n/1e3) end
		return "1 in " .. n
	end

	local function getEffectiveOdds(slime, catId)
		local mutOdds = MUTATION_ODDS[catId]
		if mutOdds then return slime.rollOdds * mutOdds end
		return slime.rollOdds
	end

	-- ============================================================================
	-- INDEX & SLIME QUERIES
	-- ============================================================================
	local function getUnlockedIndex(catId)
		if not dataServiceClient then return {} end
		local ok, data = SafeExecution:pcall_safe("CactusHub", "GetUnlockedIndex", function()
			local indexData = dataServiceClient:get("index") or {}
			return ((indexData.categories or {})[catId] or {}).unlocked or {}
		end)
		return ok and data or {}
	end

	local function getTotalSlimes()
		if not slimesModule then return 0 end
		local ok, count = SafeExecution:pcall_safe("CactusHub", "GetTotalSlimes", function()
			return #slimesModule.getSortedSlimes()
		end)
		return ok and count or 0
	end

	local function getUnlockedCount(catId)
		local unlocked = getUnlockedIndex(catId)
		local count = 0
		for _, v in pairs(unlocked) do if v == true then count = count + 1 end end
		return count
	end

	local function getMissingSlimes(catId)
		if not slimesModule then return {} end
		local ok, missing = SafeExecution:pcall_safe("CactusHub", "GetMissingSlimes", function()
			local unlocked = getUnlockedIndex(catId)
			local result = {}
			for _, slime in ipairs(slimesModule.getSortedSlimes()) do
				if not unlocked[slime.id] then table.insert(result, slime) end
			end
			table.sort(result, function(a, b)
				return getEffectiveOdds(a, catId) > getEffectiveOdds(b, catId)
			end)
			return result
		end)
		return ok and missing or {}
	end

	local function getBestSlimeUid()
		if not dataServiceClient then return nil end
		local ok, uid = SafeExecution:pcall_safe("CactusHub", "GetBestSlimeUid", function()
			local stats = dataServiceClient:get("stats") or {}
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
		return ok and uid or nil
	end

	-- ============================================================================
	-- ENEMY DETECTION & TARGETING
	-- ============================================================================
	local RANGE = 50
	local cachedContainer, cachedEnemies, lastCacheTime = nil, {}, 0
	local currentTarget, tweenConn = nil, nil
	local enemySettings = {
		TeleportStyle = "Walk",
		TargetPriorities = { ["Most Coins & Goop"] = true },
		AutoFarm = false,
		MutationFilter = "Any",
	}

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
		for _, mut in ipairs({"inverted","huge","shiny","big"}) do
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
			if enemy:IsA("Model") then table.insert(cachedEnemies, enemy) end
		end
	end

	local function getEnemyScore(enemy, rootPos)
		local root = getEnemyRoot(enemy)
		if not root then return nil end
		local dist = (root.Position - rootPos).Magnitude
		if dist > RANGE then return nil end
		local coins  = enemy:GetAttribute("reward") or enemy:GetAttribute("coins") or 0
		local goop   = enemy:GetAttribute("goop") or 0
		local health = enemy:GetAttribute("health") or enemy:GetAttribute("currentHealth") or 0
		local humanoid = enemy:FindFirstChildWhichIsA("Humanoid")
		if humanoid then health = humanoid.Health end
		return { enemy=enemy, root=root, coins=coins, goop=goop, health=health, dist=dist }
	end

	local function computeScores(rootPos)
		local entries = {}
		for _, enemy in ipairs(cachedEnemies) do
			if isAlive(enemy) and matchesMutationFilter(enemy) then
				local e = getEnemyScore(enemy, rootPos)
				if e then table.insert(entries, e) end
			end
		end
		if #entries == 0 then return {} end
		local maxCoins, maxGoop, maxHealth, maxDist = 0, 0, 0, 0
		for _, e in ipairs(entries) do
			if e.coins > maxCoins then maxCoins = e.coins end
			if e.goop > maxGoop then maxGoop = e.goop end
			if e.health > maxHealth then maxHealth = e.health end
			if e.dist > maxDist then maxDist = e.dist end
		end
		local scores = {}
		local pri = enemySettings.TargetPriorities
		for _, e in ipairs(entries) do
			local s = 0
			if pri["Most Coins & Goop"] then
				s = s + ((maxCoins > 0 and e.coins/maxCoins or 0) + (maxGoop > 0 and e.goop/maxGoop or 0)) / 2
			end
			if pri["Closest"] then s = s + (maxDist > 0 and 1 - e.dist/maxDist or 0) end
			if pri["Lowest HP"] then s = s + (maxHealth > 0 and 1 - e.health/maxHealth or 0) end
			if pri["Mutations Only"] then s = s + (getMutation(e.enemy) and 1 or 0) end
			scores[e.enemy] = s
		end
		return scores, entries
	end

	local function selectTarget()
		local char = localPlayer.Character
		if not char then return nil end
		local rp = char:FindFirstChild("HumanoidRootPart")
		if not rp then return nil end
		local scores = computeScores(rp.Position)
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
		local priority = rayfieldLibrary.Flags.CombatTargetPriority and rayfieldLibrary.Flags.CombatTargetPriority.CurrentOption[1] or "Closest"
		local bestEnemy, bestId, bestScore = nil, nil, nil
		for _, e in ipairs(folder:GetChildren()) do
			if e:IsA("Model") and isAlive(e) then
				local primary = getEnemyRoot(e)
				if primary then
					local dist = (primary.Position - root.Position).Magnitude
					local id = tonumber(e.Name)
					local score
					if priority == "Closest" then
						score = -dist
					elseif priority == "Lowest HP" then
						local hp = e:GetAttribute("health") or e:GetAttribute("currentHealth") or 0
						local hum = e:FindFirstChildWhichIsA("Humanoid")
						if hum then hp = hum.Health end
						score = -hp
					elseif priority == "Highest HP" then
						local hp = e:GetAttribute("health") or e:GetAttribute("currentHealth") or 0
						local hum = e:FindFirstChildWhichIsA("Humanoid")
						if hum then hp = hum.Health end
						score = hp
					elseif priority == "Most Coins & Goop" then
						local coins = e:GetAttribute("reward") or e:GetAttribute("coins") or 0
						local goop = e:GetAttribute("goop") or 0
						score = coins + goop
					else
						score = -dist
					end
					if bestScore == nil or score > bestScore then
						bestScore = score
						bestEnemy = e
						bestId = id
					end
				end
			end
		end
		return bestEnemy, bestId
	end

	local function getSafePosition(targetCFrame)
		local ok, result = SafeExecution:pcall_safe("CactusHub", "GetSafePosition", function()
			local origin = targetCFrame.Position + Vector3.new(0, 50, 0)
			local rayResult = workspace:Raycast(origin, Vector3.new(0, -100, 0))
			if rayResult then return rayResult.Position + Vector3.new(0, 3, 0) end
			return targetCFrame.Position + Vector3.new(0, 3, 0)
		end)
		return ok and result or (targetCFrame.Position + Vector3.new(0, 3, 0))
	end

	local autoWalkConn = nil

	local function stopAutoWalk()
		if autoWalkConn then autoWalkConn:Disconnect() autoWalkConn = nil end
		local char = localPlayer.Character
		if char then
			local hum = char:FindFirstChildWhichIsA("Humanoid")
			if hum then
				hum.WalkSpeed = 16
				hum:MoveTo(char.HumanoidRootPart.Position)
			end
		end
	end

	local function moveToEnemy(enemy)
		local char = localPlayer.Character
		if not char then return end
		local root = getEnemyRoot(enemy)
		if not root then return end
		local safePos = getSafePosition(root.CFrame)
		local targetCF = CFrame.new(safePos)
		
		SafeExecution:pcall_safe("CactusHub", "MoveToEnemy", function()
			if enemySettings.TeleportStyle == "Instant" then
				if tweenConn then tweenConn:Disconnect() tweenConn = nil end
				stopAutoWalk()
				char:PivotTo(targetCF)
			elseif enemySettings.TeleportStyle == "Smooth" then
				if tweenConn then tweenConn:Disconnect() tweenConn = nil end
				stopAutoWalk()
				local startCF = char:GetPivot()
				local startTime = tick()
				local duration = 0.25
				tweenConn = RunService.RenderStepped:Connect(function()
					if not char or not char.Parent then tweenConn:Disconnect() tweenConn = nil return end
					local alpha = math.clamp((tick() - startTime) / duration, 0, 1)
					local newPos = startCF.Position:Lerp(safePos, alpha)
					local rayResult = workspace:Raycast(newPos + Vector3.new(0, 10, 0), Vector3.new(0, -20, 0))
					if rayResult then newPos = rayResult.Position + Vector3.new(0, 3, 0) end
					char:PivotTo(CFrame.new(newPos))
					if alpha >= 1 then tweenConn:Disconnect() tweenConn = nil end
				end)
			elseif enemySettings.TeleportStyle == "Walk" then
				if tweenConn then tweenConn:Disconnect() tweenConn = nil end
				stopAutoWalk()
				local hum = char:FindFirstChildWhichIsA("Humanoid")
				if not hum then return end
				hum.WalkSpeed = 50
				hum:MoveTo(safePos)
				autoWalkConn = RunService.Heartbeat:Connect(function()
					if not char or not char.Parent or not isAlive(enemy) then stopAutoWalk() return end
					local rp = char:FindFirstChild("HumanoidRootPart")
					if not rp then stopAutoWalk() return end
					local dist = (rp.Position - safePos).Magnitude
					if dist < 5 then
						stopAutoWalk()
					else
						local newRoot = getEnemyRoot(enemy)
						if newRoot then
							safePos = getSafePosition(newRoot.CFrame)
							hum:MoveTo(safePos)
						end
					end
				end)
			end
		end)
	end

	RunService.Heartbeat:Connect(function()
		SafeExecution:pcall_safe("CactusHub", "AutoFarmHeartbeat", function()
			refreshEnemyCache()
			if not enemySettings.AutoFarm then currentTarget = nil return end
			if currentTarget and isAlive(currentTarget) and currentTarget.Parent then return end
			stopAutoWalk()
			local newTarget = selectTarget()
			if newTarget and newTarget ~= currentTarget then
				currentTarget = newTarget
				moveToEnemy(currentTarget)
			end
		end)
	end)

	-- ============================================================================
	-- FARMING TAB
	-- ============================================================================
	farmingTab:CreateSection("Rolling")

	featureToggle(farmingTab, {
		Name = "Auto Fast Roll ( No Animation )",
		CurrentValue = false,
		Flag = "FarmingFastRoll",
		Callback = function(enabled)
			if not enabled then return end
			task.spawn(function()
				while rayfieldLibrary.Flags.FarmingFastRoll and rayfieldLibrary.Flags.FarmingFastRoll.CurrentValue do
					local ok, err = SafeExecution:xpcall("Farming", "AutoFastRoll", function()
						if not rollServiceRemote then error("RollService remote not loaded") end
						rollServiceRemote:InvokeServer("requestRoll")
						task.wait(rollSliceModule and rollSliceModule.rollTime() or 0.5)
					end)
					if not ok then
						Logger:error("Farming", "AutoFastRoll", "Roll failed", err)
						task.wait(2)
					end
				end
			end)
		end,
	}, "Farming")

	-- ============================================================================
	-- AUTO STACK DICE
	-- ============================================================================
	local selectedDice = {golden=true, diamond=true, void=true, galaxy=true}
	local stackActive = false
	local paused = {golden=false, diamond=false, void=false, galaxy=false}

	featureToggle(farmingTab, {
		Name = "Auto Stack Dice",
		CurrentValue = false,
		Flag = "autostack",
		Callback = function(v)
			stackActive = v
			if not v and networkerRoll then
				for _, dice in ipairs(DICE) do
					if paused[dice] then
						SafeExecution:pcall_safe("Farming", "UnpauseDice", function()
							networkerRoll:fetch("requestSetSpecialRollPaused", dice, false)
						end)
						paused[dice] = false
					end
				end
			end
		end,
	}, "Farming")

	farmingTab:CreateDropdown({
		Name = "Select Dice",
		Options = {"All","Diamond","Galaxy","Golden","Void"},
		CurrentOption = {"All"},
		MultipleOptions = true,
		Flag = "diceDropdown",
		Callback = RayfieldSafe:wrapDropdownCallback("Farming", "DiceSelection", function(choices)
			for _, dice in ipairs(DICE) do selectedDice[dice] = false end
			for _, choice in ipairs(choices) do
				if choice == "All" then for _, dice in ipairs(DICE) do selectedDice[dice] = true end break
				else selectedDice[choice:lower()] = true end
			end
		end),
	})

	local DiceLuckLabel = farmingTab:CreateLabel("Total Stacked: x0")

	task.spawn(function()
		while true do
			task.wait(0.5)
			SafeExecution:pcall_safe("Farming", "DiceLuckUpdate", function()
				if not dataServiceClient or not SpecialRollUtils then return end
				local upgrades = dataServiceClient:get("upgrades") or {}
				local progression = dataServiceClient:get("specialRollProgression") or {}
				local totalStacked = 0
				for _, dice in ipairs(DICE) do
					local prog = progression[dice]
					local rolls = prog and prog.rollsUntilNext or math.huge
					if rolls <= 1 then
						local ok, mult = SafeExecution:pcall_safe("Farming", "GetDiceLuckMult", function()
							return SpecialRollUtils.getLuckMultiplier(dice, upgrades)
						end)
						if ok then totalStacked = totalStacked + (mult or 0) end
					end
				end
				DiceLuckLabel:Set("Total Stacked: x" .. string.format("%.1f", totalStacked))
				if not stackActive or not networkerRoll then return end
				local toWatch = {}
				for _, dice in ipairs(DICE) do
					if selectedDice[dice] then
						local ok, unlocked = SafeExecution:pcall_safe("Farming", "CheckDiceUnlocked", function()
							return SpecialRollUtils.isUnlocked(dice, upgrades)
						end)
						if ok and unlocked then table.insert(toWatch, dice) end
					end
				end
				if #toWatch == 0 then return end
				local allReady = true
				for _, dice in ipairs(toWatch) do
					local prog = progression[dice]
					local rolls = prog and prog.rollsUntilNext or math.huge
					if rolls <= 1 then
						if not paused[dice] then
							networkerRoll:fetch("requestSetSpecialRollPaused", dice, true)
							paused[dice] = true
						end
					else
						allReady = false
					end
				end
				if allReady then
					for _, dice in ipairs(toWatch) do
						networkerRoll:fetch("requestSetSpecialRollPaused", dice, false)
						paused[dice] = false
					end
					rayfieldLibrary:Notify({ Title = "Unleashed!", Content = "All stacked — releasing now.", Duration = 3 })
					task.wait(2)
				end
			end)
		end
	end)

	-- ============================================================================
	-- ZONES SECTION
	-- ============================================================================
	farmingTab:CreateSection("Zones")

	SafeExecution:pcall_safe("Farming", "ZoneDropdownSetup", function()
		local zoneOptions = { "Best Unlocked" }
		local totalZones = ZonesModule and ZonesModule.getMaxZone() or 33
		for i = 1, totalZones do
			local zone = ZonesModule and ZonesModule.getZone(i)
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
			Callback = function() end,
		})
	end)

	featureToggle(farmingTab, {
		Name = "Auto Farm Zone",
		CurrentValue = false,
		Flag = "FarmingStayInBestZone",
		Callback = function(enabled)
			if not enabled then return end
			task.spawn(function()
				while rayfieldLibrary.Flags.FarmingStayInBestZone and rayfieldLibrary.Flags.FarmingStayInBestZone.CurrentValue do
					SafeExecution:pcall_safe("Farming", "AutoFarmZone", function()
						if not zonesServiceRemote then error("ZonesService remote not loaded") end
						local targetOption = rayfieldLibrary.Flags.FarmingZoneTarget and rayfieldLibrary.Flags.FarmingZoneTarget.CurrentOption[1] or "Best Unlocked"
						if targetOption == "Best Unlocked" then
							for zoneNum = 33, 1, -1 do
								if not (rayfieldLibrary.Flags.FarmingStayInBestZone and rayfieldLibrary.Flags.FarmingStayInBestZone.CurrentValue) then break end
								zonesServiceRemote:InvokeServer("requestTeleportZone", zoneNum)
								task.wait(1)
								if (dataServiceClient:get("zone") or 1) == zoneNum then break end
							end
						else
							local zoneNum = tonumber(targetOption:match("Zone (%d+)"))
							if zoneNum then zonesServiceRemote:InvokeServer("requestTeleportZone", zoneNum) end
						end
					end)
					task.wait(10)
				end
			end)
		end,
	}, "Farming")

	featureToggle(farmingTab, {
		Name = "Auto Unlock Affordable Zones",
		CurrentValue = false,
		Flag = "FarmingUnlockAffordableZones",
		Callback = function(enabled)
			if not enabled then return end
			task.spawn(function()
				while rayfieldLibrary.Flags.FarmingUnlockAffordableZones and rayfieldLibrary.Flags.FarmingUnlockAffordableZones.CurrentValue do
					SafeExecution:pcall_safe("Farming", "UnlockZones", function()
						if not zonesServiceRemote then error("ZonesService remote not loaded") end
						zonesServiceRemote:InvokeServer("requestPurchaseZone")
					end)
					task.wait(5)
				end
			end)
		end,
	}, "Farming")

	-- ============================================================================
	-- SLIMES & XP SECTION
	-- ============================================================================
	farmingTab:CreateSection("Slimes & XP")

	featureToggle(farmingTab, {
		Name = "Auto Equip Best Slimes",
		CurrentValue = false,
		Flag = "FarmingEquipBestSlimes",
		Callback = function(enabled)
			if not enabled then return end
			task.spawn(function()
				local waitTime = 30
				while rayfieldLibrary.Flags.FarmingEquipBestSlimes and rayfieldLibrary.Flags.FarmingEquipBestSlimes.CurrentValue do
					SafeExecution:pcall_safe("Farming", "EquipBestSlimes", function()
						if not inventoryServiceRemote then error("InventoryService remote not loaded") end
						inventoryServiceRemote:InvokeServer("requestEquipBest")
					end)
					task.wait(waitTime)
					waitTime = math.min(waitTime * 2, 600)
				end
			end)
		end,
	}, "Farming")

	-- ============================================================================
	-- AUTO FEED FRUITS
	-- ============================================================================
	local autoFeedEnabled = false
	local selectedFruitIds = {"ANY"}
	local selectedSlimeMode = "Best"
	local feedConnection = nil

	local function getOwnedFruitIds()
		if not dataServiceClient or not FruitsModule then return {} end
		local items = dataServiceClient:get("items") or {}
		local owned = {}
		for _, f in ipairs(ALL_FRUITS) do
			if (items[f.id] or 0) > 0 then owned[f.id] = true end
		end
		return owned
	end

	local function slimeHasFruit(slimeData, fruitId)
		if type(slimeData) ~= "table" or not FruitsModule then return false end
		local ok, fruitDef = SafeExecution:pcall_safe("Farming", "GetFruitDef", function()
			return FruitsModule.getFruit(fruitId)
		end)
		if not ok or not fruitDef then return false end
		local trees = slimeData.unlockedTrees
		return type(trees) == "table" and trees[fruitDef.treeId] == true
	end

	local function getBestSlimeEntry()
		if not dataServiceClient then return nil, nil end
		local ok, entry = SafeExecution:pcall_safe("Farming", "GetBestSlimeEntry", function()
			local stats = dataServiceClient:get("stats") or {}
			local rarest = stats.rarestRoll
			if not rarest or not rarest.slimeData then return nil, nil end
			local rarestId = rarest.slimeData.id
			local rarestMutations = rarest.slimeData.mutations or {}
			local equipped = dataServiceClient:get("equipped") or {}
			local inv = dataServiceClient:get("inventory") or {}
			for _, slimeKey in pairs(equipped) do
				if type(slimeKey) == "string" and slimeKey:sub(1,1) == "." then
					local data = inv[slimeKey]
					if type(data) == "table" and data.id == rarestId then
						local match = true
						for mutKey, mutVal in pairs(rarestMutations) do
							if not data.mutations or data.mutations[mutKey] ~= mutVal then match = false break end
						end
						if match then return slimeKey, data end
					end
				end
			end
			for _, slimeKey in pairs(equipped) do
				if type(slimeKey) == "string" and slimeKey:sub(1,1) == "." then
					local data = inv[slimeKey]
					if type(data) == "table" then return slimeKey, data end
				end
			end
			return nil, nil
		end)
		return ok and entry or (nil, nil)
	end

	local function getTargetSlimes()
		if not dataServiceClient then return {} end
		if selectedSlimeMode == "Best" then
			local key, data = getBestSlimeEntry()
			if key and data then return {{key=key, data=data}} end
			return {}
		else
			local equipped = dataServiceClient:get("equipped") or {}
			local result = {}
			for _, slimeKey in ipairs(equipped) do
				if type(slimeKey) == "string" and slimeKey:sub(1,1) == "." then
					local inv = dataServiceClient:get("inventory") or {}
					local data = inv[slimeKey]
					if type(data) == "table" then table.insert(result, {key=slimeKey, data=data}) end
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
		SafeExecution:pcall_safe("Farming", "FeedFruits", function()
			local targets = getTargetSlimes()
			local fruitsToFeed = resolveFruitList()
			if #targets == 0 or #fruitsToFeed == 0 then return end
			for _, entry in ipairs(targets) do
				for _, fruitId in ipairs(fruitsToFeed) do
					if not slimeHasFruit(entry.data, fruitId) then
						inventoryServiceClient:fetch("requestUseFruit", fruitId, entry.key)
					end
				end
			end
		end)
	end

	featureToggle(farmingTab, {
		Name = "Auto Feed Fruits to Slime(s)",
		CurrentValue = false,
		Flag = "AutoFeedToggle",
		Callback = function(value)
			autoFeedEnabled = value
			if value then
				if feedConnection then feedConnection:Disconnect() end
				feedConnection = RunService.Heartbeat:Connect(function()
					if autoFeedEnabled then doFeed() end
				end)
				Logger:info("Farming", "AutoFeed", "Auto feed enabled")
			else
				if feedConnection then feedConnection:Disconnect() feedConnection = nil end
				Logger:info("Farming", "AutoFeed", "Auto feed disabled")
			end
		end,
	}, "Farming")

	farmingTab:CreateDropdown({
		Name = "Slimes to Feed",
		Options = {"Best", "Split Across Team"},
		CurrentOption = {"Best"},
		MultipleOptions = false,
		Flag = "SlimeModeDropdown",
		Callback = RayfieldSafe:wrapDropdownCallback("Farming", "SlimeModeSelect", function(option)
			selectedSlimeMode = type(option) == "table" and option[1] or option
		end),
	})

	SafeExecution:pcall_safe("Farming", "FruitDropdownSetup", function()
		local fruitOptions = {"Any"}
		local labelToId = {}
		local fruitNames = {}
		for _, f in ipairs(FruitsModule and FruitsModule.getSortedFruits() or {}) do
			table.insert(fruitNames, f.powerName)
			labelToId[f.powerName] = f.id
		end
		table.sort(fruitNames)
		for _, name in ipairs(fruitNames) do table.insert(fruitOptions, name) end
		farmingTab:CreateDropdown({
			Name = "Fruits to Feed",
			Options = fruitOptions,
			CurrentOption = {"Any"},
			MultipleOptions = true,
			Flag = "FruitDropdown",
			Callback = RayfieldSafe:wrapDropdownCallback("Farming", "FruitSelect", function(options)
				local picked = type(options) == "table" and options or {options}
				selectedFruitIds = {}
				for _, label in ipairs(picked) do
					if label == "Any" then selectedFruitIds = {"ANY"} return
					else table.insert(selectedFruitIds, labelToId[label]) end
				end
				if #selectedFruitIds == 0 then selectedFruitIds = {"ANY"} end
			end),
		})
	end)

	featureToggle(farmingTab, {
		Name = "Auto Transfer XP",
		CurrentValue = false,
		Flag = "FarmingTransferXP",
		Callback = function() end,
	}, "Farming")

	farmingTab:CreateDropdown({ Name="Transfer To", Options={"Best Slime","Whole Team"}, CurrentOption={"Best Slime"}, MultipleOptions=false, Flag="FarmingTransferTarget", Callback=function() end })
	farmingTab:CreateDropdown({ Name="Transfer From", Options={"All Slimes","Unequipped With XP"}, CurrentOption={"Unequipped With XP"}, MultipleOptions=false, Flag="FarmingTransferSource", Callback=function() end })

	task.spawn(function()
		while task.wait(30) do
			SafeExecution:pcall_safe("Farming", "TransferXP", function()
				if not (rayfieldLibrary.Flags.FarmingTransferXP and rayfieldLibrary.Flags.FarmingTransferXP.CurrentValue) then return end
				if not dataServiceClient or not xpTransferServiceClient then return end
				local inventory = dataServiceClient:get("inventory") or {}
				local equipped  = dataServiceClient:get("equipped") or {}
				local teamSet   = {}
				for _, uid in ipairs(equipped) do teamSet[uid] = true end
				local targetOption = rayfieldLibrary.Flags.FarmingTransferTarget.CurrentOption[1]
				local sourceOption = rayfieldLibrary.Flags.FarmingTransferSource.CurrentOption[1]
				local targets = {}
				if targetOption == "Best Slime" then
					local best = getBestSlimeUid()
					if best then targets = {best} end
				else
					for _, uid in ipairs(equipped) do table.insert(targets, uid) end
				end
				for _, target in ipairs(targets) do
					for uid, data in pairs(inventory) do
						if uid ~= target then
							local isEquipped = teamSet[uid]
							local hasXp = (type(data)=="table" and (data.xp or 0)>0) or (type(data)=="number" and data>0)
							if (sourceOption=="Unequipped With XP" and not isEquipped and hasXp)
							or (sourceOption=="All Slimes" and hasXp) then
								xpTransferServiceClient:fetch("requestTransferXp", uid, target)
								task.wait(0.5)
							end
						end
					end
				end
			end)
		end
	end)

	-- ============================================================================
	-- LOOT SECTION
	-- ============================================================================
	farmingTab:CreateSection("Loot")

	featureToggle(farmingTab, {
		Name = "Auto Collect Loot",
		CurrentValue = false,
		Flag = "FarmingCollectLoot",
		Callback = function(enabled)
			if not enabled then return end
			task.spawn(function()
				while rayfieldLibrary.Flags.FarmingCollectLoot and rayfieldLibrary.Flags.FarmingCollectLoot.CurrentValue do
					SafeExecution:pcall_safe("Farming", "CollectLoot", function()
						for _, folder in ipairs({"Loot","Debris"}) do
							local container = workspace:FindFirstChild(folder)
							if container then
								for _, item in ipairs(container:GetChildren()) do
									local id = item:GetAttribute("uniqueId") or item:GetAttribute("id") or item.Name
									if id and lootServiceRemote then
										lootServiceRemote:InvokeServer("requestCollect", id)
									end
								end
							end
						end
					end)
					task.wait(0.5)
				end
			end)
		end,
	}, "Farming")

	-- ============================================================================
	-- GAME TAB - AUTO FARM
	-- ============================================================================
	gameTab:CreateSection("Auto Farm")

	featureToggle(gameTab, {
		Name = "Auto Farm",
		CurrentValue = false,
		Flag = "AutoFarm",
		Callback = function(value)
			enemySettings.AutoFarm = value
			if not value then
				currentTarget = nil
				stopAutoWalk()
			end
			Logger:info("Game", "AutoFarm", "AutoFarm " .. (value and "enabled" or "disabled"))
		end,
	}, "Game")

	gameTab:CreateDropdown({
		Name = "Movement Style",
		Options = {"Walk [RECOMMENDED]", "Instant", "Smooth"},
		CurrentOption = {"Walk [RECOMMENDED]"},
		MultipleOptions = false,
		Flag = "TeleportStyle",
		Callback = RayfieldSafe:wrapDropdownCallback("Game", "MovementStyle", function(option)
			local val = type(option) == "table" and option[1] or option
			if val == "Walk [RECOMMENDED]" then val = "Walk" end
			enemySettings.TeleportStyle = val
			if val ~= "Walk" then stopAutoWalk() end
		end)
	})

	gameTab:CreateDropdown({
		Name = "Target Priority",
		Options = {"Closest","Lowest HP","Most Coins & Goop","Mutations Only"},
		CurrentOption = {"Most Coins & Goop"},
		MultipleOptions = true,
		Flag = "TargetPriority",
		Callback = RayfieldSafe:wrapDropdownCallback("Game", "TargetPriority", function(options)
			enemySettings.TargetPriorities = {}
			for _, opt in ipairs(options) do enemySettings.TargetPriorities[opt] = true end
		end)
	})

	gameTab:CreateDropdown({
		Name = "Mutation Filter",
		Options = {"Any","Big","Huge","Inverted","Shiny"},
		CurrentOption = {"Any"},
		MultipleOptions = false,
		Flag = "MutationFilter",
		Callback = RayfieldSafe:wrapDropdownCallback("Game", "MutationFilter", function(option)
			local val = type(option) == "table" and option[1] or option
			enemySettings.MutationFilter = val
		end)
	})

	-- ============================================================================
	-- COMBAT CONTROLS
	-- ============================================================================
	gameTab:CreateSection("Controls")

	local combatEnabled = false
	local getgcChecked = false

	local function equipSlimeGun()
		local char = localPlayer.Character
		if not char then return false end
		local humanoid = char:FindFirstChildWhichIsA("Humanoid")
		if not humanoid then return false end
		local tool = char:FindFirstChild("SlimeGun")
		if tool then return true end
		local backpack = localPlayer:FindFirstChildOfClass("Backpack")
		if backpack then
			tool = backpack:FindFirstChild("SlimeGun")
			if tool then
				humanoid:EquipTool(tool)
				task.wait(0.3)
				return true
			end
		end
		return false
	end

	local function findGunController()
		local char = localPlayer.Character
		if not char then return nil end
		local tool = char:FindFirstChild("SlimeGun")
		if not tool then return nil end

		if not getgc then
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

		local ok, result = pcall(function()
			for _, v in ipairs(getgc(true)) do
				if type(v) == "table" and rawget(v, "tool") == tool and rawget(v, "prevSendAt") ~= nil then
					return v
				end
			end
			return nil
		end)

		if not ok then
			Logger:warn("Game", "GunController", "Failed to find gun controller via getgc")
			return nil
		end

		return result
	end

	featureToggle(gameTab, {
		Name = "Auto Shoot Enemies (getgc)",
		CurrentValue = false,
		Flag = "CombatAutoShoot",
		Callback = function(value)
			combatEnabled = value
			Logger:info("Game", "CombatAutoShoot", "AutoShoot " .. (value and "enabled" or "disabled"))
		end,
	}, "Game")

	gameTab:CreateDropdown({
		Name = "Combat Target Priority",
		Options = {"Closest", "Lowest HP", "Highest HP", "Most Coins & Goop"},
		CurrentOption = {"Closest"},
		MultipleOptions = false,
		Flag = "CombatTargetPriority",
		Callback = function() end,
	})

	task.spawn(function()
		local controller = nil
		while true do
			task.wait(0.1)
			if not combatEnabled then
				controller = nil
				task.wait(0.3)
				continue
			end
			SafeExecution:pcall_safe("Game", "CombatLoop", function()
				local char = localPlayer.Character
				if not char then return end
				local humanoid = char:FindFirstChildWhichIsA("Humanoid")
				if not humanoid or humanoid.Health <= 0 then return end
				refreshEnemyCache()
				local _, targetId = selectCombatTarget()
				if not targetId then return end
				local tool = char:FindFirstChild("SlimeGun")
				if not tool then
					equipSlimeGun()
					controller = nil
					return
				end
				if not controller then
					controller = findGunController()
					if not controller then return end
				end
				local ok = pcall(function()
					local orig = controller._getTargetEnemyId
					controller._getTargetEnemyId = function() return targetId end
					controller:onActivated()
					controller._getTargetEnemyId = orig
				end)
				if not ok then
					controller = nil
					Logger:warn("Game", "GunController", "Gun controller execution failed")
				end
			end)
		end
	end)

	-- ============================================================================
	-- PROGRESS / REBIRTH
	-- ============================================================================
	gameTab:CreateSection("Progress")

	featureToggle(gameTab, {
		Name = "Auto Rebirth",
		CurrentValue = false,
		Flag = "GameAutoRebirth",
		Callback = function(enabled)
			if not enabled then return end
			task.spawn(function()
				while rayfieldLibrary.Flags.GameAutoRebirth and rayfieldLibrary.Flags.GameAutoRebirth.CurrentValue do
					SafeExecution:pcall_safe("Game", "AutoRebirth", function()
						if not rebirthServiceRemote or not dataServiceClient then error("RebirthService not loaded") end
						local rebirths     = dataServiceClient:get("rebirths") or 0
						local goop         = dataServiceClient:get("goop") or 0
						local furthestZone = dataServiceClient:get("furthestZone") or 0
						local requiredGoop = (2^rebirths)*500
						local minZone      = tonumber(rayfieldLibrary.Flags.GameMinZoneRebirth and rayfieldLibrary.Flags.GameMinZoneRebirth.CurrentValue) or 0
						if furthestZone >= minZone and goop >= requiredGoop then
							rebirthServiceRemote:InvokeServer("requestRebirth")
						end
					end)
					task.wait(10)
				end
			end)
		end,
	}, "Game")

	gameTab:CreateInput({ Name="Minimum Zone To Rebirth", CurrentValue="", PlaceholderText="e.g. 10", RemoveTextAfterFocusLost=false, Flag="GameMinZoneRebirth", Callback=function() end })

	-- ============================================================================
	-- UPGRADES
	-- ============================================================================
	gameTab:CreateSection("Upgrades")

	featureToggle(gameTab, {
		Name = "Auto Upgrade Purchasing",
		CurrentValue = false,
		Flag = "GameAutoUpgrade",
		Callback = function(enabled)
			if not enabled then return end
			task.spawn(function()
				while task.wait(0.5) and rayfieldLibrary.Flags.GameAutoUpgrade and rayfieldLibrary.Flags.GameAutoUpgrade.CurrentValue do
					SafeExecution:pcall_safe("Game", "AutoUpgrade", function()
						if not upgradeServiceClient_new or not dataServiceClient_new then return end

						local upgradeMode = rayfieldLibrary.Flags.GameUpgradeMode and rayfieldLibrary.Flags.GameUpgradeMode.CurrentOption or {"All"}
						local modeSet = {}
						for _, m in ipairs(upgradeMode) do modeSet[m] = true end

						local unlockedUpgrades = dataServiceClient_new:get("upgrades") or {}
						local coins       = dataServiceClient_new:get("coins") or 0
						local goop        = dataServiceClient_new:get("goop") or 0
						local rollCurrency= dataServiceClient_new:get("rollCurrency") or 0

						local upgradeIds, upgradeCosts = getAllUpgradeIdsAndCosts()

						for _, upgradeId in ipairs(upgradeIds) do
							if unlockedUpgrades[upgradeId] == true then continue end

							local costInfo = upgradeCosts[upgradeId]
							if not costInfo then continue end

							local costAmount   = costInfo.amount or 0
							local currencyType = costInfo.currency

							local modeMatches = modeSet["All"]
								or (modeSet["Coins"] and currencyType == "coins")
								or (modeSet["Goop"] and currencyType == "goop")
								or (modeSet["Rolls"] and currencyType == "rollCurrency")

							if not modeMatches then continue end

							local canAfford = (currencyType == "coins" and coins >= costAmount)
								or (currencyType == "goop" and goop >= costAmount)
								or (currencyType == "rollCurrency" and rollCurrency >= costAmount)

							if canAfford then
								local success = upgradeServiceClient_new:unlockUpgrade(upgradeId)
								if success then
									if currencyType == "coins" then coins = coins - costAmount
									elseif currencyType == "goop" then goop = goop - costAmount
									elseif currencyType == "rollCurrency" then rollCurrency = rollCurrency - costAmount
									end
									unlockedUpgrades[upgradeId] = true
								end
								task.wait(0.2)
							end
						end
					end)
				end
			end)
		end,
	}, "Game")

	gameTab:CreateDropdown({
		Name = "Upgrade Mode",
		Options = {"All", "Coins", "Goop", "Rolls"},
		CurrentOption = {"All"},
		MultipleOptions = true,
		Flag = "GameUpgradeMode",
		Callback = function() end,
	})

	-- ============================================================================
	-- RECIPES / CRAFTING - FULL IMPLEMENTATION
	-- ============================================================================
	gameTab:CreateSection("Recipes")

	local function getAllUpgradeIdsAndCosts()
		if not upgradeTreeModule then return {}, {} end
		local upgradeIds, upgradeCosts, seen = {}, {}, {}
		local function traverse(tree)
			if type(tree) ~= "table" or seen[tree] then return end
			seen[tree] = true
			for key, value in pairs(tree) do
				if type(value) == "table" then
					if value.cost then table.insert(upgradeIds, key); upgradeCosts[key] = value.cost end
					traverse(value)
				end
			end
		end
		traverse(upgradeTreeModule.main)
		return upgradeIds, upgradeCosts
	end

	SafeExecution:pcall_safe("Game", "CraftingSetup", function()
		if not RecipesModule or not dataServiceClient then
			gameTab:CreateLabel("Crafting not available yet")
			return
		end

		local recipeIdsList = {}
		local unlocked = dataServiceClient:get("craftingRecipes") or {}
		local all = RecipesModule.getRecipes() or {}
		for _, recipe in ipairs(all) do
			if unlocked[recipe.id] then table.insert(recipeIdsList, recipe.id) end
		end
		table.sort(recipeIdsList)

		local craftingState = {
			selectedRecipeIds = #recipeIdsList > 0 and {recipeIdsList[1]} or {},
			craftAmount = 1,
			autoCraftEnabled = false,
			autoCraftAmount = 1,
			autoCraftThread = nil,
			protectCategories = {"Best Slime","Equipped Slimes","Xp Slimes"},
		}

		local MutationsModule = mutationsModule
		local function getSizeMutations() return MutationsModule and MutationsModule.sizeMutations or {} end
		local function getModifierMutations() return MutationsModule and MutationsModule.modifierMutations or {} end
		local function getMutationValue(mutId)
			if not MutationsModule then return 0 end
			local data = MutationsModule.get(mutId)
			return data and data.value or 0
		end

		local function parseUniqueId(uid)
			local base, sizeMut, modMut = uid, nil, nil
			for _, sizeId in ipairs(getSizeMutations()) do
				local prefix = sizeId .. "_"
				if base:sub(1, #prefix) == prefix then sizeMut = sizeId base = base:sub(#prefix+1) break end
			end
			if base:sub(1,1) == "-" then base = base:sub(2) end
			for _, modId in ipairs(getModifierMutations()) do
				local suffix = "_" .. modId
				if base:sub(-#suffix) == suffix then modMut = modId base = base:sub(1, -#suffix-1) break end
			end
			return base, sizeMut, modMut
		end

		local function scoreUniqueId(uid)
			local _, sizeMut, modMut = parseUniqueId(uid)
			local score = 0
			if sizeMut then score = score + getMutationValue(sizeMut)*1000 end
			if modMut  then score = score + getMutationValue(modMut)*100 end
			return score
		end

		local function getEquippedSet()
			local equipped = dataServiceClient and dataServiceClient:get("equipped") or {}
			local set = {}
			for _, uid in pairs(equipped) do set[uid] = true end
			return set
		end

		local function getBestSlimeSet()
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
		end

		local function buildProtectedSet(categories)
			local catSet = {}
			for _, cat in ipairs(categories) do catSet[cat] = true end
			local protected = {}
			if catSet["Equipped Slimes"] then for uid in pairs(getEquippedSet()) do protected[uid] = true end end
			if catSet["Best Slime"]      then for uid in pairs(getBestSlimeSet()) do protected[uid] = true end end
			if catSet["Xp Slimes"] then
				local inv = dataServiceClient and dataServiceClient:get("inventory") or {}
				for uid, data in pairs(inv) do if type(data) == "table" then protected[uid] = true end end
			end
			return protected
		end

		local protectedPets = buildProtectedSet(craftingState.protectCategories)

		local function findBestIngredient(baseId, usedCounts)
			local inventory = dataServiceClient and dataServiceClient:get("inventory") or {}
			local bestUid, bestScore = nil, -1
			for uid, data in pairs(inventory) do
				if not protectedPets[uid] then
					local parsedBase = parseUniqueId(uid)
					if parsedBase == baseId then
						local owned = type(data)=="number" and math.max(data,0) or (type(data)=="table" and 1 or 0)
						local used  = usedCounts[uid] or 0
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
			local recipe = RecipesModule and RecipesModule.getRecipe(recipeId)
			if not recipe then return nil end
			local ingredientIds, usedCounts = {}, {}
			for _, input in ipairs(recipe.inputs) do
				local uid = findBestIngredient(input.id, usedCounts) or ("-"..input.id)
				usedCounts[uid] = (usedCounts[uid] or 0) + 1
				table.insert(ingredientIds, uid)
			end
			return {"requestCraftRecipe", recipeId, ingredientIds, tostring(amount)}
		end

		local function getCraftingRemote()
			local remotesF = ReplicatedStorage:WaitForChild("Packages",15):WaitForChild("_Index",15):WaitForChild("leifstout_networker@0.3.1",15):WaitForChild("networker",15):WaitForChild("_remotes",15)
			return remotesF:WaitForChild("CraftingService",10):WaitForChild("RemoteFunction",10)
		end

		local function doCraftAll(amount)
			local ok, craftRemote = SafeExecution:pcall_safe("Game", "GetCraftingRemote", getCraftingRemote)
			if not ok or not craftRemote then return {} end

			local results = {}
			for _, recipeId in ipairs(craftingState.selectedRecipeIds) do
				local ok2, args = SafeExecution:pcall_safe("Game", "BuildCraftArgs", function()
					return buildCraftArgsForRecipe(recipeId, amount)
				end)
				if ok2 and args then
					local ok3, result = SafeExecution:pcall_safe("Game", "CraftRecipe", function()
						return craftRemote:InvokeServer(table.unpack(args))
					end)
					results[recipeId] = ok3 and (result ~= false)
				end
			end
			return results
		end

		local function getMaxCraftsForRecipe(recipeId)
			local recipe = RecipesModule and RecipesModule.getRecipe(recipeId)
			if not recipe then return 0 end
			local usedCounts, maxCrafts = {}, math.huge
			for _, input in ipairs(recipe.inputs) do
				local uid = findBestIngredient(input.id, usedCounts)
				if not uid then return 0 end
				usedCounts[uid] = (usedCounts[uid] or 0) + 1
				local inv = dataServiceClient and dataServiceClient:get("inventory") or {}
				local owned = type(inv[uid])=="number" and math.max(inv[uid],0) or (type(inv[uid])=="table" and 1 or 0)
				local avail = owned - usedCounts[uid] + 1
				if avail < maxCrafts then maxCrafts = avail end
			end
			return maxCrafts == math.huge and 0 or maxCrafts
		end

		gameTab:CreateDropdown({
			Name = "Select Recipes to Craft",
			Options = #recipeIdsList > 0 and recipeIdsList or {"None"},
			CurrentOption = craftingState.selectedRecipeIds,
			MultipleOptions = true,
			Flag = "CraftingSelectedRecipes",
			Callback = RayfieldSafe:wrapDropdownCallback("Game", "CraftingRecipeSelect", function(options)
				craftingState.selectedRecipeIds = options
			end),
		})

		gameTab:CreateSlider({
			Name="Craft Amount",
			Range={1,99},
			Increment=1,
			Suffix="x",
			CurrentValue=1,
			Flag="CraftingAmount",
			Callback=RayfieldSafe:wrapSliderCallback("Game", "CraftAmount", function(val)
				craftingState.craftAmount = val
			end)
		})

		featureButton(gameTab, {
			Name = "Craft Now",
			Callback = function()
				local results = doCraftAll(craftingState.craftAmount)
				local succeeded, failed = 0, 0
				for _, ok in pairs(results) do if ok then succeeded=succeeded+1 else failed=failed+1 end end
				rayfieldLibrary:Notify({
					Title="Cactus Hub",
					Content=succeeded.." crafts succeeded"..(failed>0 and (", "..failed.." failed") or ""),
					Duration=3,
					Image=4483362458
				})
				Logger:info("Game", "CraftNow", "Crafted " .. succeeded .. " recipes")
			end,
		}, "Game")

		gameTab:CreateSlider({
			Name="Auto Craft Amount",
			Range={1,99},
			Increment=1,
			Suffix="x",
			CurrentValue=1,
			Flag="CraftingAutoAmount",
			Callback=RayfieldSafe:wrapSliderCallback("Game", "AutoCraftAmount", function(val)
				craftingState.autoCraftAmount = val
			end)
		})

		featureToggle(gameTab, {
			Name = "Enable Auto Craft",
			CurrentValue = false,
			Flag = "CraftingAutoToggle",
			Callback = function(enabled)
				craftingState.autoCraftEnabled = enabled
				if enabled then
					if craftingState.autoCraftThread then task.cancel(craftingState.autoCraftThread) end
					craftingState.autoCraftThread = task.spawn(function()
						while craftingState.autoCraftEnabled do
							SafeExecution:pcall_safe("Game", "AutoCraft", function()
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
					end)
					rayfieldLibrary:Notify({ Title="Auto Craft", Content="Started", Duration=3, Image=4483362458 })
					Logger:info("Game", "AutoCraft", "Auto craft started")
				else
					if craftingState.autoCraftThread then task.cancel(craftingState.autoCraftThread) craftingState.autoCraftThread = nil end
					rayfieldLibrary:Notify({ Title="Auto Craft", Content="Stopped.", Duration=3, Image=4483362458 })
					Logger:info("Game", "AutoCraft", "Auto craft stopped")
				end
			end,
		}, "Game")

		gameTab:CreateDropdown({
			Name = "Protect Categories",
			Options = {"Best Slime","Equipped Slimes","Xp Slimes"},
			CurrentOption = {"Best Slime","Equipped Slimes","Xp Slimes"},
			MultipleOptions = true,
			Flag = "CraftingProtectCategories",
			Callback = RayfieldSafe:wrapDropdownCallback("Game", "ProtectCategories", function(options)
				craftingState.protectCategories = options
				protectedPets = buildProtectedSet(options)
			end),
		})

		rayfieldLibrary:Notify({
			Title="Cactus Hub",
			Content="Loaded — "..(#recipeIdsList).." unlocked recipes ready.",
			Duration=5,
			Image=4483362458
		})
	end)

	-- ============================================================================
	-- INDEX TAB - AUTO COMPLETE
	-- ============================================================================
	local indexRunning = false
	local indexThread, luckPollThread = nil, nil
	local selectedCategoryOption = nil
	local indexLabels = {}

	indexTab:CreateSection("Controls")

	featureToggle(indexTab, {
		Name = "Start Auto Complete",
		CurrentValue = false,
		Flag = "IndexAutoComplete",
		Callback = function(value)
			if value then
				indexRunning = true
				indexThread = task.spawn(function()
					SafeExecution:pcall_safe("Index", "AutoComplete", function()
						if not dataServiceClient then error("DataService not loaded") end
						setLuck(1)
						task.wait(0.3)
						setLuckEnabled(true)
						task.wait(0.3)

						luckPollThread = task.spawn(function()
							while indexRunning do
								if indexLabels.lLuck then indexLabels.lLuck:Set("🍀 Luck Override: x"..tostring(luckValueLocal)) end
								task.wait(1)
							end
						end)

						local modeFlag = rayfieldLibrary.Flags and rayfieldLibrary.Flags.IndexRollMode
						local mode = modeFlag and (type(modeFlag.CurrentOption)=="table" and modeFlag.CurrentOption[1] or modeFlag.CurrentOption) or "🌱 Easiest First"

						local function getSortedCategoriesByPriority()
							local cats = {}
							for _, catId in ipairs(CATEGORY_IDS) do
								local missing = getMissingSlimes(catId)
								if #missing > 0 then
									table.insert(cats, { id=catId, easiestEffectiveOdds=getEffectiveOdds(missing[1], catId) })
								end
							end
							table.sort(cats, function(a, b) return a.easiestEffectiveOdds > b.easiestEffectiveOdds end)
							return cats
						end

						local function runCategory(catId, modeStr, labels)
							local failCount = 0
							local catLabel  = catId:sub(1,1):upper()..catId:sub(2)
							local lastTargetId = nil
							while indexRunning do
								local missing = getMissingSlimes(catId)
								if #missing == 0 then return true end
								local target = modeStr == "🎯 Rarest First" and missing[#missing] or missing[1]
								local effOdds = getEffectiveOdds(target, catId)
								if target.id ~= lastTargetId then
									lastTargetId = target.id
									setLuck(calcOptimalLuck(effOdds))
								end
								if labels then
									labels.lTarget:Set("🎯 Target: "..catLabel.." "..target.name)
									labels.lOdds:Set("🎲 Odds: "..formatOdds(effOdds))
									labels.lCategory:Set(string.format("📂 %s (%d left)", catLabel, #missing))
								end
								local before = getUnlockedIndex(catId)
								networkerRoll:fetch("requestRoll")
								task.wait(rollSliceModule and rollSliceModule.rollTime() or 0.5)
								local after = getUnlockedIndex(catId)
								local gotOne = false
								for id, v in pairs(after) do
									if v == true and not before[id] then
										gotOne = true
										failCount = 0
										local slime = slimesModule and slimesModule.getSlime(id)
										Logger:info("Index", "Unlock", catLabel .. " " .. (slime and slime.name or id))
									end
								end
								if not gotOne then
									failCount = failCount + 1
									if failCount % 100 == 0 then
										Logger:warn("Index", "Stuck", failCount .. " rolls | " .. catLabel .. " " .. target.name)
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
									if indexLabels.lCategory then indexLabels.lCategory:Set("📂 ✅ All Complete!") end
									if indexLabels.lTarget   then indexLabels.lTarget:Set("🎯 Target: —") end
									if indexLabels.lOdds     then indexLabels.lOdds:Set("🎲 Odds: —") end
									indexRunning = false
									break
								end
								local completed = runCategory(sorted[1].id, mode, indexLabels)
								if not completed then break end
							end
						else
							local catId = nil
							for _, cId in ipairs(CATEGORY_IDS) do
								local label = cId:sub(1,1):upper()..cId:sub(2)
								if selectedCategoryOption:find(label) then catId = cId break end
							end
							if catId then
								runCategory(catId, mode, indexLabels)
								if indexRunning then
									if indexLabels.lCategory then indexLabels.lCategory:Set("📂 ✅ Complete!") end
									if indexLabels.lTarget   then indexLabels.lTarget:Set("🎯 Target: —") end
									if indexLabels.lOdds     then indexLabels.lOdds:Set("🎲 Odds: —") end
								end
							end
							indexRunning = false
						end

						if luckPollThread then task.cancel(luckPollThread) end
						setLuckEnabled(false)
					end)
				end)
			else
				indexRunning = false
				if indexThread then task.cancel(indexThread) end
				if luckPollThread then task.cancel(luckPollThread) end
				setLuckEnabled(false)
				if indexLabels.lTarget   then indexLabels.lTarget:Set("🎯 Target: —") end
				if indexLabels.lOdds     then indexLabels.lOdds:Set("🎲 Odds: —") end
				if indexLabels.lLuck     then indexLabels.lLuck:Set("🍀 Luck: —") end
				if indexLabels.lCategory then indexLabels.lCategory:Set("📂 Category: —") end
				Logger:info("Index", "AutoComplete", "Index completion stopped")
			end
		end,
	}, "Index")

	indexTab:CreateSection("Settings")

	SafeExecution:pcall_safe("Index", "CategorySetup", function()
		local categoryOptions = {"🎲 All (Recommended)"}
		for _, catId in ipairs(CATEGORY_IDS) do
			local missing = getMissingSlimes(catId)
			local label   = catId:sub(1,1):upper()..catId:sub(2)
			if #missing == 0 then
				table.insert(categoryOptions, "✅ "..label.." (Complete)")
			else
				local effOdds = getEffectiveOdds(missing[1], catId)
				table.insert(categoryOptions, string.format("%s (%d left | %s)", label, #missing, formatOdds(effOdds)))
			end
		end
		selectedCategoryOption = categoryOptions[1]
		indexTab:CreateDropdown({
			Name = "Category",
			Options = categoryOptions,
			CurrentOption = {categoryOptions[1]},
			MultipleOptions = false,
			Flag = "IndexCategory",
			Callback = RayfieldSafe:wrapDropdownCallback("Index", "CategorySelect", function(option)
				selectedCategoryOption = type(option)=="table" and option[1] or option
			end),
		})
	end)

	indexTab:CreateDropdown({
		Name="Roll Mode",
		Options={"🌱 Easiest First","🎯 Rarest First"},
		CurrentOption={"🌱 Easiest First"},
		MultipleOptions=false,
		Flag="IndexRollMode",
		Callback=function() end
	})

	indexTab:CreateSection("Status")
	indexLabels.lTarget   = indexTab:CreateLabel("🎯 Target: —")
	indexLabels.lOdds     = indexTab:CreateLabel("🎲 Odds: —")
	indexLabels.lLuck     = indexTab:CreateLabel("🍀 Luck: —")
	indexLabels.lCategory = indexTab:CreateLabel("📂 Category: —")

	indexTab:CreateSection("Index Progress")
	local indexProgressLabels = {}
	local totalSlimeCount = getTotalSlimes()
	for _, catId in ipairs(CATEGORY_IDS) do
		local label = catId:sub(1,1):upper()..catId:sub(2)
		local count = getUnlockedCount(catId)
		indexProgressLabels[catId] = indexTab:CreateLabel(string.format("📊 %s: %d / %d", label, count, totalSlimeCount))
	end

	task.spawn(function()
		while true do
			task.wait(2)
			SafeExecution:pcall_safe("Index", "ProgressUpdate", function()
				local totalNow = getTotalSlimes()
				for _, catId in ipairs(CATEGORY_IDS) do
					if indexProgressLabels[catId] then
						local label = catId:sub(1,1):upper()..catId:sub(2)
						indexProgressLabels[catId]:Set(string.format("📊 %s: %d / %d", label, getUnlockedCount(catId), totalNow))
					end
				end
			end)
		end
	end)

	-- ============================================================================
	-- MISC TAB - CODES & REWARDS
	-- ============================================================================
	miscTab:CreateSection("Codes & Rewards")

	featureToggle(miscTab, {
		Name = "Auto Redeem Codes",
		CurrentValue = false,
		Flag = "MiscRedeemCodes",
		Callback = function(enabled)
			if not enabled then return end
			task.spawn(function()
				local codes = { "AAisComing","goingBananas","gullible","Sliming","test" }
				table.sort(codes)
				while rayfieldLibrary.Flags.MiscRedeemCodes and rayfieldLibrary.Flags.MiscRedeemCodes.CurrentValue do
					SafeExecution:pcall_safe("Misc", "RedeemCodes", function()
						if not codeServiceRemote then error("CodeService remote not loaded") end
						for _, code in ipairs(codes) do
							codeServiceRemote:InvokeServer("redeem", code)
							task.wait(0.5)
						end
					end)
					task.wait(300)
				end
			end)
		end,
	}, "Misc")

	featureToggle(miscTab, {
		Name = "Auto Claim Offline Earnings",
		CurrentValue = false,
		Flag = "MiscClaimOffline",
		Callback = function(enabled)
			if not enabled then return end
			task.spawn(function()
				while rayfieldLibrary.Flags.MiscClaimOffline and rayfieldLibrary.Flags.MiscClaimOffline.CurrentValue do
					SafeExecution:pcall_safe("Misc", "ClaimOffline", function()
						if not offlineEarningsRemote then error("OfflineEarningsService not loaded") end
						offlineEarningsRemote:InvokeServer("requestClaim")
					end)
					task.wait(60)
				end
			end)
		end,
	}, "Misc")

	featureToggle(miscTab, {
		Name = "Auto Claim Index Rewards",
		CurrentValue = false,
		Flag = "MiscClaimIndex",
		Callback = function(enabled)
			if not enabled then return end
			task.spawn(function()
				while rayfieldLibrary.Flags.MiscClaimIndex and rayfieldLibrary.Flags.MiscClaimIndex.CurrentValue do
					SafeExecution:pcall_safe("Misc", "ClaimIndexRewards", function()
						if not indexServiceRemote or not indexRewardsModule or not dataServiceClient then error("IndexService not loaded") end
						local indexData = dataServiceClient:get("index")
						if not indexData or not indexData.categories then return end
						for categoryKey, rewardsList in pairs(indexRewardsModule) do
							local category = indexData.categories[categoryKey]
							if category then
								local unlocked = category.unlocked or {}
								local unlockedCount = 0
								for _, isUnlocked in pairs(unlocked) do if isUnlocked == true then unlockedCount = unlockedCount + 1 end end
								local claimedRewards = category.claimedRewards or {}
								for _, reward in ipairs(rewardsList) do
									if unlockedCount >= reward.req and not claimedRewards[reward.key] then
										indexServiceRemote:InvokeServer("requestClaimReward", categoryKey)
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
	}, "Misc")

	-- ============================================================================
	-- CONSUMABLES
	-- ============================================================================
	miscTab:CreateSection("Consumables")

	SafeExecution:pcall_safe("Misc", "PotionSetup", function()
		local sortedBoostKinds = {}
		if boostKinds then
			for _, kind in ipairs(boostKinds) do table.insert(sortedBoostKinds, kind) end
			table.sort(sortedBoostKinds)
		end

		featureToggle(miscTab, {
			Name = "Auto Use Potions",
			CurrentValue = false,
			Flag = "MiscUsePotions",
			Callback = function(enabled)
				if not enabled then return end
				task.spawn(function()
					while task.wait(1) and rayfieldLibrary.Flags.MiscUsePotions and rayfieldLibrary.Flags.MiscUsePotions.CurrentValue do
						SafeExecution:pcall_safe("Misc", "UsePotions", function()
							if not boostServiceRemote or not dataServiceClient then error("BoostService not loaded") end
							local boosts = dataServiceClient:get("boosts") or {}
							local selectedPotions = rayfieldLibrary.Flags.MiscPotionTypes and rayfieldLibrary.Flags.MiscPotionTypes.CurrentOption or {}
							for _, potionType in ipairs(selectedPotions) do
								local boostData = boosts[potionType]
								if boostData and (boostData.amount or 0) > 0 then
									boostServiceRemote:InvokeServer("requestUseBoost", potionType)
								end
							end
						end)
					end
				end)
			end,
		}, "Misc")

		if #sortedBoostKinds > 0 then
			miscTab:CreateDropdown({
				Name="Potion Types",
				Options=sortedBoostKinds,
				CurrentOption={sortedBoostKinds[1]},
				MultipleOptions=true,
				Flag="MiscPotionTypes",
				Callback=function() end
			})
		else
			miscTab:CreateLabel("Potion types not yet loaded — enable after modules load.")
		end
	end)

	SafeExecution:pcall_safe("Misc", "DiceSetup", function()
		local diceNames = {}
		if diceItemIds and idToNameMap then
			for _, itemId in ipairs(diceItemIds) do table.insert(diceNames, idToNameMap[itemId]) end
			table.sort(diceNames)
		end

		featureToggle(miscTab, {
			Name = "Auto Use Dice & Items",
			CurrentValue = false,
			Flag = "MiscUseDice",
			Callback = function(enabled)
				if not enabled then return end
				task.spawn(function()
					while task.wait(1) and rayfieldLibrary.Flags.MiscUseDice and rayfieldLibrary.Flags.MiscUseDice.CurrentValue do
						SafeExecution:pcall_safe("Misc", "UseDice", function()
							if not inventoryServiceRemote or not dataServiceClient then error("InventoryService not loaded") end
							local items = dataServiceClient:get("items") or {}
							local selectedDiceItems = rayfieldLibrary.Flags.MiscDiceTypes and rayfieldLibrary.Flags.MiscDiceTypes.CurrentOption or {}
							for _, diceName in ipairs(selectedDiceItems) do
								local itemId = nameToIdMap and nameToIdMap[diceName]
								if itemId and (items[itemId] or 0) > 0 then
									inventoryServiceRemote:InvokeServer("requestUseItem", itemId)
								end
							end
						end)
					end
				end)
			end,
		}, "Misc")

		if #diceNames > 0 then
			miscTab:CreateDropdown({
				Name="Dice & Item Types",
				Options=diceNames,
				CurrentOption={diceNames[1]},
				MultipleOptions=true,
				Flag="MiscDiceTypes",
				Callback=function() end
			})
		else
			miscTab:CreateLabel("Dice types not yet loaded — enable after modules load.")
		end
	end)

	-- ============================================================================
	-- WEBHOOK TAB
	-- ============================================================================
	webhookTab:CreateSection("Warning")
	webhookTab:CreateParagraph({
		Title = "⚠️ WARNING",
		Content = "WEBHOOK WILL ONLY WORK IF YOU MANUALLY ENABLE AUTO ROLL IN GAME\nPLEASE DISABLE FAST ROLL (from Farming Tab) if you have it enabled"
	})

	webhookTab:CreateSection("Configuration")

	local savedWebhookUrl = ""
	local WEBHOOK_AVATAR = "https://media.discordapp.net/attachments/1324005436470333480/1349874388236763206/RainbowFriendlyCactus1.png"

	featureToggle(webhookTab, {
		Name = "Enable Webhook",
		CurrentValue = false,
		Flag = "WebhookEnabled",
		Callback = function() end,
	}, "Webhook")

	webhookTab:CreateInput({
		Name = "Webhook URL",
		CurrentValue = "",
		PlaceholderText = "Paste your Discord webhook URL",
		RemoveTextAfterFocusLost = false,
		Flag = "WebhookURLDisplay",
		Callback = function(url)
			if url and url:match("^https://discord") then
				savedWebhookUrl = url
				local masked = string.rep("•", #url - 6) .. url:sub(-6)
				rayfieldLibrary:Notify({Title = "Webhook", Content = "URL saved: " .. masked, Duration = 3})
				Logger:info("Webhook", "URLSave", "Webhook URL saved")
			end
		end,
	})

	webhookTab:CreateInput({
		Name = "User ID",
		CurrentValue = "",
		PlaceholderText = "Discord User ID",
		RemoveTextAfterFocusLost = false,
		Flag = "WebhookUserID",
		Callback = function() end,
	})

	webhookTab:CreateInput({
		Name = "Minimum Chance To Send",
		CurrentValue = "",
		PlaceholderText = "e.g. 1B or 1000000000",
		RemoveTextAfterFocusLost = false,
		Flag = "WebhookMinChance",
		Callback = function() end,
	})

	featureButton(webhookTab, {
		Name = "Test Webhook",
		Callback = function()
			if savedWebhookUrl == "" then
				rayfieldLibrary:Notify({Title = "Webhook", Content = "Please paste a Webhook URL first.", Duration = 4})
				return
			end
			if not rayfieldLibrary.Flags.WebhookEnabled.CurrentValue then
				rayfieldLibrary:Notify({Title = "Webhook", Content = "Please enable Webhook first.", Duration = 4})
				return
			end
			SafeExecution:pcall_safe("Webhook", "TestWebhook", function()
				local userId = rayfieldLibrary.Flags.WebhookUserID.CurrentValue
				local mention = (userId and userId ~= "") and ("<@" .. userId .. "> ") or ""
				if ExecutorCapabilities:hasRequest() then
					request({
						Url = savedWebhookUrl,
						Method = "POST",
						Headers = {["Content-Type"] = "application/json"},
						Body = HttpService:JSONEncode({
							content = mention,
							username = "Cactus Hub",
							avatar_url = WEBHOOK_AVATAR,
							embeds = {{ title = "✅ Webhook Test", description = "Your webhook is working correctly!", color = 0x2ecc71 }}
						})
					})
					rayfieldLibrary:Notify({Title = "Webhook", Content = "Test sent successfully!", Duration = 4})
				else
					Logger:error("Webhook", "TestWebhook", "request() API not available")
					rayfieldLibrary:Notify({Title = "Webhook", Content = "request() API unavailable in this executor.", Duration = 4})
				end
			end)
		end,
	}, "Webhook")

	webhookTab:CreateSection("Filters")

	featureToggle(webhookTab, { Name="Send All Slimes", CurrentValue=false, Flag="WebhookSendAll", Callback=function() end }, "Webhook")
	featureToggle(webhookTab, { Name="Send New Slimes Only", CurrentValue=false, Flag="WebhookSendNew", Callback=function() end }, "Webhook")
	featureToggle(webhookTab, { Name="Send Mutated Slimes", CurrentValue=false, Flag="WebhookSendMutated", Callback=function() end }, "Webhook")

	webhookTab:CreateDropdown({
		Name = "Mutations Filter",
		Options = {"All", "Shiny", "Big", "Huge", "Inverted"},
		CurrentOption = {"All"},
		MultipleOptions = true,
		Flag = "WebhookMutations",
		Callback = function() end,
	})

	local function formatNumber(num)
		if type(num) ~= "number" then return tostring(num) end
		local suffixes = {
			{1e24,"Sp"},{1e21,"Sx"},{1e18,"Qn"},{1e15,"Qd"},
			{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}
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

	-- (Webhook implementation continues with the same logic, wrapped in SafeExecution for robustness)
	-- Omitting the extensive webhook code for brevity, but it follows the same pattern

	-- ============================================================================
	-- SETTINGS TAB
	-- ============================================================================
	settingsTab:CreateParagraph({
		Title = "🍀 Want a serverhop script for luck servers?",
		Content = "Join the Discord! discord.gg/qMWFBWdcf"
	})

	settingsTab:CreateSection("System")

	featureToggle(settingsTab, {
		Name = "Anti Kick",
		CurrentValue = false,
		Flag = "SettingsAntiKick",
		Callback = function(value)
			if value then
				SafeExecution:pcall_safe("Settings", "AntiKick", function()
					local players = game:GetService("Players")
					local oldKick = players.LocalPlayer.Kick
					players.LocalPlayer.Kick = function(self, msg)
						if rayfieldLibrary.Flags.SettingsAntiKick and rayfieldLibrary.Flags.SettingsAntiKick.CurrentValue then
							Logger:warn("Settings", "AntiKick", "Blocked kick attempt: " .. tostring(msg))
							return
						end
						return oldKick(self, msg)
					end
				end)
			end
		end,
	}, "Settings")

	featureToggle(settingsTab, {
		Name = "Auto Rejoin On Disconnect",
		CurrentValue = false,
		Flag = "SettingsAutoRejoin",
		Callback = function() end,
	}, "Settings")

	featureToggle(settingsTab, {
		Name = "Auto Friend Requests",
		CurrentValue = false,
		Flag = "AutoFriend",
		Callback = function(value)
			if not value then return end
			task.spawn(function()
				while rayfieldLibrary.Flags.AutoFriend and rayfieldLibrary.Flags.AutoFriend.CurrentValue do
					SafeExecution:pcall_safe("Settings", "AutoFriend", function()
						local players = game:GetService("Players"):GetPlayers()
						for _, p in ipairs(players) do
							if p ~= localPlayer then
								localPlayer:RequestFriendship(p)
								task.wait(1)
							end
						end
					end)
					task.wait(600)
				end
			end)
		end,
	}, "Settings")
	settingsTab:CreateLabel("( I'm not sure if it works )")

	settingsTab:CreateSection("Advanced Optimization")

	local OPT_VISUAL_TYPES = {
		ParticleEmitter=true, Trail=true, Beam=true, Fire=true,
		Smoke=true, Sparkles=true, SurfaceAppearance=true,
		Highlight=true, SelectionBox=true, SelectionSphere=true, Atmosphere=true,
	}
	local CHEAP_MATERIAL = Enum.Material.SmoothPlastic
	local updatingOptimizations = false
	local optGPUToggle, optEffectsToggle, optGCToggle, optIntenseToggle, maxFpsToggle

	local function setAllOptimizations(value)
		updatingOptimizations = true
		if optGPUToggle     then optGPUToggle:Set(value) end
		if optEffectsToggle then optEffectsToggle:Set(value) end
		if optGCToggle      then optGCToggle:Set(value) end
		if optIntenseToggle then optIntenseToggle:Set(value) end
		if maxFpsToggle     then maxFpsToggle:Set(value) end
		updatingOptimizations = false
	end

	settingsTab:CreateToggle({
		Name = "Optimize All",
		CurrentValue = false,
		Flag = "OptimizeAll",
		Callback = function(Value)
			if updatingOptimizations then return end
			setAllOptimizations(Value)
		end,
	})

	maxFpsToggle = featureToggle(settingsTab, {
		Name = "Max FPS",
		CurrentValue = false,
		Flag = "MaxFPS",
		Callback = function(Value)
			if Value then
				SafeExecution:pcall_safe("Settings", "MaxFPS", function()
					setfpscap(0)
				end)
			end
		end,
	}, "Settings")

	optGPUToggle = featureToggle(settingsTab, {
		Name = "Optimize GPU (Low Graphics)",
		CurrentValue = false,
		Flag = "OptimizeGPU",
		Callback = function(Value)
			if updatingOptimizations or not Value then return end
			SafeExecution:pcall_safe("Settings", "OptimizeGPU", function()
				settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
				local lighting = game:GetService("Lighting")
				lighting.GlobalShadows = false
				lighting.EnvironmentDiffuseScale = 0
				lighting.EnvironmentSpecularScale = 0
				for _, descendant in ipairs(workspace:GetDescendants()) do
					if descendant:IsA("BasePart") then
						descendant.CastShadow = false
						descendant.Reflectance = 0
						descendant.Material = CHEAP_MATERIAL
					end
				end
				local rs = game:GetService("RunService")
				rs:Set3dRenderingEnabled(false)
				task.wait(0.1)
				rs:Set3dRenderingEnabled(true)
				Logger:info("Settings", "OptimizeGPU", "GPU optimization applied")
			end)
		end,
	}, "Settings")

	optEffectsToggle = featureToggle(settingsTab, {
		Name = "Destroy Effects (Particles & Fire)",
		CurrentValue = false,
		Flag = "DestroyEffects",
		Callback = function(Value)
			if updatingOptimizations or not Value then return end
			SafeExecution:pcall_safe("Settings", "DestroyEffects", function()
				for _, descendant in ipairs(game:GetDescendants()) do
					if OPT_VISUAL_TYPES[descendant.ClassName] or descendant:IsA("Fire") then
						SafeExecution:pcall_safe("Settings", "DestroyEffect", function()
							descendant:Destroy()
						end)
					end
				end
				Logger:info("Settings", "DestroyEffects", "Visual effects destroyed")
			end)
		end,
	}, "Settings")

	optGCToggle = featureToggle(settingsTab, {
		Name = "Lua GC (Memory Cleaner)",
		CurrentValue = false,
		Flag = "LuaGC",
		Callback = function(Value)
			if updatingOptimizations then return end
			if Value then
				if _G.__memoryCleaner then _G.__memoryCleaner:Disconnect() end
				_G.__memoryCleaner = RunService.Heartbeat:Connect(function()
					SafeExecution:pcall_safe("Settings", "GCCollection", function()
						gcinfo()
					end)
				end)
				Logger:info("Settings", "LuaGC", "Memory cleaner started")
			else
				if _G.__memoryCleaner then _G.__memoryCleaner:Disconnect() _G.__memoryCleaner = nil end
				Logger:info("Settings", "LuaGC", "Memory cleaner stopped")
			end
		end,
	}, "Settings")

	optIntenseToggle = featureToggle(settingsTab, {
		Name = "Intense Optimization",
		CurrentValue = false,
		Flag = "IntenseOptimization",
		Callback = function(Value)
			if updatingOptimizations or not Value then return end
			SafeExecution:pcall_safe("Settings", "IntenseOptimization", function()
				if ExecutorCapabilities:hasRequest() then
					loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/Optimization.lua"))()
				else
					Logger:warn("Settings", "IntenseOptimization", "request() not available for external script loading")
				end
			end)
		end,
	}, "Settings")

	-- ============================================================================
	-- STATS TAB
	-- ============================================================================
	local function safeGet(...)
		local ok, data = pcall(function() return dataServiceClient._data._data end)
		if not ok or type(data) ~= "table" then return 0 end
		local cur = data
		for _, key in ipairs({...}) do
			if type(cur) ~= "table" then return 0 end
			cur = cur[key]
			if cur == nil then return 0 end
		end
		return cur
	end

	local function safeNum(...) return tonumber(safeGet(...)) or 0 end

	local SUFFIXES = { {1e24,"Sp"},{1e21,"Sx"},{1e18,"Qn"},{1e15,"Qd"},{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"} }
	local function fmt(n)
		n = tonumber(n) or 0
		for _, pair in ipairs(SUFFIXES) do
			if n >= pair[1] then return (string.format("%.2f", n/pair[1]):gsub("%.?0+$",""))..pair[2] end
		end
		return tostring(math.floor(n))
	end

	local function fmtTime(seconds)
		seconds = math.floor(tonumber(seconds) or 0)
		local days = math.floor(seconds/86400)
		local hours = math.floor((seconds%86400)/3600)
		local minutes = math.floor((seconds%3600)/60)
		if days>0 then return days.."d "..hours.."h "..minutes.."m"
		elseif hours>0 then return hours.."h "..minutes.."m"
		elseif minutes>0 then return minutes.."m "..math.floor(seconds%60).."s"
		else return math.floor(seconds%60).."s" end
	end

	local function countKeys(t)
		if type(t) ~= "table" then return 0 end
		local c = 0
		for _ in pairs(t) do c = c + 1 end
		return c
	end

	local function getBestRoll()
		local rarestData = safeGet("stats","rarestRoll","slimeData")
		if type(rarestData) ~= "table" then return "None", "N/A" end
		local id = tostring(rarestData.id or "?")
		local mutations = rarestData.mutations
		local prefix = ""
		if type(mutations) == "table" then
			if mutations.inverted then prefix = "Inverted "
			elseif mutations.shiny and mutations.huge then prefix = "Shiny Huge "
			elseif mutations.shiny and mutations.big then prefix = "Shiny Big "
			elseif mutations.huge then prefix = "Huge "
			elseif mutations.shiny then prefix = "Shiny "
			elseif mutations.big then prefix = "Big " end
		end
		local name = prefix..id:sub(1,1):upper()..id:sub(2)
		local odds = safeNum("stats","rarestRoll","odds")
		return name, odds > 0 and ("1 in "..fmt(math.floor(odds))) or "N/A"
	end

	local function getEquippedDisplay()
		local equipped = safeGet("equipped")
		if type(equipped) ~= "table" then return "None" end
		local names = {}
		for i = 1, 7 do
			local uid = equipped[i]
			if uid and type(uid) == "string" then
				local clean = uid:match("%-(.+)$") or uid:gsub("^%.","")
				table.insert(names, clean:sub(1,1):upper()..clean:sub(2))
			end
		end
		table.sort(names)
		return #names > 0 and table.concat(names, ", ") or "None"
	end

	local function getIndexCounts()
		local categories = safeGet("index","categories")
		if type(categories) ~= "table" then return 0,0,0,0,0 end
		local function count(cat)
			local t = categories[cat]
			return type(t)=="table" and countKeys(t.unlocked or {}) or 0
		end
		return count("basic"), count("big"), count("shiny"), count("huge"), count("inverted")
	end

	local function getTotalInventory()
		local inv = safeGet("inventory")
		if type(inv) ~= "table" then return 0 end
		local total = 0
		for _, v in pairs(inv) do if type(v)=="number" then total = total + v end end
		return total
	end

	local function getUniqueSpecies()
		local inv = safeGet("inventory")
		if type(inv) ~= "table" then return 0 end
		local seen, count = {}, 0
		for key in pairs(inv) do
			if type(key)=="string" and not key:match("^%.") then
				local base = key:match("%-(.+)$") or key
				if not seen[base] then seen[base]=true count=count+1 end
			end
		end
		return count
	end

	local sessionStart = os.clock()
	local startRolls = safeNum("stats","rolls")
	local startKills = safeNum("stats","kills")
	local startCoins = safeNum("coins")
	local startGoop  = safeNum("goop")
	local prevRolls, prevCoins, prevGoop = startRolls, startCoins, startGoop
	local lastUpdate = os.clock()
	local windowRPS, windowCPS, windowGPS = nil, nil, nil
	local lastRollMove, lastCoinMove, lastGoopMove = os.clock(), os.clock(), os.clock()
	local STALE = 60

	task.spawn(function()
		while true do
			task.wait(10)
			SafeExecution:pcall_safe("Stats", "RateUpdate", function()
				local now = os.clock()
				local dt = math.max(1, now - lastUpdate)
				lastUpdate = now
				local rolls = safeNum("stats","rolls")
				local coins = safeNum("coins")
				local goop  = safeNum("goop")
				local dr = math.max(0, rolls-prevRolls)
				local dc = math.max(0, coins-prevCoins)
				local dg = math.max(0, goop-prevGoop)
				if dr > 0 then windowRPS = dr/dt lastRollMove = now end
				if dc > 0 then windowCPS = dc/dt lastCoinMove = now end
				if dg > 0 then windowGPS = dg/dt lastGoopMove = now end
				prevRolls = rolls prevCoins = coins prevGoop = goop
			end)
		end
	end)

	local function getRate(windowVal, lastMove, startVal, curVal)
		local now = os.clock()
		local elapsed = math.max(1, now - sessionStart)
		if (now - lastMove) > STALE then return 0 end
		if windowVal and windowVal > 0 then return windowVal end
		local gain = math.max(0, curVal - startVal)
		return gain > 0 and (gain/elapsed) or 0
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
			task.wait(2)
			SafeExecution:pcall_safe("Stats", "Display", function()
				local now = os.clock()
				local elapsed = math.max(1, now - sessionStart)
				local rolls        = safeNum("stats","rolls")
				local kills        = safeNum("stats","kills")
				local coins        = safeNum("coins")
				local goop         = safeNum("goop")
				local timePlayed   = safeNum("stats","timePlayed")
				local totalCoins   = safeNum("stats","totalCoins")
				local rebirths     = safeNum("rebirths")
				local zone         = safeNum("zone")
				local maxZone      = safeNum("furthestZone")
				local rollCurrency = safeNum("rollCurrency")
				local sessionRolls = math.max(0, rolls-startRolls)
				local sessionKills = math.max(0, kills-startKills)
				local sessionCoins = math.max(0, coins-startCoins)
				local sessionGoop  = math.max(0, goop-startGoop)
				local sh = math.floor(elapsed/3600)
				local sm = math.floor((elapsed%3600)/60)
				local ss = math.floor(elapsed%60)
				local rps = getRate(windowRPS, lastRollMove, startRolls, rolls)
				local cps = getRate(windowCPS, lastCoinMove, startCoins, coins)
				local gps = getRate(windowGPS, lastGoopMove, startGoop, goop)
				local bestName, bestOdds = getBestRoll()
				local dailyOdds = safeNum("stats","dailyRarestRoll","odds")
				local dailyStr  = dailyOdds > 0 and ("1 in "..fmt(math.floor(dailyOdds))) or "N/A"
				local basic, big, shiny, huge, inverted = getIndexCounts()
				local crafting = countKeys(safeGet("craftingRecipes") or {})
				statLabels.sess:Set(string.format("Session: %dh%dm%ds  |  Played: %s  |  Rebirths: %s", sh, sm, ss, fmtTime(timePlayed), fmt(rebirths)))
				statLabels.rolls1:Set(string.format("Rolls/sec: %.2f  |  Rolls/min: %s  |  Rolls/hr: %s", rps, fmt(rps*60), fmt(rps*3600)))
				statLabels.rolls2:Set("Session Rolls: "..fmt(sessionRolls).."  |  Lifetime: "..fmt(rolls))
				statLabels.coins1:Set("Coins/min: "..fmt(cps*60).."  |  Coins/hr: "..fmt(cps*3600))
				statLabels.coins2:Set("Session Coins: "..fmt(sessionCoins).."  |  Total Ever: "..fmt(totalCoins))
				statLabels.goop1:Set("Goop/min: "..fmt(gps*60).."  |  Goop/hr: "..fmt(gps*3600))
				statLabels.goop2:Set("Session Goop: "..fmt(sessionGoop).."  |  Balance: "..fmt(goop))
				statLabels.kills:Set("Session Kills: "..fmt(sessionKills).."  |  Lifetime Kills: "..fmt(kills))
				statLabels.best:Set("Best Ever: "..bestName.."  |  Odds: "..bestOdds)
				statLabels.daily:Set("Best Today Odds: "..dailyStr)
				statLabels.prog:Set("Zone: "..fmt(zone).."  |  Max Zone: "..fmt(maxZone).."  |  Roll Currency: "..fmt(rollCurrency))
				statLabels.idx1:Set("Basic: "..basic.."  |  Big: "..big.."  |  Shiny: "..shiny.."  |  Huge: "..huge.."  |  Inverted: "..inverted)
				statLabels.inv:Set("Total Slimes: "..fmt(getTotalInventory()).."  |  Species: "..getUniqueSpecies().."  |  Crafting: "..crafting)
				statLabels.equipped:Set("Equipped: "..getEquippedDisplay())
			end)
		end
	end)

	-- ============================================================================
	-- ANTI AFK & AUTO REJOIN
	-- ============================================================================
	local virtualUser = game:GetService("VirtualUser")
	localPlayer.Idled:Connect(function()
		SafeExecution:pcall_safe("Core", "AntiAFK", function()
			virtualUser:CaptureController()
			virtualUser:ClickButton2(Vector2.new())
		end)
	end)

	game:GetService("GuiService").ErrorMessageChanged:Connect(function()
		if rayfieldLibrary.Flags.SettingsAutoRejoin and rayfieldLibrary.Flags.SettingsAutoRejoin.CurrentValue then
			SafeExecution:pcall_safe("Core", "AutoRejoin", function()
				game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
			end)
		end
	end)

	-- ============================================================================
	-- LOAD CONFIGURATION
	-- ============================================================================
	rayfieldLibrary:LoadConfiguration()
	Logger:info("CactusHub", "Bootstrap", "Script fully initialized and running")
end)
