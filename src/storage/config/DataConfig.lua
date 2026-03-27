-- Data Config

export type DataType = "NumberValue" | "StringValue" | "BoolValue" | "IntValue"

export type DataConfig = {
    Default: any,
    Type: DataType,
    Leaderstats: {boolean | number}
}

return {
    DataStoreName = "DataStore",

    DataList = {
        ["Cash"] = {
            Default = 0,
            Type = "IntValue",
            Leaderstats = {true, 1}, -- {IsLeaderstats, Order}
        } :: DataConfig,

        ["Rebirth"] = {
            Default = 0,
            Type = "IntValue",
            Leaderstats = {true, 2}, -- {IsLeaderstats, Order}
        } :: DataConfig,
    }
}