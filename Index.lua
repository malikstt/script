AUTO_CLAIM_INDEX = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(
    ReplicatedStorage.Packages.DataService
).client

local Rewards = require(
    ReplicatedStorage.Source.Features.Index.IndexRewards
)

local Remote = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("leifstout_networker@0.3.1")
    :WaitForChild("networker")
    :WaitForChild("_remotes")
    :WaitForChild("IndexService")
    :WaitForChild("RemoteFunction")

local function getUnlockedCount(categoryData)
    local unlocked = categoryData.unlocked

    if type(unlocked) ~= "table" then
        return 0
    end

    local count = 0

    for _, v in pairs(unlocked) do
        if v == true then
            count += 1
        end
    end

    return count
end

local function checkRewards()
    local data = DataService:get("index")

    if not data or not data.categories then
        print("[INDEX] No data")
        return
    end

    local found = false

    for category, rewards in pairs(Rewards) do
        local categoryData = data.categories[category]

        if categoryData then
            local unlockedCount = getUnlockedCount(categoryData)

            local claimedRewards =
                categoryData.claimedRewards or {}

            for _, reward in ipairs(rewards) do
                local key = reward.key
                local req = reward.req

                local claimed = claimedRewards[key]

                if unlockedCount >= req and not claimed then
                    found = true

                    print(
                        "[INDEX] Claimable:",
                        key,
                        "(" .. unlockedCount .. "/" .. req .. ")"
                    )

                    local success, result = pcall(function()
                        return Remote:InvokeServer(
                            "requestClaimReward",
                            category
                        )
                    end)

                    print(
                        "[INDEX] Result:",
                        success,
                        result
                    )

                    task.wait(0.5)
                end
            end
        end
    end

    if not found then
        print("[INDEX] No claimable rewards")
    end
end

task.spawn(function()
    while AUTO_CLAIM_INDEX do
        checkRewards()
        task.wait(60)
    end
end)
