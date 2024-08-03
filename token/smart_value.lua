--- Smart value token

---@class token.smart_value.data_table
---@field amount number
---@field total_sum number

---@class token.smart_value
---@field data_table token.smart_value.data_table
---@field params token.token_config_data
local M = {}


---Create new smart value token
---@param params token.token_config_data
---@param amount number
---@return token.smart_value
function M.create(params, amount)
	---@type token.smart_value
	local instance = setmetatable({}, { __index = M })
	instance.params = params or {}
	instance.data_table = {
		amount = amount or instance.params.default or 0,
		total_sum = 0,
	}

	instance:sync_visual()
	return instance
end


---Set value to token
---@param value number
---@param reason string|nil
---@param visual_later boolean|nil
---@return number
function M:set(value, reason, visual_later)
	local min_value = self.params.min
	if min_value then
		value = math.max(min_value, value)
	end

	local max_value = self.params.max
	if max_value then
		value = math.min(value, max_value)
	end

	local old_value = self:get()
	local delta = value - old_value

	self.data_table.amount = value
	if delta > 0 then
		self.data_table.total_sum = self.data_table.total_sum + delta
	end

	if visual_later then
		self.visual_credit = self.visual_credit + (value - old_value)
	end

	if delta ~= 0 then
		if self._on_change_callbacks then
			for i = 1, #self._on_change_callbacks do
				self._on_change_callbacks[i](self, delta, reason)
			end
		end
	end

	if not visual_later then
		if self._on_visual_change_callbacks then
			for i = 1, #self._on_visual_change_callbacks do
				self._on_visual_change_callbacks[i](self, delta)
			end
		end
	end

	return self:get()
end


function M:get()
	return self.data_table.amount
end


---Add value to token
---@param value number
---@param reason string|nil
---@param visual_later boolean|nil
---@return number
function M:add(value, reason, visual_later)
	local prev_value = self:get()
	local new_value = self:set(prev_value + value, reason, visual_later)
	return new_value
end


function M:sync_visual()
	local prev_value = self.visual_credit
	self.visual_credit = 0

	if prev_value ~= 0 then
		if self._on_visual_change_callbacks then
			for i = 1, #self._on_visual_change_callbacks do
				self._on_visual_change_callbacks[i](self, prev_value)
			end
		end
	end

	return prev_value
end


function M:add_visual(value)
	self.visual_credit = self.visual_credit - value

	if value ~= 0 then
		if self._on_visual_change_callbacks then
			for i = 1, #self._on_visual_change_callbacks do
				self._on_visual_change_callbacks[i](self, value)
			end
		end
	end
end


function M:get_visual()
	return self:get() - self.visual_credit
end


function M:get_total_sum()
	return self.data_table.total_sum
end


function M:check(value)
	return self:get() >= value
end


---Pay value from token
---@param value number
---@param reason string|nil
---@param visual_later boolean|nil
---@return boolean
function M:pay(value, reason, visual_later)
	value = value or 1

	if self:check(value) then
		self:add(-value, reason, visual_later)
		return true
	end

	return false
end


function M:set_max()
	if self.params.max then
		self:set(self.params.max)
	end
end


function M:on_change(callback)
	self._on_change_callbacks = self._on_change_callbacks or {}
	table.insert(self._on_change_callbacks, callback)
end


function M:on_visual_change(callback)
	self._on_visual_change_callbacks = self._on_visual_change_callbacks or {}
	table.insert(self._on_visual_change_callbacks, callback)
end


--- Return token_id from token.params.id
function M:get_token_id()
	return self.params.id
end


return M
