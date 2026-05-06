local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local TRANSPARENT = 1
local CHEAP_MATERIAL = Enum.Material.SmoothPlastic

local VISUAL_TYPES = {
	ParticleEmitter = true,
	Trail = true,
	Beam = true,
	Fire = true,
	Smoke = true,
	Sparkles = true,
	SurfaceAppearance = true,
	Highlight = true,
	SelectionBox = true,
	SelectionSphere = true,
}

local LIGHT_TYPES = {
	PointLight = true,
	SpotLight = true,
	SurfaceLight = true,
}

local LIGHTING_EFFECT_TYPES = {
	BloomEffect = true,
	BlurEffect = true,
	ColorCorrectionEffect = true,
	DepthOfFieldEffect = true,
	SunRaysEffect = true,
	PixelateEffect = true,
	FilmGrainEffect = true,
	Atmosphere = true,
	Sky = true,
}

local connections = {}

local function safeDestroy(obj)
	if obj and obj.Parent then
		obj:Destroy()
	end
end

local function trySet(obj, prop, val)
	pcall(function()
		obj[prop] = val
	end)
end

local function tryHidden(obj, prop, val)
	if sethiddenproperty then
		pcall(sethiddenproperty, obj, prop, val)
	end
end

local function optimizeLighting()
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 100000
	Lighting.FogStart = 100000
	Lighting.Brightness = 1
	Lighting.Ambient = Color3.fromRGB(180, 180, 180)
	Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
	Lighting.ShadowSoftness = 0
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	tryHidden(Lighting, "Technology", 0)

	for _, child in ipairs(Lighting:GetChildren()) do
		if LIGHTING_EFFECT_TYPES[child.ClassName] then
			safeDestroy(child)
		end
	end

	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		local clouds = terrain:FindFirstChildOfClass("Clouds")
		if clouds then
			safeDestroy(clouds)
		end
		trySet(terrain, "WaterWaveSize", 0)
		trySet(terrain, "WaterWaveSpeed", 0)
		trySet(terrain, "WaterReflectance", 0)
		trySet(terrain, "WaterTransparency", 1)
	end
end

local function workspaceCleanup()
	local mpView = Workspace:FindFirstChild("MultiplayerView")
	if mpView then
		safeDestroy(mpView)
	end

	local zonesFolder = Workspace:FindFirstChild("Zones")
	if zonesFolder then
		for _, zone in ipairs(zonesFolder:GetChildren()) do
			local decor = zone:FindFirstChild("decor")
			if decor then
				safeDestroy(decor)
			end
			local gate = zone:FindFirstChild("Gate")
			if gate then
				safeDestroy(gate)
			end
		end
	end
end

local function stripVisuals(root)
	for _, v in ipairs(root:GetDescendants()) do
		local cn = v.ClassName
		if VISUAL_TYPES[cn] then
			safeDestroy(v)
		elseif cn == "Decal" or cn == "Texture" then
			trySet(v, "Transparency", TRANSPARENT)
		elseif cn == "SpecialMesh" then
			trySet(v, "TextureId", "")
		elseif LIGHT_TYPES[cn] then
			trySet(v, "Enabled", false)
			trySet(v, "Brightness", 0)
		end
	end
end

local function optimizeWorkspaceInstances()
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj ~= Camera then
			local isCharacter = false
			for _, p in ipairs(Players:GetPlayers()) do
				if p.Character == obj then
					isCharacter = true
					break
				end
			end
			if not isCharacter then
				stripVisuals(obj)
			end
		end
	end
end

local function degradeMaterials(root)
	for _, v in ipairs(root:GetDescendants()) do
		if v:IsA("BasePart") then
			trySet(v, "Material", CHEAP_MATERIAL)
			trySet(v, "Reflectance", 0)
			trySet(v, "CastShadow", false)
			tryHidden(v, "RenderFidelity", 2)
		end
	end
end

local function optimizeCharacter(character)
	if not character then
		return
	end

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			trySet(part, "Transparency", TRANSPARENT)
			trySet(part, "CastShadow", false)
			trySet(part, "Material", CHEAP_MATERIAL)
			trySet(part, "Reflectance", 0)
		elseif part:IsA("Decal") or part:IsA("Texture") then
			trySet(part, "Transparency", TRANSPARENT)
		end
	end

	for _, acc in ipairs(character:GetChildren()) do
		if acc:IsA("Accessory") then
			safeDestroy(acc)
		end
	end

	for _, v in ipairs(character:GetDescendants()) do
		if VISUAL_TYPES[v.ClassName] then
			safeDestroy(v)
		elseif v.ClassName == "SpecialMesh" then
			trySet(v, "TextureId", "")
		end
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				pcall(function()
					track:Stop(0)
				end)
			end
		end
		trySet(humanoid, "DisplayDistanceType", Enum.HumanoidDisplayDistanceType.None)
		trySet(humanoid, "HealthDisplayType", Enum.HumanoidHealthDisplayType.AlwaysOff)
		trySet(humanoid, "NameDisplayDistance", 0)
		trySet(humanoid, "HealthDisplayDistance", 0)
	end
end

local function optimizeOtherPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = player.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						trySet(part, "Transparency", TRANSPARENT)
						trySet(part, "CastShadow", false)
					elseif part:IsA("Decal") or part:IsA("Texture") then
						trySet(part, "Transparency", TRANSPARENT)
					end
				end
				for _, acc in ipairs(char:GetChildren()) do
					if acc:IsA("Accessory") then
						safeDestroy(acc)
					end
				end
				for _, v in ipairs(char:GetDescendants()) do
					if VISUAL_TYPES[v.ClassName] then
						safeDestroy(v)
					end
				end
			end
		end
	end
end

local function optimizeCamera()
	if Camera then
		trySet(Camera, "FieldOfView", 70)
		for _, v in ipairs(Camera:GetChildren()) do
			if LIGHTING_EFFECT_TYPES[v.ClassName] then
				safeDestroy(v)
			end
		end
	end
end

local function setGlobalRenderQuality()
	pcall(function()
		settings().Rendering.QualityLevel = 1
	end)
	pcall(function()
		UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel01
	end)
end

local function optimizeGUI()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	end)
end

local function watchForNewVisuals(root)
	local conn = root.DescendantAdded:Connect(function(v)
		local cn = v.ClassName
		if VISUAL_TYPES[cn] then
			task.defer(safeDestroy, v)
		elseif cn == "SurfaceAppearance" or cn == "Atmosphere" then
			task.defer(safeDestroy, v)
		elseif cn == "Decal" or cn == "Texture" then
			task.defer(function()
				trySet(v, "Transparency", TRANSPARENT)
			end)
		elseif v:IsA("BasePart") then
			task.defer(function()
				trySet(v, "CastShadow", false)
				trySet(v, "Reflectance", 0)
				trySet(v, "Material", CHEAP_MATERIAL)
			end)
		end
	end)
	table.insert(connections, conn)
end

local function watchPlayers()
	local conn = Players.PlayerAdded:Connect(function(player)
		local charConn = player.CharacterAdded:Connect(function(char)
			task.defer(function()
				optimizeCharacter(char)
			end)
		end)
		table.insert(connections, charConn)
	end)
	table.insert(connections, conn)

	local respawnConn = LocalPlayer.CharacterAdded:Connect(function(char)
		task.defer(function()
			task.wait(0.5)
			optimizeCharacter(char)
		end)
	end)
	table.insert(connections, respawnConn)
end

local gcRunning = true

task.spawn(function()
	while gcRunning do
		task.wait(30)

		task.defer(function()
			for _, obj in ipairs(Workspace:GetChildren()) do
				if obj ~= Camera then
					local isChar = false
					for _, p in ipairs(Players:GetPlayers()) do
						if p.Character == obj then
							isChar = true
							break
						end
					end
					if not isChar then
						for _, v in ipairs(obj:GetDescendants()) do
							if VISUAL_TYPES[v.ClassName] then
								safeDestroy(v)
							end
						end
					end
				end
			end
		end)

		task.defer(optimizeOtherPlayers)

		task.defer(function()
			for _, child in ipairs(Lighting:GetChildren()) do
				if LIGHTING_EFFECT_TYPES[child.ClassName] then
					safeDestroy(child)
				end
			end
		end)
	end
end)

if _G.__ultraOptConnections then
	for _, c in ipairs(_G.__ultraOptConnections) do
		pcall(function()
			c:Disconnect()
		end)
	end
end
_G.__ultraOptConnections = connections
gcRunning = true

task.spawn(setGlobalRenderQuality)
optimizeLighting()
workspaceCleanup()
optimizeCamera()
task.spawn(optimizeWorkspaceInstances)
task.defer(function()
	degradeMaterials(Workspace)
end)

local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
task.spawn(function()
	optimizeCharacter(char)
end)

task.spawn(optimizeOtherPlayers)
optimizeGUI()
watchForNewVisuals(Workspace)
watchPlayers()
