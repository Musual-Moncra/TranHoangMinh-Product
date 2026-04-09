local Folder = Instance.new("Folder")
Folder.Name = "Characters"; Folder.Parent = workspace

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		char.Parent =  Folder
	end)
end)
