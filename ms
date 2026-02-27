local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Window = Fluent:CreateWindow({
    Title = "Shop & Player Manager",
    SubTitle = "Main Controls",
    TabWidth = 160,
    Size = UDim2.fromOffset(380, 400),
    Acrylic = true,
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" })
}

local selectedPlayers = {}
local targetAcceptPlayer = ""
local autoTpEnabled = false
local placeItemsEnabled = false
local acceptAnyEnabled = false
local acceptSpecificEnabled = false

local function getPlayerNames()
    local n = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(n, p.Name)
        end
    end
    return n
end

local PlayerMultiSelect = Tabs.Main:AddDropdown("MultiTP", {
    Title = "Select Players to TP",
    Values = getPlayerNames(),
    Multi = true,
    Default = {},
    Callback = function(Value)
        selectedPlayers = Value
    end
})

Tabs.Main:AddToggle("AutoTP", {
    Title = "Auto TP (0.5s)",
    Default = false,
    Callback = function(Value)
        autoTpEnabled = Value
    end
})

task.spawn(function()
    while task.wait(0.5) do
        if autoTpEnabled and LocalPlayer.Character then
            local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then
                for name, state in pairs(selectedPlayers) do
                    if state then
                        local p = Players:FindFirstChild(name)
                        if p and p.Character then
                            local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
                            if targetRoot then
                                LocalPlayer.Character:PivotTo(targetRoot.CFrame * CFrame.new(0, 0, -3))
                            end
                        end
                    end
                end
            end
        end
    end
end)

Tabs.Main:AddSection("Shop Section")

Tabs.Main:AddButton({
    Title = "Teleport to Random Shelf",
    Callback = function()
        if not LocalPlayer.Character then return end

        local plotName = LocalPlayer:WaitForChild("NonSaveVars"):WaitForChild("OwnsPlot").Value
        if typeof(plotName) ~= "string" then plotName = plotName.Name end

        local plot = workspace:WaitForChild("Plots"):WaitForChild(plotName)
        local shelves = {}

        for _, furniture in ipairs(plot:WaitForChild("Furniture"):GetChildren()) do
            local s = furniture:FindFirstChild("Shelves")
            if s then
                for _, shelf in ipairs(s:GetChildren()) do
                    if shelf:IsA("BasePart") then
                        table.insert(shelves, shelf)
                    elseif shelf:FindFirstChild("MainPart") then
                        table.insert(shelves, shelf.MainPart)
                    end
                end
            end
        end

        if #shelves > 0 then
            local randomShelf = shelves[math.random(#shelves)]
            LocalPlayer.Character:PivotTo(randomShelf.CFrame * CFrame.new(0, 3, 0))
        end
    end
})

Tabs.Main:AddToggle("PlaceItems", {
    Title = "Place All Items (1s)",
    Default = false,
    Callback = function(Value)
        placeItemsEnabled = Value
    end
})

task.spawn(function()
    local SellRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Shop"):WaitForChild("SellItemInShop")
    local GetAll = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Data"):WaitForChild("GetAll")
    local ItemsModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Items"))

    while task.wait(1) do
        if placeItemsEnabled then
            local data = GetAll:InvokeServer()
            local plotName = LocalPlayer:WaitForChild("NonSaveVars"):WaitForChild("OwnsPlot").Value
            if typeof(plotName) ~= "string" then plotName = plotName.Name end
            local plot = workspace:WaitForChild("Plots"):WaitForChild(plotName)

            local shelves = {}
            for _, furniture in ipairs(plot:WaitForChild("Furniture"):GetChildren()) do
                local s = furniture:FindFirstChild("Shelves")
                if s then
                    for _, shelf in ipairs(s:GetChildren()) do
                        table.insert(shelves, shelf)
                    end
                end
            end

            local guids = {}
            for guid, info in pairs(data.Inventory) do
                local itemData = ItemsModule[tostring(info.Id)]
                local name = itemData and string.lower(itemData.Name or "") or ""
                if tostring(info.Id) ~= "281" and tostring(info.Id) ~= "2294" and not string.find(name, "safe") then
                    table.insert(guids, guid)
                end
            end

            local count = math.min(#shelves, #guids)
            for i = 1, count do
                if not placeItemsEnabled then break end
                SellRemote:FireServer(guids[i], shelves[i], true)
                task.wait(0.1)
            end
        end
    end
end)

Tabs.Main:AddToggle("AcceptAny", {
    Title = "Accept Any Offers",
    Default = false,
    Callback = function(Value)
        acceptAnyEnabled = Value
    end
})

Tabs.Main:AddDropdown("AcceptSpecificPlayer", {
    Title = "Select Player to Accept From",
    Values = getPlayerNames(),
    Default = "",
    Callback = function(Value)
        targetAcceptPlayer = Value
    end
})

Tabs.Main:AddToggle("AcceptSpecific", {
    Title = "Accept Offers From Selected Player",
    Default = false,
    Callback = function(Value)
        acceptSpecificEnabled = Value
    end
})

local function handleOffer(obj)
    local AcceptRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Shop"):WaitForChild("AcceptPlayerOffer")
    local from = obj:GetAttribute("OfferFromPlayerName")
    local guid = obj:GetAttribute("GUID")
    local price = obj:GetAttribute("Offer")

    if from and guid and price then
        if acceptAnyEnabled then
            AcceptRemote:InvokeServer(from, guid, price)
        elseif acceptSpecificEnabled and from == targetAcceptPlayer then
            AcceptRemote:InvokeServer(from, guid, price)
        end
    end
end

LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
    task.wait(0.1)
    handleOffer(child)
end)

for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
    handleOffer(gui)
end

Window:SelectTab(Tabs.Main)
