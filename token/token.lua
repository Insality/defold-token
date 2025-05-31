local event = require("event.event")
local smart_value = require("token.smart_value")
local token_internal = require("token.token_internal")
local token_debug_page = require("token.token_debug_page")

---The Defold Token module.
---Used to manage all countable items in the game.
---@class token
local M = {}

---Persisted data of token module
---@class token.state
---@field containers table<string, token.container>
M.state = nil

---Triggers when token amount was changed
---Callback is fun(container_id: string, token_id: string, amount: number, reason: string|nil)
---@class token.event.on_token_change: event
---@field trigger fun(_, container_id: string, token_id: string, amount: number, reason: string|nil)
---@field subscribe fun(_, callback: fun(container_id: string, token_id: string, amount: number, reason: string|nil), _)
M.on_token_change = event.create()

---Triggers when token visual amount was changed
---Callback is fun(container_id: string, token_id: string, amount: number)
---@class token.event.on_token_visual_change: event
---@field trigger fun(_, container_id: string, token_id: string, amount: number)
---@field subscribe fun(_, callback: fun(container_id: string, token_id: string, amount: number), _)
M.on_token_visual_change = event.create()

---Triggers when token restore config was changed
---Callback is fun(container_id: string, token_id: string, config: token.token_restore_config)
---@class token.event.on_token_restore_change: event
---@field trigger fun(_, container_id: string, token_id: string, config: token.token_restore_config)
---@field subscribe fun(_, callback: fun(container_id: string, token_id: string, config: token.token_restore_config), _)
M.on_token_restore_change = event.create()


---Call this to reset state to default
function M.reset_state()
	M.state = {
		containers = {}
	}

	M.runtime = {
		token_wrappers = {}, -- Store token smart value wrappers here instead of SMART_CONTAINERS
		timer_id = nil
	}
end
M.reset_state()

M.UPDATE_DELAY = 1/60


---Customize the logging mechanism used by Token Module. You can use **Defold Log** library or provide a custom logger.
---@param logger_instance token.logger|table|nil
function M.set_logger(logger_instance)
	token_internal.logger = logger_instance or token_internal.empty_logger
end


---Inner function to get current time
---Override it to use custom time
---@return number Current time in seconds
function M.get_time()
	return socket.gettime()
end


---@return token.token_config_data
local function get_token_config(token_id)
	return token_internal.CONFIG.TOKENS[token_id] or {}
end


---@return table<string, number>
local function get_token_group_config(group_id)
	return token_internal.CONFIG.TOKEN_GROUPS[group_id]
end


---@return token.lot
local function get_token_lot_config(lot_id)
	return token_internal.CONFIG.LOTS[lot_id]
end


---@return table<string, token.container>
local function get_containers_state()
	return M.state.containers
end


---Creates or gets a token wrapper for a specific token
---@param container_id string Container id
---@param token_id string Token id
---@param token_amount number|nil The initial token amount (optional)
---@return token.smart_value|nil
local function create_token_wrapper(container_id, token_id, token_amount)
	local container_data = get_containers_state()[container_id]
	if not container_data then
		token_internal.logger:error("No container with id", { container_id = container_id, token_id = token_id })
		return nil
	end

	M.runtime.token_wrappers[container_id] = M.runtime.token_wrappers[container_id] or {}

	local config = get_token_config(token_id)
	local amount = token_amount or container_data.tokens[token_id] or config.default

	local smart_token = smart_value.create(config, amount)

	smart_token:on_change(function(token, delta, reason)
		container_data.tokens[token_id] = token:get()
		M.on_token_change:trigger(container_id, token_id, token:get(), reason)
	end)

	smart_token:on_visual_change(function(token, delta)
		M.on_token_visual_change:trigger(container_id, token_id, token:get_visual())
	end)

	M.runtime.token_wrappers[container_id][token_id] = smart_token
	return smart_token
end


---@param container_id string
---@param token_id string
---@return token.smart_value|nil
local function get_token(container_id, token_id)
	assert(container_id, "You should provide container_id")
	assert(token_id, "You should provide token_id")

	local container_data = get_containers_state()[container_id]
	if not container_data then
		token_internal.logger:error("No container with id", { container_id = container_id, token_id = token_id })
		return nil
	end

	-- Make wrapper if needed
	if not M.runtime.token_wrappers[container_id] or not M.runtime.token_wrappers[container_id][token_id] then
		return create_token_wrapper(container_id, token_id)
	end

	return M.runtime.token_wrappers[container_id][token_id]
end


---@param container_id string
---@param token_id string
---@param config token.token_restore_config
local function restore_token_update(container_id, token_id, config)
	local token = get_token(container_id, token_id)
	if not token then
		return
	end

	local token_config = get_token_config(token_id)
	local current_time = M.get_time()
	config.last_restore_time = math.min(config.last_restore_time, current_time)

	local token_max = token_config.max
	if token_max and token:get() == token_max then
		config.last_restore_time = current_time
	end

	local elapsed = current_time - config.last_restore_time
	if elapsed >= config.timer then
		local amount = math.floor(elapsed / config.timer)
		local need_to_add = amount * config.value

		if config.max then
			need_to_add = math.min(need_to_add, config.max)
		end
		token:add(need_to_add)

		local cur_elapse_time = elapsed - (amount * config.timer)
		config.last_restore_time = current_time - cur_elapse_time
	end
end


---Check if token container exists in the system
---@param container_id string The unique identifier for the container
---@return boolean is_exist True if container exists, false otherwise
function M.is_container_exist(container_id)
	return get_containers_state()[container_id] ~= nil
end


---Create a new token container if it doesn't already exist
---@param container_id string The unique identifier for the new container
---@return boolean True if container was successfully created, false if it already exists
function M.create_container(container_id)
	if M.is_container_exist(container_id) then
		return false
	end

	local data_containers = get_containers_state()
	data_containers[container_id] = { tokens = {} }
	M.runtime.token_wrappers[container_id] = {}

	token_internal.logger:debug("Create token container", container_id)

	return true
end


---Delete an existing token container and all associated tokens
---@param container_id string The unique identifier for the container to delete
function M.delete_container(container_id)
	local data_containers = get_containers_state()

	data_containers[container_id] = nil
	M.runtime.token_wrappers[container_id] = nil
end


---Clear all tokens from a container but keep the container itself
---@param container_id string The unique identifier for the container to clear
function M.clear_container(container_id)
	if not M.is_container_exist(container_id) then
		token_internal.logger:warn("Can't clear non existing container", container_id)
		return
	end

	local containers = get_containers_state()
	containers[container_id] = { tokens = {} }
	M.runtime.token_wrappers[container_id] = {}
end


---Configure automatic token restoration over time
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@param config token.token_restore_param Configuration for token restoration {timer: seconds between restores, value: amount to restore each time, max: optional maximum to restore}
function M.set_restore_config(container_id, token_id, config)
	local container = get_containers_state()[container_id]
	if not container then
		token_internal.logger:error("No container with id", { container_id = container_id, token_id = token_id })
		return nil
	end

	container.restore_config = container.restore_config or {}
	local restore_config = container.restore_config

	---@type token.token_restore_config
	local new_config = {
		is_enabled = true,
		disabled_time = nil,
		last_restore_time = M.get_time(),
		timer = config.timer,
		value = config.value or 1,
		max = config.max,
	}

	restore_config[token_id] = new_config
	M.on_token_restore_change:trigger(container_id, token_id, new_config)

	token_internal.logger:debug("Set restore config for token", {
		container_id = container_id,
		token_id = token_id,
		config = new_config
	})
end


---Get the current restoration configuration for a token
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@return token.token_restore_config|nil The restoration configuration or nil if not set
function M.get_restore_config(container_id, token_id)
	local container = get_containers_state()[container_id]
	if not container then
		token_internal.logger:error("No container with id", { container_id = container_id, token_id = token_id })
		return
	end

	if not container.restore_config then
		return nil
	end

	return container.restore_config[token_id]
end


---Enable or disable token restoration for a specific token
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@param is_enabled boolean Whether restoration should be enabled
function M.set_restore_config_enabled(container_id, token_id, is_enabled)
	local config = M.get_restore_config(container_id, token_id)
	if not config then
		token_internal.logger:error("No restore config for token", { container_id = container_id, token_id = token_id })
		return nil
	end

	config.is_enabled = is_enabled

	if not is_enabled then
		config.disabled_time = M.get_time()
	end
	if is_enabled then
		local time_delta = config.disabled_time and M.get_time() - config.disabled_time or 0
		config.last_restore_time = config.last_restore_time + time_delta
	end
end


---Check if token restoration is enabled for a specific token
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@return boolean|nil True if enabled, false if disabled, nil if no config exists
function M.is_restore_config_enabled(container_id, token_id)
	local config = M.get_restore_config(container_id, token_id)
	if not config then
		token_internal.logger:error("No restore config for token", { container_id = container_id, token_id = token_id })
		return nil
	end

	return config.is_enabled
end


---Remove the restoration configuration for a token
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@return boolean True if config was removed, false if it didn't exist
function M.remove_restore_config(container_id, token_id)
	local restore_config = get_containers_state()[container_id].restore_config

	if restore_config and restore_config[token_id] then
		restore_config[token_id] = nil
		return true
	end

	return false
end


---Get a token group by its identifier
---@param token_group_id string The unique identifier for the token group
---@return table<string, number>|nil Table mapping token IDs to amounts, or nil if group doesn't exist
function M.get_token_group(token_group_id)
	local group = get_token_group_config(token_group_id)

	if not group then
		token_internal.logger:error("No token group with id", token_group_id)
	end

	return group
end


---Get the reward tokens for a specific lot
---@param lot_id string The unique identifier for the lot
---@return table<string, number>|nil Table mapping token IDs to amounts, or nil if lot doesn't exist
function M.get_lot_reward(lot_id)
	local lot = get_token_lot_config(lot_id)

	if not lot then
		token_internal.logger:error("No token lot with id", lot_id)
	end

	return M.get_token_group(lot.reward)
end


---Get the price tokens for a specific lot
---@param lot_id string The unique identifier for the lot
---@return table<string, number>|nil Table mapping token IDs to amounts, or nil if lot doesn't exist
function M.get_lot_price(lot_id)
	local lot = get_token_lot_config(lot_id)

	if not lot then
		token_internal.logger:error("No token lot with id", lot_id)
	end

	return M.get_token_group(lot.price)
end


---Add tokens to a container
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@param amount number Amount of tokens to add
---@param reason string|nil Optional reason for logging/tracking
---@param visual_later boolean|nil If true, visual update will be delayed
---@return number New token amount after addition
function M.add(container_id, token_id, amount, reason, visual_later)
	return get_token(container_id, token_id):add(amount, reason, visual_later)
end


---Add multiple tokens to a container
---@param container_id string The unique identifier for the container
---@param tokens table<string, number>|nil Table mapping token IDs to amounts
---@param reason string|nil Optional reason for logging/tracking
---@param visual_later boolean|nil If true, visual update will be delayed
function M.add_many(container_id, tokens, reason, visual_later)
	if not tokens then
		return
	end

	for token_id, amount in pairs(tokens) do
		M.add(container_id, token_id, amount, reason, visual_later)
	end
end


---Set the amount of multiple tokens in a container
---@param container_id string The unique identifier for the container
---@param tokens table<string, number>|nil Table mapping token IDs to new amounts
---@param reason string|nil Optional reason for logging/tracking
---@param visual_later boolean|nil If true, visual update will be delayed
function M.set_many(container_id, tokens, reason, visual_later)
	if not tokens then
		return
	end

	for token_id, amount in pairs(tokens) do
		M.set(container_id, token_id, amount, reason, visual_later)
	end
end


---Add tokens from a token group to a container
---@param container_id string The unique identifier for the container
---@param token_group_id string The unique identifier for the token group
---@param reason string|nil Optional reason for logging/tracking
---@param visual_later boolean|nil If true, visual update will be delayed
function M.add_group(container_id, token_group_id, reason, visual_later)
	local tokens = M.get_token_group(token_group_id)
	return M.add_many(container_id, tokens, reason, visual_later)
end


---Set tokens in a container to match a token group
---@param container_id string The unique identifier for the container
---@param token_group_id string The unique identifier for the token group
---@param reason string|nil Optional reason for logging/tracking
---@param visual_later boolean|nil If true, visual update will be delayed
function M.set_group(container_id, token_group_id, reason, visual_later)
	local tokens = M.get_token_group(token_group_id)
	return M.set_many(container_id, tokens, reason, visual_later)
end


---Pay tokens from a container using a token group as the cost
---@param container_id string The unique identifier for the container
---@param token_group_id string The unique identifier for the token group
---@param reason string|nil Optional reason for logging/tracking
---@return boolean True if payment was successful, false otherwise
function M.pay_group(container_id, token_group_id, reason)
	local tokens = M.get_token_group(token_group_id)
	if not tokens then
		return false
	end

	return M.pay_many(container_id, tokens, reason)
end


---Set a token amount in a container
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@param amount number New amount for the token
---@param reason string|nil Optional reason for logging/tracking
---@param visual_later boolean|nil If true, visual update will be delayed
---@return number New token amount
function M.set(container_id, token_id, amount, reason, visual_later)
	-- This creates a wrapper if needed
	return get_token(container_id, token_id):set(amount, reason, visual_later)
end


---Get the current amount of a token in a container
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@param default_value any Value to return if the container or token doesn't exist
---@return number|any Current token amount or default_value if not found
function M.get(container_id, token_id, default_value)
	local token = get_token(container_id, token_id)
	if not token then
		return default_value
	end

	return token:get()
end


---Get all tokens from a container
---@param container_id string The unique identifier for the container
---@return table<string, number>|nil Table mapping token IDs to amounts, or nil if container doesn't exist
function M.get_many(container_id)
	local container_data = get_containers_state()[container_id]
	if not container_data then
		return nil
	end

	local tokens = {}
	local wrappers = M.runtime.token_wrappers[container_id]

	-- All tokens should have wrappers now
	if wrappers then
		for id, token in pairs(wrappers) do
			tokens[id] = token:get()
		end
	end

	return tokens
end


---Pay a specific amount of tokens from a container
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@param amount number Amount to pay/subtract
---@param reason string|nil Optional reason for logging/tracking
---@param visual_later boolean|nil If true, visual update will be delayed
---@return boolean True if payment was successful, false if not enough tokens
function M.pay(container_id, token_id, amount, reason, visual_later)
	if M.is_infinity(container_id, token_id) then
		return true
	end

	return get_token(container_id, token_id):pay(amount, reason, visual_later)
end


---Pay multiple tokens from a container
---@param container_id string The unique identifier for the container
---@param tokens table<string, number> Table mapping token IDs to amounts to pay
---@param reason string|nil Optional reason for logging/tracking
---@param visual_later boolean|nil If true, visual update will be delayed
---@return boolean True if all payments were successful, false otherwise
function M.pay_many(container_id, tokens, reason, visual_later)
	local is_enough = true

	for token_id, amount in pairs(tokens) do
		is_enough = is_enough and M.is_enough(container_id, token_id, amount)
	end

	if not is_enough then
		return false
	end

	for token_id, amount in pairs(tokens) do
		M.pay(container_id, token_id, amount, reason, visual_later)
	end

	return true
end


---Check if there are enough tokens to pay a specific amount
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@param amount number Amount to check for
---@return boolean True if enough tokens are available, false otherwise
function M.is_enough(container_id, token_id, amount)
	if M.is_infinity(container_id, token_id) then
		return true
	end

	return get_token(container_id, token_id):check(amount)
end


---Check if a token has zero amount
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@return boolean True if token amount is zero, false otherwise
function M.is_empty(container_id, token_id)
	return M.get(container_id, token_id) == 0
end


---Check if a token is at its maximum allowed amount
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@return boolean True if token is at maximum, false otherwise
function M.is_max(container_id, token_id)
	local amount = M.get(container_id, token_id)
	local config = get_token_config(token_id)
	if not config or not amount then
		return false
	end
	return amount == config.max
end


---@param token_id string The unique identifier for the token
---@return token.token_config_data|nil config The token config, or nil if the token doesn't exist
function M.get_token_config(token_id)
	local config = get_token_config(token_id)
	if not config then
		return nil
	end

	return config
end


---Check if there are enough tokens to pay multiple costs
---@param container_id string The unique identifier for the container
---@param tokens table<string, number>|nil Table mapping token IDs to amounts to check
---@return boolean True if enough of all tokens are available, false otherwise
function M.is_enough_many(container_id, tokens)
	if not tokens then
		return true
	end

	local is_enough = true
	for token_id, amount in pairs(tokens) do
		is_enough = is_enough and M.is_enough(container_id, token_id, amount)
	end

	return is_enough
end


---Check if there are enough tokens to pay for a token group
---@param container_id string The unique identifier for the container
---@param token_group_id string The unique identifier for the token group
---@return boolean True if enough of all tokens in group are available, false otherwise
function M.is_enough_group(container_id, token_group_id)
	local tokens = M.get_token_group(token_group_id)
	return M.is_enough_many(container_id, tokens)
end


---Add time to a token's infinity state (where it can be spent without limit)
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@param seconds number Number of seconds to add to infinity time
function M.add_infinity_time(container_id, token_id, seconds)
	local container = get_containers_state()[container_id]
	if not container.infinity_timers then
		container.infinity_timers = {}
	end

	local timers = container.infinity_timers --[[@as table<string, number>]]
	local current_time = M.get_time()

	timers[token_id] = math.max(timers[token_id] or current_time, current_time) + seconds
end


---Check if a token is currently in infinity state
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@return boolean True if token is in infinity state, false otherwise
function M.is_infinity(container_id, token_id)
	return M.get_infinity_time(container_id, token_id) > 0
end


---Get remaining time in seconds for a token's infinity state
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@return number Seconds remaining in infinity state, 0 if not in infinity state
function M.get_infinity_time(container_id, token_id)
	local container = get_containers_state()[container_id]
	if not container.infinity_timers then
		return 0
	end

	local end_timer = container.infinity_timers[token_id]
	if end_timer then
		return math.max(0, math.ceil(end_timer - M.get_time()))
	end

	return 0
end


---Set the time for a token's infinity state
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@param time number End time for infinity state in seconds
function M.set_infinity_time(container_id, token_id, time)
	local container = get_containers_state()[container_id]
	if not container.infinity_timers then
		container.infinity_timers = {}
	end

	container.infinity_timers[token_id] = time
end


---Get time remaining until next automatic token restore
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@return number|nil Seconds until next restore, or nil if no restore config
function M.get_time_to_restore(container_id, token_id)
	local config = M.get_restore_config(container_id, token_id)

	if not config then
		return nil
	end

	local time_elapsed = M.get_time() - config.last_restore_time
	return math.max(0, config.timer - time_elapsed)
end


---Reset visual debt of tokens to match actual value
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
function M.sync_visual(container_id, token_id)
	return get_token(container_id, token_id):sync_visual()
end


---Add visual debt to a token (for animations, etc.)
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@param amount number Amount to add to visual counter
function M.add_visual(container_id, token_id, amount)
	return get_token(container_id, token_id):add_visual(amount)
end


---Get current visual amount of a token (including debt)
---@param container_id string The unique identifier for the container
---@param token_id string The unique identifier for the token
---@return number Visual amount of the token (never negative)
function M.get_visual(container_id, token_id)
	return math.max(0, get_token(container_id, token_id):get_visual())
end


---Get the total accumulated amount of a specific token
---@param container_id string Container id
---@param token_id string Token id
---@return number The total amount of tokens ever acquired (regardless of spending)
function M.get_total_sum(container_id, token_id)
	return get_token(container_id, token_id):get_total_sum()
end


---Initialize the token system with configuration
---@param token_config_or_path token.config|string|nil Lua table or path to token config. Example: "/resources/tokens.json"
function M.init(token_config_or_path)
	-- Load Token config data
	token_internal.load_config(token_config_or_path or {})
	M.load_token_state()
	M.start_update()
end


---Register tokens in the token system
---@param tokens table<string, token.token_config_data> Table mapping token IDs to token config data
function M.register_tokens(tokens)
	for token_id, data in pairs(tokens) do
		token_internal.register_token(token_id, data)
	end
end


---Register token groups in the token system
---@param groups table<string, table<string, number>> Table mapping group IDs to token IDs and amounts
function M.register_token_groups(groups)
	for group_id, tokens in pairs(groups) do
		token_internal.register_token_group(group_id, tokens)
	end
end


---Register lots in the token system
---@param lots table<string, token.lot> Table mapping lot IDs to lot config
function M.register_lots(lots)
	for lot_id, lot in pairs(lots) do
		token_internal.register_lot(lot_id, lot)
	end
end


---Load all current tokens into token wrappers
function M.load_token_state()
	-- Reset token wrappers
	M.runtime.token_wrappers = {}

	-- Fill data from save
	local data_containers = get_containers_state()
	for container_id, data_container in pairs(data_containers) do
		-- Create container wrapper object
		M.runtime.token_wrappers[container_id] = {}

		-- Create wrappers for all existing tokens
		for token_id, amount in pairs(data_container.tokens) do
			create_token_wrapper(container_id, token_id, amount)
		end
	end
end


---Start periodic updates for token restore timers
---@private
function M.start_update()
	if not M.runtime.timer_id then
		M.runtime.timer_id = timer.delay(M.UPDATE_DELAY, true, M.update)
	end
end


---Update all tokens restore timers
---@private
function M.update()
	local containers = get_containers_state()
	for container_id, container in pairs(containers) do
		local restore_config = container.restore_config
		if restore_config then
			for token_id, config in pairs(restore_config) do
				if config.is_enabled then
					restore_token_update(container_id, token_id, config)
				end
			end
		end
	end
end


---@param druid druid.instance
---@param properties_panel druid.widget.properties_panel
function M.render_properties_panel(druid, properties_panel)
	token_debug_page.render_properties_panel(M, druid, properties_panel)
end


return M
