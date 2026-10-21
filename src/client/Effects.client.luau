--!strict
-- Feedback effects on your screen:
--  * a hit marker at your crosshair when the server confirms you hit someone
--    (red when it was a kill)
--  * a quick red flash around the edges when you take damage

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local HIT_COLOR = Color3.new(1, 1, 1)
local KILL_COLOR = Color3.fromRGB(255, 60, 60)

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local hitConfirmed = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("HitConfirmed") :: RemoteEvent

local screen = Instance.new("ScreenGui")
screen.Name = "Effects"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true -- so the hit marker lines up with the mouse
screen.Parent = player:WaitForChild("PlayerGui")

-- Hit marker: an "X" that pops up where you're aiming.
local hitMarker = Instance.new("TextLabel")
hitMarker.Size = UDim2.fromOffset(40, 40)
hitMarker.AnchorPoint = Vector2.new(0.5, 0.5)
hitMarker.BackgroundTransparency = 1
hitMarker.Font = Enum.Font.GothamBold
hitMarker.TextSize = 32
hitMarker.Text = "X"
hitMarker.TextTransparency = 1
hitMarker.Parent = screen

hitConfirmed.OnClientEvent:Connect(function(killed: boolean)
	hitMarker.Position = UDim2.fromOffset(mouse.X, mouse.Y)
	hitMarker.TextColor3 = if killed then KILL_COLOR else HIT_COLOR
	hitMarker.TextTransparency = 0
	TweenService:Create(hitMarker, TweenInfo.new(if killed then 0.5 else 0.2), { TextTransparency = 1 }):Play()
end)

-- Damage flash: the whole screen tints red for a moment.
local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = screen

local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local lastHealth = humanoid.Health
	humanoid.HealthChanged:Connect(function(health)
		if health < lastHealth then
			flash.BackgroundTransparency = 0.6
			TweenService:Create(flash, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		end
		lastHealth = health
	end)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
