# DataHandler

A crosswalk module to handle Player data.

This library is designed to facilitate the management, saving, and loading of player data in Roblox games within the [crosswalk framework](https://crosswalk.seaofvoices.ca/). It provides a flexible and customizable solution for handling player-specific information using Roblox's data storage services.

Instead of having a centralized place where all the player data is contained and managed, each crosswalk server modules can register their specific player data that needs to persist.

## Installation

Add `@crosswalk-game/data-handler` in your dependencies:

```bash
yarn add @crosswalk-game/data-handler
```

Or if you are using `npm`:

```bash
npm install @crosswalk-game/data-handler
```

## Initialization

In one of your crosswalk server module's `Init` function, call the `config` function to configure the data handling settings.

```lua
Modules.DataHandler.config({
    dataStoreName = "YourDataStoreName",
    -- optional settings
    autoSaveInterval = 45,
    maxDataStoreRetries = 4,
    dataStoreRetryTime = 5,
    autoSaveDelay = 3.5
})
```

This module can also be configured using a set of global variables:

- `DATA_HANDLER_DATA_STORE_NAME`
- `DATA_HANDLER_AUTO_SAVE_INTERVAL`
- `DATA_HANDLER_MAX_TRIES`
- `DATA_HANDLER_RETRY_TIME`
- `DATA_HANDLER_SAVE_DELAY`

## Register Player Data

```lua
Modules.DataHandler.register<Data>(
    dataName: string,
    getDefault: () -> Data,
    onLoaded: (player: Player, data: Data) -> ()?,
    onRemoved: (player: Player, data: Data) -> ()?
): PlayersData<Data>
```

Call this function in an `Init` function of each crosswalk server module where player data is needed.

**Note:** once a player re-join a server with existing data, their data is going to be deeply merged with the value returned by the `getDefault` function.

- **Parameters:**

  - `dataName`: A unique identifier for the player data.
  - `getDefault`: A function returning the default data structure.
  - `onLoaded`: A callback function triggered when player data is loaded. (**optional**)
  - `onRemoved`: A callback function triggered when player data is removed. (**optional**)

- **Returns:**
  - `PlayersData` object to store in a static variable. This object can be used to get the specific

### PlayersData Object

The `PlayersData` object is an abstraction for managing player-specific data. It provides methods for retrieving player data and handling scenarios where data may or may not be available.

#### `tryGet<Data>(player: Player): Data?`

Attempts to retrieve the data associated with a specific player.

- **Parameters:**

  - `player`: The player for whom data is to be retrieved.

- **Returns:**
  - `Data`: The player's data if available, or `nil` if not found.

#### `tryRun<Data>(player: Player, fn: (Data) -> ()): boolean`

Execute the given `fn` function only if data is found for the given `Player`.

- **Parameters:**

  - `player`: The player for whom data is to be retrieved.
  - `fn`: A function that accepts the data associated with the player.

- **Returns:**
  - `boolean`: If the `fn` function was called or not.

#### `expect<Data>(player: Player): Data`

Retrieves the data associated with a specific player and raises an error if the data is not available.

- **Parameters:**

  - `player`: The player for whom data is to be retrieved.

- **Returns:**
  - `Data`: The player's data.

#### `restoreDefault<Data>(player: Player)`

Updates the data associated with a specific player to match the default value.

- **Parameters:**
  - `player`: The player for whom data is to be restored.

### Example

```lua
local playerDatas

function module.Init()
    playerDatas = Modules.DataHandler.register("stats", function()
        return {
            points = 0,
            level = 1,
        }
    end)
end

function module.AddPoints(player: Player, amount: number)
    local data = playerDatas:expect(player)
    data.points += amount
end
```

## Connect to Data Ready Signal

Use the `connectToDataReady` to trigger a callback when the data of a player is ready to be used.

```lua
local disconnectFn = Modules.DataHandler.connectToDataReady(function(player: Player)
    -- ...
end)
```

This allows you to connect functions to be executed when player data is ready.

## Save Player Data Manually

```lua
local success = Modules.DataHandler.savePlayer(player)
```

Manually triggers the saving of a player's data.

## Restore to Default Player Data

```lua
local success = Modules.DataHandler.restorePlayer(player)
```

Restore the player data to the default value and save the changes.

## Erase Player Data

```lua
local success = Modules.DataHandler.erasePlayer(player)
```

Erase all the player data and save the changes.

## License

This project is available under the MIT license. See [LICENSE.txt](LICENSE.txt) for details.
