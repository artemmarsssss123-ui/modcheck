-- Fox's player join warning script
-- Put this in your executor's autoexec folder.
print("hello")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Names to watch for (case-insensitive)
local WATCH_NAMES = {
	["lui20102"] = true,
	["skylerosen140"] = true,
	["wtskae"] = true,
	["void6rs"] = true,
	["reavvvvvvvvvvvvvvvvv"] = true,
	["ryrycanhoop"] = true,
	["wwallets"] = true,
	["growagardencameron4"] = true,
	["al3x6z"] = true
}

-- Sound played when a warning pops up
local function playAlertSound()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://9125230493" -- notification "ding"
	sound.Volume = 1
	sound.Parent = game:GetService("SoundService")
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 3)
end

-- Create warning GUI (a popup that stays until manually closed)
local function createWarningGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "FoxWarningGui"
	gui.Parent = game:GetService("CoreGui") -- safer than PlayerGui if executor strips it
	gui.ResetOnSpawn = false
	gui.Enabled = false

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	frame.BorderSizePixel = 0
	frame.Size = UDim2.new(0, 320, 0, 100)
	frame.Position = UDim2.new(0.5, -160, 0.1, 0) -- top center
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 60, 60)
	stroke.Thickness = 2
	stroke.Parent = frame

	-- Accent bar on the left
	local accent = Instance.new("Frame")
	accent.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	accent.BorderSizePixel = 0
	accent.Size = UDim2.new(0, 6, 1, 0)
	accent.Position = UDim2.new(0, 0, 0, 0)
	accent.Parent = frame
	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 10)
	accentCorner.Parent = accent

	-- Close (X) button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	closeButton.Size = UDim2.new(0, 24, 0, 24)
	closeButton.Position = UDim2.new(1, -32, 0, 8)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 14
	closeButton.AutoButtonColor = true
	closeButton.Parent = frame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		gui.Enabled = false
	end)

	local label = Instance.new("TextLabel")
	label.Name = "TitleLabel"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -50, 0, 40)
	label.Position = UDim2.new(0, 18, 0, 10)
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 90, 90)
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = "⚠️ Suspicious Player Joined"
	label.Parent = frame

	local textName = Instance.new("TextLabel")
	textName.Name = "PlayerNameLabel"
	textName.BackgroundTransparency = 1
	textName.Size = UDim2.new(1, -36, 0, 30)
	textName.Position = UDim2.new(0, 18, 0, 55)
	textName.Font = Enum.Font.GothamMedium
	textName.TextColor3 = Color3.fromRGB(230, 230, 235)
	textName.TextScaled = true
	textName.TextXAlignment = Enum.TextXAlignment.Left
	textName.Text = ""
	textName.Parent = frame

	return gui
end

local warningGui = createWarningGui()

-- Function to display warning for a player name
local function warnPlayer(playerName)
	local frame = warningGui:FindFirstChild("Frame")
	if frame then
		local nameLabel = frame:FindFirstChild("PlayerNameLabel")
		if nameLabel then
			nameLabel.Text = playerName .. " has entered the server"
		end
	end

	warningGui.Enabled = true
	playAlertSound()

	-- No auto-hide anymore — stays until the X button is clicked

	warn("[Fox Warning] Detected player:", playerName)
end

-- Check all current players (in case script injected after they joined)
for _, player in ipairs(Players:GetPlayers()) do
	if player ~= LocalPlayer and WATCH_NAMES[player.Name:lower()] then
		warnPlayer(player.Name)
	end
end

-- Listen for new players joining
Players.PlayerAdded:Connect(function(player)
	if player ~= LocalPlayer and WATCH_NAMES[player.Name:lower()] then
		warnPlayer(player.Name)
	end
end)
