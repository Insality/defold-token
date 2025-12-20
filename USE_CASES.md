# Use Cases

This section provides examples of how to use the `token` module.

## Save token state

You need to save the token state and load it before the `token.init` function.

For this you can use [Defold Saver](https://github.com/Insality/defold-saver) module.

```lua
local saver = require("saver.saver")
local token = require("token.token")

function init(self)
	saver.init()
	saver.bind_save_part("token", token.get_state())

	token.init()
end
```

Or you can use other save system

```lua
local token = require("token.token")

local function save_token_state()
	-- Save a token.state table as you wish
	save_token_state(token.get_state())
end


local function load_token_state()
	-- Load a token.state table as you wish
	return load_token_state_from_save()
end


function init(self)
	local state = load_token_state()
	token.set_state(state)
	token.init()
end
```

## Example: wallet container

Often we need to create a container for a player's wallet or other "global" container.
You can do this by choosing one name for the container. For example `token.container("wallet")` and look like this:

```lua
local token = require("token.token")
token.container("wallet"):add("gold", 100, "task_completed")

-- Or with const name?
local const = require("game.const")
token.container(const.WALLET_ID):add(const.ITEM.GOLD, 100, const.REASON.TASK_COMPLETED)
```

or you can create a Lua module file which will be used as a container itself

```lua
-- /game/wallet.lua
local token = require("token.token")

---@class wallet
local M = {}
local METATABLE = { __index = nil }

---@param wallet token.container
function M.set_wallet(wallet)
	METATABLE.__index = wallet
end

M.set_wallet(token.container("wallet"))

return setmetatable(M, METATABLE)
```

And use it in your code like this (no any `token` required in each place)

```lua
local wallet = require("game.wallet")
wallet:add("gold", 100, "task_completed")
```

## Tokens Config

This config can be a Lua file, for example placed at `/game/tokens.lua` and look like this:

```lua
-- /game/tokens.lua
return {
	["gold"] = {},
	["exp"] = {},
	["token_basic"] = { default = 8, min = 0, max = 10000 },
	["token_interaction"] = { default = 0, min = 0, max = 10000 },
	["damage_power"] = { default = 1 },
	["damage_crit"] = { default = 0.05 },
}
```

This allow to use this file as a config for `token.init` function.

```lua
token.init(require("game.tokens"))
```

And you can use Lua checks to validate your token is exists in the code:

```lua
-- Instead of "gold", where you can made a typo and get an unexpected behavior
wallet:add("gold", 100, "task_completed")

-- You can use Lua checks to validate your token is exists
local tokens = require("game.tokens")

-- If gold is not exists, it will be an syntax error here
-- (token container can accept both string token id or token config)
wallet:add(tokens.gold, 100, "task_completed")


-- You still can use any token id as a string, the token config is not required to count as a valid token id
wallet:add("token_without_config", 100, "task_completed")
```


## Token Groups and Lots

Token groups and lots should be registered separately using dedicated functions:

```lua
local token = require("token.token")

-- Initialize with tokens config
token.init(require("game.tokens"))

-- Register token groups (collections of tokens for rewards/prices)
token.register_token_groups({
	["starter_pack_price"] = {
		["money"] = 5,
	},
	["starter_pack"] = {
		["gold"] = 100,
		["exp"] = 50,
	},
	["daily_reward"] = {
		["gold"] = 10,
		["token_basic"] = 5,
	},
})

-- Register lots (price + reward pairs)
token.register_lots({
	["shop_item_1"] = {
		price = "starter_pack_price", -- group id
		reward = "starter_pack", -- group id
	},
})
```
