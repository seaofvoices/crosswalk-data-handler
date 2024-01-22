local DataStoreService = game:GetService('DataStoreService')

local IS_STUDIO = game:GetService('RunService'):IsStudio()

local module = {}

local STUDIO_LOADS = _G.DATA_HANDLER_STUDIO_LOADS or false
local STUDIO_SAVES = _G.DATA_HANDLER_STUDIO_SAVES or false

local LOAD_DATA = not IS_STUDIO or STUDIO_LOADS
local SAVE_DATA = not IS_STUDIO or STUDIO_SAVES

local retryTime = 5
local maxTries = 4

type Config = {
    maxDataStoreRetries: number?,
    dataStoreRetryTime: number?,
}

local function getDataStoreKey(player: Player): string
    return string.format('%x', player.UserId)
end

function module.config(config: Config)
    if config.dataStoreRetryTime then
        retryTime = config.dataStoreRetryTime
    end
    if config.maxDataStoreRetries then
        maxTries = config.maxDataStoreRetries
    end
end

function module.save(player: Player, dataStoreName: string, data: any): boolean
    local tries = 0
    local playerKey = getDataStoreKey(player)
    local success = false

    local storedData = DataStoreService:GetDataStore(dataStoreName)

    repeat
        success = pcall(function()
            if SAVE_DATA then
                storedData:SetAsync(playerKey, data)
            end
        end)

        if not success then
            tries += 1
            task.wait(retryTime ^ tries)
        end
    until success or tries >= maxTries

    return success
end

function module.getSaved(player: Player, dataStoreName: string): any?
    local tries = 0
    local success = false

    local savedData = nil

    local playerKey = getDataStoreKey(player)
    local storedData = DataStoreService:GetDataStore(dataStoreName)

    repeat
        success = pcall(function()
            if LOAD_DATA then
                savedData = storedData:GetAsync(playerKey)
            end
        end)

        if not success then
            tries += 1
            task.wait(retryTime ^ tries)
        end
    until success or tries >= maxTries

    if tries > maxTries then
        error(`could not load player data from '{dataStoreName}'`)
    end

    return savedData
end

return module
