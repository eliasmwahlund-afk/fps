--!strict
-- On-screen game info: your weapon and level, who's in the lead, a kill feed
-- in the top-right corner and a winner banner at the end of each round.
-- This is display only; the server decides kills and wins.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponLadder = require(ReplicatedStorage.Shared.WeaponLadder)

local KILL_FEED_LINES = 5
local KILL_FEED_SECONDS = 5
local HIGHLIGHT = Color3.fromRGB(255, 220, 120) -- kill feed lines about you

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local killFeedEvent = remotes:WaitForChild("KillFeed") :: RemoteEvent
local roundEndedEvent = remotes:WaitForChild("RoundEnded") :: RemoteEvent
local roundStartedEvent = remotes:WaitForChild("RoundStarted") :: RemoteEvent

local screen = Instance.new("ScreenGui")
screen.Name = "Hud"
screen.ResetOnSpawn = false -- keep the kill feed when you respawn
screen.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(parent: Instance, size: UDim2, position: UDim2, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.4
	label.BorderSizePixel = 0
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.Text = ""
	label.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label
	return label
end

-- Top middle: your weapon, and who's leading.
local weaponLabel = makeLabel(screen, UDim2.fromOffset(320, 36), UDim2.new(0.5, -160, 0, 8), 20)
local leaderLabel = makeLabel(screen, UDim2.fromOffset(320, 26), UDim2.new(0.5, -160, 0, 48), 16)

-- Top right: kill feed, newest on top.
local feed = Instance.new("Frame")
feed.Size = UDim2.fromOffset(320, 200)
feed.Position = UDim2.new(1, -330, 0, 8)
feed.BackgroundTransparency = 1
feed.Parent = screen

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 4)
layout.Parent = feed

-- Middle of the screen: winner banner, hidden until someone wins.
local banner = makeLabel(screen, UDim2.fromOffset(520, 100), UDim2.new(0.5, -260, 0.3, 0), 34)
banner.Visible = false

local function getLevel(p: Player): number?
	local leaderstats = p:FindFirstChild("leaderstats")
	local level = leaderstats and leaderstats:FindFirstChild("Level")
	if level and level:IsA("IntValue") then
		return level.Value
	end
	return nil
end

local function refresh()
	local myLevel = getLevel(player)
	if myLevel then
		weaponLabel.Text = `{WeaponLadder[myLevel] or "?"}  ·  Level {myLevel}/{#WeaponLadder}`
	end

	local leader: Player? = nil
	local leaderLevel = 0
	for _, other in Players:GetPlayers() do
		local level = getLevel(other)
		if level and level > leaderLevel then
			leader = other
			leaderLevel = level
		end
	end
	if leader == player then
		leaderLabel.Text = "You're in the lead!"
	elseif leader then
		leaderLabel.Text = `Leader: {leader.Name} (Level {leaderLevel})`
	else
		leaderLabel.Text = ""
	end
end

local feedCount = 0
killFeedEvent.OnClientEvent:Connect(function(killerName: string, victimName: string, weaponName: string)
	feedCount += 1
	local line = makeLabel(feed, UDim2.new(1, 0, 0, 28), UDim2.new(), 16)
	line.LayoutOrder = -feedCount -- newer lines sort above older ones
	line.Text = `{killerName}  [{weaponName}]  {victimName}`
	if killerName == player.Name or victimName == player.Name then
		line.TextColor3 = HIGHLIGHT
	end

	-- Keep only the newest few lines.
	local lines = {}
	for _, child in feed:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(lines, child)
		end
	end
	table.sort(lines, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = KILL_FEED_LINES + 1, #lines do
		lines[i]:Destroy()
	end

	task.delay(KILL_FEED_SECONDS, function()
		line:Destroy()
	end)
end)

local roundNumber = 0
roundEndedEvent.OnClientEvent:Connect(function(winnerName: string, secondsUntilNext: number)
	roundNumber += 1
	local thisRound = roundNumber
	local title = if winnerName == player.Name then "You win!" else `{winnerName} wins!`
	banner.Visible = true
	for secondsLeft = secondsUntilNext, 1, -1 do
		if roundNumber ~= thisRound or not banner.Visible then
			return
		end
		banner.Text = `{title}\nNext round in {secondsLeft}`
		task.wait(1)
	end
end)

roundStartedEvent.OnClientEvent:Connect(function()
	banner.Visible = false
end)

while true do
	refresh()
	task.wait(0.25)
end
