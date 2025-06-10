local M = {}

---@class token.container
---@field tokens table<string, number> Container tokens data
---@field restore_config table<string, token.token_restore_config>|nil
---@field infinity_timers table<string, number>|nil

---@class token.token_restore_config
---@field is_enabled boolean
---@field last_restore_time number Last restore time in seconds since epoch
---@field disabled_time number|nil
---@field timer number Timer in seconds for restore
---@field value number Value for restore per timer
---@field max number Max accumulated value for restore offline

---@class token.token_restore_param
---@field timer number -- Timer in seconds for restore
---@field value number|nil -- Value for restore per timer. Default is 1
---@field max number|nil -- Max accumulated value for restore. Nil means no limit

---@class token.token_config_data
---@field id string|nil Token id, Autofill
---@field default number|nil Default value
---@field min number|nil Min value
---@field max number|nil Max value

---@class token.lot
---@field price string Group id
---@field reward string Group id

---Logger interface
---@class token.logger
---@field trace fun(logger: token.logger, message: string, data: any|nil)
---@field debug fun(logger: token.logger, message: string, data: any|nil)
---@field info fun(logger: token.logger, message: string, data: any|nil)
---@field warn fun(logger: token.logger, message: string, data: any|nil)
---@field error fun(logger: token.logger, message: string, data: any|nil)


---@class token.config
---@field tokens table<string, token.token_config_data>|nil Key is token_id
---@field groups table<string, table<string, number>>|nil Key is group_id
---@field lots table<string, token.lot>|nil Key is lot_id
---@field containers table<string, token.container>|nil Key is container_id
M.CONFIG = {
	TOKENS = {},
	TOKEN_GROUPS = {},
	LOTS = {},
	CONTAINERS = {}
}


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
---@param config_or_path string|token.config Lua table or path to token config. Example: "/resources/tokens.json"
---@return boolean True if success
function M.load_config(config_or_path)
	if type(config_or_path) == "string" then
		local config = M.load_json(config_or_path)
		if not config then
			M.logger:error("Can't load token config", config_or_path)
			return false
		end

		config_or_path = config
	end

	M.CONFIG.TOKENS = config_or_path or {}
	M.CONFIG.TOKEN_GROUPS = {}
	M.CONFIG.LOTS = {}
	M.CONFIG.CONTAINERS = {}

	-- Autofill token id
	for token, data in pairs(M.CONFIG.TOKENS) do
		data.id = token
	end

	return true
end


---Register tokens in the token system
---@param token_id string Token id
---@param data token.token_config_data Token config data
---@return nil
function M.register_token(token_id, data)
	local tokens_config = M.CONFIG.TOKENS
	tokens_config[token_id] = data
	data.id = token_id
end


---Register token groups in the token system
---@param group_id string Group id
---@param tokens table<string, number> Table mapping token IDs to token config data
---@return nil
function M.register_token_group(group_id, tokens)
	local token_groups_config = M.CONFIG.TOKEN_GROUPS
	token_groups_config[group_id] = tokens
end


---Register lot in the token system
---@param lot_id string Lot id
---@param lot token.lot Lot config
---@return nil
function M.register_lot(lot_id, lot)
	local lots_config = M.CONFIG.LOTS
	lots_config[lot_id] = lot
end


---Register container in the token system
---@param container_id string Container id
---@param container token.container Container config
---@return nil
function M.register_container(container_id, container)
	local containers_config = M.CONFIG.CONTAINERS
	containers_config[container_id] = container
end


return M
