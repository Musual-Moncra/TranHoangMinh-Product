local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local Folder = Instance.new("Folder")
Folder.Name = "Characters"
Folder.Parent = workspace

local function applyCollisionGroup(character: Model)
	local PlayersCollisionGroupId = PhysicsService:GetCollisionGroupId("Players")
	
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroupId = PlayersCollisionGroupId
		end
	end
	
	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroupId = PlayersCollisionGroupId
		end
	end)
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		char.Parent = Folder
		applyCollisionGroup(char)
	end)
end)
