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

local function GetRandomItemName(weightTable)
	local totalWeight = 0
	for _, chance in pairs(weightTable) do
		totalWeight += chance
	end
	
	if totalWeight == 0 then return nil end
	
	local randomNum = math.random() * totalWeight
	local currentWeight = 0
	
	for itemName, chance in pairs(weightTable) do
		currentWeight += chance
		if randomNum <= currentWeight then
			return itemName
		end
	end
	
	return next(weightTable)
end

-- Handle
local SpawnersFolder = workspace:FindFirstChild("Spawners")
if not SpawnersFolder then
	SpawnersFolder = Instance.new("Folder")
	SpawnersFolder.Name = "Spawners"
	SpawnersFolder.Parent = workspace
end

function ItemsSpawner.new(Spawner: Model)
	local self = setmetatable({}, ItemsSpawner)
	self.Spawner = Spawner
	self.Connections = {}
	self.SpawnedItems = {}
	self.SpawnCount = 0
	
	-- Configure
	self.FallbackItemName = Spawner:GetAttribute("ItemName") or "Noob"
	self.SpawnRate = Spawner:GetAttribute("SpawnRate") or 5
	self.MaxItems = Spawner:GetAttribute("MaxItems") or 5
	self.SpawnRadius = Spawner:GetAttribute("SpawnRadius") or 10
	
	local configModule = Spawner:FindFirstChild("Config")
	if configModule and configModule:IsA("ModuleScript") then
		self.SpawnerConfig = require(configModule)
		
		if self.SpawnerConfig.MaxItems ~= nil then self.MaxItems = self.SpawnerConfig.MaxItems end
		if self.SpawnerConfig.SpawnRate ~= nil then self.SpawnRate = self.SpawnerConfig.SpawnRate end
		if self.SpawnerConfig.SpawnRadius ~= nil then self.SpawnRadius = self.SpawnerConfig.SpawnRadius end
	end
	
	-- Organize Workspace Folders
	if Spawner.Parent ~= SpawnersFolder then
		Spawner.Parent = SpawnersFolder
	end
	
	self.CachedFolder = Spawner:FindFirstChild("SpawnedItems")
	if not self.CachedFolder then
		self.CachedFolder = Instance.new("Folder")
		self.CachedFolder.Name = "SpawnedItems"
		self.CachedFolder.Parent = Spawner
	end
	
	table.insert(ActiveSpawners, self)
	
	self:Connect()
	return self
end

function ItemsSpawner:SpawnItem()
	if self.SpawnCount >= self.MaxItems then return end
	
	local chosenItemName = self.FallbackItemName
	if self.SpawnerConfig and self.SpawnerConfig.Items then
		local picked = GetRandomItemName(self.SpawnerConfig.Items)
		if picked then chosenItemName = picked end
	end
	
	local itemTemplate = items:FindFirstChild(chosenItemName)
	if not itemTemplate then 
		warn("Item template not found: " .. tostring(chosenItemName))
		return 
	end
	
	local newItem = itemTemplate:Clone()
	
	-- Determine spawn bounding area based on Spawner size and Radius
	local spawnerCFrame = self.Spawner:GetPivot()
	local spawnerSize = self.Spawner:IsA("BasePart") and self.Spawner.Size or self.Spawner:GetExtentsSize()
	
	local maxSpreadX = math.min(self.SpawnRadius, spawnerSize.X / 2)
	local maxSpreadZ = math.min(self.SpawnRadius, spawnerSize.Z / 2)
	if maxSpreadX < 0 then maxSpreadX = 0 end
	if maxSpreadZ < 0 then maxSpreadZ = 0 end
	
	local randomX = (math.random() - 0.5) * 2 * maxSpreadX
	local randomZ = (math.random() - 0.5) * 2 * maxSpreadZ
	
	-- Height is Spawner's top + 5 studs to drop from
	local spawnY = (spawnerSize.Y / 2) + 5
	local overheadPosition = spawnerCFrame.Position + Vector3.new(randomX, spawnY, randomZ)
	
	-- Raycast directly down
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {newItem, self.Spawner}
	
	local raycastResult = workspace:Raycast(overheadPosition, Vector3.new(0, -1000, 0), rayParams)
	local spawnPosition = spawnerCFrame.Position + Vector3.new(randomX, 0, randomZ) -- Fallback
	
	if raycastResult then
		local offsetY = newItem:GetExtentsSize().Y / 2
		spawnPosition = raycastResult.Position + Vector3.new(0, offsetY, 0)
	end
	
	newItem:PivotTo(CFrame.new(spawnPosition))
	newItem.Parent = self.CachedFolder
	CollectionService:AddTag(newItem, "SpawnedItem")
	newItem:SetAttribute("ItemName", chosenItemName)
	
	-- Apply Physics Collision Group
	local PhysicsService = game:GetService("PhysicsService")
	local success, groupId = pcall(function() return PhysicsService:GetCollisionGroupId("SpawnedItems") end)
	if success and groupId then
		for _, part in ipairs(newItem:GetDescendants()) do
			if part:IsA("BasePart") then 
				part.CollisionGroupId = groupId 
				part.Anchored = true -- Fix via anchoring tightly
			end
		end
		if newItem:IsA("BasePart") then 
			newItem.CollisionGroupId = groupId 
			newItem.Anchored = true
		end
	end
	
	self.SpawnCount += 1
	table.insert(self.SpawnedItems, newItem)
	
	-- Pickup Setup
	local basePart = newItem:IsA("BasePart") and newItem or newItem.PrimaryPart
	if not basePart then basePart = newItem:FindFirstChildWhichIsA("BasePart", true) end
	
	-- Check Interaction Type
	local interactType = self.Spawner:GetAttribute("InteractType")
	if self.SpawnerConfig and self.SpawnerConfig.InteractType then
		interactType = self.SpawnerConfig.InteractType
	end
	interactType = interactType or "Touch"
	
	local proxyTouchHitbox = basePart
	if basePart and interactType == "Touch" then
		proxyTouchHitbox = Instance.new("Part")
		proxyTouchHitbox.Name = "TouchHitbox"
		proxyTouchHitbox.Size = basePart.Size + Vector3.new(2, 2, 2)
		proxyTouchHitbox.CFrame = basePart.CFrame
		proxyTouchHitbox.Anchored = false
		proxyTouchHitbox.CanCollide = false
		proxyTouchHitbox.Massless = true
		proxyTouchHitbox.Transparency = 1
		proxyTouchHitbox.CollisionGroupId = 0 -- Bắt buộc là 0 (Default) để chạm được Player
		
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = basePart
		weld.Part1 = proxyTouchHitbox
		weld.Parent = proxyTouchHitbox
		
		proxyTouchHitbox.Parent = newItem
	end
	
	if basePart then
		-- Setup BillboardGui
		local itemData = itemsconfig.Items[chosenItemName]
		if itemData then
			local rarityColor = itemsconfig.Rarity[itemData.Rarity or "Common"] or Color3.new(1, 1, 1)
			
			local billboard = Instance.new("BillboardGui")
			billboard.Name = "ItemInfo"
			billboard.Size = UDim2.fromOffset(150, 75)
			billboard.StudsOffset = Vector3.new(0, 2.5, 0)
			billboard.MaxDistance = 30
			billboard.AlwaysOnTop = true
			billboard.LightInfluence = 0
			
			-- Header: Name
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.fromScale(1, 0.4)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = chosenItemName
			nameLabel.TextColor3 = rarityColor
			nameLabel.Font = Enum.Font.FredokaOne
			nameLabel.TextScaled = true
			nameLabel.TextStrokeTransparency = 0.2
			nameLabel.Parent = billboard

			-- Line 2: Rarity
			local rarityLabel = Instance.new("TextLabel")
			rarityLabel.Size = UDim2.fromScale(1, 0.3)
			rarityLabel.Position = UDim2.fromScale(0, 0.35)
			rarityLabel.BackgroundTransparency = 1
			rarityLabel.Text = string.upper(itemData.Rarity or "COMMON")
			rarityLabel.TextColor3 = rarityColor
			rarityLabel.Font = Enum.Font.GothamBold
			rarityLabel.TextScaled = true
			rarityLabel.TextStrokeTransparency = 0.5
			rarityLabel.Parent = billboard
			
			-- Line 3: Price
			if itemData.Price then
				local priceLabel = Instance.new("TextLabel")
				priceLabel.Size = UDim2.fromScale(1, 0.3)
				priceLabel.Position = UDim2.fromScale(0, 0.65)
				priceLabel.BackgroundTransparency = 1
				priceLabel.Text = "💎 " .. numberformat(itemData.Price, "Suffix")
				priceLabel.TextColor3 = Color3.fromRGB(115, 250, 121)
				priceLabel.Font = Enum.Font.GothamBold
				priceLabel.TextScaled = true
				priceLabel.TextStrokeTransparency = 0.5
				priceLabel.Parent = billboard
			end
			
			billboard.Parent = basePart
		end

		-- Interact Logic
		local debounce = false
		local connection = nil
		
		local function TriggerEvent(player)
			if debounce then return end
			debounce = true
			
			if connection then connection:Disconnect() end
			
			-- Aggressively clean up interaction prompts
			if interactType == "Prompt" then
				local prompt = basePart:FindFirstChildOfClass("ProximityPrompt")
				if prompt then prompt:Destroy() end
			elseif interactType == "Click" then
				local click = basePart:FindFirstChildOfClass("ClickDetector")
				if click then click:Destroy() end
			end
			
			if proxyTouchHitbox and proxyTouchHitbox ~= basePart then
				proxyTouchHitbox:Destroy()
			end
			
			TakeItem(player, chosenItemName)
			
			-- Remove item from list
			for i, v in ipairs(self.SpawnedItems) do
				if v == newItem then
					table.remove(self.SpawnedItems, i)
					break
				end
			end
			self.SpawnCount -= 1
			
			-- Pickup Effect (Tween Module)
			local TweenWrapper = require(ReplicatedStorage.shared.tween)
			
			-- Anchor it to stop falling
			for _, v in ipairs(newItem:GetDescendants()) do
				if v:IsA("BasePart") then
					v.Anchored = true
					-- Giữ nguyên CanCollide theo group thay vì ép tắt thủ công
					TweenWrapper:Play(v, {0.3, "Quad", "Out"}, {Transparency = 1})
				end
			end
			if newItem:IsA("BasePart") then
				newItem.Anchored = true
				TweenWrapper:Play(newItem, {0.3, "Quad", "Out"}, {Transparency = 1})
			end
			
			if basePart:FindFirstChild("ItemInfo") then
				TweenWrapper:Play(basePart.ItemInfo, {0.3, "Quad", "Out"}, {Size = UDim2.fromOffset(0, 0)})
			end
			
			TweenWrapper:Play(basePart, {0.3, "Quad", "Out"}, {CFrame = basePart.CFrame * CFrame.new(0, 4, 0)})
			
			-- Clean up
			task.delay(0.35, function()
				if newItem and newItem.Parent then
					newItem:Destroy()
				end
			end)
		end
		
		if interactType == "Touch" then
			connection = proxyTouchHitbox.Touched:Connect(function(hit)
				local character = hit:FindFirstAncestorWhichIsA("Model")
				if character then
					local player = game.Players:GetPlayerFromCharacter(character)
					if player then
						TriggerEvent(player)
					end
				end
			end)
		elseif interactType == "Prompt" then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Lấy " .. (chosenItemName or "Item")
			prompt.ObjectText = "Vật phẩm"
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 10
			prompt.Parent = basePart
			
			connection = prompt.Triggered:Connect(function(player)
				TriggerEvent(player)
			end)
		elseif interactType == "Click" then
			local clickDetector = Instance.new("ClickDetector")
			clickDetector.MaxActivationDistance = 15
			clickDetector.Parent = basePart
			
			connection = clickDetector.MouseClick:Connect(function(player)
				TriggerEvent(player)
			end)
		end
		
		if connection then
			table.insert(self.Connections, connection)
		end
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
