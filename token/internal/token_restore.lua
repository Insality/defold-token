--- Token restore timer plugin
--- Provides automatic token restoration over time

local time = require("token.internal.token_time")
local logger = require("token.internal.token_logger")

---@class token.token_restore_config
---@field is_enabled boolean
---@field last_restore_time number Last restore time in seconds since epoch
---@field disabled_time number|nil
---@field timer number Timer in seconds for restore
---@field value number Value for restore per timer
---@field max number|nil Max accumulated value for restore offline

---@class token.token_restore_param
---@field timer number Timer in seconds for restore
---@field value number|nil Value for restore per timer. Default is 1
---@field max number|nil Max accumulated value for restore while offline. Nil means no limit

local M = {}

---Set restore configuration for a token
---If config already exists, only updates timer/value/max parameters, preserving restore state
---@param container token.container
---@param token_id string
---@param config token.token_restore_param
function M.set_restore_config(container, token_id, config)
	local container_data = container:get_state_data()

	container_data.restore_config = container_data.restore_config or {}

	local existing_config = container_data.restore_config[token_id]

	if existing_config then
		-- Update only config parameters, preserve restore state
		existing_config.timer = config.timer
		existing_config.value = config.value or 1
		existing_config.max = config.max

		-- Trigger per-container event
		container.on_token_restore_change:trigger(token_id, existing_config)

		logger:debug("Update restore config for token", {
			container_id = container.id,
			token_id = token_id,
			config = existing_config
		})
	else
		-- Create new config with current time
		---@type token.token_restore_config
		local new_config = {
			is_enabled = true,
			disabled_time = nil,
			last_restore_time = time.get_time(),
			timer = config.timer,
			value = config.value or 1,
			max = config.max,
		}

		container_data.restore_config[token_id] = new_config

		-- Trigger per-container event
		container.on_token_restore_change:trigger(token_id, new_config)

		logger:debug("Create restore config for token", {
			container_id = container.id,
			token_id = token_id,
			config = new_config
		})
	end
end


---Reset restore configuration timer for a token (start from current time)
---Use this if you want to force reset the restore timer
---@param container token.container
---@param token_id string
function M.reset_restore_timer(container, token_id)
	local config = M.get_restore_config(container, token_id)

	if not config then
		logger:error("No restore config for token", {
			container_id = container.id,
			token_id = token_id
		})
		return
	end

	config.last_restore_time = time.get_time()

	logger:debug("Reset restore timer for token", {
		container_id = container.id,
		token_id = token_id
	})
end


---Get restore configuration for a token
---@param container token.container
---@param token_id string
---@return token.token_restore_config|nil
function M.get_restore_config(container, token_id)
	local container_data = container:get_state_data()

	if not container_data.restore_config then
		return nil
	end

	return container_data.restore_config[token_id]
end


---Enable or disable restore for a token
---@param container token.container
---@param token_id string
---@param is_enabled boolean
function M.set_restore_config_enabled(container, token_id, is_enabled)
	local config = M.get_restore_config(container, token_id)

	if not config then
		logger:error("No restore config for token", {
			container_id = container.id,
			token_id = token_id
		})
		return
	end

	config.is_enabled = is_enabled

	if not is_enabled then
		config.disabled_time = time.get_time()
	end

	if is_enabled then
		local time_delta = config.disabled_time and time.get_time() - config.disabled_time or 0
		config.last_restore_time = config.last_restore_time + time_delta
	end
end


---Check if restore is enabled for a token
---@param container token.container
---@param token_id string
---@return boolean|nil
function M.is_restore_config_enabled(container, token_id)
	local config = M.get_restore_config(container, token_id)
	if not config then
		return nil
	end

	return config.is_enabled
end


---Remove restore configuration for a token
---@param container token.container
---@param token_id string
---@return boolean True if config was removed, false otherwise
function M.remove_restore_config(container, token_id)
	local container_data = container:get_state_data()

	if container_data.restore_config and container_data.restore_config[token_id] then
		container_data.restore_config[token_id] = nil
		return true
	end

	return false
end


---Get time remaining until next restore
---@param container token.container
---@param token_id string
---@return number|nil Seconds until next restore, or nil if no restore config
function M.get_time_to_restore(container, token_id)
	local config = M.get_restore_config(container, token_id)

	if not config then
		return nil
	end

	local time_elapsed = time.get_time() - config.last_restore_time
	return math.max(0, config.timer - time_elapsed)
end


---Update restore timer for a token (called by update loop)
---@param container token.container
---@param token_id string
---@param config token.token_restore_config
function M.update_restore(container, token_id, config)
	-- Skip if restore is disabled
	if not config.is_enabled then
		return
	end

	local token = container:token(token_id)
	if not token then
		return
	end

	local token_config = token.config
	local current_time = time.get_time()
	config.last_restore_time = math.min(config.last_restore_time, current_time)

	-- If at max, reset restore timer
	local token_max = token_config.max
	if token_max and token:get() == token_max then
		config.last_restore_time = current_time
		return
	end

	local elapsed = current_time - config.last_restore_time
	if elapsed >= config.timer then
		local amount = math.floor(elapsed / config.timer)
		local need_to_add = amount * config.value

		-- Cap to max restore amount
		if config.max then
			need_to_add = math.min(need_to_add, config.max)
		end

		token:add(need_to_add)

		local cur_elapse_time = elapsed - (amount * config.timer)
		config.last_restore_time = current_time - cur_elapse_time
	end
end


---Update restore timer for all tokens (called by update loop)
---@param containers table<string, token.container>
function M.update(containers)
	for _, container in pairs(containers) do
		local restore_config = container:get_state_data().restore_config
		if restore_config then
			for token_id, config in pairs(restore_config) do
				M.update_restore(container, token_id, config)
			end
		end
	end
end



return M

