-- Create BaseFolder for Data
return function (Parent: any)
    local BaseFolder = Instance.new("Folder")
    BaseFolder.Name = "PlayerData"
    BaseFolder.Parent = Parent
    return BaseFolder
end