local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local starterGui = player:WaitForChild("PlayerGui")

-- SETTINGS (customize)
local TITLE_TEXT = "Steal a Brainrot"
local SUBTEXT = "Loading game..."
local BACKDROP_COLOR = Color3.fromRGB(18, 18, 24)
local ACCENT_COLOR = Color3.fromRGB(199, 34, 255) -- magenta-ish
local PROGRESS_BG = Color3.fromRGB(45,45,50)
local PROGRESS_HEIGHT = 18
local SIMULATED_SPEED = 0.8 -- how fast simulated load progresses (higher is faster)

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StealABrainrot_LoadingGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = starterGui

local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.AnchorPoint = Vector2.new(0.5,0.5)
backdrop.Size = UDim2.new(0.8, 0, 0.6, 0)
backdrop.Position = UDim2.new(0.5,0,0.5,0)
backdrop.BackgroundColor3 = BACKDROP_COLOR
backdrop.BorderSizePixel = 0
backdrop.Parent = screenGui
backdrop.ClipsDescendants = true

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -80, 0, 70)
title.Position = UDim2.new(0, 40, 0, 24)
title.BackgroundTransparency = 1
title.Text = TITLE_TEXT
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 36
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = backdrop

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(1, -80, 0, 24)
subtitle.Position = UDim2.new(0, 40, 0, 64)
subtitle.BackgroundTransparency = 1
subtitle.Text = SUBTEXT
subtitle.TextColor3 = Color3.fromRGB(200,200,200)
subtitle.Font = Enum.Font.Gotham
title.TextSize = 16
subtitle.TextSize = 16
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = backdrop

-- Decorative accent bar
local accent = Instance.new("Frame")
accent.Name = "Accent"
accent.AnchorPoint = Vector2.new(0,0)
accent.Position = UDim2.new(0, 0, 0, 0)
accent.Size = UDim2.new(0.08, 0, 1, 0)
accent.BackgroundColor3 = ACCENT_COLOR
accent.BorderSizePixel = 0
accent.Parent = backdrop

-- Progress bar background
local progressBg = Instance.new("Frame")
progressBg.Name = "ProgressBg"
progressBg.AnchorPoint = Vector2.new(0.5, 0)
progressBg.Size = UDim2.new(0.85, 0, 0, PROGRESS_HEIGHT + 8)
progressBg.Position = UDim2.new(0.5, 0, 1, -80)
progressBg.BackgroundColor3 = PROGRESS_BG
progressBg.BorderSizePixel = 0
progressBg.Parent = backdrop

local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.Position = UDim2.new(0, 0, 0, 0)
progressBar.BackgroundColor3 = ACCENT_COLOR
progressBar.BorderSizePixel = 0
progressBar.Parent = progressBg

local percentLabel = Instance.new("TextLabel")
percentLabel.Name = "Percent"
percentLabel.AnchorPoint = Vector2.new(0.5, 0.5)
percentLabel.Size = UDim2.new(0, 120, 0, 24)
percentLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
percentLabel.BackgroundTransparency = 1
percentLabel.Text = "0%"
percentLabel.TextColor3 = Color3.new(1,1,1)
percentLabel.Font = Enum.Font.GothamSemibold
percentLabel.TextSize = 14
percentLabel.Parent = progressBg

-- Spinner (rotating circle)
local spinner = Instance.new("ImageLabel")
spinner.Name = "Spinner"
spinner.Size = UDim2.new(0, 40, 0, 40)
spinner.AnchorPoint = Vector2.new(1, 0)
spinner.Position = UDim2.new(1, -24, 0, 24)
spinner.BackgroundTransparency = 1
-- A commonly used free circular asset (Roblox library) — replace if you want a custom image
spinner.Image = "rbxassetid://11329340118" -- small ring; if this 404s, replace with your own
spinner.Parent = backdrop

-- Optional: subtle blur effect (works only if the client supports it)
local blur = Instance.new("BlurEffect")
blur.Parent = game:GetService("Lighting")
blur.Size = 0

-- Animation helpers
local function tweenObject(obj, props, time, style, direction)
	local info = TweenInfo.new(time or 0.5, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

-- Rotate spinner
spawn(function()
	local angle = 0
	while screenGui and screenGui.Parent do
		angle = angle + 360 * RunService.Heartbeat:Wait() * 0.6
		spinner.Rotation = angle % 360
	end
end)

-- Loading logic: try to actually preload common asset containers, otherwise simulate
local function tryPreload()
	local toPreload = {}
	-- Add common service containers that may contain assets (images, sounds, models)
	local function addIfExists(container)
		if container and #container:GetChildren() > 0 then
			for _, v in ipairs(container:GetChildren()) do
				table.insert(toPreload, v)
			end
		end
	end

	addIfExists(game:GetService("ReplicatedStorage"))
	addIfExists(game:GetService("StarterPack"))
	addIfExists(game:GetService("Workspace"))
	addIfExists(game:GetService("StarterGui"))

	if #toPreload > 0 then
		local ok, err = pcall(function()
			ContentProvider:PreloadAsync(toPreload, function(assetId, status)
				-- progress callback is intentionally left empty (we'll poll ContentProvider:GetAssetStatus)
			end)
		end)
		if not ok then
			return false, err
		end
		return true
	end
	return false
end

-- Progress updater
local progress = 0
local loadingDone = false

local function updateProgress(target)
	tweenObject(progressBar, {Size = UDim2.new(target/100, 0, 1, 0)}, 0.35)
	percentLabel.Text = string.format("%d%%", math.floor(target))
end

-- Start: fade-in GUI
backdrop.BackgroundTransparency = 1
title.TextTransparency = 1
subtitle.TextTransparency = 1
progressBg.BackgroundTransparency = 1
accent.BackgroundTransparency = 1
spinner.ImageTransparency = 1

-- Fade in quickly
tweenObject(backdrop, {BackgroundTransparency = 0}, 0.45)
tweenObject(title, {TextTransparency = 0}, 0.5)
tweenObject(subtitle, {TextTransparency = 0}, 0.55)
tweenObject(progressBg, {BackgroundTransparency = 0}, 0.6)
tweenObject(accent, {BackgroundTransparency = 0}, 0.6)
spawn(function()
	local spinTween = TweenService:Create(spinner, TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {ImageTransparency = 0})
	spinTween:Play()
end)local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local starterGui = player:WaitForChild("PlayerGui")

-- SETTINGS (customize)
local TITLE_TEXT = "Steal a Brainrot"
local SUBTEXT = "Loading game..."
local BACKDROP_COLOR = Color3.fromRGB(18, 18, 24)
local ACCENT_COLOR = Color3.fromRGB(199, 34, 255) -- magenta-ish
local PROGRESS_BG = Color3.fromRGB(45,45,50)
local PROGRESS_HEIGHT = 18
local SIMULATED_SPEED = 0.8 -- how fast simulated load progresses (higher is faster)

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StealABrainrot_LoadingGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = starterGui

local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.AnchorPoint = Vector2.new(0.5,0.5)
backdrop.Size = UDim2.new(0.8, 0, 0.6, 0)
backdrop.Position = UDim2.new(0.5,0,0.5,0)
backdrop.BackgroundColor3 = BACKDROP_COLOR
backdrop.BorderSizePixel = 0
backdrop.Parent = screenGui
backdrop.ClipsDescendants = true

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -80, 0, 70)
title.Position = UDim2.new(0, 40, 0, 24)
title.BackgroundTransparency = 1
title.Text = TITLE_TEXT
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 36
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = backdrop

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(1, -80, 0, 24)
subtitle.Position = UDim2.new(0, 40, 0, 64)
subtitle.BackgroundTransparency = 1
subtitle.Text = SUBTEXT
subtitle.TextColor3 = Color3.fromRGB(200,200,200)
subtitle.Font = Enum.Font.Gotham
title.TextSize = 16
subtitle.TextSize = 16
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = backdrop

-- Decorative accent bar
local accent = Instance.new("Frame")
accent.Name = "Accent"
accent.AnchorPoint = Vector2.new(0,0)
accent.Position = UDim2.new(0, 0, 0, 0)
accent.Size = UDim2.new(0.08, 0, 1, 0)
accent.BackgroundColor3 = ACCENT_COLOR
accent.BorderSizePixel = 0
accent.Parent = backdrop

-- Progress bar background
local progressBg = Instance.new("Frame")
progressBg.Name = "ProgressBg"
progressBg.AnchorPoint = Vector2.new(0.5, 0)
progressBg.Size = UDim2.new(0.85, 0, 0, PROGRESS_HEIGHT + 8)
progressBg.Position = UDim2.new(0.5, 0, 1, -80)
progressBg.BackgroundColor3 = PROGRESS_BG
progressBg.BorderSizePixel = 0
progressBg.Parent = backdrop

local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.Position = UDim2.new(0, 0, 0, 0)
progressBar.BackgroundColor3 = ACCENT_COLOR
progressBar.BorderSizePixel = 0
progressBar.Parent = progressBg

local percentLabel = Instance.new("TextLabel")
percentLabel.Name = "Percent"
percentLabel.AnchorPoint = Vector2.new(0.5, 0.5)
percentLabel.Size = UDim2.new(0, 120, 0, 24)
percentLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
percentLabel.BackgroundTransparency = 1
percentLabel.Text = "0%"
percentLabel.TextColor3 = Color3.new(1,1,1)
percentLabel.Font = Enum.Font.GothamSemibold
percentLabel.TextSize = 14
percentLabel.Parent = progressBg

-- Spinner (rotating circle)
local spinner = Instance.new("ImageLabel")
spinner.Name = "Spinner"
spinner.Size = UDim2.new(0, 40, 0, 40)
spinner.AnchorPoint = Vector2.new(1, 0)
spinner.Position = UDim2.new(1, -24, 0, 24)
spinner.BackgroundTransparency = 1
-- A commonly used free circular asset (Roblox library) — replace if you want a custom image
spinner.Image = "rbxassetid://11329340118" -- small ring; if this 404s, replace with your own
spinner.Parent = backdrop

-- Optional: subtle blur effect (works only if the client supports it)
local blur = Instance.new("BlurEffect")
blur.Parent = game:GetService("Lighting")
blur.Size = 0

-- Animation helpers
local function tweenObject(obj, props, time, style, direction)
	local info = TweenInfo.new(time or 0.5, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

-- Rotate spinner
spawn(function()
	local angle = 0
	while screenGui and screenGui.Parent do
		angle = angle + 360 * RunService.Heartbeat:Wait() * 0.6
		spinner.Rotation = angle % 360
	end
end)

-- Loading logic: try to actually preload common asset containers, otherwise simulate
local function tryPreload()
	local toPreload = {}
	-- Add common service containers that may contain assets (images, sounds, models)
	local function addIfExists(container)
		if container and #container:GetChildren() > 0 then
			for _, v in ipairs(container:GetChildren()) do
				table.insert(toPreload, v)
			end
		end
	end

	addIfExists(game:GetService("ReplicatedStorage"))
	addIfExists(game:GetService("StarterPack"))
	addIfExists(game:GetService("Workspace"))
	addIfExists(game:GetService("StarterGui"))

	if #toPreload > 0 then
		local ok, err = pcall(function()
			ContentProvider:PreloadAsync(toPreload, function(assetId, status)
				-- progress callback is intentionally left empty (we'll poll ContentProvider:GetAssetStatus)
			end)
		end)
		if not ok then
			return false, err
		end
		return true
	end
	return false
end

-- Progress updater
local progress = 0
local loadingDone = false

local function updateProgress(target)
	tweenObject(progressBar, {Size = UDim2.new(target/100, 0, 1, 0)}, 0.35)
	percentLabel.Text = string.format("%d%%", math.floor(target))
end

-- Start: fade-in GUI
backdrop.BackgroundTransparency = 1
title.TextTransparency = 1
subtitle.TextTransparency = 1
progressBg.BackgroundTransparency = 1
accent.BackgroundTransparency = 1
spinner.ImageTransparency = 1

-- Fade in quickly
tweenObject(backdrop, {BackgroundTransparency = 0}, 0.45)
tweenObject(title, {TextTransparency = 0}, 0.5)
tweenObject(subtitle, {TextTransparency = 0}, 0.55)
tweenObject(progressBg, {BackgroundTransparency = 0}, 0.6)
tweenObject(accent, {BackgroundTransparency = 0}, 0.6)
spawn(function()
	local spinTween = TweenService:Create(spinner, TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {ImageTransparency = 0})
	spinTween:Play()
end)
