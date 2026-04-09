--[[
	@MainGui - @musual
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Dependiences
local Player = Players.LocalPlayer
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")
local pData = PlayerData:WaitForChild(Player.Name)
local Stats = pData:WaitForChild("Stats")

-- Helper
local Tween = require(ReplicatedStorage.shared.tween)
local FormatNumber = require(ReplicatedStorage.shared.numberformat)

-- GUI
local PlayerGui = Player.PlayerGui
local Gui = PlayerGui:WaitForChild("Main")
local LeftFrame = Gui:FindFirstChild("Left")
local PlayerCardFrame = LeftFrame:FindFirstChild("PlayerCard")
local CashText = LeftFrame:FindFirstChild("Cash")
local RebirthText = LeftFrame:FindFirstChild("Rebirth")
local JumpPower = PlayerCardFrame:FindFirstChild("JumpPower")
local Speed = PlayerCardFrame:FindFirstChild("Speed")
local UsernameText = PlayerCardFrame:FindFirstChild("Username")
local HPCanvas = PlayerCardFrame:FindFirstChild("HP"):FindFirstChild("Fill")
local Fill = HPCanvas:FindFirstChild("UIGradient")
local PlayerIcon = PlayerCardFrame:FindFirstChild("PlayerIcon"):FindFirstChild("Icon")
local UIScale = Gui:FindFirstChild("UIScale")

local RightFrame = Gui:FindFirstChild("Right")
local ButtonFrame = RightFrame:FindFirstChild("ButtonFrame")

-- Helper func
local function UpdateValue()
	local RebirthObj = Stats:FindFirstChild("Rebirth") :: IntValue
	local CashObj = Stats:FindFirstChild("Cash") :: IntValue
	
	-- Setting UP 
	CashText.Text = "Cash: " .. FormatNumber(CashObj.Value, "Suffix")
	RebirthText.Text = "Rebirth: " .. FormatNumber(RebirthObj.Value, "Suffix")
end

local function UpdateHP()
	-- FIX 1: Changed 'and' to 'or'. 
	-- If you use 'and', the script will pause indefinitely if the character already exists.
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Humanoid = Character:FindFirstChild("Humanoid") :: Humanoid

	if not Humanoid then return end -- Safety check

	-- FIX 2: Swapped the division order.
	-- Health / MaxHealth gives you a percentage (0 to 1). 
	-- MaxHealth / Health will result in numbers greater than 1 (or math.huge if Health is 0).
	local healthPercentage = Humanoid.Health / Humanoid.MaxHealth

	Tween:Play(Fill, {0.4}, {Offset = Vector2.new(0, healthPercentage)})
	Speed.Text = "Speed: ".. Humanoid.WalkSpeed
	JumpPower.Text =  "JumpPower: " .. Humanoid.JumpPower
end

local function Default()
	UsernameText.Text = "@"..Player.Name.. "(" .. Player.DisplayName .. ")"
	PlayerIcon.Image = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)
end

for _, Object : GuiButton in ButtonFrame:GetChildren() do
	if Object:IsA("GuiButton") then
		Object.MouseEnter:Connect(function()
			Tween:Play(Object:FindFirstChild("UIScale"), {0.2}, {Scale = 1.1})
		end)
		Object.MouseLeave:Connect(function()
			Tween:Play(Object:FindFirstChild("UIScale"), {0.2}, {Scale = 1})
		end)
		Object.MouseButton1Up:Connect(function()
			Tween:Play(Object:FindFirstChild("UIScale"), {0.2}, {Scale = 1})
		end)
		Object.MouseButton1Down:Connect(function()
			Tween:Play(Object:FindFirstChild("UIScale"), {0.2}, {Scale = 0.9})
		end)
		Object.MouseLeave:Connect(function()
			Tween:Play(Object:FindFirstChild("UIScale"), {0.2}, {Scale = 1.1})
		end)
	end
end

-- Connection

-- 1. Listen for Stat changes
Stats:WaitForChild("Cash").Changed:Connect(UpdateValue)
Stats:WaitForChild("Rebirth").Changed:Connect(UpdateValue)

-- 2. Handle Character/Humanoid connections securely
local function OnCharacterAdded(character)
	local Humanoid = character:WaitForChild("Humanoid")

	-- Update HP initially when the character loads
	UpdateHP()

	-- Listen for Health, Speed, and JumpPower changes
	Humanoid.HealthChanged:Connect(UpdateHP)
	Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(UpdateHP)
	Humanoid:GetPropertyChangedSignal("JumpPower"):Connect(UpdateHP)
end

Player.CharacterAdded:Connect(OnCharacterAdded)

-- 3. Initialize everything on first load
if Player.Character then
	OnCharacterAdded(Player.Character)
end

if UserInputService.TouchEnabled then
	UIScale.Scale = 0.6
end

Default()
UpdateValue()

