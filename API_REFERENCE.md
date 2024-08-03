# API Reference

## Table of Contents

- [Token](#token)
- [Functions](#functions)
  - [token.init()](#tokeninit)
  - [token.reset_state()](#tokenreset_state)
  - [token.create_container()](#tokencreate_container)
  - [token.delete_container()](#tokendelete_container)
  - [token.clear_container()](#tokenclear_container)
  - [token.is_container_exist()](#tokenis_container_exist)
  - [token.get()](#tokenget)
  - [token.set()](#tokenset)
  - [token.add()](#tokenadd)
  - [token.pay()](#tokenpay)
  - [token.is_enough()](#tokenis_enough)
  - [token.get_many()](#tokenget_many)
  - [token.set_many()](#tokenset_many)
  - [token.add_many()](#tokenadd_many)
  - [token.pay_many()](#tokenpay_many)
  - [token.is_enough_many()](#tokenis_enough_many)
  - [token.get_token_group()](#tokenget_token_group)
  - [token.add_group()](#tokenadd_group)
  - [token.pay_group()](#tokenpay_group)
  - [token.set_group()](#tokenset_group)
  - [token.is_enough_group()](#tokenis_enough_group)
  - [token.create_restore_config()](#tokencreate_restore_config)
  - [token.set_restore_config()](#tokenset_restore_config)
  - [token.get_restore_config()](#tokenget_restore_config)
  - [token.set_restore_enabled()](#tokenset_restore_enabled)
  - [token.is_restore_enabled()](#tokenis_restore_enabled)
  - [token.remove_restore_config()](#tokenremove_restore_config)
  - [token.get_time_to_restore()](#tokenget_time_to_restore)
  - [token.get_lot_reward()](#tokenget_lot_reward)
  - [token.get_lot_price()](#tokenget_lot_price)
  - [token.add_infinity_time()](#tokenadd_infinity_time)
  - [token.get_infinity_time()](#tokenget_infinity_time)
  - [token.set_infinity_time()](#tokenset_infinity_time)
  - [token.is_infinity_time()](#tokenis_infinity)
  - [token.get_visual()](#tokenget_visual)
  - [token.add_visual()](#tokenadd_visual)
  - [token.sync_visual()](#tokensync_visual)
  - [token.get_total_sum()](#tokenget_total_sum)
  - [token.set_logger()](#tokenset_logger)
- [Events](#events)
  - [token.on_token_change](#tokenon_token_change)
  - [token.on_token_visual_change](#tokenon_token_visual_change)
  - [token.on_token_restore_change](#tokenon_token_restore_change)


## Token

To start using the Token module in your project, you first need to import it. This can be done with the following line of code:

```lua
local token = require("token.token")
```

## Functions

**token.init()**
---
```lua
token.init
```

This function initializes the Token module. It should be called at the beginning of the game to load the configuration file and initialize the Token module. The token state should be loaded before calling this function.

- **Usage Example:**

```lua
-- Default initialization
token.init()

-- Load configuration from a file
token.init("/resources/token_config.json")

-- Load configuration from a table. Each table is optional.
token.init({
	tokens = {
		level = {
			min = 1,
			max = 100,
			default = 1
		},
		money = {
			max = 99999,
		},
		crystal = {
			max = 999,
		}
	},
	groups = {
		reward_1 = {
			money = 100,
			exp = 10
		},
		price_1 = {
			crystal = 5
		}
	},
	lots = {
		shop_item_1 = {
			price = "price_1",
			reward = "reward_1"
		}
	},
	containers = {
		wallet = {
			money = 100,
			level = 1,
			exp = 0,
		}
	}
})
```

**token.reset_state()**
---
```lua
token.reset_state()
```

This function resets the token state. It should be called when you want to reset the token module state to the default values. For example when game in soft reset.

- **Usage Example:**

```lua
token.reset_state()
```

**token.create_container()**
---
```lua
token.create_container(container_id)
```

This function creates a new container with the specified ID. Containers are used to group tokens together. Containers are required to store tokens. If the container already exists, this function will do nothing.

- **Parameters:**
  - `container_id` (string): The ID of the container to create.

- **Return Value:**
  - `true` if the container was created successfully, `false` otherwise.

- **Usage Example:**

```lua
token.create_container("wallet")
token.create_container("drop_container_1")
```

**token.delete_container()**
---
```lua
token.delete_container(container_id)
```

This function deletes the container with the specified ID. If the container does not exist, this function will do nothing.

- **Parameters:**
  - `container_id` (string): The ID of the container to delete.

- **Return Value:**
  - `true` if the container was deleted successfully, `false` otherwise.

- **Usage Example:**

```lua
token.delete_container("wallet")
token.delete_container("drop_container_1")
```

**token.clear_container()**
---
```lua
token.clear_container(container_id)
```

This function clears all tokens in the container with the specified ID. If the container does not exist, this function will do nothing.

- **Parameters:**
  - `container_id` (string): The ID of the container to clear.

- **Usage Example:**

```lua
token.clear_container("wallet")
token.clear_container("drop_container_1")
```

**token.is_container_exist()**
---
```lua
token.is_container_exist(container_id)
```

This function checks if the container with the specified ID exists.

- **Parameters:**
  - `container_id` (string): The ID of the container to check.

- **Return Value:**
  - `true` if the container exists, `false` otherwise.

- **Usage Example:**

```lua
print(token.is_container_exist("wallet")) -- true
print(token.is_container_exist("drop_container_1")) -- false
```

**token.get()**
---
```lua
token.get(container_id, token_id)
```

This function retrieves the amount of a token in the specified container. If the container or token does not exist, this function will return 0. If container is not exist, the error will be logged.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.

- **Return Value:**
  - The amount of the token in the container.

- **Usage Example:**

```lua
local money = token.get("wallet", "money")
print("Money:", money)
```

**token.set()**
---
```lua
token.set(container_id, token_id, amount, [reason])
```

This function sets the amount of a token in the specified container to the specified value.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.
  - `amount` (number): The new amount of the token.
  - `reason` (string | nil): The reason for the change.

- **Return Value:**
  - New amount of the token in the container.

- **Usage Example:**

```lua
token.set("wallet", "money", 100, "quest_reward")
```

**token.add()**
---
```lua
token.add(container_id, token_id, amount, [reason], [visual_later])
```

This function adds the specified amount to the token in the specified container.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.
  - `amount` (number): The amount to add to the token.
  - `reason` (string | nil): The reason for the change.
  - `visual_later` (boolean | nil): Whether to trigger a visual change event later.

- **Return Value:**
  - New amount of the token in the container.

- **Usage Example:**

```lua
token.add("wallet", "money", 100, "quest_reward")
```

**token.pay()**
---
```lua
token.pay(container_id, token_id, amount, [reason], [visual_later])
```

This function subtracts the specified amount from the token in the specified container.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.
  - `amount` (number): The amount to subtract from the token.
  - `reason` (string | nil): The reason for the change.
  - `visual_later` (boolean | nil): Whether to trigger a visual change event later.

- **Return Value:**
  - New amount of the token in the container.

- **Usage Example:**

```lua
token.pay("wallet", "money", 50, "buy_item")
```

**token.is_enough()**
---
```lua
token.is_enough(container_id, token_id, amount)
```

This function checks if the specified container has enough of the specified token.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.
  - `amount` (number): The amount to check.

- **Return Value:**
  - `true` if the container has enough of the token, `false` otherwise.

- **Usage Example:**

```lua
if token.is_enough("wallet", "money", 50) then
	print("You have enough money to buy the item.")
else
	print("You don't have enough money to buy the item.")
end
```

**token.get_many()**
---
```lua
token.get_many(container_id)
```

This function retrieves the amounts of all tokens in the specified container.

- **Parameters:**
  - `container_id` (string): The ID of the container.

- **Return Value:**
  - A table containing the amounts of all tokens in the container.

- **Usage Example:**

```lua
local tokens = token.get_many("wallet")
for token_id, amount in pairs(tokens) do
	print(token_id, amount)
end
```

**token.set_many()**
---
```lua
token.set_many(container_id, tokens, [reason], [visual_later])
```

This function sets the amounts of multiple tokens in the specified container to the specified values.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `tokens` (table): A table containing the token IDs as keys and the amounts as values.
  - `reason` (string | nil): The reason for the change.
  - `visual_later` (boolean | nil): Whether to trigger a visual change event later.

- **Usage Example:**

```lua
token.set_many("wallet", {
	money = 100,
	exp = 10
}, "quest_reward")
```

**token.add_many()**
---
```lua
token.add_many(container_id, tokens, [reason], [visual_later])
```

This function adds the specified amounts to the tokens in the specified container.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `tokens` (table): A table containing the token IDs as keys and the amounts to add as values.
  - `reason` (string | nil): The reason for the change.
  - `visual_later` (boolean | nil): Whether to trigger a visual change event later.

- **Usage Example:**

```lua
token.add_many("wallet", {
	money = 100,
	exp = 10
}, "quest_reward")
```

**token.pay_many()**
---
```lua
token.pay_many(container_id, tokens, [reason], [visual_later])
```

This function subtracts the specified amounts from the tokens in the specified container.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `tokens` (table): A table containing the
  - `reason` (string | nil): The reason for the change.
  - `visual_later` (boolean | nil): Whether to trigger a visual change event later.

- **Return Value:**
  - `true` if the container has enough of all the tokens, `false` otherwise.

- **Usage Example:**

```lua
if token.pay_many("wallet", {
	money = 50,
	exp = 5
}, "buy_item") then
	print("You have enough money and experience to buy the item.")
else
	print("You don't have enough money or experience to buy the item.")
end
```

**token.is_enough_many()**
---
```lua
token.is_enough_many(container_id, tokens)
```

This function checks if the specified container has enough of all the specified tokens.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `tokens` (table): A table containing the token IDs as keys and the amounts to check as values.

- **Return Value:**
  - `true` if the container has enough of all the tokens, `false` otherwise.

- **Usage Example:**

```lua
if token.is_enough_many("wallet", {
	money = 50,
	exp = 5
}) then
	print("You have enough money and experience to buy the item.")
else
	print("You don't have enough money or experience to buy the item.")
end
```

**token.get_token_group()**
---
```lua
token.get_token_group(token_group_id)
```

This function retrieves the tokens in the specified group.

- **Parameters:**
  - `token_group_id` (string): The ID of the group.

- **Return Value:**
  - A table containing the token IDs as keys and the amounts as values.

- **Usage Example:**

```lua
local reward = token.get_token_group("reward_1")
for token_id, amount in pairs(reward) do
	print(token_id, amount)
end
```

**token.add_group()**
---
```lua
token.add_group(container_id, token_group_id, [reason], [visual_later])
```

This function adds the tokens in the specified group to the specified container.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_group_id` (string): The ID of the group.
  - `reason` (string | nil): The reason for the change.
  - `visual_later` (boolean | nil): Whether to trigger a visual change event later.

- **Usage Example:**

```lua
token.add_group("wallet", "reward_1", "quest_reward")
```

**token.set_group()**
---
```lua
token.set_group(container_id, token_group_id, [reason], [visual_later])
```

This function sets the tokens in the specified group to the specified container. All the tokens in the group will be set to the container. All other tokens in the container will be removed.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_group_id` (string): The ID of the group.
  - `reason` (string | nil): The reason for the change.
  - `visual_later` (boolean | nil): Whether to trigger a visual change event later.

- **Usage Example:**

```lua
token.set_group("wallet", "reward_1", "quest_reward")
```


**token.pay_group()**
---
```lua
token.pay_group(container_id, token_group_id, [reason], [visual_later])
```

This function subtracts the tokens in the specified group from the specified container.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_group_id` (string): The ID of the group.
  - `reason` (string | nil): The reason for the change.
  - `visual_later` (boolean | nil): Whether to trigger a visual change event later.

- **Return Value:**
  - `true` if the container has enough of all the tokens in the group, `false` otherwise.

- **Usage Example:**

```lua
if token.pay_group("wallet", "reward_1", "buy_item") then
	print("You have enough money and experience to buy the item.")
else
	print("You don't have enough money or experience to buy the item.")
end
```

**token.is_enough_group()**
---
```lua
token.is_enough_group(container_id, token_group_id)
```

This function checks if the specified container has enough of all the tokens in the specified group.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_group_id` (string): The ID of the group.

- **Return Value:**
  - `true` if the container has enough of all the tokens in the group, `false` otherwise.

- **Usage Example:**

```lua
if token.is_enough_group("wallet", "reward_1") then
	print("You have enough money and experience to buy the item.")
else
	print("You don't have enough money or experience to buy the item.")
end
```

**token.create_restore_config()**
---
```lua
token.create_restore_config()
```

This function creates a new restore configuration. The restore configuration is used to automatically restore tokens over time.

- **Usage Example:**

```lua
token.create_restore_config()
```

**token.set_restore_config()**
---
```lua
token.set_restore_config(container_id, token_id, config)
```

This function sets the restore configuration for the specified token in the specified container.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.
  - `config` (table): A table containing the restore configuration. The table should have the following keys:
    - `interval` (number): The time interval in seconds between each restore.
    - `amount` (number): The amount to restore each interval.

- **Usage Example:**

```lua
token.set_restore_config("wallet", "money", {interval = 60, amount = 10})
```

**token.is_restore_enabled()**
---
```lua
token.is_restore_enabled(container_id, token_id)
```

This function checks if the restore functionality is enabled for the specified token in the specified container.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.

- **Return Value:**
  - `true` if the restore functionality is enabled, `false` otherwise.

- **Usage Example:**

```lua
if token.is_restore_enabled("wallet", "money") then
	print("Restore is enabled for money.")
else
	print("Restore is disabled for money.")
end
```


**token.get_restore_config()**
---
```lua
token.get_restore_config(container_id, token_id)
```

This function retrieves the restore configuration for the specified token in the specified container.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.

- **Return Value:**
  - A table containing the restore configuration.

- **Usage Example:**

```lua
local restore_config = token.get_restore_config("wallet", "money")
print("Restore config:", restore_config)
```

**token.set_restore_enabled()**
---
```lua
token.set_restore_enabled(container_id, token_id, is_enabled)
```

This function enables or disables the restore functionality for the specified token in the specified container.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.
  - `is_enabled` (boolean): `true` to enable restore, `false` to disable restore.

- **Usage Example:**

```lua
token.set_restore_enabled("wallet", "money", true)
```

**token.remove_restore_config()**
---
```lua
token.remove_restore_config(container_id, token_id)
```

This function removes the restore configuration for the specified token in the specified container.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.

- **Usage Example:**

```lua
token.remove_restore_config("wallet", "money")
```

**token.get_time_to_restore()**
---
```lua
token.get_time_to_restore(container_id, token_id)
```

This function retrieves the time remaining until the next restore for the specified token in the specified container.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.

- **Return Value:**
  - The time remaining until the next restore in seconds.

- **Usage Example:**

```lua
local time_to_restore = token.get_time_to_restore("wallet", "money")
print("Time to restore:", time_to_restore)
```

**token.get_lot_reward()**
---
```lua
token.get_lot_reward(lot_id)
```

This function retrieves the reward tokens for the specified lot.

- **Parameters:**
  - `lot_id` (string): The ID of the lot.

- **Return Value:**
  - A table containing the token IDs as keys and the amounts as values.

- **Usage Example:**

```lua
local reward = token.get_lot_reward("shop_item_1")
for token_id, amount in pairs(reward) do
	print(token_id, amount)
end
```

**token.get_lot_price()**
---
```lua
token.get_lot_price(lot_id)
```

This function retrieves the price tokens for the specified lot.

- **Parameters:**
  - `lot_id` (string): The ID of the lot.

- **Return Value:**
  - A table containing the token IDs as keys and the amounts as values.

- **Usage Example:**

```lua
local price = token.get_lot_price("shop_item_1")

for token_id, amount in pairs(price) do
	print(token_id, amount)
end
```

**token.add_infinity_time()**
---
```lua
token.add_infinity_time(container_id, token_id, seconds)
```

This function adds time to the infinity setting for the specified token in the specified container.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.
  - `seconds` (number): The time in seconds to add to the infinity setting.

- **Usage Example:**

```lua
token.add_infinity_time("wallet", "money", 60)
```

**token.get_infinity_time()**
---
```lua
token.get_infinity_time(container_id, token_id)
```

This function retrieves the remaining time for the infinity setting for the specified token in the specified container.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.

- **Return Value:**
  - The remaining time in seconds for the infinity setting.

- **Usage Example:**

```lua
local time = token.get_infinity_time("wallet", "money")
print("Infinity time:", time)
```

**token.set_infinity_time()**
---
```lua
token.set_infinity_time(container_id, token_id, seconds)
```

This function sets the infinity setting for the specified token in the specified container to the specified time.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.
  - `seconds` (number): The time in seconds for the infinity setting.

- **Usage Example:**

```lua
token.set_infinity_time("wallet", "money", 60)
```

**token.is_infinity_time()**
---
```lua
token.is_infinity_time(container_id, token_id)
```

This function checks if the specified token in the specified container is set to infinity.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.

- **Return Value:**
  - `true` if the token is set to infinity, `false` otherwise.

- **Usage Example:**

```lua
if token.is_infinity_time("wallet", "money") then
	print("Money is set to infinity.")
else
	print("Money is not set to infinity.")
end
```


**token.get_visual()**
---
```lua
token.get_visual(container_id, token_id)
```

This function retrieves the visual amount of the token in the specified container. The visual amount is used for UI updates.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.

- **Return Value:**
  - The visual amount of the token in the container.

- **Usage Example:**

```lua
local visual_money = token.get_visual("wallet", "money")
print("Visual Money:", visual_money)
```

**token.add_visual()**
---
```lua
token.add_visual(container_id, token_id, amount)
```

This function adds the specified amount to the visual amount of the token in the specified container. The visual amount is used for UI updates.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.
  - `amount` (number): The amount to add to the visual amount.

- **Usage Example:**

```lua
token.add_visual("wallet", "money", 100)
```

**token.sync_visual()**
---
```lua
token.sync_visual(container_id, token_id)
```

This function synchronizes the visual amount of the token in the specified container with the actual amount. This function should be called after the UI has been updated.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.

- **Usage Example:**

```lua
token.sync_visual("wallet", "money")
```

**token.get_total_sum()**
---
```lua
token.get_total_sum(container_id, token_id)
```

This function retrieves the total sum of the token in the specified container. The total sum is the sum of all tokens acquired in the container.

- **Parameters:**
  - `container_id` (string): The ID of the container.
  - `token_id` (string): The ID of the token.

- **Return Value:**
  - The total sum of the token in the container.

- **Usage Example:**

```lua
local total_money = token.get_total_sum("wallet", "money")
print("Total Money:", total_money)
```

**token.set_logger**
---
Customize the logging mechanism used by **token Runtime**. You can use **Defold Log** library or provide a custom logger.

```lua
token.set_logger(logger_instance)
```

- **Parameters:**
  - `logger_instance`: A logger object that follows the specified logging interface, including methods for `trace`, `debug`, `info`, `warn`, `error`. Pass `nil` to remove the default logger.

- **Usage Example:**

Using the [Defold Log](https://github.com/Insality/defold-log) module:
```lua
local log = require("log.log")
local token = require("token.token")

token.set_logger(log.get_logger("token"))
```

Creating a custom user logger:
```lua
local logger = {
    trace = function(_, message, context) end,
    debug = function(_, message, context) end,
    info = function(_, message, context) end,
    warn = function(_, message, context) end,
    error = function(_, message, context) end
}
token.set_logger(logger)
```

Remove the default logger:
```lua
token.set_logger(nil)
```




## Events

**token.on_token_change**
---
```lua
token.on_token_change:subscribe(function(container_id, token_id, amount, [reason])
	-- Your code here
end)
```

This event is triggered when the token amount changes. It provides the container ID, token ID, amount, and reason for the change.

- **Usage Example:**

```lua
token.on_token_change:subscribe(function(container_id, token_id, amount, reason)
	print("Token change event:", container_id, token_id, amount, reason)
end)

token.add("wallet", "money", 100, "quest_reward")
```

**token.on_token_visual_change**
---
```lua
token.on_token_visual_change:subscribe(function(container_id, token_id, amount)
	-- Your code here
end)
```

This event is triggered when the visual token amount changes. It provides the container ID, token ID, and amount. Visual changes are used for UI updates.

- **Usage Example:**

```lua
token.on_token_visual_change:subscribe(function(container_id, token_id, amount)
	print("Token visual change event:", container_id, token_id, amount)
end)

token.add("wallet", "money", 100, "quest_reward", true)
```

**token.on_token_restore_change**
---
```lua
token.on_token_restore_change:subscribe(function(container_id, token_id, restore_config)
	-- Your code here
end)
```

This event is triggered when the token restore configuration changes. It provides the container ID, token ID, and the restore configuration.

- **Usage Example:**

```lua
token.on_token_restore_change:subscribe(function(container_id, token_id, restore_config)
	print("Token restore change event:", container_id, token_id, restore_config)
end)

token.set_restore_config("wallet", "money", {interval = 60, amount = 10})
```