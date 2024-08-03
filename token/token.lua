local event = require("event.event")
local smart_value = require("token.smart_value")
local token_internal = require("token.token_internal")

---@class token
local M = {}

---Persisted data
---@type token.state
M.state = nil

---@class token.event.on_token_change: event
---@field trigger fun(_, container_id: string, token_id: string, amount: number, reason: string|nil)
---@field subscribe fun(_, callback: fun(container_id: string, token_id: string, amount: number, reason: string|nil), _)
M.on_token_change = event.create()

---@class token.event.on_token_visual_change: event
---@field trigger fun(_, container_id: string, token_id: string, amount: number)
---@field subscribe fun(_, callback: fun(container_id: string, token_id: string, amount: number), _)
M.on_token_visual_change = event.create()

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
		timer_id = nil
	}
end
M.reset_state()

local SMART_CONTAINERS = {}

M.UPDATE_DELAY = 1/60


---Set logger for token system
---@param logger_instance token.logger|nil
function M.set_logger(logger_instance)
	token_internal.logger = logger_instance or token_internal.empty_logger
end


---Get current logger for token system
---@return token.logger
function M.get_logger()
	return token_internal.logger
end


---Inner function to get current time
---Override it to use custom time
---@return number
function M.get_time()
	return socket.gettime()
end


---@return token.token_config_data
local function get_token_config(token_id)
	return token_internal.CONFIG_TOKENS[token_id] or {}
end


---@return table<string, number>
local function get_token_group_config(group_id)
	return token_internal.CONFIG_TOKEN_GROUPS[group_id]
end


---@return token.lot
local function get_token_lot_config(lot_id)
	return token_internal.CONFIG_LOTS[lot_id]
end


---@return table<string, token.container>
local function get_containers_state()
	return M.state.containers
end


---@param container_id string
---@return token.container|nil
local function get_smart_container(container_id)
	return SMART_CONTAINERS[container_id]
end


---@param container_id string
---@param token_id string
---@param amount number|nil
---@return token.smart_value
local function create_token_in_save(container_id, token_id, amount)
	local config = get_token_config(token_id)
	local container_data = get_containers_state()[container_id]
	local token_amount = amount or container_data.tokens[token_id] or config.default

	local smart_token = smart_value.create(config, token_amount)

	smart_token:on_change(function(token, delta, reason)
		container_data.tokens[token_id] = token:get()
		M.on_token_change:trigger(container_id, token_id, token:get(), reason)
	end)

	smart_token:on_visual_change(function(token, delta)
		M.on_token_visual_change:trigger(container_id, token_id, token:get_visual())
	end)

	return smart_token
end


---@param container_id string
---@param token_id string
---@return token.smart_value|nil
local function get_token(container_id, token_id)
	assert(container_id, "You should provide container_id")
	assert(token_id, "You should provide token_id")

	local container = get_smart_container(container_id)
	if not container then
		token_internal.logger:error("No container with id", { container_id = container_id, token_id = token_id })
		return nil
	end

	if not container[token_id] then
		container[token_id] = create_token_in_save(container_id, token_id)
	end

	return container[token_id]
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


---Check if token container exist
---@param container_id string
---@return boolean
function M.is_container_exist(container_id)
	return (not not get_smart_container(container_id))
end


---Create token container. If container already exist, do nothing
---@param container_id string
---@return boolean @True if container was created
function M.create_container(container_id)
	if M.is_container_exist(container_id) then
		return false
	end

	local data_containers = get_containers_state()
	data_containers[container_id] = { tokens = {} }
	SMART_CONTAINERS[container_id] = {}

	token_internal.logger:debug("Create token container", container_id)

	return true
end


---Delete token container
---@param container_id string
function M.delete_container(container_id)
	local data_containers = get_containers_state()

	data_containers[container_id] = nil
	SMART_CONTAINERS[container_id] = nil
end


---Clear all tokens from container
---@param container_id string
function M.clear_container(container_id)
	if not M.is_container_exist(container_id) then
		token_internal.logger:warn("Can't clear non existing container", container_id)
		return
	end

	local containers = get_containers_state()
	containers[container_id] = { tokens = {} }
	SMART_CONTAINERS[container_id] = {}
end


---Set restore config for token
---@param container_id string
---@param token_id string
---@param config token.token_restore_param
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


---Get restore config for token
---@param container_id string
---@param token_id string
---@return token.token_restore_config|nil @Nil if no config
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


---@param container_id string
---@param token_id string
---@param is_enabled boolean
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


---@param container_id string
---@param token_id string
---@return boolean|nil
function M.is_restore_config_enabled(container_id, token_id)
	local config = M.get_restore_config(container_id, token_id)
	if not config then
		token_internal.logger:error("No restore config for token", { container_id = container_id, token_id = token_id })
		return nil
	end

	return config.is_enabled
end


---Remove restore config for token
---@param container_id string
---@param token_id string
---@return boolean @True if config was removed
function M.remove_restore_config(container_id, token_id)
	local restore_config = get_containers_state()[container_id].restore_config

	if restore_config and restore_config[token_id] then
		restore_config[token_id] = nil
		return true
	end

	return false
end


---Return token group by id.
---@param token_group_id string
---@return table<string, number>|nil
function M.get_token_group(token_group_id)
	local group = get_token_group_config(token_group_id)

	if not group then
		token_internal.logger:error("No token group with id", token_group_id)
	end

	return group
end


---Return lot reward by lot_id.
---@param lot_id string
---@return table<string, number>|nil
function M.get_lot_reward(lot_id)
	local lot = get_token_lot_config(lot_id)

	if not lot then
		token_internal.logger:error("No token lot with id", lot_id)
	end

	return M.get_token_group(lot.reward)
end


---Return lot price by lot_id.
---@param lot_id string
---@return table<string, number>|nil
function M.get_lot_price(lot_id)
	local lot = get_token_lot_config(lot_id)

	if not lot then
		token_internal.logger:error("No token lot with id", lot_id)
	end

	return M.get_token_group(lot.price)
end


---Add tokens to container
---@param container_id string
---@param token_id string
---@param amount number
---@param reason string|nil
---@param visual_later boolean|nil
---@return number
function M.add(container_id, token_id, amount, reason, visual_later)
	return get_token(container_id, token_id):add(amount, reason, visual_later)
end


---Add multiply tokens
---@param container_id string
---@param tokens table<string, number>|nil
---@param reason string|nil
---@param visual_later boolean|nil
function M.add_many(container_id, tokens, reason, visual_later)
	if not tokens then
		return
	end

	for token_id, amount in pairs(tokens) do
		M.add(container_id, token_id, amount, reason, visual_later)
	end
end


---Set multiply tokens
---@param container_id string
---@param tokens table<string, number>|nil
---@param reason string|nil
---@param visual_later boolean|nil
function M.set_many(container_id, tokens, reason, visual_later)
	if not tokens then
		return
	end

	for token_id, amount in pairs(tokens) do
		M.set(container_id, token_id, amount, reason, visual_later)
	end
end


---Add multiply tokens by token_group_id
---@param container_id string
---@param token_group_id string
---@param reason string|nil
---@param visual_later boolean|nil
function M.add_group(container_id, token_group_id, reason, visual_later)
	local tokens = M.get_token_group(token_group_id)
	return M.add_many(container_id, tokens, reason, visual_later)
end


---Set multiply tokens by token_group_id
---@param container_id string
---@param token_group_id string
---@param reason string|nil
---@param visual_later boolean|nil
function M.set_group(container_id, token_group_id, reason, visual_later)
	local tokens = M.get_token_group(token_group_id)
	return M.set_many(container_id, tokens, reason, visual_later)
end


---Pay multiply tokens by token_group_id
---@param container_id string
---@param token_group_id string
---@param reason string|nil
---@return boolean
function M.pay_group(container_id, token_group_id, reason)
	local tokens = M.get_token_group(token_group_id)
	if not tokens then
		return false
	end

	return M.pay_many(container_id, tokens, reason)
end


---Set tokens amount in container
---@param container_id string
---@param token_id string
---@param amount number
---@param reason string|nil
---@return number @New token amount
function M.set(container_id, token_id, amount, reason, visual_later)
	return get_token(container_id, token_id):set(amount, reason, visual_later)
end


---Get token amount from container
---@param container_id string
---@param token_id string
---@return number|nil @Nil if container not exist
function M.get(container_id, token_id)
	local token = get_token(container_id, token_id)
	if not token then
		return nil
	end

	return token:get()
end


---Get all tokens from container
---@param container_id string
---@return table<string, number>|nil @Nil if container not exist
function M.get_many(container_id)
	local container = get_smart_container(container_id)
	if not container then
		return nil
	end

	local tokens = {}
	for id, token in pairs(container) do
		tokens[id] = token:get()
	end

	return tokens
end


---Pay tokens from container, if not enough, return false
---@param container_id string
---@param token_id string
---@param amount number
---@param reason string|nil
---@param visual_later boolean|nil
---@return boolean
function M.pay(container_id, token_id, amount, reason, visual_later)
	if M.is_infinity(container_id, token_id) then
		return true
	end

	return get_token(container_id, token_id):pay(amount, reason, visual_later)
end


---Pay multiply tokens from container, if not enough, return false
---@param container_id string
---@param tokens table<string, number>
---@param reason string|nil
---@param visual_later boolean|nil
---@return boolean
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


---Check is enough to pay token
---@param container_id string
---@param token_id string
---@param amount number
---@return boolean
function M.is_enough(container_id, token_id, amount)
	if M.is_infinity(container_id, token_id) then
		return true
	end

	return get_token(container_id, token_id):check(amount)
end


---Check is token equal to 0
---@param container_id string
---@param token_id string
---@return boolean
function M.is_empty(container_id, token_id)
	return M.get(container_id, token_id) == 0
end


---Check is token max
---@param container_id string
---@param token_id string
---@return boolean
function M.is_max(container_id, token_id)
	local amount = M.get(container_id, token_id)
	local config = get_token_config(token_id)
	if not config or not amount then
		return false
	end
	return amount == config.max
end


---Check multiply tokens
---@param container_id string
---@param tokens table<string, number>|nil
---@return boolean
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


---Check multiply tokens by token_group_id
---@param container_id string
---@param token_group_id string
---@return boolean
function M.is_enough_group(container_id, token_group_id)
	local tokens = M.get_token_group(token_group_id)
	return M.is_enough_many(container_id, tokens)
end


---Add time in seconds to infinity timer.
---When token is infinity, it can be paid without any restrictions
---@param container_id string
---@param token_id string
---@param seconds number
function M.add_infinity_time(container_id, token_id, seconds)
	local container = get_containers_state()[container_id]
	if not container.infinity_timers then
		container.infinity_timers = {}
	end

	local timers = container.infinity_timers --[[@as table<string, number>]]
	local current_time = M.get_time()

	timers[token_id] = math.max(timers[token_id] or current_time, current_time) + seconds
end


---Return is token is infinity now
---@param container_id string
---@param token_id string
---@return boolean
function M.is_infinity(container_id, token_id)
	return M.get_infinity_time(container_id, token_id) > 0
end


---Get amount of seconds till end of infinity time
---@param container_id string
---@param token_id string
---@return number
function M.get_infinity_time(container_id, token_id)
	local container = get_containers_state()[container_id]
	if not container.infinity_timers then
		return 0
	end

	local end_timer = container.infinity_timers[token_id]
	if end_timer then
		return math.ceil(end_timer - M.get_time())
	end

	return 0
end


---Set time in seconds to infinity timer.
---When token is infinity, it can be paid without any restrictions
---@param container_id string
---@param token_id string
---@param time number
function M.set_infinity_time(container_id, token_id, time)
	local container = get_containers_state()[container_id]
	if not container.infinity_timers then
		container.infinity_timers = {}
	end

	container.infinity_timers[token_id] = time
end


---Get current time to next restore point
---@param container_id string
---@param token_id string
---@return number|nil @Nil if no restore config
function M.get_time_to_restore(container_id, token_id)
	local config = M.get_restore_config(container_id, token_id)

	if not config then
		return nil
	end

	local time_elapsed = M.get_time() - config.last_restore_time
	return math.max(0, config.timer - time_elapsed)
end


---Reset visual debt of tokens
---@param container_id string
---@param token_id string
function M.sync_visual(container_id, token_id)
	return get_token(container_id, token_id):sync_visual()
end


---Add visual debt to token
---@param container_id string
---@param token_id string
---@param amount number
function M.add_visual(container_id, token_id, amount)
	return get_token(container_id, token_id):add_visual(amount)
end


---Get current visual debt of token
---@param container_id string
---@param token_id string
---@return number
function M.get_visual(container_id, token_id)
	return math.max(0, get_token(container_id, token_id):get_visual())
end


---Get total amount of acquired tokens for container
---@param container_id string Container id
---@param token_id string Token id
---@return number The total amount of acquired tokens for container
function M.get_total_sum(container_id, token_id)
	return get_token(container_id, token_id):get_total_sum()
end


---Init token system
---@param token_config_or_path token.config|string|nil Lua table or path to token config. Example: "/resources/tokens.json"
function M.init(token_config_or_path)
	-- Load Token config data
	token_internal.load_config(token_config_or_path or {})
	M.load_token_state()
	M.start_update()
end


---Load all current tokens into smart containers to work with them
function M.load_token_state()
	-- Reset state
	SMART_CONTAINERS = {}

	-- Fill data from save
	local data_containers = get_containers_state()
	for container_id, data_container in pairs(data_containers) do
		SMART_CONTAINERS[container_id] = SMART_CONTAINERS[container_id] or {}

		for token_id, amount in pairs(data_container.tokens) do
			local container = SMART_CONTAINERS[container_id]
			container[token_id] = create_token_in_save(container_id, token_id, amount)
		end
	end
end


function M.start_update()
	if M.runtime.timer_id then
		timer.cancel(M.runtime.timer_id)
		M.runtime.timer_id = nil
	end

	M.runtime.timer_id = timer.delay(M.UPDATE_DELAY, true, M.update)
end


---Update all tokens refresh timers
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


return M
