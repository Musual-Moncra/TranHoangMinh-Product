--[[
	FormatNumber // Musual, March 2022
	
	FormatNumber lets you easily format passed whole numbers into strings. There are currently three formats:
	• Number: 123456789
	• Notation: 1.2e08
	• Commas: 123,456,789
	• Suffix: 123.45M
	
	Usage Example ----
	local FormatNumber = require(path.to.module)
	FormatNumber(123456789, "Suffix") -- 123.45M
	FormatNumber(1000, FormatNumber.FormatType.Commas) -- 1,000
	FormatNumber(999, "Suffix") -- 999
]] 

local Suffixes = {"k", "m", "n", "t", "qd", "qn", "sx", "sp", "oc", "n", "d", "ud", "dd", "tdd"}

local function isNan(n: number)
	return n ~= n
end

local function roundToNearest(n: number, to: number)
	return math.round(n / to) * to
end

local function formatNotation(n: number)
	return string.gsub(string.format("%.1e", n), "+", "")
end

local function formatCommas(n: number)
	local str = string.format("%.f", n)
	return #str % 3 == 0 and str:reverse():gsub("(%d%d%d)", "%1,"):reverse():sub(2) or str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
end

local function formatSuffix(n: number)
	local str = string.format("%.f", math.floor(n))
	if #str > 12 then
		str = roundToNearest(tonumber(string.sub(str, 1, 12)) or 0, 10) .. string.sub(str, 13, #str)
	end
	local size = #str
	
	local cutPoint = (size-1) % 3 + 1
	local before = string.sub(str, 1, cutPoint) -- (123).4M
	
	local after = string.sub(str, cutPoint + 1, cutPoint + 2) -- 123.(45)M
	local suffix = Suffixes[math.clamp(math.floor((size-1)/3), 1, #Suffixes)] -- 123.45(M)
	
	if not suffix or n > 9.999e44 then
		return formatNotation(n)
	end
	
	return string.format("%s.%s%s", before, after, suffix)
end

--------------------------------------------------------------------------------

local API = {}

API.FormatType = {
	Notation = "Notation",
	Commas = "Commas",
	Suffix = "Suffix",
}

local function Convert(n: number, FormatType: "Suffix"|"Commas"|"Notation")
	if n == nil or isNan(n) then
		warn(("[FormatNumber]: First argument passed, '%s', isn't a valid number."):format(tostring(n)))
		warn(debug.traceback(nil, 3))
		return "<?>"
	end
	
	if n < 1e3 or FormatType == nil then
		if FormatType == nil then
			warn("[FormatNumber]: FormatType wasn't given.")
			warn(debug.traceback(nil, 3))
		end
		return tostring(n)
	end
	
	if FormatType == "Notation" then
		return formatNotation(n)
	elseif FormatType == "Commas" or n < 1e4 then
		return formatCommas(n)
	elseif FormatType == "Suffix" then
		return formatSuffix(n)
	else
		warn("[FormatNumber]: FormatType not found for \"".. FormatType .."\".")
	end
end

setmetatable(API, {
	__call = function(t, ...)
		if t == API then
			return Convert(...)
		end
	end,
})

return API