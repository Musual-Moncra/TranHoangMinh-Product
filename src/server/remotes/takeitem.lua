-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Remote
local Remote = ReplicatedStorage.events.bindable:WaitForChild("takeitem") :: BindableEvent

-- Helper
local givestats = require(ServerStorage.data.givestats)
local removestats = require(ServerStorage.data.removestats)
local ItemsConfig = require(ReplicatedStorage.config.ItemsConfig)

-- Handle
Remote.Event:Connect(function(plr, itemname)
	local itemData = ItemsConfig.Items[itemname]
	
	if itemData then
		-- Collect prize
		if itemData.Price then
			givestats(plr, "Cash", itemData.Price)
		end
	else
		warn("Item Info Not Found:", itemname)
	end
end)