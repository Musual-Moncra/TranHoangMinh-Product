local PhysicsService = game:GetService("PhysicsService")

local function Init()
	-- Create collision groups if they don't exist
	pcall(function()
		PhysicsService:RegisterCollisionGroup("Players")
		PhysicsService:RegisterCollisionGroup("SpawnedItems")
	end)

	-- Disable collision between items and players
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable("Players", "SpawnedItems", false)
		
		-- Optionally disable collision between items themselves
		PhysicsService:CollisionGroupSetCollidable("SpawnedItems", "SpawnedItems", false)
	end)
end

Init()
