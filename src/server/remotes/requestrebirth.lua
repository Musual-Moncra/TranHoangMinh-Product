--[[
	@remotehandler - request rebirth
	@Musual

	Server-side xử lý request rebirth từ client.
	- Kiểm tra điều kiện (Cash đủ, chưa max rebirth)
	- Trừ Cash, tăng Rebirth
	- Reset Cash về 0
	- Áp dụng buff vào nhân vật
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Dependencies
local remote = ReplicatedStorage.events.remotes.request_rebirth
local givestats = require(ServerStorage.data.givestats)
local removestats = require(ServerStorage.data.removestats)
local RebirthConfig = require(ReplicatedStorage.config.RebirthConfig)

-- Cooldown tracking (chống spam)
local Cooldowns = {}
local COOLDOWN_TIME = 2 -- seconds

-- Áp dụng buff rebirth vào Humanoid
local function ApplyRebirthBuffs(player: Player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	if not humanoid then return end

	-- Lấy rebirth level hiện tại
	local PlayerData = ReplicatedStorage:FindFirstChild("PlayerData")
	if not PlayerData then return end

	local pData = PlayerData:FindFirstChild(player.Name)
	if not pData then return end

	local Stats = pData:FindFirstChild("Stats")
	if not Stats then return end

	local RebirthStat = Stats:FindFirstChild("Rebirth")
	if not RebirthStat then return end

	local rebirthLevel = RebirthStat.Value

	-- Tính tổng buff
	local buffs = RebirthConfig.GetTotalBuffs(rebirthLevel)

	-- Áp dụng buff
	humanoid.WalkSpeed = RebirthConfig.BaseStats.WalkSpeed + buffs.SpeedBuff
	humanoid.JumpPower = RebirthConfig.BaseStats.JumpPower * (1 + buffs.JumpBoost)
end

-- Xử lý khi nhân vật spawn (áp dụng lại buff)
local function OnCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	-- Delay nhỏ để đảm bảo humanoid đã sẵn sàng
	task.wait(0.5)
	ApplyRebirthBuffs(player)
end

-- Kết nối CharacterAdded cho tất cả player
local function SetupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		OnCharacterAdded(player, character)
	end)

	-- Áp dụng ngay nếu nhân vật đã tồn tại
	if player.Character then
		task.spawn(function()
			OnCharacterAdded(player, player.Character)
		end)
	end
end

-- Setup cho player hiện tại và mới
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(SetupPlayer, player)
end
Players.PlayerAdded:Connect(SetupPlayer)

-- Dọn dẹp cooldown khi player rời
Players.PlayerRemoving:Connect(function(player)
	Cooldowns[player.UserId] = nil
end)

-- Xử lý Remote
remote.OnServerEvent:Connect(function(player)
	-- Chống spam
	local now = tick()
	if Cooldowns[player.UserId] and (now - Cooldowns[player.UserId]) < COOLDOWN_TIME then
		return
	end
	Cooldowns[player.UserId] = now

	-- Lấy data
	local PlayerData = ReplicatedStorage:FindFirstChild("PlayerData")
	if not PlayerData then return end

	local pData = PlayerData:FindFirstChild(player.Name)
	if not pData then return end

	local Stats = pData:FindFirstChild("Stats")
	if not Stats then return end

	local CashStat = Stats:FindFirstChild("Cash") :: IntValue
	local RebirthStat = Stats:FindFirstChild("Rebirth") :: IntValue

	if not CashStat or not RebirthStat then return end

	-- Kiểm tra max rebirth
	if RebirthStat.Value >= RebirthConfig.MaxRebirth then
		return
	end

	-- Tính chi phí
	local cost = RebirthConfig.GetCost(RebirthStat.Value)

	-- Kiểm tra đủ Cash
	if CashStat.Value < cost then
		return
	end

	-- === Thực hiện Rebirth ===

	-- 1. Trừ Cash (trừ hết, reset về 0)
	CashStat.Value = 0

	-- 2. Tăng Rebirth
	RebirthStat.Value += 1

	-- 3. Áp dụng buff vào nhân vật hiện tại
	ApplyRebirthBuffs(player)

	-- 4. Thông báo thành công cho client
	remote:FireClient(player, true, RebirthStat.Value)
end)