local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local ItemsModule = require(ReplicatedStorage.Modules.Items)

local MakeOfferRemote = ReplicatedStorage.Events.Shop.MakePlayerOffer
local AcceptRemote = ReplicatedStorage.Events.Shop.AcceptPlayerOffer
local GetAllRemote = ReplicatedStorage.Events.Data.GetAll
local SellRemote = ReplicatedStorage.Events.Shop.SellItemInShop

local cam = workspace.CurrentCamera
local viewport = cam.ViewportSize

local Window = Fluent:CreateWindow({
    Title = "Malik",
    SubTitle = "lmklmk",
    TabWidth = 160,
    Size = UDim2.fromOffset(viewport.X * 0.5, viewport.Y * 0.4),
    Acrylic = true,
    Theme = "Dark"
})

pcall(function()
    Fluent.Options.AccentColor:SetValue(Color3.fromRGB(255,0,0))
end)

local Tab = Window:AddTab({ Title = "Main", Icon = "home" })

local function getOtherPlayers()
    local t = {}
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(t,p.Name)
        end
    end
    return t
end

local teleportTargets = {}
local teleportEnabled = false
local teleportIndex = 1

Tab:AddDropdown("TeleportTargets",{
    Title="Teleport Targets",
    Values=getOtherPlayers(),
    Multi=true,
    Callback=function(v)
        teleportTargets=v
    end
})

Tab:AddToggle("TeleportToggle",{
    Title="Teleport Cycle",
    Default=false,
    Callback=function(v)
        teleportEnabled=v
        teleportIndex=1
    end
})

local function teleportTo(playerName)
    local char=LocalPlayer.Character
    if not char then return end

    local plr=Players:FindFirstChild(playerName)
    if not plr then return end

    local non=plr:FindFirstChild("NonSaveVars")
    if not non then return end

    local floor=non:FindFirstChild("DefaultFloor")
    if not floor then return end

    local canvas=floor.Value and floor.Value:FindFirstChild("Canvas")
    if not canvas then return end

    char:SetPrimaryPartCFrame(canvas.CFrame+Vector3.new(0,3,0))
end

task.spawn(function()
    while true do
        if teleportEnabled then

            local list={}
            for name,enabled in pairs(teleportTargets) do
                if enabled then
                    table.insert(list,name)
                end
            end

            if #list>0 then

                if teleportIndex>#list then
                    teleportIndex=1
                end

                teleportTo(list[teleportIndex])

                teleportIndex+=1
            end
        end
        task.wait(0.25)
    end
end)

local sendTargets={}
local sendEnabled=false
local offerPercent=50

Tab:AddDropdown("SendTargets",{
    Title="Send Targets",
    Values=getOtherPlayers(),
    Multi=true,
    Callback=function(v)
        sendTargets=v
    end
})

Tab:AddDropdown("Percent",{
    Title="Offer Percent",
    Values={"+50%","-50%"},
    Default="+50%",
    Callback=function(v)
        offerPercent=v=="+50%" and 50 or -50
    end
})

Tab:AddToggle("SendToggle",{
    Title="Send Offers",
    Default=false,
    Callback=function(v)
        sendEnabled=v
    end
})

local function getPlacedItems(plot)

    local items={}

    local furniture=plot:FindFirstChild("Furniture")
    if not furniture then return items end

    for _,f in ipairs(furniture:GetChildren()) do

        local shelves=f:FindFirstChild("Shelves")

        if shelves then

            for _,shelf in ipairs(shelves:GetChildren()) do

                local item=shelf:FindFirstChild("Item")

                if item and item:GetAttribute("ItemId") then
                    table.insert(items,item)
                end

            end

        end

    end

    return items
end

local function getPrice(item)

    local id=item:GetAttribute("ItemId")
    if not id then return end

    local info=ItemsModule[id]
    if not info then return end

    local base=info.Price or 0

    return math.floor(base*(1+offerPercent/100))
end

task.spawn(function()
    while true do

        if sendEnabled then

            for name,enabled in pairs(sendTargets) do

                if enabled then

                    local plr=Players:FindFirstChild(name)

                    if plr then

                        local non=plr:FindFirstChild("NonSaveVars")

                        if non then

                            local plotVal=non:FindFirstChild("OwnsPlot")

                            if plotVal and plotVal.Value then

                                local items=getPlacedItems(plotVal.Value)

                                for _,item in ipairs(items) do

                                    local price=getPrice(item)

                                    if price then

                                        pcall(function()
                                            MakeOfferRemote:InvokeServer(plr,nil,price,item)
                                        end)

                                        print("Offered",price,"for",item.Name,"from",plr.Name)

                                        task.wait(0.4)

                                    end

                                end

                            end

                        end

                    end

                end

            end

        end

        task.wait(1)

    end
end)

local acceptAny=false

Tab:AddToggle("AcceptToggle",{
    Title="Accept All Offers",
    Default=false,
    Callback=function(v)
        acceptAny=v
    end
})

task.spawn(function()

    while true do

        if acceptAny then

            for _,gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do

                local from=gui:GetAttribute("OfferFromPlayerName")
                local guid=gui:GetAttribute("GUID")
                local price=gui:GetAttribute("Offer")

                if from and guid and price then

                    pcall(function()
                        AcceptRemote:InvokeServer(from,guid,price)
                    end)

                    print("Accepted",from,price)

                end

            end

        end

        task.wait(0.5)

    end

end)

local placeEnabled=false

Tab:AddToggle("PlaceToggle",{
    Title="Auto Place",
    Default=false,
    Callback=function(v)
        placeEnabled=v
    end
})

task.spawn(function()

    while true do

        if placeEnabled then

            local data=GetAllRemote:InvokeServer()

            if data and data.Inventory then

                local non=LocalPlayer:FindFirstChild("NonSaveVars")

                if non then

                    local plotVal=non:FindFirstChild("OwnsPlot")

                    if plotVal and plotVal.Value then

                        local shelves={}

                        local furniture=plotVal.Value:FindFirstChild("Furniture")

                        if furniture then

                            for _,f in ipairs(furniture:GetChildren()) do

                                local s=f:FindFirstChild("Shelves")

                                if s then
                                    for _,shelf in ipairs(s:GetChildren()) do
                                        table.insert(shelves,shelf)
                                    end
                                end

                            end

                        end

                        local guids={}

                        for guid,info in pairs(data.Inventory) do
                            if not info.ItemPlaced then
                                table.insert(guids,guid)
                            end
                        end

                        for i=1,math.min(#guids,#shelves) do

                            SellRemote:FireServer(guids[i],shelves[i],true)

                            print("Placed",guids[i])

                            task.wait(0.25)

                        end

                    end

                end

            end

        end

        task.wait(2)

    end

end)

Window:SelectTab(Tab)
