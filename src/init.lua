return function(_, _, _)
    local module = {}

    local Signal = require('@pkg/luau-signal')

    local DataStore = require('./impl/DataStore')
    local PlayersData = require('./impl/PlayersData')
    local deepMerge = require('./impl/deepMerge')

    type Signal<T> = Signal.Signal<T>
    type PlayersData<Data> = PlayersData.PlayersData<Data>

    local function getDefaultGlobalNumber(globalName: string, default: number): number
        local value = _G[globalName]
        if value == nil then
            return default
        else
            local num = tonumber(value)
            if num == nil then
                error(
                    `unable to get number value from global '{globalName}' with a value of '{value}'`
                )
            else
                return num
            end
        end
    end

    local dataStoreIndex = _G.DATA_HANDLER_DATA_STORE_NAME or 'DefaultDataStore'
    local autoSaveInterval = getDefaultGlobalNumber('DATA_HANDLER_AUTO_SAVE_INTERVAL', 45)
    local autoSaveDelay = getDefaultGlobalNumber('DATA_HANDLER_SAVE_DELAY', 3.5)
    local retryTime = getDefaultGlobalNumber('DATA_HANDLER_RETRY_TIME', 5)
    local maxTries = getDefaultGlobalNumber('DATA_HANDLER_MAX_TRIES', 4)

    local registeredData = {}
    local dataReadySignal: Signal<Player> = Signal.new()

    local playerDatas: { [Player]: any } = {}

    type Config = {
        dataStoreName: string?,
        maxDataStoreRetries: number?,
        dataStoreRetryTime: number?,
        autoSaveInterval: number?,
        autoSaveDelay: number?,
    }

    local hasStarted = false

    function module.config(config: Config)
        if config.dataStoreName then
            dataStoreIndex = config.dataStoreName
        end
        if config.autoSaveInterval then
            autoSaveInterval = config.autoSaveInterval
        end
        if config.autoSaveDelay then
            autoSaveDelay = config.autoSaveDelay
        end
        if config.dataStoreRetryTime then
            retryTime = config.dataStoreRetryTime
        end
        if config.maxDataStoreRetries then
            maxTries = config.maxDataStoreRetries
        end

        DataStore.config({
            dataStoreRetryTime = retryTime,
            maxDataStoreRetries = maxTries,
        })
    end

    function module.Start()
        hasStarted = true
        if not dataStoreIndex then
            error(
                'dataStoreIndex is nil, make sure to use DataHandler.config({ dataStoreName = '
                    .. "'YourDataStoreName' }) to set the correct datastore index"
            )
        end

        task.spawn(function()
            while true do
                for player in playerDatas do
                    task.spawn(function()
                        local randomSaveDelay = math.random() * autoSaveDelay
                        task.wait(randomSaveDelay)

                        module.savePlayer(player)
                    end)
                end

                task.wait(autoSaveInterval)
            end
        end)

        game:BindToClose(function()
            local done = {}

            local i = 0
            for player in playerDatas do
                i += 1
                table.insert(done, false)
                task.spawn(function()
                    module.savePlayer(player)
                    done[i] = true
                end)
            end

            repeat
                task.wait(0.1)
                local isDone = true
                for _, success in done do
                    if not success then
                        isDone = false
                        break
                    end
                end
            until isDone
        end)
    end

    function module.register<Data>(
        dataName: string,
        getDefault: () -> Data,
        onLoaded: (player: Player, data: Data) -> ()?,
        onRemoved: (player: Player, data: Data) -> ()?
    ): PlayersData<Data>
        if registeredData[dataName] ~= nil then
            error(`attempt to register player data '{dataName}' more than once`)
        end
        if hasStarted then
            error(
                `attempt to register player data '{dataName}' after the 'Init' `
                    .. "phase. Make sure to call 'DataHandler.register' within an 'Init' function."
            )
        end

        local loadedData: { [Player]: Data } = setmetatable({}, { __mode = 'k' }) :: any
        local playersData = PlayersData.new(loadedData, getDefault)

        registeredData[dataName] = {
            getDefault = getDefault,
            onLoaded = onLoaded,
            onRemoved = onRemoved,
            loadedData = loadedData,
            playersData = playersData,
        }

        return playersData
    end

    function module.connectToDataReady(onDataReady: (player: Player) -> ()): () -> ()
        return dataReadySignal:connect(onDataReady):disconnectFn()
    end

    local function savePlayer(player: Player, data: any): boolean
        return DataStore.save(player, dataStoreIndex, data)
    end

    function module.savePlayer(player: Player): boolean
        local data = playerDatas[player]
        if data == nil then
            return true
        end

        return savePlayer(player, data)
    end

    function module.erasePlayer(player: Player): boolean
        local data = playerDatas[player]

        if data ~= nil then
            for _, info in registeredData do
                info.playersData:restoreDefault(player)
            end
        end

        return savePlayer(player, nil)
    end

    function module.restorePlayer(player: Player): boolean
        local data = playerDatas[player]

        if data ~= nil then
            for _, info in registeredData do
                info.playersData:restoreDefault(player)
            end
        end

        return module.savePlayer(player)
    end

    function module.OnPlayerReady(player: Player)
        local savedData = DataStore.getSaved(player, dataStoreIndex)

        local data = if savedData == nil then {} else savedData

        for dataName, info in registeredData do
            local template: any = info.getDefault()

            if data[dataName] == nil then
                data[dataName] = template
            else
                data[dataName] = deepMerge(template, data[dataName])
            end

            info.loadedData[player] = data[dataName]
            if info.onLoaded then
                info.onLoaded(player, data[dataName])
            end
        end

        playerDatas[player] = data

        dataReadySignal:fire(player)
    end

    function module.OnPlayerLeaving(player: Player)
        local data = playerDatas[player]
        if data == nil then
            return
        end

        for _, info in registeredData do
            if info.loadedData[player] ~= nil then
                if info.onRemoved then
                    info.onRemoved(player, info.loadedData[player])
                end
                info.loadedData[player] = nil
            end
        end

        playerDatas[player] = nil

        local success = savePlayer(player, data)
        if not success then
            error('could not save player data on leaving')
        end
    end

    return module
end
