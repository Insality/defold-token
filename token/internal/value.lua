--- Token value wrapper
--- Manages individual token instances with value, visual debt, and total sum tracking

---@class token.value
---@field amount number Current token amount
---@field total_sum number Total accumulated amount (never decreases)
---@field visual_credit number Visual debt amount
---@field config token.token_config_data Token configuration
---@field _on_change_callbacks function[]|nil Callbacks for value changes
---@field _on_visual_change_callbacks function[]|nil Callbacks for visual changes
local M = {}


---Create new token value instance
---@param config token.token_config_data Token configuration
---@param amount number Initial amount
---@return token.value
function M.create(config, amount)
	---@type token.value
	local instance = setmetatable({}, { __index = M })
	instance.config = config or {}
	instance.amount = amount or instance.config.default or 0
	instance.total_sum = 0
	instance.visual_credit = 0

	return instance
end


---Set token value
---@param value number New value
---@param reason string|nil Optional reason for tracking
---@param visual_later boolean|nil If true, visual update will be delayed
---@return number The new value after applying min/max constraints
function M:set(value, reason, visual_later)
	-- Apply min constraint
	local min_value = self.config.min
	if min_value then
		value = math.max(min_value, value)
	end

	-- Apply max constraint
	local max_value = self.config.max
	if max_value then
		value = math.min(value, max_value)
	end

	local old_value = self.amount
	local delta = value - old_value

	self.amount = value

	-- Update total sum only on positive changes
	if delta > 0 then
		self.total_sum = self.total_sum + delta
	end

	-- Handle visual debt
	if visual_later then
		self.visual_credit = self.visual_credit + delta
	end

	-- Fire change callbacks
	if delta ~= 0 then
		if self._on_change_callbacks then
			for i = 1, #self._on_change_callbacks do
				self._on_change_callbacks[i](self, delta, reason)
			end
		end
	end

	-- Fire visual change callbacks (if not deferred)
	if not visual_later and delta ~= 0 then
		if self._on_visual_change_callbacks then
			for i = 1, #self._on_visual_change_callbacks do
				self._on_visual_change_callbacks[i](self, delta)
			end
		end
	end

	return self.amount
end


---Get current token value
---@return number
function M:get()
	return self.amount
end


---Add to token value
---@param value number Amount to add
---@param reason string|nil Optional reason for tracking
---@param visual_later boolean|nil If true, visual update will be delayed
---@return number The new value
function M:add(value, reason, visual_later)
	return self:set(self.amount + value, reason, visual_later)
end


---Check if token has enough value
---@param value number Amount to check
---@return boolean
function M:check(value)
	return self.amount >= value
end


---Pay (subtract) value from token
---@param value number Amount to pay
---@param reason string|nil Optional reason for tracking
---@param visual_later boolean|nil If true, visual update will be delayed
---@return boolean True if payment was successful, false otherwise
function M:pay(value, reason, visual_later)
	value = value or 1

	if self:check(value) then
		self:add(-value, reason, visual_later)
		return true
	end

	return false
end


---Sync visual debt with actual value
---@return number The visual debt that was synced
function M:sync_visual()
	local prev_credit = self.visual_credit
	self.visual_credit = 0

	if prev_credit ~= 0 then
		if self._on_visual_change_callbacks then
			for i = 1, #self._on_visual_change_callbacks do
				self._on_visual_change_callbacks[i](self, prev_credit)
			end
		end
	end

	return prev_credit
end


---Add visual debt to token
---@param value number Amount to add (positive shows more, negative shows less)
---@return number The new visual value
function M:add_visual(value)
	self.visual_credit = self.visual_credit - value

	if value ~= 0 then
		if self._on_visual_change_callbacks then
			for i = 1, #self._on_visual_change_callbacks do
				self._on_visual_change_callbacks[i](self, value)
			end
		end
	end

	return self:get_visual()
end


---Get visual value (actual value - visual debt)
---@return number
function M:get_visual()
	return self.amount - self.visual_credit
end


---Get total sum (all tokens ever accumulated)
---@return number
function M:get_total_sum()
	return self.total_sum
end


---Set token to maximum value
function M:set_max()
	if self.config.max then
		self:set(self.config.max)
	end
end


---Register callback for value changes
---@param callback fun(token: token.value, delta: number, reason: string|nil)
function M:on_change(callback)
	self._on_change_callbacks = self._on_change_callbacks or {}
	table.insert(self._on_change_callbacks, callback)
end


---Register callback for visual changes
---@param callback fun(token: token.value, delta: number)
function M:on_visual_change(callback)
	self._on_visual_change_callbacks = self._on_visual_change_callbacks or {}
	table.insert(self._on_visual_change_callbacks, callback)
end


---Get token id from config
---@return string|nil
function M:get_token_id()
	return self.config.id
end


return M

