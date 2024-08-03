local M = {}


---@type table<string, token.token_config_data> @Key is token_id
M.CONFIG_TOKENS = {}

---@type table<string, table<string, number>> @Key is group_id
M.CONFIG_TOKEN_GROUPS = {}

---@type table<string, token.lot> @Key is lot_id
M.CONFIG_LOTS = {}

---@type table<string, table<string, number>> @Key is container_id
M.CONFIG_CONTAINERS = {}

--- Use empty function to save a bit of memory
local EMPTY_FUNCTION = function(_, message, context) end

---@type token.logger
M.empty_logger = {
	trace = EMPTY_FUNCTION,
	debug = EMPTY_FUNCTION,
	info = EMPTY_FUNCTION,
	warn = EMPTY_FUNCTION,
	error = EMPTY_FUNCTION,
}

---@type token.logger
M.logger = {
	trace = function(_, msg) print("TRACE: " .. msg) end,
	debug = function(_, msg, data) pprint("DEBUG: " .. msg, data) end,
	info = function(_, msg, data) pprint("INFO: " .. msg, data) end,
	warn = function(_, msg, data) pprint("WARN: " .. msg, data) end,
	error = function(_, msg, data) error(msg) pprint(data) end
}


---Load JSON file from game resources folder (by relative path to game.project)
---Return nil if file not found or error
---@param json_path string
---@return table|nil
function M.load_json(json_path)
	local resource, is_error = sys.load_resource(json_path)
	if is_error or not resource then
		return nil
	end

	return json.decode(resource)
end


---Load token config from file or table
---@param config_or_path string|table
---@return boolean @True if success
function M.load_config(config_or_path)
	if type(config_or_path) == "string" then
		local config = M.load_json(config_or_path)
		if not config then
			M.logger:error("Can't load token config", config_or_path)
			return false
		end

		config_or_path = config
	end

	local config = config_or_path --[[@as token.config]]
	M.CONFIG_TOKENS = config_or_path.tokens or {}
	M.CONFIG_TOKEN_GROUPS = config_or_path.groups or {}
	M.CONFIG_LOTS = config_or_path.lots or {}
	M.CONFIG_CONTAINERS = config_or_path.containers or {}

	-- Autofill token id
	for token, data in pairs(M.CONFIG_TOKENS) do
		data.id = token
	end

	return true
end


return M
