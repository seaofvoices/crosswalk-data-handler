local HttpService = game:GetService('HttpService')

type DataWithLock<T> = {
    data: T,
    lock: string?,
    lockExpiration: number?,
}

local LOCK_DURATION = 15

local function createLockedData<T>(data: T): DataWithLock<T>
    return {
        lock = game.JobId,
        lockExpiration = os.time() + LOCK_DURATION,
        data = data,
    }
end

local function createUnlockedData<T>(data: T): DataWithLock<T>
    return {
        data = data,
    }
end

local function encodeJSON(data: any): string
    return HttpService:JSONEncode(data)
end

local function decodeJSON(data: string): any
    return HttpService:JSONDecode(data)
end

local function validateLock(value: DataWithLock<any>?): boolean
    return value == nil
        or value.lock == nil
        or value.lock == game.JobId
        or (type(value.lockExpiration) == 'number' and os.time() > value.lockExpiration)
end

type FetchStatus = 'success' | 'failure' | 'data-lock'

export type LockedDataStore = {
    get: (self: LockedDataStore, key: string) -> { status: FetchStatus, value: any? },
    update: (self: LockedDataStore, key: string, data: any, releaseLock: boolean?) -> FetchStatus,
}

type Private = {
    _dataStore: DataStore,
    _encode: (any) -> string,
    _decode: (string) -> any,
}
type PrivateLockedDataStore = LockedDataStore & Private

type LockedDataStoreStatic = LockedDataStore & Private & {
    new: (dataStore: DataStore) -> LockedDataStore,
}

local LockedDataStore: LockedDataStoreStatic = {} :: any
local LockedDataStoreMetatable = {
    __index = LockedDataStore,
}

function LockedDataStore.new(dataStore: DataStore): LockedDataStore
    local self: Private = {
        _dataStore = dataStore,
        _encode = encodeJSON,
        _decode = decodeJSON,
    }

    return setmetatable(self, LockedDataStoreMetatable) :: any
end

function LockedDataStore:get(key: string): { status: FetchStatus, value: any? }
    local self: PrivateLockedDataStore = self :: any

    local data = nil
    local status: FetchStatus = 'failure'

    local updateSuccess, updateResult = pcall(function()
        self._dataStore:UpdateAsync(key, function(previousValue: DataWithLock<any>?)
            if previousValue == nil then
                status = 'success'
                data = nil
                return nil
            elseif validateLock(previousValue) then
                local decodeSuccess, result = pcall(self._decode, previousValue.data)

                if decodeSuccess then
                    status = 'success'
                    data = result
                    return createLockedData(previousValue.data)
                else
                    warn(`unable to decode data: {result}`)
                    return nil
                end
            else
                status = 'data-lock'
                return nil
            end
        end)
    end)

    if not updateSuccess then
        status = 'failure'
        warn(`failed to update datastore: {updateResult}`)
    end

    return { status = status, value = data }
end

function LockedDataStore:update(key: string, data: any, releaseLock: boolean?): FetchStatus
    local self: PrivateLockedDataStore = self :: any

    local serializeSuccess, serialized = pcall(self._encode, data)

    if not serializeSuccess then
        warn(`unable to encode data: {serialized}`)
        return 'failure'
    end

    local success = false

    local updateSuccess = pcall(function()
        self._dataStore:UpdateAsync(key, function(previousValue: DataWithLock<any>?)
            if validateLock(previousValue) then
                local updated = if releaseLock
                    then createUnlockedData(serialized)
                    else createLockedData(serialized)
                success = true
                return updated
            else
                -- data is locked
                return nil
            end
        end)
    end)

    return if updateSuccess and success
        then 'success'
        elseif updateSuccess then 'data-lock'
        else 'failure'
end

return LockedDataStore
