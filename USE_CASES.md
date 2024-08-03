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
	saver.bind_save_part("token", token.state)

	token.init()
end
```

Or you can use other save system

```lua
local token = require("token.token")

local function save_token_state()
	-- Save a token.state table as you wish
	save_token_state(token.state)
end


local function load_token_state()
	-- Load a token.state table as you wish
	return load_token_state_from_save()
end


function init(self)
	token.state = load_token_state()
	token.init(token_state)
end
```


## How to use restore tokens config


## How to use infinity tokens config


## Example: wallet container