local function deepCopy<T>(dictionary: T): T
    local new = table.clone(dictionary :: any)

    for key, value in pairs(dictionary :: any) do
        if type(value) == 'table' then
            new[key] = deepCopy(value)
        end
    end

    return new :: any
end

return deepCopy
