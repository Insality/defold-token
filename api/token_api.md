# token API

> at /token/token.lua

The Defold Token module.
Used to manage all countable items in the game.

## Functions

- [reset_state](#reset_state)
- [set_logger](#set_logger)
- [get_time](#get_time)
- [is_container_exist](#is_container_exist)
- [create_container](#create_container)
- [delete_container](#delete_container)
- [clear_container](#clear_container)
- [set_restore_config](#set_restore_config)
- [get_restore_config](#get_restore_config)
- [set_restore_config_enabled](#set_restore_config_enabled)
- [is_restore_config_enabled](#is_restore_config_enabled)
- [remove_restore_config](#remove_restore_config)
- [get_token_group](#get_token_group)
- [get_lot_reward](#get_lot_reward)
- [get_lot_price](#get_lot_price)
- [add](#add)
- [add_many](#add_many)
- [set_many](#set_many)
- [add_group](#add_group)
- [set_group](#set_group)
- [pay_group](#pay_group)
- [set](#set)
- [get](#get)
- [get_many](#get_many)
- [pay](#pay)
- [pay_many](#pay_many)
- [is_enough](#is_enough)
- [is_empty](#is_empty)
- [is_max](#is_max)
- [is_enough_many](#is_enough_many)
- [is_enough_group](#is_enough_group)
- [add_infinity_time](#add_infinity_time)
- [is_infinity](#is_infinity)
- [get_infinity_time](#get_infinity_time)
- [set_infinity_time](#set_infinity_time)
- [get_time_to_restore](#get_time_to_restore)
- [sync_visual](#sync_visual)
- [add_visual](#add_visual)
- [get_visual](#get_visual)
- [get_total_sum](#get_total_sum)
- [init](#init)
- [register_tokens](#register_tokens)
- [register_token_groups](#register_token_groups)
- [register_lots](#register_lots)
- [load_token_state](#load_token_state)
- [start_update](#start_update)
- [update](#update)

## Fields

- [state](#state)
- [on_token_change](#on_token_change)
- [on_token_visual_change](#on_token_visual_change)
- [on_token_restore_change](#on_token_restore_change)
- [runtime](#runtime)
- [UPDATE_DELAY](#UPDATE_DELAY)



### reset_state

---
```lua
token.reset_state()
```

Call this to reset state to default

### set_logger

---
```lua
token.set_logger([logger_instance])
```

Customize the logging mechanism used by Token Module. You can use **Defold Log** library or provide a custom logger.

- **Parameters:**
	- `[logger_instance]` *(table|token.logger|nil)*: Logger interface

### get_time

---
```lua
token.get_time()
```

Inner function to get current time
Override it to use custom time

- **Returns:**
	- `Current` *(number)*: time in seconds

### is_container_exist

---
```lua
token.is_container_exist(container_id)
```

Check if token container exists in the system

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container

- **Returns:**
	- `is_exist` *(boolean)*: True if container exists, false otherwise

### create_container

---
```lua
token.create_container(container_id)
```

Create a new token container if it doesn't already exist

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the new container

- **Returns:**
	- `True` *(boolean)*: if container was successfully created, false if it already exists

### delete_container

---
```lua
token.delete_container(container_id)
```

Delete an existing token container and all associated tokens

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container to delete

### clear_container

---
```lua
token.clear_container(container_id)
```

Clear all tokens from a container but keep the container itself

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container to clear

### set_restore_config

---
```lua
token.set_restore_config(container_id, token_id, config)
```

Configure automatic token restoration over time

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token
	- `config` *(token.token_restore_param)*: Configuration for token restoration {timer: seconds between restores, value: amount to restore each time, max: optional maximum to restore}

- **Returns:**
	- `` *(nil)*:

### get_restore_config

---
```lua
token.get_restore_config(container_id, token_id)
```

Get the current restoration configuration for a token

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token

- **Returns:**
	- `The` *(token.token_restore_config|nil)*: restoration configuration or nil if not set

### set_restore_config_enabled

---
```lua
token.set_restore_config_enabled(container_id, token_id, is_enabled)
```

Enable or disable token restoration for a specific token

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token
	- `is_enabled` *(boolean)*: Whether restoration should be enabled

- **Returns:**
	- `` *(nil)*:

### is_restore_config_enabled

---
```lua
token.is_restore_config_enabled(container_id, token_id)
```

Check if token restoration is enabled for a specific token

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token

- **Returns:**
	- `True` *(boolean|nil)*: if enabled, false if disabled, nil if no config exists

### remove_restore_config

---
```lua
token.remove_restore_config(container_id, token_id)
```

Remove the restoration configuration for a token

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token

- **Returns:**
	- `True` *(boolean)*: if config was removed, false if it didn't exist

### get_token_group

---
```lua
token.get_token_group(token_group_id)
```

Get a token group by its identifier

- **Parameters:**
	- `token_group_id` *(string)*: The unique identifier for the token group

- **Returns:**
	- `Table` *(table<string, number>|nil)*: mapping token IDs to amounts, or nil if group doesn't exist

### get_lot_reward

---
```lua
token.get_lot_reward(lot_id)
```

Get the reward tokens for a specific lot

- **Parameters:**
	- `lot_id` *(string)*: The unique identifier for the lot

- **Returns:**
	- `Table` *(table<string, number>|nil)*: mapping token IDs to amounts, or nil if lot doesn't exist

### get_lot_price

---
```lua
token.get_lot_price(lot_id)
```

Get the price tokens for a specific lot

- **Parameters:**
	- `lot_id` *(string)*: The unique identifier for the lot

- **Returns:**
	- `Table` *(table<string, number>|nil)*: mapping token IDs to amounts, or nil if lot doesn't exist

### add

---
```lua
token.add(container_id, token_id, amount, [reason], [visual_later])
```

Add tokens to a container

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token
	- `amount` *(number)*: Amount of tokens to add
	- `[reason]` *(string|nil)*: Optional reason for logging/tracking
	- `[visual_later]` *(boolean|nil)*: If true, visual update will be delayed

- **Returns:**
	- `New` *(number)*: token amount after addition

### add_many

---
```lua
token.add_many(container_id, [tokens], [reason], [visual_later])
```

Add multiple tokens to a container

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `[tokens]` *(table<string, number>|nil)*: Table mapping token IDs to amounts
	- `[reason]` *(string|nil)*: Optional reason for logging/tracking
	- `[visual_later]` *(boolean|nil)*: If true, visual update will be delayed

### set_many

---
```lua
token.set_many(container_id, [tokens], [reason], [visual_later])
```

Set the amount of multiple tokens in a container

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `[tokens]` *(table<string, number>|nil)*: Table mapping token IDs to new amounts
	- `[reason]` *(string|nil)*: Optional reason for logging/tracking
	- `[visual_later]` *(boolean|nil)*: If true, visual update will be delayed

### add_group

---
```lua
token.add_group(container_id, token_group_id, [reason], [visual_later])
```

Add tokens from a token group to a container

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_group_id` *(string)*: The unique identifier for the token group
	- `[reason]` *(string|nil)*: Optional reason for logging/tracking
	- `[visual_later]` *(boolean|nil)*: If true, visual update will be delayed

### set_group

---
```lua
token.set_group(container_id, token_group_id, [reason], [visual_later])
```

Set tokens in a container to match a token group

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_group_id` *(string)*: The unique identifier for the token group
	- `[reason]` *(string|nil)*: Optional reason for logging/tracking
	- `[visual_later]` *(boolean|nil)*: If true, visual update will be delayed

### pay_group

---
```lua
token.pay_group(container_id, token_group_id, [reason])
```

Pay tokens from a container using a token group as the cost

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_group_id` *(string)*: The unique identifier for the token group
	- `[reason]` *(string|nil)*: Optional reason for logging/tracking

- **Returns:**
	- `True` *(boolean)*: if payment was successful, false otherwise

### set

---
```lua
token.set(container_id, token_id, amount, [reason], [visual_later])
```

Set a token amount in a container

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token
	- `amount` *(number)*: New amount for the token
	- `[reason]` *(string|nil)*: Optional reason for logging/tracking
	- `[visual_later]` *(boolean|nil)*: If true, visual update will be delayed

- **Returns:**
	- `New` *(number)*: token amount

### get

---
```lua
token.get(container_id, token_id, [default_value])
```

Get the current amount of a token in a container

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token
	- `[default_value]` *(any)*: Value to return if the container or token doesn't exist

- **Returns:**
	- `Current` *(any)*: token amount or default_value if not found

### get_many

---
```lua
token.get_many(container_id)
```

Get all tokens from a container

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container

- **Returns:**
	- `Table` *(table<string, number>|nil)*: mapping token IDs to amounts, or nil if container doesn't exist

### pay

---
```lua
token.pay(container_id, token_id, amount, [reason], [visual_later])
```

Pay a specific amount of tokens from a container

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token
	- `amount` *(number)*: Amount to pay/subtract
	- `[reason]` *(string|nil)*: Optional reason for logging/tracking
	- `[visual_later]` *(boolean|nil)*: If true, visual update will be delayed

- **Returns:**
	- `True` *(boolean)*: if payment was successful, false if not enough tokens

### pay_many

---
```lua
token.pay_many(container_id, tokens, [reason], [visual_later])
```

Pay multiple tokens from a container

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `tokens` *(table<string, number>)*: Table mapping token IDs to amounts to pay
	- `[reason]` *(string|nil)*: Optional reason for logging/tracking
	- `[visual_later]` *(boolean|nil)*: If true, visual update will be delayed

- **Returns:**
	- `True` *(boolean)*: if all payments were successful, false otherwise

### is_enough

---
```lua
token.is_enough(container_id, token_id, amount)
```

Check if there are enough tokens to pay a specific amount

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token
	- `amount` *(number)*: Amount to check for

- **Returns:**
	- `True` *(boolean)*: if enough tokens are available, false otherwise

### is_empty

---
```lua
token.is_empty(container_id, token_id)
```

Check if a token has zero amount

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token

- **Returns:**
	- `True` *(boolean)*: if token amount is zero, false otherwise

### is_max

---
```lua
token.is_max(container_id, token_id)
```

Check if a token is at its maximum allowed amount

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token

- **Returns:**
	- `True` *(boolean)*: if token is at maximum, false otherwise

### is_enough_many

---
```lua
token.is_enough_many(container_id, [tokens])
```

Check if there are enough tokens to pay multiple costs

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `[tokens]` *(table<string, number>|nil)*: Table mapping token IDs to amounts to check

- **Returns:**
	- `True` *(boolean)*: if enough of all tokens are available, false otherwise

### is_enough_group

---
```lua
token.is_enough_group(container_id, token_group_id)
```

Check if there are enough tokens to pay for a token group

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_group_id` *(string)*: The unique identifier for the token group

- **Returns:**
	- `True` *(boolean)*: if enough of all tokens in group are available, false otherwise

### add_infinity_time

---
```lua
token.add_infinity_time(container_id, token_id, seconds)
```

Add time to a token's infinity state (where it can be spent without limit)

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token
	- `seconds` *(number)*: Number of seconds to add to infinity time

### is_infinity

---
```lua
token.is_infinity(container_id, token_id)
```

Check if a token is currently in infinity state

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token

- **Returns:**
	- `True` *(boolean)*: if token is in infinity state, false otherwise

### get_infinity_time

---
```lua
token.get_infinity_time(container_id, token_id)
```

Get remaining time in seconds for a token's infinity state

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token

- **Returns:**
	- `Seconds` *(number)*: remaining in infinity state, 0 if not in infinity state

### set_infinity_time

---
```lua
token.set_infinity_time(container_id, token_id, time)
```

Set the time for a token's infinity state

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token
	- `time` *(number)*: End time for infinity state in seconds

### get_time_to_restore

---
```lua
token.get_time_to_restore(container_id, token_id)
```

Get time remaining until next automatic token restore

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token

- **Returns:**
	- `Seconds` *(number|nil)*: until next restore, or nil if no restore config

### sync_visual

---
```lua
token.sync_visual(container_id, token_id)
```

Reset visual debt of tokens to match actual value

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token

- **Returns:**
	- `` *(number)*:

### add_visual

---
```lua
token.add_visual(container_id, token_id, amount)
```

Add visual debt to a token (for animations, etc.)

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token
	- `amount` *(number)*: Amount to add to visual counter

- **Returns:**
	- `` *(number)*:

### get_visual

---
```lua
token.get_visual(container_id, token_id)
```

Get current visual amount of a token (including debt)

- **Parameters:**
	- `container_id` *(string)*: The unique identifier for the container
	- `token_id` *(string)*: The unique identifier for the token

- **Returns:**
	- `Visual` *(number)*: amount of the token (never negative)

### get_total_sum

---
```lua
token.get_total_sum(container_id, token_id)
```

Get the total accumulated amount of a specific token

- **Parameters:**
	- `container_id` *(string)*: Container id
	- `token_id` *(string)*: Token id

- **Returns:**
	- `The` *(number)*: total amount of tokens ever acquired (regardless of spending)

### init

---
```lua
token.init([token_config_or_path])
```

Initialize the token system with configuration

- **Parameters:**
	- `[token_config_or_path]` *(string|token.config|nil)*: Lua table or path to token config. Example: "/resources/tokens.json"

### register_tokens

---
```lua
token.register_tokens(tokens)
```

Register tokens in the token system

- **Parameters:**
	- `tokens` *(table<string, token.token_config_data>)*: Table mapping token IDs to token config data

### register_token_groups

---
```lua
token.register_token_groups(groups)
```

Register token groups in the token system

- **Parameters:**
	- `groups` *(table<string, table<string, number>>)*: Table mapping group IDs to token IDs and amounts

### register_lots

---
```lua
token.register_lots(lots)
```

Register lots in the token system

- **Parameters:**
	- `lots` *(table<string, token.lot>)*: Table mapping lot IDs to lot config

### load_token_state

---
```lua
token.load_token_state()
```

Load all current tokens into token wrappers

### start_update

---
```lua
token.start_update()
```

Start periodic updates for token restore timers

### update

---
```lua
token.update()
```

Update all tokens restore timers


## Fields
<a name="state"></a>
- **state** (_nil_): Persisted data of token module

<a name="on_token_change"></a>
- **on_token_change** (_unknown_): Triggers when token amount was changed

<a name="on_token_visual_change"></a>
- **on_token_visual_change** (_unknown_): Triggers when token visual amount was changed

<a name="on_token_restore_change"></a>
- **on_token_restore_change** (_unknown_): Triggers when token restore config was changed

<a name="runtime"></a>
- **runtime** (_table_)

<a name="UPDATE_DELAY"></a>
- **UPDATE_DELAY** (_number_)

