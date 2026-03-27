export type ClassType = "NumberValue" | "StringValue" | "BoolValue" | "IntValue"
export type CreateStatInstance = (Class: ClassType) -> Instance

return function (Class: ClassType, Default: any, Parent: Instance, Name: string)
    local Instance = Instance.new(Class)
    Instance.Name = Name
    Instance.Value = Default
    Instance.Parent = Parent
    return Instance
end