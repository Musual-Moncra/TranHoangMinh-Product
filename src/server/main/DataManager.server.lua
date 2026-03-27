-- Services
local DataStoreService = game:GetService("DataStoreService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
-- Configs
local Config = require(ReplicatedStorage.config.DataConfig)
-- API
local CreateBaseFolder = require(ServerStorage.data.createbasefolder)
local CreateStatInstance = require(ServerStorage.data.createstatinstance)
-- Data
local DataStore = DataStoreService:GetDataStore(Config.DataStoreName)
local BaseFolder = CreateBaseFolder(ReplicatedStorage)

-- CreateData
local function CreateStats(pData: Folder)
    local Stats = Instance.new("Folder")
    Stats.Name = "Stats"
    Stats.Parent = pData

    for StatName, StatConfig in pairs(Config.DataList) do
        CreateStatInstance(StatConfig.Type, StatConfig.Default, Stats, StatName)
    end

    return Stats
end

local function CreateData(Player: Player)
    local PlayerData = Instance.new("Folder")
    PlayerData.Name = Player.Name
    PlayerData.Parent = BaseFolder

    -- Handle
    CreateStats(PlayerData)

    return PlayerData
end

-- Setup Leaderstats
local function SetupLeaderstats(Player: Player, PlayerData: Folder)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = Player
    
    local Stats = PlayerData:WaitForChild("Stats")
    
    for StatName, StatConfig in pairs(Config.DataList) do
        local statValue = Stats:FindFirstChild(StatName)
        if statValue and StatConfig.Leaderstats and StatConfig.Leaderstats[1] then
            -- Create Leaderstat Instance
            local lsValue = CreateStatInstance(StatConfig.Type, statValue.Value, leaderstats, StatName)
            
            -- Keep them synced
            statValue.Changed:Connect(function(val)
                lsValue.Value = val
            end)
            lsValue.Changed:Connect(function(val)
                statValue.Value = val
            end)
        end
    end
end

-- Load Data
local function LoadStats(pData: Folder, Data: table)
    local Stats = pData:FindFirstChild("Stats")
    if Stats and type(Data) == "table" then
        for _, stat in ipairs(Stats:GetChildren()) do
            if Data[stat.Name] ~= nil then
                stat.Value = Data[stat.Name]
            end
        end
    end
end

local function LoadData(Player: Player)
    local key = "Player_" .. Player.UserId
    local success, data = pcall(function()
        return DataStore:GetAsync(key)
    end)
    
    local PlayerData = CreateData(Player)
    
    if success and data then
        LoadStats(PlayerData, data)
    elseif not success then
        warn("Failed to load data for: " .. Player.Name)
    end
    
    SetupLeaderstats(Player, PlayerData)
end

-- Save Data
local function SaveStats(pData: Folder, DataToSave: table)
    local Stats = pData:FindFirstChild("Stats")
    if Stats then
        for _, stat in ipairs(Stats:GetChildren()) do
            DataToSave[stat.Name] = stat.Value
        end
    end
end

local function SaveData(Player: Player)
    local DataToSave = {}
    local PlayerData = BaseFolder:FindFirstChild(Player.Name)
    
    if PlayerData then
        SaveStats(PlayerData, DataToSave)
        
        local key = "Player_" .. Player.UserId
        local success, err = pcall(function()
            DataStore:SetAsync(key, DataToSave)
        end)
        
        if not success then
            warn("Failed to save data for " .. Player.Name .. ": ", err)
        end
        
        -- Clean up
        PlayerData:Destroy()
    end
end

-- Init
Players.PlayerAdded:Connect(function(Player)
    LoadData(Player)
end)

Players.PlayerRemoving:Connect(function(Player)
    SaveData(Player)
end)

-- Auto Save
task.spawn(function()
    while true do
        task.wait(60) -- Auto save every 60 seconds
        for _, Player in ipairs(Players:GetPlayers()) do
            local PlayerData = BaseFolder:FindFirstChild(Player.Name)
            if PlayerData then
                local DataToSave = {}
                SaveStats(PlayerData, DataToSave)
                
                local key = "Player_" .. Player.UserId
                pcall(function()
                    DataStore:SetAsync(key, DataToSave)
                end)
            end
        end
    end
end)
