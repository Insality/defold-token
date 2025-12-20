--- Token container class
--- Manages a collection of tokens with all operations

local event = require("event.event")
local logger = require("token.internal.token_logger")
local value = require("token.internal.token_value")
local config = require("token.internal.token_config")
local restore = require("token.internal.token_restore")
local infinity = require("token.internal.token_infinity")

---@class token.container
---@field id string Container unique identifier
---@field config_group string|nil Configuration group name
---@field _state_data token.container_data Reference to state data
---@field _tokens table<string, token.value> Runtime token instances
---@field on_token_change event Per-container change event
---@field on_token_visual_change event Per-container visual change event
---@field on_token_restore_change event Per-container restore change event
local M = {}


---Create a new container instance
---@param container_id string Unique container identifier
---@param config_group string|nil Configuration group (optional)
---@param state_data token.container_data Reference to state data
---@return token.container
function M.create(container_id, config_group, state_data)
	---@type token.container
	local instance = setmetatable({}, { __index = M })

	instance.id = container_id
	instance.config_group = config_group
	instance._state_data = state_data
	instance._tokens = {}

	-- Create per-container events
	instance.on_token_change = event.create()
	instance.on_token_visual_change = event.create()
	instance.on_token_restore_change = event.create()

	-- Load existing tokens from state
	for token_id, amount in pairs(state_data.tokens) do
		instance:_create_token(token_id, amount)
	end

	return instance
end


---Create or get a token instance
---@private
---@param token_id string
---@param initial_amount number|nil
---@return token.value
function M:_create_token(token_id, initial_amount)
	if self._tokens[token_id] then
		return self._tokens[token_id]
	end

	local token_config = config.get_token_config(token_id, self.config_group)
	local amount = initial_amount or self._state_data.tokens[token_id] or token_config.default or 0
	local token = value.create(token_config, amount)

	-- Register callbacks
	token:on_change(function(token_instance, delta, reason)
		self._state_data.tokens[token_id] = token_instance:get()
		-- Fire per-container event
		self.on_token_change:trigger(token_id, token_instance:get(), reason)
	end)

	token:on_visual_change(function(token_instance, delta)
		-- Fire per-container event
		self.on_token_visual_change:trigger(token_id, token_instance:get_visual())
	end)

	self._tokens[token_id] = token
	return token
end


---Get token instance
---@param token_id string|token.token_config_data
---@return token.value
function M:token(token_id)
	if type(token_id) == "table" then
		assert(token_id.id, "Token config data must have an id field")
		token_id = token_id.id
	end
	---@cast token_id string

	if not self._tokens[token_id] then
		return self:_create_token(token_id)
	end
	return self._tokens[token_id]
end


---Get container state data
---@nodiscard
---@return token.container_data
---**For internal use only by token module plugins (restore/infinity)**
function M:get_state_data()
	return self._state_data
end


---Add tokens to the container
---@param token_id string|token.token_config_data
---@param amount number
---@param reason string|nil
---@param visual_later boolean|nil
---@return number New token amount
function M:add(token_id, amount, reason, visual_later)
	return self:token(token_id):add(amount, reason, visual_later)
end


---Set token amount in the container
---@param token_id string|token.token_config_data
---@param amount number
---@param reason string|nil
---@param visual_later boolean|nil
---@return number New token amount
function M:set(token_id, amount, reason, visual_later)
	return self:token(token_id):set(amount, reason, visual_later)
end


---Get token amount from the container
---@param token_id string|token.token_config_data
---@return number|any
function M:get(token_id)
	local token = self._tokens[token_id]
	if not token then
		token = self:token(token_id)
	end

	return token:get()
end


---Pay (subtract) tokens from the container
---@param token_id string
---@param amount number
---@param reason string|nil
---@param visual_later boolean|nil
---@return boolean True if payment was successful
function M:pay(token_id, amount, reason, visual_later)
	-- Check infinity first
	if self:is_infinity(token_id) then
		return true
	end

	local result = self:token(token_id):pay(amount, reason, visual_later)
	return result or false
end


---Check if container has enough tokens
---@param token_id string
---@param amount number
---@return boolean
function M:is_enough(token_id, amount)
	if self:is_infinity(token_id) then
		return true
	end

	return self:token(token_id):check(amount)
end


---Check if token is empty (zero)
---@param token_id string
---@return boolean
function M:is_empty(token_id)
	return self:get(token_id) == 0
end


---Check if token is at maximum value
---@param token_id string
---@return boolean
function M:is_max(token_id)
	local amount = self:get(token_id)
	local token_config = config.get_token_config(token_id, self.config_group)
	if not token_config or not amount then
		return false
	end
	return (token_config.max and amount == token_config.max) or false
end


---Add multiple tokens to the container
---@param tokens table<string, number>|nil
---@param reason string|nil
---@param visual_later boolean|nil
function M:add_many(tokens, reason, visual_later)
	if not tokens then
		return
	end

	for token_id, amount in pairs(tokens) do
		self:add(token_id, amount, reason, visual_later)
	end
end


---Set multiple tokens in the container
---@param tokens table<string, number>|nil
---@param reason string|nil
---@param visual_later boolean|nil
function M:set_many(tokens, reason, visual_later)
	if not tokens then
		return
	end

	for token_id, amount in pairs(tokens) do
		self:set(token_id, amount, reason, visual_later)
	end
end


---Pay multiple tokens from the container
---@param tokens table<string, number>
---@param reason string|nil
---@param visual_later boolean|nil
---@return boolean True if all payments were successful
function M:pay_many(tokens, reason, visual_later)
	-- First check if we have enough of everything
	local is_enough = self:is_enough_many(tokens)

	if not is_enough then
		return false
	end

	-- Pay all tokens
	for token_id, amount in pairs(tokens) do
		self:pay(token_id, amount, reason, visual_later)
	end

	return true
end


---Check if container has enough of multiple tokens
---@param tokens table<string, number>|nil
---@return boolean
function M:is_enough_many(tokens)
	if not tokens then
		return true
	end

	for token_id, amount in pairs(tokens) do
		if not self:is_enough(token_id, amount) then
			return false
		end
	end

	return true
end


---Get all tokens from the container
---@return table<string, number>
function M:get_many()
	local result = {}

	for token_id, token in pairs(self._tokens) do
		result[token_id] = token:get()
	end

	return result
end


---Sync visual debt for a token
---@param token_id string
---@return number The visual debt that was synced
function M:sync_visual(token_id)
	return self:token(token_id):sync_visual()
end


---Add visual debt to a token
---@param token_id string
---@param amount number
---@return number The new visual value
function M:add_visual(token_id, amount)
	return self:token(token_id):add_visual(amount)
end


---Get visual value of a token
---@param token_id string
---@return number
function M:get_visual(token_id)
	return math.max(0, self:token(token_id):get_visual())
end


---Get total sum for a token
---@param token_id string
---@return number
function M:get_total_sum(token_id)
	return self:token(token_id):get_total_sum()
end


---Get token configuration
---@param token_id string
---@return token.token_config_data
function M:get_token_config(token_id)
	return config.get_token_config(token_id, self.config_group)
end


---Add tokens from a token group to container
---@param group_id string Token group id
---@param reason string|nil Optional reason for tracking
---@param visual_later boolean|nil If true, visual update will be delayed
function M:add_group(group_id, reason, visual_later)
	local tokens = config.get_group(group_id)
	if not tokens then
		logger:error("No token group with id", group_id)
		return
	end

	self:add_many(tokens, reason, visual_later)
end


---Set tokens in container to match a token group
---@param group_id string Token group id
---@param reason string|nil Optional reason for tracking
---@param visual_later boolean|nil If true, visual update will be delayed
function M:set_group(group_id, reason, visual_later)
	local tokens = config.get_group(group_id)
	if not tokens then
		logger:error("No token group with id", group_id)
		return
	end

	self:set_many(tokens, reason, visual_later)
end


---Pay tokens from container using a token group as cost
---@param group_id string Token group id
---@param reason string|nil Optional reason for tracking
---@param visual_later boolean|nil If true, visual update will be delayed
---@return boolean True if payment was successful, false otherwise
function M:pay_group(group_id, reason, visual_later)
	local tokens = config.get_group(group_id)
	if not tokens then
		logger:error("No token group with id", group_id)
		return false
	end

	return self:pay_many(tokens, reason, visual_later)
end


---Check if container has enough tokens to pay for a token group
---@param group_id string Token group id
---@return boolean True if enough tokens are available, false otherwise
function M:is_enough_group(group_id)
	local tokens = config.get_group(group_id)
	if not tokens then
		logger:error("No token group with id", group_id)
		return false
	end

	return self:is_enough_many(tokens)
end


-- Integrate token_restore methods
M.set_restore_config = restore.set_restore_config
M.get_restore_config = restore.get_restore_config
M.set_restore_config_enabled = restore.set_restore_config_enabled
M.is_restore_config_enabled = restore.is_restore_config_enabled
M.remove_restore_config = restore.remove_restore_config
M.reset_restore_timer = restore.reset_restore_timer
M.get_time_to_restore = restore.get_time_to_restore


-- Integrate token_infinity methods
M.add_infinity_time = infinity.add_infinity_time
M.is_infinity = infinity.is_infinity
M.get_infinity_time = infinity.get_infinity_time
M.set_infinity_time = infinity.set_infinity_time


return M

