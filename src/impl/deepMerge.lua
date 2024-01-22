local deepCopy = require('./deepCopy')

local function deepMerge<T>(...: any): T
    local result = {}

    for dictionaryIndex = 1, select('#', ...) do
        local dictionary = select(dictionaryIndex, ...)

        if type(dictionary) ~= 'table' then
            continue
        end

        for key, value in pairs(dictionary) do
            if type(value) == 'table' then
                if result[key] == nil or type(result[key]) ~= 'table' then
                    result[key] = deepCopy(value)
                else
                    result[key] = deepMerge(result[key], value)
                end
            else
                result[key] = value
            end
        end
    end

    return result :: any
end

return deepMerge
