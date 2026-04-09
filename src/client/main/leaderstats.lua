--[[
	PlayerListStats
	@Musual
	
	Optimized Version
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local FormatNumber = require(ReplicatedStorage.shared.numberformat)
local DataConfig = require(ReplicatedStorage.config.DataConfig)

local StatsToShow = {}

-- Sửa DataConfig thành DataConfig.DataList
for StatName, Data in DataConfig.DataList do
	if Data.Leaderstats and Data.Leaderstats[1] then 
		table.insert(StatsToShow, {
			Name = StatName,
			Order = Data.Leaderstats[2] or 0
		})
	end
end

-- Sắp xếp stat theo thứ tự ưu tiên cấu hình trong DataConfig
table.sort(StatsToShow, function(a, b)
	return a.Order < b.Order
end)

--------------------------------------------------------------------------------

local function FormatValue(Value: any): string
	return typeof(Value) == "number" and FormatNumber(Value, "Suffix") or tostring(Value)
end

local function OnPlayerAdded(Player: Player)
	local pData = PlayerData:WaitForChild(Player.Name, 5)
	if not pData then return end

	local Stats = pData:WaitForChild("Stats", 5)
	if not Stats then return end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	-- Bảng chứa các connection để dọn dẹp sau này
	local connections = {}

	for _, StatInfo in ipairs(StatsToShow) do
		local StatName = StatInfo.Name

		-- Dùng task.spawn để không làm nghẽn vòng lặp nếu WaitForChild bị delay
		task.spawn(function()
			local Stat = Stats:WaitForChild(StatName, 5)
			if Stat then
				local ValueObject = Instance.new("StringValue")
				ValueObject.Name = StatName
				ValueObject.Value = FormatValue(Stat.Value)
				ValueObject.Parent = leaderstats

				local conn = Stat.Changed:Connect(function()
					-- Kiểm tra object còn tồn tại không trước khi update (phòng hờ)
					if ValueObject and ValueObject.Parent then
						ValueObject.Value = FormatValue(Stat.Value)
					end
				end)
				table.insert(connections, conn)
			end
		end)
	end

	leaderstats.Parent = Player

	-- Cleanup memory (ngắt event) ngay khi player rời game
	local removingConn
	removingConn = Players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer == Player then
			for _, conn in ipairs(connections) do
				conn:Disconnect()
			end
			removingConn:Disconnect()
		end
	end)
end

Players.PlayerAdded:Connect(OnPlayerAdded)

-- Dùng task.spawn để xử lý ngay cho các player đã có trong server
for _, Player in ipairs(Players:GetPlayers()) do
	task.spawn(OnPlayerAdded, Player)
end