--- Token configuration management module
--- Manages token configs, groups, and lots

---@class token.config
---@field tokens table<string, table<string, token.token_config_data>>|nil
---@field groups table<string, table<string, number>>|nil
---@field lots table<string, token.lot>|nil

---@class token.token_config_data
---@field id string|nil Token id, Autofill
---@field default number|nil Default value
---@field min number|nil Min value
---@field max number|nil Max value

---@class token.lot
---@field price string Group id
---@field reward string Group id

local M = {}

---Token configurations by config group
---Structure: { [config_group]: { [token_id]: token_config_data } }
---@type table<string, table<string, token.token_config_data>>
M.token_configs = {
	default = {}
}

---Token groups (collections of tokens for rewards/prices)
---Structure: { [group_id]: { [token_id]: amount } }
---@type table<string, table<string, number>>
M.token_groups = {}

---Lots (price + reward pairs)
---Structure: { [lot_id]: { price: group_id, reward: group_id } }
---@type table<string, token.lot>
M.lots = {}


---Load configuration from a table
---@param config token.config Configuration table with token_configs, token_groups, and lots
function M.load_config(config)
	M.token_configs = config.tokens or M.token_configs
	M.token_groups = config.groups or M.token_groups
	M.lots = config.lots or M.lots

	for _, tokens in pairs(M.token_configs) do
		for token_id, data in pairs(tokens) do
			data.id = token_id
		end
	end
end


---Get token configuration for a specific token
---Lookup order: config_group → "default" group → empty table
---@param token_id string
---@param config_group string|nil
---@return token.token_config_data
function M.get_token_config(token_id, config_group)
	-- Try specific config group first
	if config_group and M.token_configs[config_group] then
		local config = M.token_configs[config_group][token_id]
		if config then
			return config
		end
	end

	-- Fall back to default group
	if M.token_configs.default then
		local config = M.token_configs.default[token_id]
		if config then
			return config
		end
	end

	-- Return empty config with just the id
	return { id = token_id }
end


---Get token group by id
---@param group_id string
---@return table<string, number>|nil
function M.get_group(group_id)
	return M.token_groups[group_id]
end


---Get lot by id
---@param lot_id string
---@return token.lot|nil
function M.get_lot(lot_id)
	return M.lots[lot_id]
end


---Register a single token configuration
---@param token_id string
---@param data token.token_config_data
---@param config_group string|nil Config group (defaults to "default")
function M.register_token(token_id, data, config_group)
	config_group = config_group or "default"

	if not M.token_configs[config_group] then
		M.token_configs[config_group] = {}
	end

	data.id = token_id
	M.token_configs[config_group][token_id] = data
end


---Register multiple tokens
---@param tokens table<string, token.token_config_data>
---@param config_group string|nil Config group (defaults to "default")
function M.register_tokens(tokens, config_group)
	for token_id, data in pairs(tokens) do
		M.register_token(token_id, data, config_group)
	end
end


---Register a token group
---@param group_id string
---@param tokens table<string, number>
function M.register_group(group_id, tokens)
	M.token_groups[group_id] = tokens
end


---Register multiple token groups
---@param groups table<string, table<string, number>>
function M.register_groups(groups)
	for group_id, tokens in pairs(groups) do
		M.register_group(group_id, tokens)
	end
end


---Register a lot
---@param lot_id string
---@param lot token.lot
function M.register_lot(lot_id, lot)
	M.lots[lot_id] = lot
end


---Register multiple lots
---@param lots table<string, token.lot>
function M.register_lots(lots)
	for lot_id, lot in pairs(lots) do
		M.register_lot(lot_id, lot)
	end
end


return M

