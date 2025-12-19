task.spawn(function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local HttpService = game:GetService("HttpService")

	local player = Players.LocalPlayer

	local httpRequest =
		(syn and syn.request) or
		(http and http.request) or
		(http_request) or
		(fluxus and fluxus.request) or
		(request)

	if not httpRequest then return end

	local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
	local PetsModule = require(ReplicatedStorage.Shared.Data.Pets)

	local RemoteEvent =
		ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent

	local WEBHOOK = webhook_url or ""

	local lastPoints
	local STOP = false

	local function sendWebhook(tier, pet, image)
		if STOP then return end
		STOP = true
		if WEBHOOK == "" then return end

		httpRequest({
			Url = WEBHOOK,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode({
				username = "BGSI Season Guard",
				embeds = {{
					title = "🚨 SECRET PET DETECTED – PREMIUM",
					description = "Claiming has been **PERMANENTLY DISABLED**.",
					color = 16711680,
					thumbnail = { url = image },
					fields = {
						{ name = "Player", value = player.Name, inline = true },
						{ name = "Tier", value = tostring(tier), inline = true },
						{ name = "Pet", value = pet, inline = true },
						{ name = "Rarity", value = "Secret", inline = true },
						{ name = "Pass", value = "Premium", inline = true },
					}
				}}
			})
		})
	end

	while true do
		if STOP then break end

		local data = LocalData:Get()
		local s = data and data.Season
		if not s then
			task.wait(5)
			continue
		end

		local pts = s.Points or 0

		if lastPoints == nil then
			lastPoints = pts
			task.wait(5)
			continue
		end

		if pts > lastPoints then
			local nextTier = (s.Level or 0) + 1
			local tiers = s.InfinityTiers or s.Tiers
			local reward = tiers and tiers[nextTier] and tiers[nextTier].Premium

			if reward and reward.Type == "Pet" then
				local info = PetsModule[reward.Name]
				if info and info.Rarity == "Secret" then
					sendWebhook(
						nextTier,
						reward.Name,
						"https://content.bgsi.io/" .. reward.Name:lower():gsub(" ", "_") .. ".webp"
					)
					break
				end
			end

			RemoteEvent:FireServer("ClaimSeason")
			lastPoints = pts
		end

		task.wait(5)
	end
end)
