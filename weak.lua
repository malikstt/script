local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

pcall(function() settings().Rendering.QualityLevel = 1 end)

local DataClient = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("DataService")).client
local data = DataClient._data._data
local LocalPlayer = Players.LocalPlayer

local UPDATE_INTERVAL = 0.5
local TWEEN_TIME = 0.22

local P = {
	bg       = Color3.fromRGB(4, 4, 10),
	panel    = Color3.fromRGB(9, 11, 20),
	panelB   = Color3.fromRGB(13, 16, 28),
	border   = Color3.fromRGB(28, 34, 55),
	accent   = Color3.fromRGB(90, 170, 255),
	accentB  = Color3.fromRGB(40, 90, 180),
	gold     = Color3.fromRGB(255, 215, 55),
	goldD    = Color3.fromRGB(180, 130, 20),
	diamond  = Color3.fromRGB(130, 235, 255),
	diamondD = Color3.fromRGB(60, 150, 200),
	void     = Color3.fromRGB(190, 85, 255),
	voidD    = Color3.fromRGB(100, 30, 160),
	galaxy   = Color3.fromRGB(255, 100, 200),
	green    = Color3.fromRGB(75, 225, 110),
	greenD   = Color3.fromRGB(30, 120, 55),
	red      = Color3.fromRGB(255, 75, 75),
	redD     = Color3.fromRGB(140, 25, 25),
	orange   = Color3.fromRGB(255, 155, 50),
	text     = Color3.fromRGB(215, 225, 248),
	dim      = Color3.fromRGB(95, 108, 140),
	dimB     = Color3.fromRGB(55, 65, 90),
	white    = Color3.fromRGB(255, 255, 255),
}

local ICONS = {
	rebirth      = "rbxassetid://132563621658654",
	goop         = "rbxassetid://114367663524453",
	coins        = "rbxassetid://103275559073812",
	kills        = "rbxassetid://111148706433634",
	zone         = "rbxassetid://96591575070730",
	goldDice     = "rbxassetid://133158717152423",
	diamondDice  = "rbxassetid://139581611167886",
	voidDice     = "rbxassetid://98779770728903",
	galaxyDice   = "rbxassetid://138834642952755",
	shinyDice    = "rbxassetid://89237596664450",
	hugeDice     = "rbxassetid://111187395249053",
	bigDice      = "rbxassetid://107180171048542",
	invertedDice = "rbxassetid://100992984750625",
	index        = "rbxassetid://123662711814867",
	gift         = "rbxassetid://134519398228628",
	loot         = "rbxassetid://102533388850982",
	autoRoll     = "rbxassetid://95749578757531",
	shop         = "rbxassetid://106557585104181",
	boostLuck    = "rbxassetid://106587060928771",
}

local SFX = {"1e24","Sp","1e21","Sx","1e18","Qn","1e15","Qd","1e12","T","1e9","B","1e6","M","1e3","K"}
local SUFFIXES = {{1e24,"Sp"},{1e21,"Sx"},{1e18,"Qn"},{1e15,"Qd"},{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}}

local function fmt(n)
	n = tonumber(n) or 0
	for _, p in ipairs(SUFFIXES) do
		if n >= p[1] then
			return (string.format("%.2f", n/p[1]):gsub("%.?0+$","")) .. p[2]
		end
	end
	return tostring(math.floor(n))
end

local function fmtTime(s)
	s = math.floor(tonumber(s) or 0)
	local d = math.floor(s/86400)
	local h = math.floor((s%86400)/3600)
	local m = math.floor((s%3600)/60)
	if d > 0 then return d.."d "..h.."h" end
	if h > 0 then return h.."h "..m.."m" end
	return m.."m "..math.floor(s%60).."s"
end

local function tw(obj, props, t)
	TweenService:Create(obj, TweenInfo.new(t or TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function pulse(lbl)
	tw(lbl, {TextTransparency=0.55}, 0.04)
	task.delay(0.04, function() tw(lbl, {TextTransparency=0}, 0.18) end)
end

local function mk(cls, props, par)
	local o = Instance.new(cls)
	for k,v in pairs(props) do o[k]=v end
	if par then o.Parent=par end
	return o
end

local function frame(props, par)
	props.BackgroundTransparency = props.BackgroundTransparency or 0
	return mk("Frame", props, par)
end

local function lbl(props, par)
	props.BackgroundTransparency = 1
	props.Font = props.Font or Enum.Font.GothamBold
	props.TextScaled = true
	props.TextWrapped = false
	return mk("TextLabel", props, par)
end

local function img(props, par)
	props.BackgroundTransparency = 1
	props.ScaleType = props.ScaleType or Enum.ScaleType.Fit
	return mk("ImageLabel", props, par)
end

local function corner(par, r)
	mk("UICorner", {CornerRadius=UDim.new(0, r or 6)}, par)
end

local function stroke(par, col, th)
	mk("UIStroke", {Color=col or P.border, Thickness=th or 1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border}, par)
end

local function gradient(par, c0, c1, rot)
	mk("UIGradient", {Color=ColorSequence.new(c0, c1), Rotation=rot or 90}, par)
end

local function pad(par, t, b, l, r)
	mk("UIPadding", {PaddingTop=UDim.new(t,0), PaddingBottom=UDim.new(b,0), PaddingLeft=UDim.new(l,0), PaddingRight=UDim.new(r,0)}, par)
end

local function list(par, dir, ha, va, spacing)
	local ul = Instance.new("UIListLayout")
	ul.FillDirection = dir or Enum.FillDirection.Vertical
	ul.HorizontalAlignment = ha or Enum.HorizontalAlignment.Center
	ul.VerticalAlignment = va or Enum.VerticalAlignment.Top
	ul.Padding = UDim.new(0, spacing or 8)
	ul.SortOrder = Enum.SortOrder.LayoutOrder
	ul.Parent = par
	return ul
end

local function safeGet(...)
	local cur = data
	for _, k in ipairs({...}) do
		if type(cur) ~= "table" then return 0 end
		cur = cur[k]
		if cur == nil then return 0 end
	end
	return tonumber(cur) or 0
end

local function safeGetRaw(...)
	local cur = data
	for _, k in ipairs({...}) do
		if type(cur) ~= "table" then return nil end
		cur = cur[k]
		if cur == nil then return nil end
	end
	return cur
end

local function countKeys(t)
	if type(t) ~= "table" then return 0 end
	local c = 0
	for _ in pairs(t) do c=c+1 end
	return c
end

local function getBestRoll()
	local rd = safeGetRaw("stats","rarestRoll","slimeData")
	if type(rd) ~= "table" then return "None", "N/A" end
	local id = tostring(rd.id or "?")
	local mut = rd.mutations
	local pre = ""
	if type(mut) == "table" then
		if mut.inverted then pre="Inverted "
		elseif mut.shiny and mut.huge then pre="Shiny Huge "
		elseif mut.shiny and mut.big then pre="Shiny Big "
		elseif mut.huge then pre="Huge "
		elseif mut.shiny then pre="Shiny "
		elseif mut.big then pre="Big " end
	end
	local name = pre..id:sub(1,1):upper()..id:sub(2)
	local odds = safeGet("stats","rarestRoll","odds")
	return name, odds > 0 and ("1 in "..fmt(math.floor(odds))) or "N/A"
end

local function getDailyBestOdds()
	local odds = safeGet("stats","dailyRarestRoll","odds")
	return odds > 0 and ("1 in "..fmt(math.floor(odds))) or "N/A"
end

local function getTotalInventory()
	local inv = safeGetRaw("inventory")
	if type(inv) ~= "table" then return 0 end
	local t = 0
	for _, v in pairs(inv) do if type(v)=="number" then t=t+v end end
	return t
end

local function getIndexCounts()
	local cats = safeGetRaw("index","categories")
	if type(cats) ~= "table" then return 0,0,0,0,0 end
	local function c(cat)
		local t = cats[cat]
		return type(t)=="table" and countKeys(t.unlocked or {}) or 0
	end
	return c("basic"), c("big"), c("shiny"), c("huge"), c("inverted")
end

local function getProgText(v)
	local n = tonumber(v)
	if n == nil then return "-" end
	if n == 0 then return "READY" end
	return fmt(n).." rolls"
end

local sessionStart = os.clock()
local startRolls = safeGet("stats","rolls")
local startKills = safeGet("stats","kills")
local startCoins = safeGet("coins")
local startGoop  = safeGet("goop")

local prevRolls = startRolls
local prevCoins = startCoins
local prevGoop  = startGoop
local lastUpdate = os.clock()
local windowRPS, windowCPS, windowGPS = 0, 0, 0
local lastRollMove = os.clock()
local lastCoinMove = os.clock()
local lastGoopMove = os.clock()
local STALE = 60

task.spawn(function()
	while true do
		task.wait(10)
		pcall(function()
			local now = os.clock()
			local dt = math.max(1, now - lastUpdate)
			lastUpdate = now
			local r = safeGet("stats","rolls")
			local c = safeGet("coins")
			local g = safeGet("goop")
			local dr = math.max(0, r-prevRolls)
			local dc = math.max(0, c-prevCoins)
			local dg = math.max(0, g-prevGoop)
			if dr > 0 then windowRPS=dr/dt lastRollMove=now end
			if dc > 0 then windowCPS=dc/dt lastCoinMove=now end
			if dg > 0 then windowGPS=dg/dt lastGoopMove=now end
			prevRolls=r prevCoins=c prevGoop=g
		end)
	end
end)

local function getRate(wv, lm, sv, cv)
	local now = os.clock()
	local elapsed = math.max(1, now-sessionStart)
	if (now-lm) > STALE then return 0 end
	if wv and wv > 0 then return wv end
	local gain = math.max(0, cv-sv)
	return gain > 0 and (gain/elapsed) or 0
end

local function buildHUD(playerGui)
	local existing = playerGui:FindFirstChild("__SLIMEHUD_V2__")
	if existing then existing:Destroy() end

	local sg = mk("ScreenGui", {
		Name="__SLIMEHUD_V2__",
		ResetOnSpawn=false,
		IgnoreGuiInset=true,
		DisplayOrder=9999,
		ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
		Parent=playerGui,
	})

	local root = frame({
		Name="Root",
		Size=UDim2.fromScale(1,1),
		BackgroundColor3=P.bg,
	}, sg)
	gradient(root, Color3.fromRGB(4,4,12), Color3.fromRGB(6,8,18), 135)
	mk("UIScale", {Scale=1}, root)
	mk("UIAspectRatioConstraint", {AspectRatio=16/9, AspectType=Enum.AspectType.ScaleWithParentSize, DominantAxis=Enum.DominantAxis.Width}, root)

	local overlay = frame({Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0.94, ZIndex=10}, root)

	local function scanline(par)
		for i = 0, 30 do
			frame({
				Size=UDim2.fromScale(1, 0.0008),
				Position=UDim2.fromScale(0, i/30),
				BackgroundColor3=Color3.fromRGB(255,255,255),
				BackgroundTransparency=0.97,
				ZIndex=9,
			}, par)
		end
	end
	scanline(root)

	local function glow(par, col, size, pos)
		local g = frame({Size=size or UDim2.fromScale(0.4,0.4), Position=pos or UDim2.fromScale(0.3,0.3), BackgroundColor3=col, BackgroundTransparency=0.88, ZIndex=1}, par)
		corner(g, 999)
		return g
	end

	glow(root, P.accent, UDim2.fromScale(0.35,0.5), UDim2.fromScale(0.32,0.25))
	glow(root, P.void,   UDim2.fromScale(0.2,0.3),  UDim2.fromScale(0.01,0.1))
	glow(root, P.gold,   UDim2.fromScale(0.2,0.3),  UDim2.fromScale(0.79,0.1))

	local function panel(props, par)
		local f = frame(props, par)
		corner(f, props._r or 10)
		stroke(f, props._sc or P.border, props._st or 1)
		if props._grad then
			gradient(f, props._grad[1], props._grad[2], props._grad[3] or 135)
		end
		return f
	end

	local function accentBar(par, col)
		local b = frame({Size=UDim2.fromScale(1,0.003), Position=UDim2.fromScale(0,0), BackgroundColor3=col or P.accent, ZIndex=5}, par)
		gradient(b, col or P.accent, Color3.fromRGB(0,0,0), 0)
	end

	local topBar = panel({
		Size=UDim2.fromScale(0.3, 0.085),
		Position=UDim2.fromScale(0.35, 0.008),
		BackgroundColor3=P.panel,
		_sc=P.accent, _st=1,
		_grad={Color3.fromRGB(9,12,24), Color3.fromRGB(12,16,32)},
	}, root)
	accentBar(topBar, P.accent)

	local avatarWrap = frame({
		Size=UDim2.fromScale(0.16, 0.82),
		Position=UDim2.fromScale(0.018, 0.09),
		BackgroundColor3=P.accentB,
	}, topBar)
	corner(avatarWrap, 7)
	mk("UIAspectRatioConstraint", {AspectRatio=1, AspectType=Enum.AspectType.ScaleWithParentSize, DominantAxis=Enum.DominantAxis.Height}, avatarWrap)
	stroke(avatarWrap, P.accent, 1)

	local avatarImg = img({
		Size=UDim2.fromScale(1,1),
		Image="",
		ScaleType=Enum.ScaleType.Fit,
	}, avatarWrap)
	corner(avatarImg, 7)

	task.spawn(function()
		if not sg.Parent then return end
		local ok, i = pcall(function()
			return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok and sg.Parent then avatarImg.Image = i end
	end)

	local nameLabel = lbl({
		Size=UDim2.fromScale(0.56, 0.46),
		Position=UDim2.fromScale(0.2, 0.06),
		Text=LocalPlayer.Name,
		TextColor3=P.text,
		TextXAlignment=Enum.TextXAlignment.Left,
		Font=Enum.Font.GothamBold,
	}, topBar)

	local timerLbl = lbl({
		Size=UDim2.fromScale(0.56, 0.38),
		Position=UDim2.fromScale(0.2, 0.56),
		Text="00:00",
		TextColor3=P.dim,
		TextXAlignment=Enum.TextXAlignment.Left,
		Font=Enum.Font.Gotham,
	}, topBar)

	local rebirthBadge = frame({
		Size=UDim2.fromScale(0.18, 0.55),
		Position=UDim2.fromScale(0.8, 0.22),
		BackgroundColor3=P.voidD,
	}, topBar)
	corner(rebirthBadge, 6)
	stroke(rebirthBadge, P.void, 1)
	gradient(rebirthBadge, P.voidD, Color3.fromRGB(60,10,100))

	local rebirthNumLbl = lbl({
		Size=UDim2.fromScale(1,0.6),
		Position=UDim2.fromScale(0,0.05),
		Text="0",
		TextColor3=P.void,
		Font=Enum.Font.GothamBold,
	}, rebirthBadge)

	local rebirthTxtLbl = lbl({
		Size=UDim2.fromScale(1,0.38),
		Position=UDim2.fromScale(0,0.62),
		Text="rebirths",
		TextColor3=P.dim,
		Font=Enum.Font.Gotham,
	}, rebirthBadge)

	local function makePanel(size, pos, sc, grad)
		local f = panel({
			Size=size,
			Position=pos,
			BackgroundColor3=P.panel,
			_sc=sc or P.border,
			_grad=grad or {Color3.fromRGB(9,11,20), Color3.fromRGB(11,14,25)},
		}, root)
		pad(f, 0.025, 0.025, 0.04, 0.04)
		return f
	end

	local function makeRow(par, iconId, labelTxt, valTxt, valCol, h)
		local row = frame({
			Size=UDim2.fromScale(1, h or 0.14),
			BackgroundColor3=P.panelB,
		}, par)
		corner(row, 6)
		gradient(row, Color3.fromRGB(12,15,26), Color3.fromRGB(9,11,20))

		local iFrame = frame({Size=UDim2.fromScale(0.2,1), BackgroundTransparency=1}, row)
		if iconId and iconId ~= "" then
			local ic = img({Size=UDim2.fromScale(0.85,0.7), Position=UDim2.fromScale(0.075,0.15), Image=iconId}, iFrame)
			mk("UIAspectRatioConstraint", {AspectRatio=1, AspectType=Enum.AspectType.ScaleWithParentSize, DominantAxis=Enum.DominantAxis.Height}, ic)
		else
			lbl({Size=UDim2.fromScale(1,0.75), Position=UDim2.fromScale(0,0.125), Text=iconId or "?", TextColor3=P.accent, Font=Enum.Font.GothamBold}, iFrame)
		end

		if labelTxt and labelTxt ~= "" then
			lbl({Size=UDim2.fromScale(0.42,0.75), Position=UDim2.fromScale(0.21,0.125), Text=labelTxt, TextColor3=P.dim, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left}, row)
		end

		local vx = labelTxt and labelTxt ~= "" and 0.62 or 0.21
		local vw = labelTxt and labelTxt ~= "" and 0.35 or 0.76
		local valLabel = lbl({Size=UDim2.fromScale(vw,0.75), Position=UDim2.fromScale(vx,0.125), Text=valTxt or "0", TextColor3=valCol or P.text, TextXAlignment=Enum.TextXAlignment.Right}, row)
		return row, valLabel
	end

	local function makeSpecialRow(par, iconId, labelTxt, valTxt, valCol, readyCol)
		local row = frame({
			Size=UDim2.fromScale(1, 0.14),
			BackgroundColor3=P.panelB,
		}, par)
		corner(row, 6)
		gradient(row, Color3.fromRGB(14,16,28), Color3.fromRGB(9,11,20))

		local iFrame = frame({Size=UDim2.fromScale(0.18,1), BackgroundTransparency=1}, row)
		local ic = img({Size=UDim2.fromScale(0.85,0.7), Position=UDim2.fromScale(0.075,0.15), Image=iconId}, iFrame)
		mk("UIAspectRatioConstraint", {AspectRatio=1, AspectType=Enum.AspectType.ScaleWithParentSize, DominantAxis=Enum.DominantAxis.Height}, ic)

		lbl({Size=UDim2.fromScale(0.38,0.75), Position=UDim2.fromScale(0.2,0.125), Text=labelTxt, TextColor3=P.dim, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left}, row)

		local valLabel = lbl({Size=UDim2.fromScale(0.38,0.75), Position=UDim2.fromScale(0.6,0.125), Text=valTxt or "-", TextColor3=valCol or P.text, TextXAlignment=Enum.TextXAlignment.Right}, row)
		return row, valLabel
	end

	local LP = makePanel(UDim2.fromScale(0.19, 0.78), UDim2.fromScale(0.005, 0.11), P.border)
	list(LP, nil, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top, 6)
	accentBar(LP, P.green)

	lbl({Size=UDim2.fromScale(1,0.05), Text="RESOURCES", TextColor3=P.dimB, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left}, LP)

	local _, goopV  = makeRow(LP, ICONS.goop,   "",      "0", P.green)
	local _, coinsV = makeRow(LP, ICONS.coins,  "",      "0", P.gold)
	local _, rollCurV = makeRow(LP, ICONS.goldDice, "", "0", P.accent)

	lbl({Size=UDim2.fromScale(1,0.05), Text="SESSION", TextColor3=P.dimB, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left}, LP)

	local _, sRollsV = makeRow(LP, "🎲", "", "0", P.void)
	local _, sKillsV = makeRow(LP, ICONS.kills, "", "0", P.red)
	local _, sCoinsV = makeRow(LP, ICONS.coins, "", "+0", P.gold)

	lbl({Size=UDim2.fromScale(1,0.05), Text="RATES /min", TextColor3=P.dimB, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left}, LP)

	local _, rpsV    = makeRow(LP, "🎲",         "", "0/s",  P.void)
	local _, cpsV    = makeRow(LP, ICONS.coins,  "", "0/s",  P.gold)
	local _, gpsV    = makeRow(LP, ICONS.goop,   "", "0/s",  P.green)

	local CP = makePanel(UDim2.fromScale(0.3, 0.78), UDim2.fromScale(0.35, 0.11), P.accent)
	list(CP, nil, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top, 6)
	accentBar(CP, P.accent)

	lbl({Size=UDim2.fromScale(1,0.05), Text="SPECIAL ROLL PROGRESSION", TextColor3=P.dimB, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left}, CP)

	local _, goldenV  = makeSpecialRow(CP, ICONS.goldDice,    "Golden",   "-", P.gold,    P.gold)
	local _, diamondV = makeSpecialRow(CP, ICONS.diamondDice, "Diamond",  "-", P.diamond, P.diamond)
	local _, voidV    = makeSpecialRow(CP, ICONS.voidDice,    "Void",     "-", P.void,    P.void)
	local _, galaxyV  = makeSpecialRow(CP, ICONS.galaxyDice,  "Galaxy",   "-", P.galaxy,  P.galaxy)
	local _, shinyV   = makeSpecialRow(CP, ICONS.shinyDice,   "Shiny",    "-", P.diamond, P.diamond)
	local _, hugeV    = makeSpecialRow(CP, ICONS.hugeDice,    "Huge",     "-", P.orange,  P.orange)

	lbl({Size=UDim2.fromScale(1,0.04), Text="REBIRTH", TextColor3=P.dimB, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left}, CP)

	local rebirthProgressFrame = frame({Size=UDim2.fromScale(1,0.045), BackgroundColor3=P.panelB}, CP)
	corner(rebirthProgressFrame, 6)
	stroke(rebirthProgressFrame, P.border, 1)
	local rebirthBar = frame({Size=UDim2.fromScale(0,1), BackgroundColor3=P.void}, rebirthProgressFrame)
	corner(rebirthBar, 6)
	gradient(rebirthBar, P.void, P.galaxy, 0)
	local rebirthPctLbl = lbl({Size=UDim2.fromScale(1,1), Text="0%", TextColor3=P.white, Font=Enum.Font.GothamBold, ZIndex=2}, rebirthProgressFrame)

	lbl({Size=UDim2.fromScale(1,0.04), Text="BEST ROLLS", TextColor3=P.dimB, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left}, CP)

	local bestFrame = frame({Size=UDim2.fromScale(1,0.11), BackgroundColor3=P.panelB}, CP)
	corner(bestFrame, 7)
	stroke(bestFrame, P.gold, 1)
	gradient(bestFrame, Color3.fromRGB(18,15,8), Color3.fromRGB(10,10,16))

	local bestNameV = lbl({Size=UDim2.fromScale(0.6,0.5), Position=UDim2.fromScale(0.02,0.04), Text="None", TextColor3=P.gold, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left}, bestFrame)
	lbl({Size=UDim2.fromScale(0.35,0.4), Position=UDim2.fromScale(0.02,0.56), Text="All-time best", TextColor3=P.dim, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left}, bestFrame)
	local bestOddsV = lbl({Size=UDim2.fromScale(0.36,0.5), Position=UDim2.fromScale(0.62,0.04), Text="N/A", TextColor3=P.gold, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Right}, bestFrame)
	lbl({Size=UDim2.fromScale(0.36,0.4), Position=UDim2.fromScale(0.62,0.56), Text="odds", TextColor3=P.dim, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Right}, bestFrame)

	local dailyFrame = frame({Size=UDim2.fromScale(1,0.09), BackgroundColor3=P.panelB}, CP)
	corner(dailyFrame, 7)
	stroke(dailyFrame, P.diamond, 1)
	gradient(dailyFrame, Color3.fromRGB(8,15,20), Color3.fromRGB(10,10,16))

	lbl({Size=UDim2.fromScale(0.5,0.7), Position=UDim2.fromScale(0.02,0.15), Text="Today's Best Odds", TextColor3=P.dim, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left}, dailyFrame)
	local dailyOddsV = lbl({Size=UDim2.fromScale(0.46,0.7), Position=UDim2.fromScale(0.52,0.15), Text="N/A", TextColor3=P.diamond, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Right}, dailyFrame)

	lbl({Size=UDim2.fromScale(1,0.04), Text="COLLECTION INDEX", TextColor3=P.dimB, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left}, CP)

	local indexFrame = frame({Size=UDim2.fromScale(1,0.08), BackgroundColor3=P.panelB}, CP)
	corner(indexFrame, 7)
	gradient(indexFrame, Color3.fromRGB(10,12,22), Color3.fromRGB(9,11,20))

	local indexCols = {
		{lbl=nil, tag="Basic",    col=P.text},
		{lbl=nil, tag="Big",      col=P.green},
		{lbl=nil, tag="Shiny",    col=P.diamond},
		{lbl=nil, tag="Huge",     col=P.orange},
		{lbl=nil, tag="Inverted", col=P.void},
	}
	local totalW = 1/#indexCols
	for i, entry in ipairs(indexCols) do
		local x = (i-1)*totalW
		lbl({Size=UDim2.fromScale(totalW,0.45), Position=UDim2.fromScale(x,0.05), Text=entry.tag, TextColor3=P.dim, Font=Enum.Font.Gotham}, indexFrame)
		entry.lbl = lbl({Size=UDim2.fromScale(totalW,0.45), Position=UDim2.fromScale(x,0.52), Text="0", TextColor3=entry.col, Font=Enum.Font.GothamBold}, indexFrame)
	end

	local RP = makePanel(UDim2.fromScale(0.19, 0.78), UDim2.fromScale(0.806, 0.11), P.border)
	list(RP, nil, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top, 6)
	accentBar(RP, P.gold)

	lbl({Size=UDim2.fromScale(1,0.05), Text="COMBAT & ZONES", TextColor3=P.dimB, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left}, RP)

	local _, killsV   = makeRow(RP, ICONS.kills, "",       "0",  P.red)
	local _, zoneV    = makeRow(RP, ICONS.zone,  "Zone",   "0",  P.accent)
	local _, maxZoneV = makeRow(RP, ICONS.zone,  "Best",   "0",  P.diamond)
	local _, kpmV     = makeRow(RP, ICONS.kills, "k/min",  "0",  P.red)

	lbl({Size=UDim2.fromScale(1,0.05), Text="LIFETIME STATS", TextColor3=P.dimB, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left}, RP)

	local _, lifetimeRollsV  = makeRow(RP, "🎲",          "",        "0",  P.void)
	local _, lifetimeKillsV  = makeRow(RP, ICONS.kills,   "",        "0",  P.red)
	local _, totalCoinsV     = makeRow(RP, ICONS.coins,   "ever",    "0",  P.gold)
	local _, timePlayedV     = makeRow(RP, "⏱",           "",        "0h", P.dim)

	lbl({Size=UDim2.fromScale(1,0.05), Text="INVENTORY", TextColor3=P.dimB, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left}, RP)

	local _, totalSlimesV = makeRow(RP, "🐌", "Total",   "0", P.green)

	local statusPanel = panel({
		Size=UDim2.fromScale(0.3, 0.055),
		Position=UDim2.fromScale(0.35, 0.91),
		BackgroundColor3=P.panel,
		_sc=P.border,
		_r=20,
	}, root)
	gradient(statusPanel, Color3.fromRGB(9,11,20), Color3.fromRGB(12,15,28))

	local statusDot = frame({Size=UDim2.fromScale(0.02,0.35), Position=UDim2.fromScale(0.02,0.325), BackgroundColor3=P.accent}, statusPanel)
	corner(statusDot, 99)

	local statusLbl = lbl({
		Size=UDim2.fromScale(0.94,0.85),
		Position=UDim2.fromScale(0.05,0.075),
		Text="Initializing...",
		TextColor3=P.accent,
		Font=Enum.Font.GothamBold,
		TextXAlignment=Enum.TextXAlignment.Left,
	}, statusPanel)

	return {
		sg=sg,
		timerLbl=timerLbl,
		rebirthNumLbl=rebirthNumLbl,
		goopV=goopV, coinsV=coinsV, rollCurV=rollCurV,
		sRollsV=sRollsV, sKillsV=sKillsV, sCoinsV=sCoinsV,
		rpsV=rpsV, cpsV=cpsV, gpsV=gpsV,
		goldenV=goldenV, diamondV=diamondV, voidV=voidV,
		galaxyV=galaxyV, shinyV=shinyV, hugeV=hugeV,
		rebirthBar=rebirthBar, rebirthPctLbl=rebirthPctLbl,
		bestNameV=bestNameV, bestOddsV=bestOddsV,
		dailyOddsV=dailyOddsV,
		indexCols=indexCols,
		killsV=killsV, zoneV=zoneV, maxZoneV=maxZoneV, kpmV=kpmV,
		lifetimeRollsV=lifetimeRollsV, lifetimeKillsV=lifetimeKillsV,
		totalCoinsV=totalCoinsV, timePlayedV=timePlayedV,
		totalSlimesV=totalSlimesV,
		statusLbl=statusLbl, statusDot=statusDot,
	}
end

local function updateLabel(lbl, newText)
	if lbl.Text ~= newText then
		lbl.Text = newText
		pulse(lbl)
	end
end

local function updateAll(R)
	local now = os.clock()
	local elapsed = math.max(1, now - sessionStart)

	local rolls    = safeGet("stats","rolls")
	local kills    = safeGet("stats","kills")
	local coins    = safeGet("coins")
	local goop     = safeGet("goop")
	local rebirths = safeGet("rebirths")
	local zone     = safeGet("zone")
	local maxZone  = safeGet("furthestZone")
	local rollCur  = safeGet("rollCurrency")
	local timePlayed = safeGet("stats","timePlayed")
	local totalCoins = safeGet("stats","totalCoins")

	local sRolls = math.max(0, rolls - startRolls)
	local sKills = math.max(0, kills - startKills)
	local sCoins = math.max(0, coins - startCoins)

	local rps = getRate(windowRPS, lastRollMove, startRolls, rolls)
	local cps = getRate(windowCPS, lastCoinMove, startCoins, coins)
	local gps = getRate(windowGPS, lastGoopMove, startGoop, goop)
	local kpm = elapsed > 0 and (sKills / (elapsed/60)) or 0

	local rebirthReq = (2^rebirths) * 500
	local rebirthPct = math.min(1, goop / math.max(1, rebirthReq))

	local bestName, bestOdds = getBestRoll()
	local dailyOdds = getDailyBestOdds()
	local basic, big, shiny, huge, inverted = getIndexCounts()
	local totalSlimes = getTotalInventory()

	local m = math.floor(elapsed/60)
	local s = math.floor(elapsed%60)
	R.timerLbl.Text = string.format("%02d:%02d", m, s)

	updateLabel(R.rebirthNumLbl, fmt(rebirths))
	updateLabel(R.goopV,         fmt(goop))
	updateLabel(R.coinsV,        fmt(coins))
	updateLabel(R.rollCurV,      fmt(rollCur))
	updateLabel(R.sRollsV,       fmt(sRolls))
	updateLabel(R.sKillsV,       fmt(sKills))
	updateLabel(R.sCoinsV,       "+"..fmt(sCoins))
	updateLabel(R.rpsV,          string.format("%.2f/s", rps))
	updateLabel(R.cpsV,          fmt(cps).."/s")
	updateLabel(R.gpsV,          fmt(gps).."/s")

	local function progColor(v)
		local n = tonumber(v)
		if n == nil or n == 0 then return P.green end
		return P.dim
	end

	local gv = safeGet("specialRollProgression","golden","rollsUntilNext")
	local dv = safeGet("specialRollProgression","diamond","rollsUntilNext")
	local vv = safeGet("specialRollProgression","void","rollsUntilNext")
	local xv = safeGet("specialRollProgression","galaxy","rollsUntilNext")
	local sv = safeGet("specialRollProgression","shiny","rollsUntilNext")
	local hv = safeGet("specialRollProgression","huge","rollsUntilNext")

	local function setProg(lbl, raw, baseCol)
		local txt = getProgText(raw)
		if lbl.Text ~= txt then
			lbl.Text = txt
			lbl.TextColor3 = (tonumber(raw) == 0) and P.green or baseCol
			pulse(lbl)
		end
	end

	setProg(R.goldenV,  gv, P.gold)
	setProg(R.diamondV, dv, P.diamond)
	setProg(R.voidV,    vv, P.void)
	setProg(R.galaxyV,  xv, P.galaxy)
	setProg(R.shinyV,   sv, P.diamond)
	setProg(R.hugeV,    hv, P.orange)

	tw(R.rebirthBar, {Size=UDim2.fromScale(rebirthPct, 1)}, 0.4)
	R.rebirthPctLbl.Text = math.floor(rebirthPct*100).."%"

	updateLabel(R.bestNameV,  bestName)
	updateLabel(R.bestOddsV,  bestOdds)
	updateLabel(R.dailyOddsV, dailyOdds)

	local indexVals = {basic, big, shiny, huge, inverted}
	for i, entry in ipairs(R.indexCols) do
		updateLabel(entry.lbl, fmt(indexVals[i]))
	end

	updateLabel(R.killsV,        fmt(kills))
	updateLabel(R.zoneV,         fmt(zone))
	updateLabel(R.maxZoneV,      fmt(maxZone))
	updateLabel(R.kpmV,          string.format("%.1f", kpm))
	updateLabel(R.lifetimeRollsV, fmt(rolls))
	updateLabel(R.lifetimeKillsV, fmt(kills))
	updateLabel(R.totalCoinsV,   fmt(totalCoins))
	updateLabel(R.timePlayedV,   fmtTime(timePlayed))
	updateLabel(R.totalSlimesV,  fmt(totalSlimes))
end

local function runStatus(R, alive)
	local ROTATE = 4
	local WINDOW = 10
	local msgIdx = 0

	local lastCoins = safeGet("coins")
	local lastRolls = safeGet("stats","rolls")
	local lastKills = safeGet("stats","kills")
	local lastGoop  = safeGet("goop")
	local coinDelta, rollDelta, killDelta, goopDelta = 0, 0, 0, 0

	task.spawn(function()
		while alive() do
			task.wait(WINDOW)
			if not alive() then break end
			pcall(function()
				local c = safeGet("coins")
				local r = safeGet("stats","rolls")
				local k = safeGet("stats","kills")
				local g = safeGet("goop")
				coinDelta = math.max(0, c-lastCoins)
				rollDelta = math.max(0, r-lastRolls)
				killDelta = math.max(0, k-lastKills)
				goopDelta = math.max(0, g-lastGoop)
				lastCoins=c lastRolls=r lastKills=k lastGoop=g
			end)
		end
	end)

	local function setStatus(text, col)
		if not alive() then return end
		col = col or P.accent
		tw(R.statusLbl, {TextTransparency=1}, 0.1)
		tw(R.statusDot, {BackgroundColor3=col}, 0.2)
		task.delay(0.1, function()
			if not alive() then return end
			R.statusLbl.Text = text
			R.statusLbl.TextColor3 = col
			tw(R.statusLbl, {TextTransparency=0}, 0.18)
		end)
	end

	local reactive = {
		{check=function() return safeGet("specialRollProgression","galaxy","rollsUntilNext")==0 end,   text=function() return "Galaxy roll READY",   P.galaxy  end, col=P.galaxy},
		{check=function() return safeGet("specialRollProgression","void","rollsUntilNext")==0 end,     text=function() return "Void roll READY"     end, col=P.void},
		{check=function() return safeGet("specialRollProgression","diamond","rollsUntilNext")==0 end,  text=function() return "Diamond roll READY"  end, col=P.diamond},
		{check=function() return safeGet("specialRollProgression","golden","rollsUntilNext")==0 end,   text=function() return "Golden roll READY"   end, col=P.gold},
		{check=function()
			local r=safeGet("rebirths"); return safeGet("goop") >= (2^r)*500
		end, text=function() return "Rebirth requirement MET" end, col=P.green},
		{check=function()
			local r=safeGet("rebirths"); local g=safeGet("goop"); local req=(2^r)*500
			return g>=req*0.9 and g<req
		end, text=function()
			local r=safeGet("rebirths"); local g=safeGet("goop"); local req=(2^r)*500
			return "Rebirth soon  "..math.floor((g/req)*100).."%"
		end, col=P.green},
		{check=function() return killDelta >= 30 end,  text=function() return "Kill streak  +"..fmt(killDelta) end, col=P.red},
		{check=function() return coinDelta >= 1e6 end, text=function() return "Earning  "..fmt(math.floor(coinDelta/WINDOW)).."/sec" end, col=P.gold},
		{check=function() return goopDelta >= 2000 end,text=function() return "Goop flow  +"..fmt(math.floor(goopDelta/WINDOW)).."/sec" end, col=P.green},
		{check=function() return rollDelta >= 12 end,  text=function() return string.format("Rolling  %.1f/sec", rollDelta/WINDOW) end, col=P.void},
	}

	local idlePool = {
		function()
			local z=safeGet("zone"); local b=safeGet("furthestZone")
			return "Zone efficiency  "..(b>0 and math.floor((z/math.max(1,b))*100) or 100).."%", P.accent
		end,
		function()
			local n=safeGet("specialRollProgression","galaxy","rollsUntilNext")
			return n>0 and "Galaxy in  "..fmt(n).." rolls" or "Galaxy standby", P.galaxy
		end,
		function()
			local n=safeGet("specialRollProgression","void","rollsUntilNext")
			return n>0 and "Void in  "..fmt(n).." rolls" or "Void standby", P.void
		end,
		function()
			local n=safeGet("specialRollProgression","diamond","rollsUntilNext")
			return n>0 and "Diamond in  "..fmt(n).." rolls" or "Diamond standby", P.diamond
		end,
		function()
			local n=safeGet("specialRollProgression","golden","rollsUntilNext")
			return n>0 and "Golden in  "..fmt(n).." rolls" or "Golden standby", P.gold
		end,
		function()
			local r=safeGet("rebirths"); local g=safeGet("goop"); local q=(2^r)*500
			return "Rebirth progress  "..math.min(100,math.floor((g/math.max(1,q))*100)).."%", P.green
		end,
		function()
			return "Eliminations  "..fmt(safeGet("stats","kills")), P.red
		end,
		function()
			return "Lifetime rolls  "..fmt(safeGet("stats","rolls")), P.dim
		end,
		function()
			return "Balance  "..fmt(safeGet("coins")), P.gold
		end,
		function()
			return "Rebirth tier  "..fmt(safeGet("rebirths")), P.void
		end,
		function()
			return "Session  "..math.floor((os.clock()-sessionStart)/60).." min", P.dim
		end,
		function()
			local e=os.clock()-sessionStart; local k=safeGet("stats","kills")
			return string.format("Kills/hr  %s", fmt(e>0 and math.floor(k/(e/3600)) or 0)), P.red
		end,
		function()
			local e=os.clock()-sessionStart; local r=safeGet("stats","rolls")-startRolls
			return string.format("Session rps  %.2f", e>0 and (r/e) or 0), P.void
		end,
		function()
			local bestName, bestOdds = getBestRoll()
			return "Best ever  "..bestName.."  "..bestOdds, P.gold
		end,
		function()
			return "Today's best  "..getDailyBestOdds(), P.diamond
		end,
		function()
			local total = getTotalInventory()
			return "Slimes collected  "..fmt(total), P.green
		end,
		function()
			local basic,big,shiny,huge,inverted = getIndexCounts()
			return "Index  "..fmt(basic+big+shiny+huge+inverted).." unlocked", P.accent
		end,
		function()
			local vn=safeGet("specialRollProgression","void","rollsUntilNext")
			local dn=safeGet("specialRollProgression","diamond","rollsUntilNext")
			local gn=safeGet("specialRollProgression","golden","rollsUntilNext")
			local xn=safeGet("specialRollProgression","galaxy","rollsUntilNext")
			local closest=math.min(vn,dn,gn,xn)
			return closest==0 and "Special roll available" or "Next special  "..fmt(closest).." rolls", closest==0 and P.green or P.dim
		end,
	}

	task.spawn(function()
		while alive() do
			task.wait(ROTATE)
			if not alive() then break end
			pcall(function()
				for _, entry in ipairs(reactive) do
					if entry.check() then
						setStatus(entry.text(), entry.col)
						return
					end
				end
				msgIdx = (msgIdx % #idlePool) + 1
				local t, c = idlePool[msgIdx]()
				setStatus(t, c)
			end)
		end
	end)
end

getgenv().HUDv2Enabled = getgenv().HUDv2Enabled ~= false

local function init(playerGui)
	if not getgenv().HUDv2Enabled then return end
	local R = buildHUD(playerGui)
	local function alive() return getgenv().HUDv2Enabled == true and R.sg.Parent ~= nil end

	runStatus(R, alive)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		if not alive() then return end
		elapsed += dt
		if elapsed >= UPDATE_INTERVAL then
			elapsed = 0
			pcall(updateAll, R)
		end
	end)
end

init(LocalPlayer:WaitForChild("PlayerGui"))
