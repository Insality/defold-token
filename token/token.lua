local event = require("event.event")

local logger = require("token.internal.token_logger")
local state = require("token.internal.token_state")
local config = require("token.internal.token_config")
local container = require("token.internal.token_container")
local restore = require("token.internal.token_restore")

---The Defold Token module.
---Used to manage all countable items in the game.
---@class token
local M = {}

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

---Triggers when token restore config was changed (for backward compatibility)
---Callback is fun(container_id: string, token_id: string, config: token.token_restore_config)
---@class token.event.on_token_restore_change: event
---@field trigger fun(_, container_id: string, token_id: string, config: token.token_restore_config)
---@field subscribe fun(_, callback: fun(container_id: string, token_id: string, config: token.token_restore_config), _)
M.on_token_restore_change = event.create()


---Active container instances
---@type table<string, token.container>
M.containers = {}

---Timer handle for update loop
---@type any
M.timer_id = nil

---Call this to reset state to default
function M.reset_state()
	state.reset()
	M.containers = {}
	if M.timer_id then
		timer.cancel(M.timer_id)
		M.timer_id = nil
	end
end
M.reset_state()


---Get the current state for serialization
---@return token.state
function M.get_state()
	return state.get_state()
end


---Set the state (for deserialization)
---@param new_state token.state
function M.set_state(new_state)
	state.set_state(new_state)
end



---Customize the logging mechanism used by Token Module. You can use **Defold Log** library or provide a custom logger.
---@param logger_instance token.logger|table|nil
function M.set_logger(logger_instance)
	logger.set_logger(logger_instance)
end


---Get container instance, create if it doesn't exist
---@param container_id string Unique identifier for the container
---@param config_group string|nil Optional configuration group
---@return token.container Container instance
function M.container(container_id, config_group)
	-- Return existing container if it exists
	if M.containers[container_id] then
		return M.containers[container_id]
	end

	-- Create state data if it doesn't exist
	local state_data = state.get_container(container_id)
	if not state_data then
		state_data = state.create_container(container_id)
	end

	-- Create container instance
	local new_container = container.create(container_id, config_group, state_data)
	M.containers[container_id] = new_container

	-- Subscribe to container events to trigger global events
	new_container.on_token_change:subscribe(M.on_token_change, container_id)
	new_container.on_token_visual_change:subscribe(M.on_token_visual_change, container_id)
	new_container.on_token_restore_change:subscribe(M.on_token_restore_change, container_id)

	logger:debug("Create token container", container_id)

	return new_container
end


---Delete a container and all its tokens
---@param container_id string Unique identifier for the container
function M.delete_container(container_id)
	state.delete_container(container_id)
	M.containers[container_id] = nil
end


---Clear all tokens from a container but keep the container
---@param container_id string Unique identifier for the container
function M.clear_container(container_id)
	local existing_container = M.containers[container_id]
	if existing_container then
		local config_group = existing_container.config_group
		state.clear_container(container_id)
		existing_container.on_token_change:clear()
		existing_container.on_token_visual_change:clear()
		existing_container.on_token_restore_change:clear()

		-- Recreate container to clear runtime data
		local state_data = state.get_container(container_id)
		if state_data then
			local new_container = container.create(container_id, config_group, state_data)
			M.containers[container_id] = new_container

			-- Subscribe to container events to trigger global events
			new_container.on_token_change:subscribe(M.on_token_change, container_id)
			new_container.on_token_visual_change:subscribe(M.on_token_visual_change, container_id)
			new_container.on_token_restore_change:subscribe(M.on_token_restore_change, container_id)
		end
	else
		logger:warn("Can't clear non existing container", container_id)
	end
end


---Check if container exists
---@param container_id string
---@return boolean
function M.is_container_exist(container_id)
	return state.has_container(container_id)
end


---Load configuration from a table
---@param config_or_path table|string Configuration table or JSON path
function M.load_config(config_or_path)
	if type(config_or_path) == "string" then
		-- Load from JSON file
		local resource, is_error = sys.load_resource(config_or_path)
		if is_error or not resource then
			logger:error("Can't load token config", config_or_path)
			return
		end
		local is_ok, decoded_config = pcall(json.decode, resource)
		if not is_ok then
			logger:error("Can't decode token config", config_or_path)
			return
		end
		if decoded_config then
			config.load_config(decoded_config)
		end
	else
		config.load_config(config_or_path)
	end
end


---Register tokens in the token system
---@param tokens table<string, token.token_config_data> Table mapping token IDs to token config data
---@param config_group string|nil Optional config group (defaults to "default")
function M.register_tokens(tokens, config_group)
	config.register_tokens(tokens, config_group)
end


---Register token groups in the token system
---@param groups table<string, table<string, number>> Table mapping group IDs to token IDs and amounts
function M.register_token_groups(groups)
	config.register_groups(groups)
end


---Register lots in the token system
---@param lots_data table<string, token.lot> Table mapping lot IDs to lot config
function M.register_lots(lots_data)
	config.register_lots(lots_data)
end


---Get a token group by its identifier
---@param token_group_id string The unique identifier for the token group
---@return table<string, number>|nil Table mapping token IDs to amounts, or nil if group doesn't exist
function M.get_token_group(token_group_id)
	local group = config.get_group(token_group_id)

	if not group then
		logger:error("No token group with id", token_group_id)
	end

	return group
end


---Get the reward tokens for a specific lot
---@param lot_id string Lot id
---@return table<string, number>|nil
function M.get_lot_reward(lot_id)
	local lot = config.get_lot(lot_id)
	if not lot then
		return nil
	end

	return config.get_group(lot.reward)
end


---Get the price tokens for a specific lot
---@param lot_id string Lot id
---@return table<string, number>|nil
function M.get_lot_price(lot_id)
	local lot = config.get_lot(lot_id)
	if not lot then
		return nil
	end

	return config.get_group(lot.price)
end

---Get token configuration
---@param token_id string The unique identifier for the token
---@return token.token_config_data|nil config The token config, or nil if the token doesn't exist
function M.get_token_config(token_id)
	return config.get_token_config(token_id, nil)
end


---Initialize the token system with configuration (optional)
---@param tokens_config_or_path table<string, token.token_config_data>|string|nil Lua table or path to token config. Example: "/resources/tokens.json"
function M.init(tokens_config_or_path)
	if tokens_config_or_path then
		M.load_config(tokens_config_or_path)
	end

	M.containers = {}
	M.timer_id = timer.delay(1/60, true, M.update)

	-- Create container instances for all state data
	for container_id, state_data in pairs(state.get_all_containers()) do
		local new_container = container.create(container_id, nil, state_data)
		M.containers[container_id] = new_container

		-- Subscribe to container events to trigger global events
		new_container.on_token_change:subscribe(M.on_token_change, container_id)
		new_container.on_token_visual_change:subscribe(M.on_token_visual_change, container_id)
		new_container.on_token_restore_change:subscribe(M.on_token_restore_change, container_id)
	end
end


---Update the token system
function M.update()
	restore.update(M.containers)
end


return M
