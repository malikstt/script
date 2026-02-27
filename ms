local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Main", "DarkTheme")

local MainTab = Window:NewTab("Main")
local PlayerSection = MainTab:NewSection("Players")
local ShopSection = MainTab:NewSection("Shop")

local selectedPlayers = {}
local autoTP = false
local tpConn
local cashLabels = {}

local function getCash(p)
if p and p:FindFirstChild("SaveVars") and p.SaveVars:FindFirstChild("Cash") then
return p.SaveVars.Cash.Value
end
return 0
end

local function refreshPlayers()
PlayerSection:Clear()
cashLabels = {}

PlayerSection:AddToggle("Auto TP", nil, function(state)
autoTP = state
if autoTP then
if tpConn then tpConn:Disconnect() end
tpConn = RunService.Heartbeat:Connect(function()
for p,_ in pairs(selectedPlayers) do
if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
LocalPlayer.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame
end
end
task.wait(0.5)
end)
else
if tpConn then tpConn:Disconnect() tpConn=nil end
end
end)

for _,p in ipairs(Players:GetPlayers()) do
if p~=LocalPlayer then
local label = PlayerSection:AddLabel(p.Name.." $"..getCash(p))
cashLabels[p]=label
PlayerSection:AddToggle(p.Name, nil, function(state)
if state then
selectedPlayers[p]=true
else
selectedPlayers[p]=nil
end
end)
if p:FindFirstChild("SaveVars") and p.SaveVars:FindFirstChild("Cash") then
p.SaveVars.Cash:GetPropertyChangedSignal("Value"):Connect(function()
if cashLabels[p] then
cashLabels[p]:Update(p.Name.." $"..getCash(p))
end
end)
end
end
end
end

local function teleportToRandomShelf()
local plotName = LocalPlayer:WaitForChild("NonSaveVars"):WaitForChild("OwnsPlot").Value.Name
local plot = workspace:WaitForChild("Plots"):WaitForChild(plotName)
local shelves={}
for _,f in ipairs(plot:WaitForChild("Furniture"):GetChildren()) do
local s=f:FindFirstChild("Shelves")
if s then
for _,sh in ipairs(s:GetChildren()) do
table.insert(shelves,sh)
end
end
end
if #shelves>0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
LocalPlayer.Character.HumanoidRootPart.CFrame = shelves[math.random(1,#shelves)].CFrame
end
end

local placeEnabled=false
local placeConn

local function placeAllItems()
local SellRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Shop"):WaitForChild("SellItemInShop")
local GetAll = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Data"):WaitForChild("GetAll")
local ItemsModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Items"))
local data = GetAll:InvokeServer()
local plotName = LocalPlayer:WaitForChild("NonSaveVars"):WaitForChild("OwnsPlot").Value.Name
local plot = workspace:WaitForChild("Plots"):WaitForChild(plotName)
local shelves={}
for _,f in ipairs(plot:WaitForChild("Furniture"):GetChildren()) do
local s=f:FindFirstChild("Shelves")
if s then
for _,sh in ipairs(s:GetChildren()) do
table.insert(shelves,sh)
end
end
end
local guids={}
for guid,info in pairs(data.Inventory) do
local id=tonumber(info.Id)
local itemData=ItemsModule[id]
local name=itemData and string.lower(itemData.Name or "") or ""
if id~=281 and id~=2294 and not string.find(name,"safe") then
table.insert(guids,guid)
end
end
local count=math.min(#shelves,#guids)
for i=1,count do
if not placeEnabled then break end
SellRemote:FireServer(guids[i],shelves[i],true)
task.wait(1)
end
end

local acceptAny=false
local acceptPlayer=nil
local acceptConn

local function acceptOffers(filter)
local AcceptRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Shop"):WaitForChild("AcceptPlayerOffer")
local function tryAccept(obj)
local from=obj:GetAttribute("OfferFromPlayerName")
local guid=obj:GetAttribute("GUID")
local price=obj:GetAttribute("Offer")
if from and guid and price and (not filter or from==filter) then
AcceptRemote:InvokeServer(from,guid,price)
end
end
for _,gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
tryAccept(gui)
end
LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
task.wait(0.05)
if acceptAny or acceptPlayer then
tryAccept(child)
end
end)
end

ShopSection:AddButton("Teleport Random Shelf", function()
teleportToRandomShelf()
end)

ShopSection:AddToggle("Place All Items Every 1s", nil, function(state)
placeEnabled=state
if placeEnabled then
if placeConn then placeConn:Disconnect() end
placeConn=RunService.Heartbeat:Connect(function()
placeAllItems()
task.wait(1)
end)
else
if placeConn then placeConn:Disconnect() placeConn=nil end
end
end)

ShopSection:AddToggle("Accept Any Offers", nil, function(state)
acceptAny=state
acceptPlayer=nil
if acceptAny then
if acceptConn then acceptConn:Disconnect() end
acceptConn=RunService.Heartbeat:Connect(function()
acceptOffers()
task.wait(0.5)
end)
else
if acceptConn then acceptConn:Disconnect() acceptConn=nil end
end
end)

local dropdownPlayers={}
for _,p in ipairs(Players:GetPlayers()) do
if p~=LocalPlayer then
table.insert(dropdownPlayers,p.Name)
end
end

ShopSection:AddDropdown("Accept From Player", dropdownPlayers, function(sel)
acceptPlayer=sel
acceptAny=false
if acceptConn then acceptConn:Disconnect() end
acceptConn=RunService.Heartbeat:Connect(function()
acceptOffers(sel)
task.wait(0.5)
end)
end)

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)

refreshPlayers()
