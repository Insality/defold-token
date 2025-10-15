# token API

> at token/token.lua

The Defold Token module.
Used to manage all countable items in the game.

## Functions

- [reset_state](#reset_state)
- [set_logger](#set_logger)
- [create_container](#create_container)
- [get_container](#get_container)
- [delete_container](#delete_container)
- [clear_container](#clear_container)
- [is_container_exist](#is_container_exist)
- [load_config](#load_config)
- [register_tokens](#register_tokens)
- [register_token_groups](#register_token_groups)
- [register_lots](#register_lots)
- [get_token_group](#get_token_group)
- [get_lot_reward](#get_lot_reward)
- [get_lot_price](#get_lot_price)
- [get_token_config](#get_token_config)
- [init](#init)
- [render_properties_panel](#render_properties_panel)

## Fields

- [state](#state)
- [on_token_change](#on_token_change)
- [on_token_visual_change](#on_token_visual_change)
- [on_token_restore_change](#on_token_restore_change)
- [containers](#containers)



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
	- `[logger_instance]` *(table|token.logger|nil)*:

### create_container

---
```lua
token.create_container(container_id, [config_group])
```

Create or get a container

- **Parameters:**
	- `container_id` *(string)*: Unique identifier for the container
	- `[config_group]` *(string|nil)*: Optional configuration group

- **Returns:**
	- `Container` *(token.container)*: instance

### get_container

---
```lua
token.get_container(container_id)
```

Get an existing container

- **Parameters:**
	- `container_id` *(string)*: Unique identifier for the container

- **Returns:**
	- `Container` *(token.container|nil)*: instance or nil if doesn't exist

### delete_container

---
```lua
token.delete_container(container_id)
```

Delete a container and all its tokens

- **Parameters:**
	- `container_id` *(string)*: Unique identifier for the container

### clear_container

---
```lua
token.clear_container(container_id)
```

Clear all tokens from a container but keep the container

- **Parameters:**
	- `container_id` *(string)*: Unique identifier for the container

### is_container_exist

---
```lua
token.is_container_exist(container_id)
```

Check if container exists

- **Parameters:**
	- `container_id` *(string)*:

- **Returns:**
	- `` *(boolean)*:

### load_config

---
```lua
token.load_config(config_or_path)
```

Load configuration from a table

- **Parameters:**
	- `config_or_path` *(string|table)*: Configuration table or JSON path

### register_tokens

---
```lua
token.register_tokens(tokens, [config_group])
```

Register tokens in the token system

- **Parameters:**
	- `tokens` *(table<string, token.token_config_data>)*: Table mapping token IDs to token config data
	- `[config_group]` *(string|nil)*: Optional config group (defaults to "default")

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

### get_token_config

---
```lua
token.get_token_config(token_id)
```

Get token configuration

- **Parameters:**
	- `token_id` *(string)*: The unique identifier for the token

- **Returns:**
	- `config` *(token.token_config_data|nil)*: The token config, or nil if the token doesn't exist

### init

---
```lua
token.init([token_config_or_path])
```

Initialize the token system with configuration (optional)

- **Parameters:**
	- `[token_config_or_path]` *(string|table|nil)*: Lua table or path to token config. Example: "/resources/tokens.json"

### render_properties_panel

---
```lua
token.render_properties_panel([druid], [properties_panel])
```

Render properties panel for debugging

- **Parameters:**
	- `[druid]` *(any)*:
	- `[properties_panel]` *(any)*:


## Fields
<a name="state"></a>
- **state** (_nil_): Persisted data of token module

<a name="on_token_change"></a>
- **on_token_change** (_unknown_): Triggers when token amount was changed

<a name="on_token_visual_change"></a>
- **on_token_visual_change** (_unknown_): Triggers when token visual amount was changed

<a name="on_token_restore_change"></a>
- **on_token_restore_change** (_unknown_): Triggers when token restore config was changed (for backward compatibility)

<a name="containers"></a>
- **containers** (_table_): Active container instances

