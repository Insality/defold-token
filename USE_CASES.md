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

## Example: Wallet Container

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


## Events and subscribing

There are **container events** (on a specific container) and **global events** (on `token`). This section focuses on container events; use them to refresh UI, play effects, or log changes for one container (e.g. the wallet).

Container events (e.g. for `wallet = token.container("wallet")`):

- `wallet.on_token_change` — when the actual token amount changes. Callback: `(token_id, amount, reason)`
- `wallet.on_token_visual_change` — when the displayed (visual) amount changes. Callback: `(token_id, amount)`
- `wallet.on_token_restore_change` — when restore config for a token changes. Callback: `(token_id, config)`

Example: update the gold label when the wallet’s gold changes:

```lua
local token = require("token.token")
local wallet = token.container("wallet")

wallet.on_token_change:subscribe(function(token_id, amount, reason)
	if token_id == "gold" then
		update_gold_label(amount)
	end
end)

wallet:add("gold", 100, "reward")
-- Callback runs with token_id "gold", amount 100, reason "reward"
```

Global events also exist if you need to react to changes in any container:

- `token.on_token_change` — callback `(container_id, token_id, amount, reason)`
- `token.on_token_visual_change` — callback `(container_id, token_id, amount)`
- `token.on_token_restore_change` — callback `(container_id, token_id, config)`

Use container events when you care only about one container (e.g. the wallet); use global events when you listen to multiple containers.


## Visual value and sync

Token amounts can be split into “real” value (saved, used for logic) and “visual” value (what you show). The visual value can lag behind (e.g. animate from 100 → 150). Use `add_visual` to drive the displayed value; use `sync_visual` only when you want to snap visual to real without firing visual events (e.g. UI restart).

- `container:get(token_id)` - real amount
- `container:get_visual(token_id)` - value to display (real amount minus visual debt)
- `container:add(token_id, amount, reason, visual_later)` - pass `true` as fourth argument to change real value but not visual (adds “visual debt”)
- `container:add_visual(token_id, delta)` - change only what is shown (positive = show more, negative = show less). Fires `on_token_visual_change`.
- `container:sync_visual(token_id)` - make visual equal to real (clears visual debt); returns the delta that was synced. Use for UI restart or when you want to snap the display to the real value in one go (e.g. no incremental animation).

Example: grant 50 gold, animate the counter from current to +50 using `add_visual`, and subscribe to the wallet’s visual changes:

```lua
local token = require("token.token")
local wallet = token.container("wallet")

wallet.on_token_visual_change:subscribe(function(token_id, amount)
	if token_id == "gold" then
		animate_gold_label_to(amount)
	end
end)

-- Real amount increased by 50, visual unchanged (e.g. still 100)
wallet:add("gold", 50, "quest", true)

-- For example you have a particle system, which animate flying tokens to the gold panel
-- And you can increase a visual amount each time the particle system fly in the panel
token_particles:animate("gold", 50, function(amount)
	wallet:add_visual("gold", amount)
end)
```

Example: on UI restart, snap the displayed value to the real value:

```lua
local wallet = token.container("wallet")

function on_wallet_ui_show()
	wallet:sync_visual("gold")
	wallet:sync_visual("gems")
	set_label("gold", wallet:get_visual("gold"))
	set_label("gems", wallet:get_visual("gems"))
end
```


## Token config groups

Token configs (default, min, max) can be registered per **config group**. A container gets its configs from a specific group. So the same token id (e.g. `"money"`) can have different defaults and limits depending on whether the container uses a group or the default group.

Lookup order: container’s config group → `"default"` group → empty config.

Example: register `"money"` with default 100 only for the `"user_wallet"` group. A wallet created with that group starts with 100 money; a container with no group (default) has no config for `"money"` (empty config, default 0):

```lua
local token = require("token.token")

token.register_tokens({
	["money"] = { default = 100, min = 0, max = 99999 }
}, "user_wallet")

local wallet = token.container("wallet", "user_wallet")
local other = token.container("other")

wallet:get("money")
-- 100 (from "user_wallet" group)

other:get("money")
-- 0 (no config in default group; token created with empty config)
```

When creating a container, pass the config group as the second argument: `token.container(container_id, config_group)`. If omitted, the container uses the `"default"` group. When calling `token.init(tokens_config_or_path, config_group)`, the given config is registered into that group (defaults to `"default"`).


## Token Groups and Lots

Token Groups - is a collections of tokens to be managed together. For example, a reward from a quest or chest.

Token Lots - is a pair of token groups, one for the price and one for the reward. For example, a shop item.

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

Now you can use these groups and lots in your code like this:

```lua
local token = require("token.token")

local starter_pack_price = token.get_token_group("starter_pack_price")
local starter_pack = token.get_token_group("starter_pack")
local daily_reward = token.get_token_group("daily_reward")

local shop_item_1 = token.get_lot_price("shop_item_1")
local shop_item_1_reward = token.get_lot_reward("shop_item_1")

local wallet = token.container("wallet")
wallet:add_group("starter_pack_price", "purchase")
wallet:add_group("starter_pack", "purchase")
wallet:add_group("daily_reward", "daily_reward")

wallet:pay_many(shop_item_1, "purchase")
wallet:add_many(shop_item_1_reward, "purchase")
```


## Token Restore Config

You can set a restore config for a token to restore it after a certain amount of time.

Config structure:
```lua
---@class token.token_restore_param
---@field timer number Timer in seconds for restore
---@field value number|nil Value for restore per timer. Default is 1
---@field max number|nil Max accumulated value for restore while offline. Nil means no limit
```

Example:

```lua
local token = require("token.token")
local wallet = token.container("wallet")

wallet:set_restore_config("lives", {
	timer = 60, -- In 60 seconds we will restore 1 life
	value = 1, -- We will restore 1 life per 60 seconds
	max = 3, -- We will restore maximum 3 lives while offline
})

wallet:set_restore_config_enabled("lives", false) -- You can disable restore for a token
wallet:is_restore_config_enabled("lives") -- You can check if restore is enabled for a token
wallet:get_time_to_restore("lives") -- You can get time remaining until next restore for UI
```


## Token Infinity Config

You can set a infinity timer usage for a token to allow to spend tokens without limit.

Example:

```lua
local token = require("token.token")
local wallet = token.container("wallet")

wallet:add_infinity_time("lives", 60) -- You can add 60 seconds to the infinity timer
wallet:is_infinity("lives") -- You can check if the token is in infinity state
wallet:get_infinity_time("lives") -- You can get time remaining until next infinity for UI
wallet:set_infinity_time("lives", 60) -- You can set the time for the infinity timer
```


## Example: Player stats container

We can use tokens not only for a items, but also for a other numeric values like player stats.

For example we can use tokens to store player stats like health, mana, stamina, etc.

```lua
local token = require("token.token")
local player = token.container("player")

player:set("health", 100)
player:set("crit_chance", 0.05)
player:set("crit_damage", 1.5)

player:get("health") -- Returns 100
player:get("crit_chance") -- Returns 0.05
player:get("crit_damage") -- Returns 1.5
```
