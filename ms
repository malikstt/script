local Fluent=loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local LocalPlayer=Players.LocalPlayer

local RepLibrary=require(ReplicatedStorage.Modules.RepLibrary)
local ItemsModule=require(ReplicatedStorage.Modules.Items)

local MakeOfferRemote=ReplicatedStorage.Events.Shop.MakePlayerOffer
local GetInventoryRemote=ReplicatedStorage.Events.Data.Get
local AcceptRemote=ReplicatedStorage.Events.Shop.AcceptPlayerOffer
local SellRemote=ReplicatedStorage.Events.Shop.SellItemInShop

local cam=workspace.CurrentCamera
local viewport=cam.ViewportSize

local Window=Fluent:CreateWindow({
Title="Shop & Player Manager",
SubTitle="Full Fixed System",
TabWidth=160,
Size=UDim2.fromOffset(viewport.X*0.55,viewport.Y*0.35),
Acrylic=true,
Theme="Dark"
})

local Tabs={
Main=Window:AddTab({Title="Main",Icon="home"})
}

local function getAllPlayerNames()
local t={}
for _,p in ipairs(Players:GetPlayers()) do
table.insert(t,p.Name)
end
return t
end

local function getOtherPlayerNames()
local t={}
for _,p in ipairs(Players:GetPlayers()) do
if p~=LocalPlayer then
table.insert(t,p.Name)
end
end
return t
end

local selectedShopPlayer=nil

Tabs.Main:AddDropdown("ShopPlayerSelect",{
Title="Select Shop Player",
Values=getAllPlayerNames(),
Callback=function(v)
selectedShopPlayer=v
print("Selected shop:",v)
end
})

Tabs.Main:AddButton({
Title="Teleport To Shop",
Callback=function()
pcall(function()
if not selectedShopPlayer then return end
local char=LocalPlayer.Character
local plr=Players:FindFirstChild(selectedShopPlayer)
if not char or not plr then return end
local plot=plr.NonSaveVars and plr.NonSaveVars.OwnsPlot and plr.NonSaveVars.OwnsPlot.Value
if not plot then return end
local door=plot:FindFirstChild("Door",true)
if door and door:FindFirstChild("StartPart") then
char:SetPrimaryPartCFrame(door.StartPart.CFrame)
print("Teleported to",selectedShopPlayer)
end
end)
end
})

local sendPlayers={}
local sendEnabled=false
local offerPercent=50

Tabs.Main:AddDropdown("SendPlayers",{
Title="Send Offers To",
Values=getOtherPlayerNames(),
Multi=true,
Callback=function(v)
sendPlayers=v
end
})

Tabs.Main:AddDropdown("OfferPercent",{
Title="Offer Percent",
Values={"+50%","-50%"},
Default="+50%",
Callback=function(v)
offerPercent=v=="+50%" and 50 or -50
print("Offer percent:",offerPercent)
end
})

Tabs.Main:AddToggle("SendToggle",{
Title="Send Offers",
Callback=function(v)
sendEnabled=v
print("Send offers:",v)
end
})

local function getPlacedMap(plot)
local map={}
local furniture=plot:FindFirstChild("Furniture")
if not furniture then return map end
for _,v in pairs(furniture:GetDescendants()) do
if v.Name=="Item" then
for _,item in pairs(v:GetChildren()) do
map[item.Name]=map[item.Name] or {}
table.insert(map[item.Name],item)
end
end
end
return map
end

task.spawn(function()
while true do
pcall(function()
if sendEnabled then
for playerName,state in pairs(sendPlayers) do
if state then
local target=Players:FindFirstChild(playerName)
if target then
local ok,inv=pcall(function()
return GetInventoryRemote:InvokeServer("Inventory",target)
end)
if ok and type(inv)=="table" then
local plotVal=target.NonSaveVars and target.NonSaveVars.OwnsPlot
if plotVal and plotVal.Value then
local placedMap=getPlacedMap(plotVal.Value)
for guid,itemData in pairs(inv) do
local info=ItemsModule[itemData.Id]
if info then
local placed=placedMap[info.Name]
if placed and #placed>0 then
local instance=table.remove(placed,1)
local price=RepLibrary:GetItemPrice(itemData)
local offer=math.floor(price*(1+offerPercent/100))
pcall(function()
MakeOfferRemote:InvokeServer(target,guid,offer,instance)
print("Offered",info.Name,"to",playerName,"for",offer)
end)
task.wait(0.25)
end
end
end
end
end
end
end
end
end)
task.wait(1)
end
end)

local acceptPlayers={}
local acceptEnabled=false

Tabs.Main:AddDropdown("AcceptPlayers",{
Title="Accept From Players",
Values=getOtherPlayerNames(),
Multi=true,
Callback=function(v)
acceptPlayers=v
end
})

Tabs.Main:AddToggle("AcceptToggle",{
Title="Accept Offers",
Callback=function(v)
acceptEnabled=v
print("Accept offers:",v)
end
})

task.spawn(function()
while true do
pcall(function()
if acceptEnabled then
for _,gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
local from=gui:GetAttribute("OfferFromPlayerName")
local guid=gui:GetAttribute("GUID")
local price=gui:GetAttribute("Offer")
if from and guid and price and acceptPlayers[from] then
pcall(function()
AcceptRemote:InvokeServer(from,guid,price)
print("Accepted offer from",from)
end)
end
end
end
end)
task.wait(0.5)
end
end)

local placeEnabled=false

Tabs.Main:AddToggle("PlaceToggle",{
Title="Place Items",
Callback=function(v)
placeEnabled=v
print("Place items:",v)
end
})

task.spawn(function()
while true do
pcall(function()
if placeEnabled then
local ok,data=pcall(function()
return GetInventoryRemote:InvokeServer("Inventory",LocalPlayer)
end)
if ok and type(data)=="table" then
local plot=LocalPlayer.NonSaveVars and LocalPlayer.NonSaveVars.OwnsPlot and LocalPlayer.NonSaveVars.OwnsPlot.Value
if plot then
local shelves={}
for _,v in pairs(plot.Furniture:GetDescendants()) do
if v.Name=="Shelf" then
table.insert(shelves,v)
end
end
local index=1
for guid,info in pairs(data) do
if shelves[index] then
pcall(function()
SellRemote:FireServer(guid,shelves[index],true)
print("Placed item",guid)
end)
index=index+1
task.wait(0.2)
end
end
end
end
end
end)
task.wait(1)
end
end)

Window:SelectTab(Tabs.Main)
