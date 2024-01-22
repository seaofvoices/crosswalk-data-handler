export type PlayersData<Data> = {
    tryGet: (self: PlayersData<Data>, player: Player) -> Data?,
    expect: (self: PlayersData<Data>, player: Player) -> Data,
}

type Private<Data> = {
    _data: { [Player]: Data },
}
type PlayersDataStatic = {
    new: <Data>(data: { [Player]: Data }) -> PlayersData<Data>,

    tryGet: <Data>(self: PlayersData<Data>, player: Player) -> Data?,
    expect: <Data>(self: PlayersData<Data>, player: Player) -> Data,
}
type PrivatePlayersData<Data> = PlayersData<Data> & Private<Data>

local PlayersData: PlayersDataStatic = {} :: any
local PlayersDataMetatable = {
    __index = PlayersData,
}

function PlayersData.new<Data>(data: { [Player]: Data }): PlayersData<Data>
    local self: Private<Data> = {
        _data = data,
    }

    return setmetatable(self, PlayersDataMetatable) :: any
end

function PlayersData:tryGet<Data>(player: Player): Data?
    local self: PrivatePlayersData<Data> = self :: any

    return self._data[player]
end

function PlayersData:expect<Data>(player: Player): Data
    local self: PrivatePlayersData<Data> = self :: any

    local data = self._data[player]
    if data == nil then
        error('attempt to get player data before it is loaded')
    end

    return data
end

return PlayersData
