--- Token infinity timer plugin
--- Provides infinity state where tokens can be spent without limit

local time = require("token.internal.token_time")

local M = {}


---Add time to a token's infinity state
---@param container token.container
---@param token_id string
---@param seconds number Number of seconds to add
function M.add_infinity_time(container, token_id, seconds)
	local container_data = container:get_state_data()

	container_data.infinity_timers = container_data.infinity_timers or {}
	local current_time = time.get_time()
	local existing_time = container_data.infinity_timers[token_id] or current_time
	container_data.infinity_timers[token_id] = math.max(existing_time, current_time) + seconds
end


---Check if a token is currently in infinity state
---@param container token.container
---@param token_id string
---@return boolean
function M.is_infinity(container, token_id)
	return M.get_infinity_time(container, token_id) > 0
end


---Get remaining time in seconds for a token's infinity state
---@param container token.container
---@param token_id string
---@return number Seconds remaining (0 if not in infinity state)
function M.get_infinity_time(container, token_id)
	local container_data = container:get_state_data()

	if not container_data.infinity_timers then
		return 0
	end

	local end_timer = container_data.infinity_timers[token_id]
	if end_timer then
		return math.max(0, math.ceil(end_timer - time.get_time()))
	end

	return 0
end


---Set the time for a token's infinity state
---@param container token.container
---@param token_id string
---@param time number End time for infinity state in seconds
function M.set_infinity_time(container, token_id, time)
	local container_data = container:get_state_data()

	if not container_data.infinity_timers then
		container_data.infinity_timers = {}
	end

	container_data.infinity_timers[token_id] = time
end


return M

