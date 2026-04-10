--> Services
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local HIGHLIGHT_DISTANCE = 25

local itemsconfig = require(ReplicatedStorage.config.ItemsConfig)

-- Cache tracking objects
local activeHighlights = {}

local function createHighlight(item)
	if activeHighlights[item] then return activeHighlights[item] end
	
	local itemName = item:GetAttribute("ItemName") or item.Name
	local rarityColor = Color3.new(1, 1, 1)
	
	local itemData = itemsconfig.Items[itemName]
	if itemData then
		rarityColor = itemsconfig.Rarity[itemData.Rarity or "Common"] or Color3.new(1, 1, 1)
	end
	
	local highlight = Instance.new("Highlight")
	highlight.FillColor = rarityColor
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0.1
	highlight.Parent = item
	
	activeHighlights[item] = highlight
	return highlight
end

local function removeHighlight(item)
	if activeHighlights[item] then
		activeHighlights[item]:Destroy()
		activeHighlights[item] = nil
	end
end

-- Update Loop
RunService.RenderStepped:Connect(function()
	local character = LocalPlayer.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local charPos = hrp.Position
	
	for _, item in ipairs(CollectionService:GetTagged("SpawnedItem")) do
		if item.Parent then
			local itemPos = item:GetPivot().Position
			local distance = (charPos - itemPos).Magnitude
			
			if distance <= HIGHLIGHT_DISTANCE then
				createHighlight(item)
			else
				removeHighlight(item)
			end
		else
			removeHighlight(item)
		end
	end
end)

CollectionService:GetInstanceRemovedSignal("SpawnedItem"):Connect(function(item)
	removeHighlight(item)
end)
