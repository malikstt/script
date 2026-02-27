local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("Rep licatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Main", "DarkTheme")

local MainTab = Window:NewTab("Main")
local PlayerSection = MainTab:NewSection("Players")
local ShopSection = MainTab:NewSection("Shop")

local selectedPlayers = {}
local autoTPEnabled = false
local acceptOffersEnabled = false
local selectedAcceptPlayer = nil
local tpConnection = nil
local acceptConnection = nil
local placeItemsConnection = nil
local placeItemsEnabled = false

local function getCash(player)
    local success, cash = pcall(function()
        return player:FindFirstChild("SaveVars") and player.SaveVars:FindFirstChild("Cash") and player.SaveVars.Cash.Value
    end)
    return success and cash or 0
end

local function updatePlayerList()
    PlayerSection:Clear()
    PlayerSection:AddToggle("Auto TP", nil, function(state)
        autoTPEnabled = state
        if autoTPEnabled then
            if tpConnection then tpConnection:Disconnect() end
            tpConnection = game:GetService("RunService").Heartbeat:Connect(function()
                if autoTPEnabled then
                    for _, player in pairs(selectedPlayers) do
                        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                        end
                    end
                    task.wait(0.5)
                end
            end)
        else
            if tpConnection then
                tpConnection:Disconnect()
                tpConnection = nil
            end
        end
    end)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            PlayerSection:AddToggle(player.Name .. " ($" .. tostring(getCash(player)) .. ")", nil, function(state)
                selectedPlayers[player] = state
            end)
        end
    end
end

local function teleportToRandomShelf()
    local plotName = LocalPlayer:FindFirstChild("NonSaveVars") and LocalPlayer.NonSaveVars:FindFirstChild("OwnsPlot") and LocalPlayer.NonSaveVars.OwnsPlot.Value and LocalPlayer.NonSaveVars.OwnsPlot.Value.Name
    if not plotName then return end
    
    local plot = workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(plotName)
    if not plot then return end
    
    local shelves = {}
    for _, furniture in ipairs(plot:FindFirstChild("Furniture"):GetChildren()) do
        local s = furniture:FindFirstChild("Shelves")
        if s then
            for _, shelf in ipairs(s:GetChildren()) do
                table.insert(shelves, shelf)
            end
        end
    end
    
    if #shelves > 0 then
        local randomShelf = shelves[math.random(1, #shelves)]
        if randomShelf and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = randomShelf.CFrame
        end
    end
end

local function placeAllItems()
    local GetAll = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Data"):WaitForChild("GetAll")
    local SellRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Shop"):WaitForChild("SellItemInShop")
    local ItemsModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Items"))
    
    local data = GetAll:InvokeServer()
    
    local plotName = LocalPlayer:FindFirstChild("NonSaveVars") and LocalPlayer.NonSaveVars:FindFirstChild("OwnsPlot") and LocalPlayer.NonSaveVars.OwnsPlot.Value and LocalPlayer.NonSaveVars.OwnsPlot.Value.Name
    if not plotName then return end
    
    local plot = workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(plotName)
    if not plot then return end
    
    local shelves = {}
    for _, furniture in ipairs(plot:FindFirstChild("Furniture"):GetChildren()) do
        local s = furniture:FindFirstChild("Shelves")
        if s then
            for _, shelf in ipairs(s:GetChildren()) do
                table.insert(shelves, shelf)
            end
        end
    end
    
    local guids = {}
    for guid, info in pairs(data.Inventory) do
        local id = tonumber(info.Id)
        local itemData = ItemsModule[id]
        local name = itemData and string.lower(itemData.Name or "") or ""
        if id ~= 281 and id ~= 2294 and not string.find(name, "safe") then
            table.insert(guids, guid)
        end
    end
    
    local count = math.min(#shelves, #guids)
    for i = 1, count do
        if not placeItemsEnabled then break end
        SellRemote:FireServer(guids[i], shelves[i], true)
        task.wait(1)
    end
end

local function acceptOffersFromPlayer(playerName)
    local AcceptRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Shop"):WaitForChild("AcceptPlayerOffer")
    
    local function tryAccept(obj)
        local from = obj:GetAttribute("OfferFromPlayerName")
        local guid = obj:GetAttribute("GUID")
        local price = obj:GetAttribute("Offer")
        
        if from and guid and price and (not playerName or from == playerName) then
            AcceptRemote:InvokeServer(from, guid, price)
        end
    end
    
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        tryAccept(gui)
    end
    
    LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
        task.wait(0.05)
        if acceptOffersEnabled and (not selectedAcceptPlayer or child:GetAttribute("OfferFromPlayerName") == selectedAcceptPlayer) then
            tryAccept(child)
        end
    end)
end

ShopSection:AddButton("Teleport to Random Shelf", function()
    teleportToRandomShelf()
end)

ShopSection:AddToggle("Place All Items (Every 1s)", nil, function(state)
    placeItemsEnabled = state
    if placeItemsEnabled then
        if placeItemsConnection then placeItemsConnection:Disconnect() end
        placeItemsConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if placeItemsEnabled then
                placeAllItems()
                task.wait(1)
            end
        end)
    else
        if placeItemsConnection then
            placeItemsConnection:Disconnect()
            placeItemsConnection = nil
        end
    end
end)

ShopSection:AddToggle("Accept Any Offers", nil, function(state)
    acceptOffersEnabled = state
    if acceptOffersEnabled then
        selectedAcceptPlayer = nil
        if acceptConnection then acceptConnection:Disconnect() end
        acceptConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if acceptOffersEnabled then
                acceptOffersFromPlayer()
                task.wait(0.5)
            end
        end)
    else
        if acceptConnection then
            acceptConnection:Disconnect()
            acceptConnection = nil
        end
    end
end)

local playerDropdown = {}
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        table.insert(playerDropdown, player.Name)
    end
end

ShopSection:AddDropdown("Accept From Player", playerDropdown, function(selected)
    selectedAcceptPlayer = selected
    if acceptOffersEnabled then
        if acceptConnection then acceptConnection:Disconnect() end
        acceptConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if acceptOffersEnabled and selectedAcceptPlayer then
                acceptOffersFromPlayer(selectedAcceptPlayer)
                task.wait(0.5)
            end
        end)
    end
end)

Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)
LocalPlayer.SaveVars.Cash:GetPropertyChangedSignal("Value"):Connect(updatePlayerList)

updatePlayerList()
