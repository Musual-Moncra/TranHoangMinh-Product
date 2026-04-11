--[[
	@RebirthConfig - Musual
	
	Cấu hình hệ thống rebirth.
	
	- BaseCost: Chi phí cơ sở cho lần rebirth đầu tiên.
	- CostMultiplier: Hệ số nhân chi phí cho mỗi lần rebirth tiếp theo.
	  Công thức: Cost = BaseCost * (CostMultiplier ^ currentRebirth)
	- MaxRebirth: Số lần rebirth tối đa.
	- Buffs: Bảng buff cho mỗi lần rebirth.
	  Mỗi buff có format: {Value, Method}
	    - Method "Add": Cộng thêm Value vào stat.
	    - Method "Multiple": Nhân stat với Value.
]]

local RebirthConfig = {}

RebirthConfig.BaseCost = 1000
RebirthConfig.CostMultiplier = 2.5
RebirthConfig.MaxRebirth = 50

-- Tính chi phí rebirth dựa trên rebirth hiện tại
function RebirthConfig.GetCost(currentRebirth: number): number
	return math.floor(RebirthConfig.BaseCost * (RebirthConfig.CostMultiplier ^ currentRebirth))
end

-- Buff cho mỗi lần rebirth (cộng dồn)
-- Key = rebirth level, Value = bảng buff
-- Nếu rebirth level không có trong bảng, sẽ dùng buff mặc định (DefaultBuff)
RebirthConfig.DefaultBuff = {
	SpeedBuff = {2, "Add"},       -- +2 WalkSpeed mỗi lần rebirth
	JumpBoost = {0.05, "Multiple"} -- +5% JumpPower mỗi lần rebirth
}

-- Override buff đặc biệt cho các mốc rebirth cụ thể
RebirthConfig.Buffs = {
	[5] = {
		SpeedBuff = {5, "Add"},       -- +5 WalkSpeed bonus tại mốc 5
		JumpBoost = {0.1, "Multiple"} -- +10% JumpPower bonus tại mốc 5
	},
	[10] = {
		SpeedBuff = {8, "Add"},
		JumpBoost = {0.15, "Multiple"}
	},
	[25] = {
		SpeedBuff = {15, "Add"},
		JumpBoost = {0.25, "Multiple"}
	},
	[50] = {
		SpeedBuff = {25, "Add"},
		JumpBoost = {0.5, "Multiple"}
	}
}

-- Tính tổng buff tích lũy cho một rebirth level
function RebirthConfig.GetTotalBuffs(rebirthLevel: number): {SpeedBuff: number, JumpBoost: number}
	local totalSpeed = 0
	local totalJump = 0

	for i = 1, rebirthLevel do
		local buff = RebirthConfig.Buffs[i] or RebirthConfig.DefaultBuff

		-- Speed (Add)
		if buff.SpeedBuff then
			totalSpeed += buff.SpeedBuff[1]
		end

		-- JumpPower (Multiple) - tích lũy dưới dạng tổng phần trăm
		if buff.JumpBoost then
			totalJump += buff.JumpBoost[1]
		end
	end

	return {
		SpeedBuff = totalSpeed,
		JumpBoost = totalJump
	}
end

-- Stat mặc định của nhân vật (trước rebirth)
RebirthConfig.BaseStats = {
	WalkSpeed = 16,
	JumpPower = 50
}

return RebirthConfig