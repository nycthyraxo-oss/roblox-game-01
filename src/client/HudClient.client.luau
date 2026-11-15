--!strict
-- Rainbow Rush: the whole interface, built in code. Lobby screen, target
-- banner, timer bar, score, leaderboard, elimination notice and results
-- screen. The client only displays what the server sends; it never decides
-- a point, a phase or a winner.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local roundRemote = remotes:WaitForChild("RoundUpdate") :: RemoteEvent
local scoreRemote = remotes:WaitForChild("ScoreUpdate") :: RemoteEvent
local resultsRemote = remotes:WaitForChild("ResultsEvent") :: RemoteEvent

local COLOR_BY_NAME: { [string]: Color3 } = {}
for _, colorInfo in Config.COLORS do
	COLOR_BY_NAME[colorInfo.Name] = colorInfo.Color
end

local DARK = Color3.fromRGB(28, 28, 48)
local PANEL = Color3.fromRGB(40, 40, 68)
local WHITE = Color3.fromRGB(255, 255, 255)
local GOLD = Color3.fromRGB(255, 215, 0)

local gui = Instance.new("ScreenGui")
gui.Name = "RainbowRushGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function roundCorners(instance: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function makeLabel(
	name: string,
	parent: Instance,
	text: string,
	size: number,
	color: Color3,
	font: Enum.Font
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = size
	label.TextColor3 = color
	label.Font = font
	label.TextWrapped = true
	label.Parent = parent
	return label
end

-- ---------- Lobby screen ----------
local lobbyPanel = Instance.new("Frame")
lobbyPanel.Name = "LobbyPanel"
lobbyPanel.AnchorPoint = Vector2.new(0.5, 0.5)
lobbyPanel.Position = UDim2.fromScale(0.5, 0.5)
lobbyPanel.Size = UDim2.fromOffset(520, 360)
lobbyPanel.BackgroundColor3 = DARK
lobbyPanel.BackgroundTransparency = 0.08
lobbyPanel.BorderSizePixel = 0
lobbyPanel.Parent = gui
roundCorners(lobbyPanel, 16)
local lobbyStroke = Instance.new("UIStroke")
lobbyStroke.Color = GOLD
lobbyStroke.Thickness = 3
lobbyStroke.Parent = lobbyPanel

local lobbyTitle = makeLabel("Title", lobbyPanel, "RAINBOW RUSH", 52, GOLD, Enum.Font.FredokaOne)
lobbyTitle.Size = UDim2.new(1, -32, 0, 64)
lobbyTitle.Position = UDim2.new(0, 16, 0, 16)

local lobbyHow = makeLabel(
	"HowTo",
	lobbyPanel,
	"1. A color is called - run to a pad of that color.\n2. Wrong pads sink into the lava. Don't fall in!\n3. Grab golden stars for bonus points. Most points wins!",
	20,
	WHITE,
	Enum.Font.SourceSansBold
)
lobbyHow.Size = UDim2.new(1, -48, 0, 120)
lobbyHow.Position = UDim2.new(0, 24, 0, 96)
lobbyHow.TextXAlignment = Enum.TextXAlignment.Left
lobbyHow.TextYAlignment = Enum.TextYAlignment.Top

local lobbyCountdown = makeLabel("Countdown", lobbyPanel, "Next round starts in 12s", 26, GOLD, Enum.Font.FredokaOne)
lobbyCountdown.Size = UDim2.new(1, -32, 0, 40)
lobbyCountdown.Position = UDim2.new(0, 16, 0, 232)

local lobbyPlayers = makeLabel("Players", lobbyPanel, "Players in game: 1", 18, WHITE, Enum.Font.SourceSans)
lobbyPlayers.Size = UDim2.new(1, -32, 0, 28)
lobbyPlayers.Position = UDim2.new(0, 16, 0, 284)

-- ---------- Playing HUD ----------
local hudFrame = Instance.new("Frame")
hudFrame.Name = "Hud"
hudFrame.Size = UDim2.fromScale(1, 1)
hudFrame.BackgroundTransparency = 1
hudFrame.Visible = false
hudFrame.Parent = gui

-- Target color banner, top center.
local banner = Instance.new("Frame")
banner.Name = "TargetBanner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 16)
banner.Size = UDim2.fromOffset(420, 86)
banner.BackgroundColor3 = PANEL
banner.BackgroundTransparency = 0.1
banner.BorderSizePixel = 0
banner.Parent = hudFrame
roundCorners(banner, 12)

local bannerSwatch = Instance.new("Frame")
bannerSwatch.Name = "Swatch"
bannerSwatch.AnchorPoint = Vector2.new(0, 0.5)
bannerSwatch.Position = UDim2.new(0, 16, 0.5, 0)
bannerSwatch.Size = UDim2.fromOffset(54, 54)
bannerSwatch.BackgroundColor3 = WHITE
bannerSwatch.BorderSizePixel = 0
bannerSwatch.Parent = banner
roundCorners(bannerSwatch, 10)

local bannerTitle = makeLabel("BannerTitle", banner, "STAND ON", 20, WHITE, Enum.Font.SourceSansBold)
bannerTitle.Position = UDim2.new(0, 86, 0, 8)
bannerTitle.Size = UDim2.new(1, -100, 0, 24)
bannerTitle.TextXAlignment = Enum.TextXAlignment.Left

local bannerColor = makeLabel("BannerColor", banner, "?", 30, GOLD, Enum.Font.FredokaOne)
bannerColor.Position = UDim2.new(0, 86, 0, 34)
bannerColor.Size = UDim2.new(1, -100, 0, 40)
bannerColor.TextXAlignment = Enum.TextXAlignment.Left

-- Timer bar under the banner.
local timerBack = Instance.new("Frame")
timerBack.Name = "TimerBack"
timerBack.AnchorPoint = Vector2.new(0.5, 0)
timerBack.Position = UDim2.new(0.5, 0, 0, 110)
timerBack.Size = UDim2.fromOffset(420, 14)
timerBack.BackgroundColor3 = Color3.fromRGB(20, 20, 34)
timerBack.BorderSizePixel = 0
timerBack.Parent = hudFrame
roundCorners(timerBack, 7)

local timerFill = Instance.new("Frame")
timerFill.Name = "TimerFill"
timerFill.Size = UDim2.fromScale(1, 1)
timerFill.BackgroundColor3 = GOLD
timerFill.BorderSizePixel = 0
timerFill.Parent = timerBack
roundCorners(timerFill, 7)

local timerText = makeLabel("TimerText", hudFrame, "", 18, WHITE, Enum.Font.SourceSansBold)
timerText.AnchorPoint = Vector2.new(0.5, 0)
timerText.Position = UDim2.new(0.5, 0, 0, 128)
timerText.Size = UDim2.fromOffset(200, 24)

-- Score, top left.
local scoreBox = Instance.new("Frame")
scoreBox.Name = "ScoreBox"
scoreBox.Position = UDim2.new(0, 16, 0, 16)
scoreBox.Size = UDim2.fromOffset(190, 64)
scoreBox.BackgroundColor3 = PANEL
scoreBox.BackgroundTransparency = 0.1
scoreBox.BorderSizePixel = 0
scoreBox.Parent = hudFrame
roundCorners(scoreBox, 12)

local scoreTitle = makeLabel("ScoreTitle", scoreBox, "YOUR POINTS", 15, WHITE, Enum.Font.SourceSansBold)
scoreTitle.Position = UDim2.new(0, 12, 0, 6)
scoreTitle.Size = UDim2.new(1, -24, 0, 20)
scoreTitle.TextXAlignment = Enum.TextXAlignment.Left

local scoreValue = makeLabel("ScoreValue", scoreBox, "0", 30, GOLD, Enum.Font.FredokaOne)
scoreValue.Position = UDim2.new(0, 12, 0, 26)
scoreValue.Size = UDim2.new(1, -24, 0, 34)
scoreValue.TextXAlignment = Enum.TextXAlignment.Left

-- Leaderboard, top right.
local boardBox = Instance.new("Frame")
boardBox.Name = "Leaderboard"
boardBox.AnchorPoint = Vector2.new(1, 0)
boardBox.Position = UDim2.new(1, -16, 0, 16)
boardBox.Size = UDim2.fromOffset(220, 190)
boardBox.BackgroundColor3 = PANEL
boardBox.BackgroundTransparency = 0.1
boardBox.BorderSizePixel = 0
boardBox.Parent = hudFrame
roundCorners(boardBox, 12)

local boardTitle = makeLabel("BoardTitle", boardBox, "TOP PLAYERS", 17, GOLD, Enum.Font.FredokaOne)
boardTitle.Position = UDim2.new(0, 12, 0, 8)
boardTitle.Size = UDim2.new(1, -24, 0, 24)
boardTitle.TextXAlignment = Enum.TextXAlignment.Left

local boardList = Instance.new("Frame")
boardList.Name = "BoardList"
boardList.Position = UDim2.new(0, 12, 0, 38)
boardList.Size = UDim2.new(1, -24, 1, -48)
boardList.BackgroundTransparency = 1
boardList.Parent = boardBox

-- Floating "+points" toast, center screen.
local toast = makeLabel("Toast", hudFrame, "", 34, GOLD, Enum.Font.FredokaOne)
toast.AnchorPoint = Vector2.new(0.5, 0.5)
toast.Position = UDim2.fromScale(0.5, 0.38)
toast.Size = UDim2.fromOffset(320, 44)
toast.Visible = false

-- ---------- Elimination notice ----------
local eliminatedPanel = Instance.new("Frame")
eliminatedPanel.Name = "EliminatedPanel"
eliminatedPanel.AnchorPoint = Vector2.new(0.5, 0.5)
eliminatedPanel.Position = UDim2.fromScale(0.5, 0.62)
eliminatedPanel.Size = UDim2.fromOffset(440, 90)
eliminatedPanel.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
eliminatedPanel.BackgroundTransparency = 0.1
eliminatedPanel.BorderSizePixel = 0
eliminatedPanel.Visible = false
eliminatedPanel.Parent = gui
roundCorners(eliminatedPanel, 12)

local eliminatedText = makeLabel(
	"EliminatedText",
	eliminatedPanel,
	"You fell in the lava!\nWait for the next round...",
	22,
	WHITE,
	Enum.Font.SourceSansBold
)
eliminatedText.Size = UDim2.fromScale(1, 1)

-- ---------- Results screen ----------
local resultsPanel = Instance.new("Frame")
resultsPanel.Name = "ResultsPanel"
resultsPanel.AnchorPoint = Vector2.new(0.5, 0.5)
resultsPanel.Position = UDim2.fromScale(0.5, 0.5)
resultsPanel.Size = UDim2.fromOffset(520, 340)
resultsPanel.BackgroundColor3 = DARK
resultsPanel.BackgroundTransparency = 0.08
resultsPanel.BorderSizePixel = 0
resultsPanel.Visible = false
resultsPanel.Parent = gui
roundCorners(resultsPanel, 16)
local resultsStroke = Instance.new("UIStroke")
resultsStroke.Color = GOLD
resultsStroke.Thickness = 3
resultsStroke.Parent = resultsPanel

local resultsTitle = makeLabel("ResultsTitle", resultsPanel, "", 40, GOLD, Enum.Font.FredokaOne)
resultsTitle.Size = UDim2.new(1, -32, 0, 56)
resultsTitle.Position = UDim2.new(0, 16, 0, 20)

local resultsList = makeLabel("ResultsList", resultsPanel, "", 24, WHITE, Enum.Font.SourceSansBold)
resultsList.Size = UDim2.new(1, -48, 0, 150)
resultsList.Position = UDim2.new(0, 24, 0, 96)
resultsList.TextYAlignment = Enum.TextYAlignment.Top

local resultsHint = makeLabel("ResultsHint", resultsPanel, "Next round starts soon...", 18, WHITE, Enum.Font.SourceSans)
resultsHint.Size = UDim2.new(1, -32, 0, 28)
resultsHint.Position = UDim2.new(0, 16, 0, 272)

-- ---------- State ----------
local myScore = 0
local myBest = 0
local deadline = 0
local totalTime = 1
local currentPhase = "lobby"

local function showToast(text: string)
	toast.Text = text
	toast.Visible = true
	task.delay(1.5, function()
		toast.Visible = false
	end)
end

local function rebuildLeaderboard(scores: { [string]: number })
	for _, child in boardList:GetChildren() do
		child:Destroy()
	end
	type Row = { Name: string, Points: number }
	local rows: { Row } = {}
	for name, points in scores do
		table.insert(rows, { Name = name, Points = points })
	end
	table.sort(rows, function(a: Row, b: Row): boolean
		return a.Points > b.Points
	end)
	for i = 1, math.min(5, #rows) do
		local row = rows[i]
		local label = makeLabel(
			"Row" .. tostring(i),
			boardList,
			tostring(i) .. ". " .. row.Name .. "  -  " .. tostring(row.Points),
			18,
			WHITE,
			Enum.Font.SourceSansBold
		)
		label.Position = UDim2.new(0, 0, 0, (i - 1) * 26)
		label.Size = UDim2.new(1, 0, 0, 24)
		label.TextXAlignment = Enum.TextXAlignment.Left
	end
end

-- The timer bar drains in real time between the server's phase updates.
RunService.Heartbeat:Connect(function()
	if not hudFrame.Visible or deadline <= 0 then
		return
	end
	local remaining = deadline - os.clock()
	if remaining < 0 then
		remaining = 0
	end
	local fraction = math.clamp(remaining / totalTime, 0, 1)
	timerFill.Size = UDim2.fromScale(fraction, 1)
	if currentPhase == "announce" then
		timerText.Text = "Get ready... " .. tostring(math.ceil(remaining)) .. "s"
	elseif currentPhase == "move" then
		timerText.Text = "Move! " .. tostring(math.ceil(remaining)) .. "s left"
	elseif currentPhase == "resolve" then
		timerText.Text = "Pads sinking..."
	elseif currentPhase == "lobby" then
		lobbyCountdown.Text = "Next round starts in " .. tostring(math.ceil(remaining)) .. "s"
	end
end)

roundRemote.OnClientEvent:Connect(function(phase: string, targetColor: string, secondsLeft: number)
	currentPhase = phase
	if phase == "lobby" then
		lobbyPanel.Visible = true
		hudFrame.Visible = false
		resultsPanel.Visible = false
		eliminatedPanel.Visible = false
		deadline = os.clock() + secondsLeft
		totalTime = secondsLeft
		lobbyCountdown.Text = "Next round starts in " .. tostring(secondsLeft) .. "s"
	elseif phase == "start" then
		lobbyPanel.Visible = false
		hudFrame.Visible = true
		resultsPanel.Visible = false
		eliminatedPanel.Visible = false
		bannerTitle.Text = "ROUND START!"
		bannerColor.Text = "Good luck!"
		bannerSwatch.BackgroundColor3 = GOLD
	elseif phase == "announce" then
		bannerTitle.Text = "NEXT COLOR:"
		bannerColor.Text = targetColor
		bannerSwatch.BackgroundColor3 = COLOR_BY_NAME[targetColor] or WHITE
		deadline = os.clock() + secondsLeft
		totalTime = secondsLeft
	elseif phase == "move" then
		bannerTitle.Text = "STAND ON"
		bannerColor.Text = targetColor
		bannerSwatch.BackgroundColor3 = COLOR_BY_NAME[targetColor] or WHITE
		deadline = os.clock() + secondsLeft
		totalTime = secondsLeft
	elseif phase == "resolve" then
		bannerTitle.Text = "STAY ON"
		bannerColor.Text = targetColor
		bannerSwatch.BackgroundColor3 = COLOR_BY_NAME[targetColor] or WHITE
		deadline = os.clock() + secondsLeft
		totalTime = secondsLeft
	elseif phase == "eliminated" then
		eliminatedPanel.Visible = true
	end
end)

scoreRemote.OnClientEvent:Connect(function(scores: { [string]: number })
	local count = 0
	for _ in scores do
		count += 1
	end
	lobbyPlayers.Text = "Players in game: " .. tostring(count)
	local mine = scores[player.Name] or 0
	local gained = mine - myScore
	myScore = mine
	if mine > myBest then
		myBest = mine
	end
	scoreValue.Text = tostring(mine)
	if gained == Config.STAR_POINTS then
		showToast("+5  ★ Star!")
	elseif gained == Config.SURVIVAL_POINTS then
		showToast("+10  Survived!")
	elseif gained > 0 then
		showToast("+" .. tostring(gained) .. " points!")
	end
	rebuildLeaderboard(scores)
end)

resultsRemote.OnClientEvent:Connect(function(
	winnerName: string,
	top: { { Name: string, Points: number } }
)
	hudFrame.Visible = false
	lobbyPanel.Visible = false
	eliminatedPanel.Visible = false
	resultsPanel.Visible = true
	if winnerName == player.Name then
		resultsTitle.Text = "YOU WIN!"
	else
		resultsTitle.Text = winnerName .. " WINS!"
	end
	local lines: { string } = {}
	local medals = { "1st", "2nd", "3rd" }
	for i, entry in top do
		table.insert(lines, medals[i] .. "  " .. entry.Name .. "  (+" .. tostring(entry.Points) .. " this round)")
	end
	if #lines == 0 then
		table.insert(lines, "No points scored this round.")
	end
	resultsList.Text = table.concat(lines, "\n")
end)
