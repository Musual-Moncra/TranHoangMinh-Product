-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage") 

-- Dependiences
local numberformat = require(ReplicatedStorage.shared.numberformat)
local items = ReplicatedStorage:WaitForChild("items") -- Items Storage (Model, Part, Tool, ..)
local itemsconfig = require(ReplicatedStorage.config.ItemsConfig) 

local ItemsSpawner = {}
ItemsSpawner.__index = ItemsSpawner

local takeitem = ReplicatedStorage.events.bindable:WaitForChild("takeitem") :: BindableEvent

local ActiveSpawners = {}

-- Helper
local function TakeItem(player: Player,itemname: string)
	takeitem:Fire(player ,itemname)
end

-- Handle
function ItemsSpawner.new(Spawner: Model)
	local self = setmetatable({}, ItemsSpawner)
	self.Spawner = Spawner
	self.Connections = {}
	self.SpawnedItems = {}
	self.SpawnCount = 0
	
	-- Configure
	self.ItemName = Spawner:GetAttribute("ItemName") or "Noob"
	self.SpawnRate = Spawner:GetAttribute("SpawnRate") or 5
	self.MaxItems = Spawner:GetAttribute("MaxItems") or 5
	self.SpawnRadius = Spawner:GetAttribute("SpawnRadius") or 10
	
	table.insert(ActiveSpawners, self)
	
	self:Connect()
	return self
end

function ItemsSpawner:SpawnItem()
	if self.SpawnCount >= self.MaxItems then return end
	
	local itemTemplate = items:FindFirstChild(self.ItemName)
	if not itemTemplate then 
		warn("Item template not found: " .. tostring(self.ItemName))
		return 
	end
	
	local newItem = itemTemplate:Clone()
	
	-- Determine spawn position around radius
	local spawnerCFrame = self.Spawner:GetPivot()
	local randomX = (math.random() - 0.5) * 2 * self.SpawnRadius
	local randomZ = (math.random() - 0.5) * 2 * self.SpawnRadius
	local spawnPosition = spawnerCFrame.Position + Vector3.new(randomX, 0, randomZ)
	
	newItem:PivotTo(CFrame.new(spawnPosition))
	newItem.Parent = workspace
	
	self.SpawnCount += 1
	table.insert(self.SpawnedItems, newItem)
	
	-- Pickup Setup
	local basePart = newItem:IsA("BasePart") and newItem or newItem.PrimaryPart
	if not basePart then
		basePart = newItem:FindFirstChildWhichIsA("BasePart", true)
	end
	
	if basePart then
		local debounce = false
		local function OnTouch(hit)
			if debounce then return end
			local character = hit:FindFirstAncestorWhichIsA("Model")
			if character then
				local player = game.Players:GetPlayerFromCharacter(character)
				if player then
					debounce = true
					TakeItem(player, self.ItemName)
					
					-- Remove item from list
					for i, v in ipairs(self.SpawnedItems) do
						if v == newItem then
							table.remove(self.SpawnedItems, i)
							break
						end
					end
					
					newItem:Destroy()
					self.SpawnCount -= 1
				end
			end
		end
		
		local connection = basePart.Touched:Connect(OnTouch)
		table.insert(self.Connections, connection)
	end
end

function ItemsSpawner:Connect()
	self.SpawnTask = task.spawn(function()
		while true do
			task.wait(self.SpawnRate)
			if self.Spawner and self.Spawner.Parent then
				self:SpawnItem()
			else
				break
			end
		end
	end)
end

function ItemsSpawner:Disconnected()
	if self.SpawnTask then
		task.cancel(self.SpawnTask)
		self.SpawnTask = nil
	end
	
	for _, connection in ipairs(self.Connections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end
	self.Connections = {}
	
	for _, item in ipairs(self.SpawnedItems) do
		if item and item.Parent then
			item:Destroy()
		end
	end
	self.SpawnedItems = {}
	self.SpawnCount = 0
end

-- Connections
for _, spawnerObj in ipairs(CollectionService:GetTagged("ItemsSpawner")) do
	ItemsSpawner.new(spawnerObj)
end

CollectionService:GetInstanceAddedSignal("ItemsSpawner"):Connect(function(spawnerObj)
	ItemsSpawner.new(spawnerObj)
end)

CollectionService:GetInstanceRemovedSignal("ItemsSpawner"):Connect(function(spawnerObj)
	for i = #ActiveSpawners, 1, -1 do
		local spawnerData = ActiveSpawners[i]
		if spawnerData.Spawner == spawnerObj then
			spawnerData:Disconnected()
			table.remove(ActiveSpawners, i)
			break
		end
	end
end)

return ItemsSpawner
