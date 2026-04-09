-- Remove Stats
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

return function(Player: Player, StatName: string, Value: any)
	local StatObject = PlayerData:FindFirstChild(Player.Name):FindFirstChild("Stats"):FindFirstChild(StatName) :: ValueBase

	if StatObject:IsA("NumberValue") or StatObject:IsA("IntValue") then
		StatObject.Value -= tonumber(Value)
	else
		StatObject.Value = Value
	end
end