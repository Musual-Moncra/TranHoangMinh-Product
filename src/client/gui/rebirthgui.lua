--[[
	@RebirthGUI - Musual
	
	Client-side xử lý giao diện rebirth.
	- Hiển thị chi phí rebirth, buff tiếp theo
	- Nút xác nhận rebirth
	- Nút thoát
	- Hiệu ứng tween mượt mà
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local Gui = PlayerGui:WaitForChild("Rebirth")
local MainFrame = Gui:FindFirstChild("MainFrame")
local ExitButton = MainFrame:FindFirstChild("ExitButton")
local Content = MainFrame:FindFirstChild("Content")
local RebirthButton = Content:FindFirstChild("Confirm")
local ButtonScale = RebirthButton:FindFirstChild("UIScale")
local RequestRebirth = ReplicatedStorage.events.remotes:WaitForChild("request_rebirth") :: RemoteEvent

-- Helper
local Tween = require(ReplicatedStorage.shared.tween)
local FormatNumber = require(ReplicatedStorage.shared.numberformat)
local RebirthConfig = require(ReplicatedStorage.config.RebirthConfig)

-- Player Data
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")
local pData = PlayerData:WaitForChild(Player.Name)
local Stats = pData:WaitForChild("Stats")
local CashStat = Stats:WaitForChild("Cash") :: IntValue
local RebirthStat = Stats:WaitForChild("Rebirth") :: IntValue

-- UI Elements (tìm hoặc tạo text labels trong Content)
local CostLabel = Content:FindFirstChild("CostLabel")
local BuffLabel = Content:FindFirstChild("BuffLabel")
local StatusLabel = Content:FindFirstChild("StatusLabel")

-- State
local isProcessing = false
local isOpen = false

-- === Helper Functions ===

local function UpdateUI()
	local currentRebirth = RebirthStat.Value
	local currentCash = CashStat.Value

	-- Kiểm tra max rebirth
	if currentRebirth >= RebirthConfig.MaxRebirth then
		if CostLabel then
			CostLabel.Text = "🔥 MAX REBIRTH!"
		end
		if BuffLabel then
			BuffLabel.Text = "Đã đạt giới hạn rebirth"
		end
		RebirthButton.Visible = false
		return
	end

	-- Chi phí rebirth tiếp theo
	local cost = RebirthConfig.GetCost(currentRebirth)
	local canAfford = currentCash >= cost

	if CostLabel then
		CostLabel.Text = "💰 Chi phí: " .. FormatNumber(cost, "Suffix")
	end

	-- Buff tiếp theo
	local nextBuffs = RebirthConfig.GetTotalBuffs(currentRebirth + 1)
	local currentBuffs = RebirthConfig.GetTotalBuffs(currentRebirth)

	if BuffLabel then
		local speedGain = nextBuffs.SpeedBuff - currentBuffs.SpeedBuff
		local jumpGain = math.floor((nextBuffs.JumpBoost - currentBuffs.JumpBoost) * 100)
		BuffLabel.Text = "⚡ +" .. speedGain .. " Speed | +" .. jumpGain .. "% Jump"
	end

	-- Trạng thái nút
	if canAfford then
		RebirthButton.Visible = true
		if StatusLabel then
			StatusLabel.Text = "✅ Sẵn sàng rebirth!"
			StatusLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
		end
	else
		RebirthButton.Visible = true
		if StatusLabel then
			StatusLabel.Text = "❌ Không đủ Cash (" .. FormatNumber(currentCash, "Suffix") .. "/" .. FormatNumber(cost, "Suffix") .. ")"
			StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
		end
	end
end

-- === Toggle UI ===

function _G.ToggleRebirthUI()
	isOpen = not isOpen

	if isOpen then
		UpdateUI()
		MainFrame.Visible = true
		Tween:Play(MainFrame, {0.3, "Back", "Out"}, {GroupTransparency = 0})
	else
		local tween = Tween:Play(MainFrame, {0.25, "Back", "In"}, {GroupTransparency = 1})
		if tween then
			tween.Completed:Connect(function()
				MainFrame.Visible = false
			end)
		end
	end
end

-- === Button Animations ===

-- Confirm Button
RebirthButton.MouseEnter:Connect(function()
	Tween:Play(ButtonScale, {0.2}, {Scale = 1.1})
end)

RebirthButton.MouseLeave:Connect(function()
	Tween:Play(ButtonScale, {0.2}, {Scale = 1})
end)

RebirthButton.MouseButton1Down:Connect(function()
	Tween:Play(ButtonScale, {0.15}, {Scale = 0.9})
end)

RebirthButton.MouseButton1Up:Connect(function()
	Tween:Play(ButtonScale, {0.15}, {Scale = 1})
end)

-- Exit Button
local ExitScale = ExitButton:FindFirstChild("UIScale")
if ExitScale then
	ExitButton.MouseEnter:Connect(function()
		Tween:Play(ExitScale, {0.2}, {Scale = 1.1})
	end)
	ExitButton.MouseLeave:Connect(function()
		Tween:Play(ExitScale, {0.2}, {Scale = 1})
	end)
	ExitButton.MouseButton1Down:Connect(function()
		Tween:Play(ExitScale, {0.15}, {Scale = 0.9})
	end)
	ExitButton.MouseButton1Up:Connect(function()
		Tween:Play(ExitScale, {0.15}, {Scale = 1})
	end)
end

-- === Button Actions ===

-- Nút thoát
ExitButton.MouseButton1Click:Connect(function()
	if isOpen then
		_G.ToggleRebirthUI()
	end
end)

-- Nút xác nhận rebirth
RebirthButton.MouseButton1Click:Connect(function()
	if isProcessing then return end

	local currentRebirth = RebirthStat.Value
	local cost = RebirthConfig.GetCost(currentRebirth)

	-- Kiểm tra client-side
	if CashStat.Value < cost then
		if StatusLabel then
			StatusLabel.Text = "❌ Không đủ Cash!"
			StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
		end
		return
	end

	if currentRebirth >= RebirthConfig.MaxRebirth then
		return
	end

	-- Gửi request
	isProcessing = true

	if StatusLabel then
		StatusLabel.Text = "⏳ Đang xử lý..."
		StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 127)
	end

	-- Hiệu ứng nút
	Tween:Play(ButtonScale, {0.2}, {Scale = 0.85})

	RequestRebirth:FireServer()
end)

-- === Server Response ===

RequestRebirth.OnClientEvent:Connect(function(success, newRebirthLevel)
	isProcessing = false
	Tween:Play(ButtonScale, {0.2}, {Scale = 1})

	if success then
		-- Hiệu ứng thành công
		if StatusLabel then
			StatusLabel.Text = "🎉 Rebirth " .. newRebirthLevel .. " thành công!"
			StatusLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
		end

		-- Flash hiệu ứng
		Tween:Play(MainFrame, {0.1}, {GroupTransparency = 0.5})
		task.wait(0.1)
		Tween:Play(MainFrame, {0.2}, {GroupTransparency = 0})

		-- Cập nhật UI sau một chút delay
		task.wait(0.5)
		UpdateUI()
	else
		if StatusLabel then
			StatusLabel.Text = "❌ Rebirth thất bại!"
			StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
		end
	end
end)

-- === Listeners ===

-- Cập nhật UI khi giá trị thay đổi
CashStat.Changed:Connect(function()
	if isOpen then
		UpdateUI()
	end
end)

RebirthStat.Changed:Connect(function()
	if isOpen then
		UpdateUI()
	end
end)

-- Khởi tạo - ẩn UI ban đầu
MainFrame.Visible = false
if MainFrame:IsA("CanvasGroup") then
	MainFrame.GroupTransparency = 1
end