export type PlayersData<Data> = {
    tryGet: (self: PlayersData<Data>, player: Player) -> Data?,
    tryRun: (self: PlayersData<Data>, player: Player, fn: (Data) -> ()) -> boolean,
    expect: (self: PlayersData<Data>, player: Player) -> Data,
    forEach: (self: PlayersData<Data>, fn: (player: Player, data: Data) -> ()) -> (),
    restoreDefault: (self: PlayersData<Data>, player: Player) -> (),
}

type Private<Data> = {
    _data: { [Player]: Data },
    _getDefault: () -> Data,
}
type PlayersDataStatic = {
    new: <Data>(data: { [Player]: Data }, getDefault: () -> Data) -> PlayersData<Data>,

    tryGet: <Data>(self: PlayersData<Data>, player: Player) -> Data?,
    tryRun: <Data>(self: PlayersData<Data>, player: Player, fn: (Data) -> ()) -> boolean,
    expect: <Data>(self: PlayersData<Data>, player: Player) -> Data,
    forEach: <Data>(self: PlayersData<Data>, fn: (player: Player, data: Data) -> ()) -> (),
    restoreDefault: <Data>(self: PlayersData<Data>, player: Player) -> (),
}
type PrivatePlayersData<Data> = PlayersData<Data> & Private<Data>

local PlayersData: PlayersDataStatic = {} :: any
local PlayersDataMetatable = {
    __index = PlayersData,
}

function PlayersData.new<Data>(data: { [Player]: Data }, getDefault: () -> Data): PlayersData<Data>
    local self: Private<Data> = {
        _data = data,
        _getDefault = getDefault,
    }

    return setmetatable(self, PlayersDataMetatable) :: any
end

function PlayersData:tryGet<Data>(player: Player): Data?
    local self: PrivatePlayersData<Data> = self :: any

    return self._data[player]
end

function PlayersData:tryRun<Data>(player: Player, fn: (Data) -> ()): boolean
    local self: PrivatePlayersData<Data> = self :: any

    local data = self._data[player]
    if data ~= nil then
        fn(data)
        return true
    end

    return false
end

function PlayersData:expect<Data>(player: Player): Data
    local self: PrivatePlayersData<Data> = self :: any

    local data = self._data[player]
    if data == nil then
        error('attempt to get player data before it is loaded')
    end

    return data
end

function PlayersData:forEach<Data>(fn: (player: Player, data: Data) -> ())
    local self: PrivatePlayersData<Data> = self :: any

    for player, data in self._data do
        fn(player, data)
    end
end

function PlayersData:restoreDefault<Data>(player: Player)
    local self: PrivatePlayersData<Data> = self :: any

    local data = self._data[player]

    if data ~= nil then
        local default = self._getDefault() :: any

        for key in data :: any do
            if default[key] == nil then
                (data :: any)[key] = nil
            end
        end

        for key, value in default do
            (data :: any)[key] = value
        end
    end
end

return PlayersData
