# token.container API

> at token/token/container.lua

## Functions

- [create](#create)

- [add](#add)
- [set](#set)
- [get](#get)
- [pay](#pay)
- [is_enough](#is_enough)
- [is_empty](#is_empty)
- [is_max](#is_max)
- [add_many](#add_many)
- [set_many](#set_many)
- [pay_many](#pay_many)
- [is_enough_many](#is_enough_many)
- [get_many](#get_many)
- [sync_visual](#sync_visual)
- [add_visual](#add_visual)
- [get_visual](#get_visual)
- [get_total_sum](#get_total_sum)
- [get_token_config](#get_token_config)

## Fields

- [id](#id)
- [config_group](#config_group)
- [on_token_change](#on_token_change)
- [on_token_visual_change](#on_token_visual_change)
- [on_token_restore_change](#on_token_restore_change)
- [add_group](#add_group)
- [set_group](#set_group)
- [pay_group](#pay_group)
- [is_enough_group](#is_enough_group)
- [set_restore_config](#set_restore_config)
- [get_restore_config](#get_restore_config)
- [set_restore_config_enabled](#set_restore_config_enabled)
- [is_restore_config_enabled](#is_restore_config_enabled)
- [remove_restore_config](#remove_restore_config)
- [get_time_to_restore](#get_time_to_restore)
- [add_infinity_time](#add_infinity_time)
- [is_infinity](#is_infinity)
- [get_infinity_time](#get_infinity_time)
- [set_infinity_time](#set_infinity_time)



### create

---
```lua
container.create(container_id, [config_group], state_data)
```

Create a new container instance

- **Parameters:**
	- `container_id` *(string)*: Unique container identifier
	- `[config_group]` *(string|nil)*: Configuration group (optional)
	- `state_data` *(token.container_data)*: Reference to state data

- **Returns:**
	- `` *(token.container)*:

### add

---
```lua
container:add(token_id, amount, [reason], [visual_later])
```

Add tokens to the container

- **Parameters:**
	- `token_id` *(string)*:
	- `amount` *(number)*:
	- `[reason]` *(string|nil)*:
	- `[visual_later]` *(boolean|nil)*:

- **Returns:**
	- `New` *(number)*: token amount

### set

---
```lua
container:set(token_id, amount, [reason], [visual_later])
```

Set token amount in the container

- **Parameters:**
	- `token_id` *(string)*:
	- `amount` *(number)*:
	- `[reason]` *(string|nil)*:
	- `[visual_later]` *(boolean|nil)*:

- **Returns:**
	- `New` *(number)*: token amount

### get

---
```lua
container:get(token_id, [default_value])
```

Get token amount from the container

- **Parameters:**
	- `token_id` *(string)*:
	- `[default_value]` *(any)*:

- **Returns:**
	- `` *(any)*:

### pay

---
```lua
container:pay(token_id, amount, [reason], [visual_later])
```

Pay (subtract) tokens from the container

- **Parameters:**
	- `token_id` *(string)*:
	- `amount` *(number)*:
	- `[reason]` *(string|nil)*:
	- `[visual_later]` *(boolean|nil)*:

- **Returns:**
	- `True` *(boolean)*: if payment was successful

### is_enough

---
```lua
container:is_enough(token_id, amount)
```

Check if container has enough tokens

- **Parameters:**
	- `token_id` *(string)*:
	- `amount` *(number)*:

- **Returns:**
	- `` *(boolean)*:

### is_empty

---
```lua
container:is_empty(token_id)
```

Check if token is empty (zero)

- **Parameters:**
	- `token_id` *(string)*:

- **Returns:**
	- `` *(boolean)*:

### is_max

---
```lua
container:is_max(token_id)
```

Check if token is at maximum value

- **Parameters:**
	- `token_id` *(string)*:

- **Returns:**
	- `` *(boolean)*:

### add_many

---
```lua
container:add_many([tokens], [reason], [visual_later])
```

Add multiple tokens to the container

- **Parameters:**
	- `[tokens]` *(table<string, number>|nil)*:
	- `[reason]` *(string|nil)*:
	- `[visual_later]` *(boolean|nil)*:

### set_many

---
```lua
container:set_many([tokens], [reason], [visual_later])
```

Set multiple tokens in the container

- **Parameters:**
	- `[tokens]` *(table<string, number>|nil)*:
	- `[reason]` *(string|nil)*:
	- `[visual_later]` *(boolean|nil)*:

### pay_many

---
```lua
container:pay_many(tokens, [reason], [visual_later])
```

Pay multiple tokens from the container

- **Parameters:**
	- `tokens` *(table<string, number>)*:
	- `[reason]` *(string|nil)*:
	- `[visual_later]` *(boolean|nil)*:

- **Returns:**
	- `True` *(boolean)*: if all payments were successful

### is_enough_many

---
```lua
container:is_enough_many([tokens])
```

Check if container has enough of multiple tokens

- **Parameters:**
	- `[tokens]` *(table<string, number>|nil)*:

- **Returns:**
	- `` *(boolean)*:

### get_many

---
```lua
container:get_many()
```

Get all tokens from the container

- **Returns:**
	- `` *(table<string, number>)*:

### sync_visual

---
```lua
container:sync_visual(token_id)
```

Sync visual debt for a token

- **Parameters:**
	- `token_id` *(string)*:

- **Returns:**
	- `The` *(number)*: visual debt that was synced

### add_visual

---
```lua
container:add_visual(token_id, amount)
```

Add visual debt to a token

- **Parameters:**
	- `token_id` *(string)*:
	- `amount` *(number)*:

- **Returns:**
	- `The` *(number)*: new visual value

### get_visual

---
```lua
container:get_visual(token_id)
```

Get visual value of a token

- **Parameters:**
	- `token_id` *(string)*:

- **Returns:**
	- `` *(number)*:

### get_total_sum

---
```lua
container:get_total_sum(token_id)
```

Get total sum for a token

- **Parameters:**
	- `token_id` *(string)*:

- **Returns:**
	- `` *(number)*:

### get_token_config

---
```lua
container:get_token_config(token_id)
```

Get token configuration

- **Parameters:**
	- `token_id` *(string)*:

- **Returns:**
	- `` *(token.token_config_data)*:


## Fields
<a name="id"></a>
- **id** (_string_): Container unique identifier

<a name="config_group"></a>
- **config_group** (_string_): Configuration group name

<a name="on_token_change"></a>
- **on_token_change** (_event_): Per-container change event

<a name="on_token_visual_change"></a>
- **on_token_visual_change** (_event_): Per-container visual change event

<a name="on_token_restore_change"></a>
- **on_token_restore_change** (_event_): Per-container restore change event

<a name="add_group"></a>
- **add_group** (_function_):  Integrate token_groups methods

<a name="set_group"></a>
- **set_group** (_function_)

<a name="pay_group"></a>
- **pay_group** (_function_)

<a name="is_enough_group"></a>
- **is_enough_group** (_function_)

<a name="set_restore_config"></a>
- **set_restore_config** (_function_):  Integrate token_restore methods

<a name="get_restore_config"></a>
- **get_restore_config** (_function_)

<a name="set_restore_config_enabled"></a>
- **set_restore_config_enabled** (_function_)

<a name="is_restore_config_enabled"></a>
- **is_restore_config_enabled** (_function_)

<a name="remove_restore_config"></a>
- **remove_restore_config** (_function_)

<a name="get_time_to_restore"></a>
- **get_time_to_restore** (_function_)

<a name="add_infinity_time"></a>
- **add_infinity_time** (_function_):  Integrate token_infinity methods

<a name="is_infinity"></a>
- **is_infinity** (_function_)

<a name="get_infinity_time"></a>
- **get_infinity_time** (_function_)

<a name="set_infinity_time"></a>
- **set_infinity_time** (_function_)

