local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Shop = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Shop")
local InsertFurniture = Shop:WaitForChild("InsertFurniture")
local DataEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Data"):WaitForChild("GetAll")
local ItemsModule = require(ReplicatedStorage.Modules.Items)

local nonSaveVars = LocalPlayer:FindFirstChild("NonSaveVars")
local ownsPlot = nonSaveVars and nonSaveVars:FindFirstChild("OwnsPlot")
local currentPlot = ownsPlot and ownsPlot:IsA("ValueBase") and ownsPlot.Value or "7"
local canvas = workspace.Plots[tostring(currentPlot)].Interior.Shop1.Canvas

local PODIUM_ID = "4"
local MAX_PODIUMS = 10
local PLACEMENT_INTERVAL = 5

local GRID_CONFIG = {
    startPos = canvas.Position + Vector3.new(-canvas.Size.X/2 + 4, canvas.Size.Y/2 + 1, -canvas.Size.Z/2 + 4),
    spacing = 6,
    itemsPerRow = math.floor(canvas.Size.X / 6) - 1,
    rowsPerFloor = math.floor(canvas.Size.Z / 6) - 1,
}

print("🎯 Podium Placement Script Started")
print("📍 Canvas Size:", canvas.Size.X, "x", canvas.Size.Z)
print("📊 Grid:", GRID_CONFIG.itemsPerRow, "x", GRID_CONFIG.rowsPerFloor, "=", GRID_CONFIG.itemsPerRow * GRID_CONFIG.rowsPerFloor, "positions")
print("⏱️  Check Interval:", PLACEMENT_INTERVAL, "seconds\n")

local function generatePosition(index)
    local row = math.floor((index - 1) / GRID_CONFIG.itemsPerRow)
    local col = (index - 1) % GRID_CONFIG.itemsPerRow
    local xOffset = col * GRID_CONFIG.spacing
    local zOffset = row * GRID_CONFIG.spacing
    
    if row >= GRID_CONFIG.rowsPerFloor then
        return nil
    end
    
    return GRID_CONFIG.startPos + Vector3.new(xOffset, 0, -zOffset)
end

local function getOccupiedPositions(playerData)
    local occupied = {}
    
    if playerData and playerData.Furniture then
        for _, furnitureData in pairs(playerData.Furniture) do
            if tostring(furnitureData.Id) == PODIUM_ID and furnitureData.Pos and type(furnitureData.Pos) == "table" then
                local pos = Vector3.new(furnitureData.Pos[1], furnitureData.Pos[2], furnitureData.Pos[3])
                
                for i = 1, GRID_CONFIG.itemsPerRow * GRID_CONFIG.rowsPerFloor do
                    local gridPos = generatePosition(i)
                    if gridPos and (pos - gridPos).Magnitude < 2 then
                        occupied[i] = true
                        break
                    end
                end
            end
        end
    end
    
    return occupied
end

local function scanAllFurniture(playerData)
    print("\n" .. string.rep("=", 50))
    print("🔍 SCANNING ALL PLACED FURNITURE")
    print(string.rep("=", 50))
    
    local totalItems = 0
    local itemsByName = {}
    local podiumPositions = {}

    if playerData and playerData.Furniture then
        for guid, furnitureData in pairs(playerData.Furniture) do
            totalItems = totalItems + 1
            
            local itemId = tostring(furnitureData.Id)
            local itemInfo = ItemsModule[itemId]
            local itemName = itemInfo and itemInfo.Name or "Unknown"
            local itemRarity = itemInfo and itemInfo.Rarity or "Unknown"
            
            if not itemsByName[itemName] then
                itemsByName[itemName] = {
                    count = 0,
                    items = {}
                }
            end
            
            itemsByName[itemName].count = itemsByName[itemName].count + 1
            
            local pos = furnitureData.Pos
            local posStr = "No position data"
            if pos and type(pos) == "table" then
                posStr = string.format("(%.2f, %.2f, %.2f)", pos[1], pos[2], pos[3])
                
                if itemId == PODIUM_ID then
                    local vectorPos = Vector3.new(pos[1], pos[2], pos[3])
                    table.insert(podiumPositions, vectorPos)
                end
            end
            
            table.insert(itemsByName[itemName].items, {
                guid = guid,
                id = itemId,
                rarity = itemRarity,
                position = posStr,
                floor = furnitureData.Floor or 1
            })
        end
    end

    print("\n📊 FURNITURE SUMMARY")
    print("Total items placed: " .. totalItems)
    print("\n📋 ITEMS BY TYPE:")

    local sortedNames = {}
    for name in pairs(itemsByName) do
        table.insert(sortedNames, name)
    end
    table.sort(sortedNames)

    for _, name in ipairs(sortedNames) do
        local data = itemsByName[name]
        print(string.format("  %s: %d", name, data.count))
    end

    return podiumPositions
end

local function placePodium(positionIndex)
    local pos = generatePosition(positionIndex)
    if not pos then
        return false
    end
    
    local args = {
        {
            Id = PODIUM_ID,
            CFrame = CFrame.new(pos),
            Floor = 1
        }
    }
    
    local success = pcall(function()
        return InsertFurniture:InvokeServer(unpack(args))
    end)
    
    if success then
        print("✅ Placed podium at position " .. positionIndex .. " (row " .. (math.floor((positionIndex-1)/GRID_CONFIG.itemsPerRow)+1) .. ", col " .. ((positionIndex-1)%GRID_CONFIG.itemsPerRow+1) .. ")")
    end
    
    return success
end

local function placeMissingPodiums()
    print("\n🔍 Checking podiums...")
    
    local success, playerData = pcall(function()
        return DataEvent:InvokeServer()
    end)
    
    if not success or not playerData then
        print("❌ Failed to get player data")
        return
    end
    
    scanAllFurniture(playerData)
    
    local occupied = getOccupiedPositions(playerData)
    local totalPositions = GRID_CONFIG.itemsPerRow * GRID_CONFIG.rowsPerFloor
    
    local placedCount = 0
    for i = 1, totalPositions do
        if occupied[i] then
            placedCount = placedCount + 1
        end
    end
    
    print("\n📌 Podiums placed:", placedCount, "/", MAX_PODIUMS)
    
    if placedCount >= MAX_PODIUMS then
        print("✨ Maximum podiums already placed!")
        return
    end
    
    local emptyPositions = {}
    for i = 1, totalPositions do
        if not occupied[i] then
            table.insert(emptyPositions, i)
        end
    end
    
    local canPlace = math.min(#emptyPositions, MAX_PODIUMS - placedCount)
    
    if canPlace <= 0 then
        print("🚫 No empty positions available")
        return
    end
    
    print("🎨 Empty positions:", #emptyPositions)
    print("🎨 Placing", canPlace, "podium(s)...")
    
    local placed = 0
    for i = 1, canPlace do
        local positionIndex = emptyPositions[i]
        
        if placePodium(positionIndex) then
            placed = placed + 1
        end
        
        task.wait(0.5)
    end
    
    print("✅ Placed", placed, "podium(s) total")
    print(string.rep("=", 50))
end

while true do
    placeMissingPodiums()
    task.wait(PLACEMENT_INTERVAL)
end
