--[[
	@SetupPlayer - Musual
	
	Client-side setup cho player khi vào game.
	- Áp dụng Rebirth buff vào nhân vật mỗi khi spawn
	- Lắng nghe thay đổi Rebirth stat để cập nhật buff
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies
local Player = Players.LocalPlayer
local RebirthConfig = require(ReplicatedStorage.config.RebirthConfig)

-- Player Data
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")
local pData = PlayerData:WaitForChild(Player.Name)
local Stats = pData:WaitForChild("Stats")
local RebirthStat = Stats:WaitForChild("Rebirth") :: IntValue

-- === Áp dụng buff Rebirth ===
local function ApplyRebirthBuffs()
	local character = Player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	if not humanoid then return end

	local rebirthLevel = RebirthStat.Value
	local buffs = RebirthConfig.GetTotalBuffs(rebirthLevel)

	-- Áp dụng buff
	humanoid.WalkSpeed = RebirthConfig.BaseStats.WalkSpeed + buffs.SpeedBuff
	humanoid.JumpPower = RebirthConfig.BaseStats.JumpPower * (1 + buffs.JumpBoost)
end

-- === Xử lý khi nhân vật spawn ===
local function OnCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	-- Delay nhỏ để đảm bảo humanoid sẵn sàng
	task.wait(0.5)
	ApplyRebirthBuffs()
end

-- Kết nối
Player.CharacterAdded:Connect(OnCharacterAdded)

-- Xử lý nếu nhân vật đã tồn tại
if Player.Character then
	task.spawn(function()
		OnCharacterAdded(Player.Character)
	end)
end

-- Lắng nghe thay đổi Rebirth stat (sau khi rebirth thành công)
RebirthStat.Changed:Connect(function()
	ApplyRebirthBuffs()
end)
