local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
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
Atmosphere = true,
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
pcall(rawset, obj, prop, val)
end

local function tryHidden(obj, prop, val)
if sethiddenproperty then
pcall(sethiddenproperty, obj, prop, val)
end
end

local function applyToInstance(v)
local cn = v.ClassName
if VISUAL_TYPES[cn] then
safeDestroy(v)
return
end
if cn == "Decal" or cn == "Texture" then
v.Transparency = 1
return
end
if cn == "SpecialMesh" then
v.TextureId = ""
return
end
if cn == "PointLight" or cn == "SpotLight" or cn == "SurfaceLight" then
v.Enabled = false
return
end
if v:IsA("BasePart") then
v.CastShadow = false
v.Reflectance = 0
pcall(function() v.Material = CHEAP_MATERIAL end)
tryHidden(v, "RenderFidelity", 2)
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
		child:Destroy()  
	end  
end  

local terrain = Workspace:FindFirstChildOfClass("Terrain")  
if terrain then  
	local clouds = terrain:FindFirstChildOfClass("Clouds")  
	if clouds then clouds:Destroy() end  
	terrain.WaterWaveSize = 0  
	terrain.WaterWaveSpeed = 0  
	terrain.WaterReflectance = 0  
	terrain.WaterTransparency = 1  
end

end

local function workspaceCleanup()
local mpView = Workspace:FindFirstChild("MultiplayerView")
if mpView then mpView:Destroy() end

local zonesFolder = Workspace:FindFirstChild("Zones")  
if zonesFolder then  
	for _, zone in ipairs(zonesFolder:GetChildren()) do  
		local decor = zone:FindFirstChild("decor")  
		if decor then decor:Destroy() end  
		local gate = zone:FindFirstChild("Gate")  
		if gate then gate:Destroy() end  
	end  
end

end

local function optimizeCharacter(character)
if not character then return end

local humanoid = character:FindFirstChildOfClass("Humanoid")  
if humanoid then  
	local animator = humanoid:FindFirstChildOfClass("Animator")  
	if animator then  
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do  
			pcall(track.Stop, track, 0)  
		end  
	end  
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None  
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff  
	humanoid.NameDisplayDistance = 0  
	humanoid.HealthDisplayDistance = 0  
end  

for _, v in ipairs(character:GetDescendants()) do  
	local cn = v.ClassName  
	if VISUAL_TYPES[cn] then  
		v:Destroy()  
	elseif v:IsA("BasePart") then  
		v.Transparency = 1  
		v.CastShadow = false  
		v.Reflectance = 0  
		pcall(function() v.Material = CHEAP_MATERIAL end)  
	elseif cn == "Decal" or cn == "Texture" then  
		v.Transparency = 1  
	elseif cn == "SpecialMesh" then  
		v.TextureId = ""  
	elseif cn == "Accessory" then  
		v:Destroy()  
	end  
end  

for _, child in ipairs(character:GetChildren()) do  
	if child:IsA("Accessory") then  
		child:Destroy()  
	end  
end

end

local function stripWorkspaceObject(obj)
if obj == Camera then return end
for _, v in ipairs(obj:GetDescendants()) do
applyToInstance(v)
end
end

local function buildCharacterSet()
local set = {}
for _, p in ipairs(Players:GetPlayers()) do
if p.Character then
set[p.Character] = true
end
end
return set
end

local function initialWorkspaceScan()
local charSet = buildCharacterSet()
for _, obj in ipairs(Workspace:GetChildren()) do
if obj ~= Camera and not charSet[obj] then
stripWorkspaceObject(obj)
end
end
end

local function hookCharacter(player, character)
optimizeCharacter(character)

local conn = character.ChildAdded:Connect(function(child)  
	if child:IsA("Accessory") then  
		task.defer(child.Destroy, child)  
	end  
end)  
table.insert(connections, conn)  

local descConn = character.DescendantAdded:Connect(function(v)  
	local cn = v.ClassName  
	if VISUAL_TYPES[cn] then  
		task.defer(v.Destroy, v)  
	elseif cn == "Decal" or cn == "Texture" then  
		task.defer(function()  
			if v.Parent then v.Transparency = 1 end  
		end)  
	end  
end)  
table.insert(connections, descConn)

end

local function watchPlayers()
for _, player in ipairs(Players:GetPlayers()) do
if player.Character then
hookCharacter(player, player.Character)
end
local charConn = player.CharacterAdded:Connect(function(char)
task.defer(hookCharacter, player, char)
end)
table.insert(connections, charConn)
end

local addedConn = Players.PlayerAdded:Connect(function(player)  
	local charConn = player.CharacterAdded:Connect(function(char)  
		task.defer(hookCharacter, player, char)  
	end)  
	table.insert(connections, charConn)  
end)  
table.insert(connections, addedConn)

end

local function watchWorkspace()
local charSet = buildCharacterSet()

local childAddedConn = Workspace.ChildAdded:Connect(function(obj)  
	if obj == Camera then return end  
	if charSet[obj] then return end  
	task.defer(stripWorkspaceObject, obj)  
end)  
table.insert(connections, childAddedConn)  

local lightingConn = Lighting.ChildAdded:Connect(function(child)  
	if LIGHTING_EFFECT_TYPES[child.ClassName] then  
		task.defer(child.Destroy, child)  
	end  
end)  
table.insert(connections, lightingConn)

end

local function optimizeCamera()
if not Camera then return end
Camera.FieldOfView = 70
for _, v in ipairs(Camera:GetChildren()) do
if LIGHTING_EFFECT_TYPES[v.ClassName] then
v:Destroy()
end
end
end

local function setRenderQuality()
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

if _G.__ultraOptConnections then
for _, c in ipairs(_G.__ultraOptConnections) do
pcall(c.Disconnect, c)
end
table.clear(_G.__ultraOptConnections)
end
_G.__ultraOptConnections = connections

pcall(setRenderQuality)
optimizeLighting()
workspaceCleanup()
optimizeCamera()
optimizeGUI()
initialWorkspaceScan()
watchPlayers()
watchWorkspace()
