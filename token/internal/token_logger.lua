---@class token.logger
---@field trace fun(_, msg: string, data: any)
---@field debug fun(_, msg: string, data: any)
---@field info fun(_, msg: string, data: any)
---@field warn fun(_, msg: string, data: any)
---@field error fun(_, msg: string, data: any)

local EMPTY_FUNCTION = function(_, message, context) end

---@type token.logger
local empty_logger = {
	trace = EMPTY_FUNCTION,
	debug = EMPTY_FUNCTION,
	info = EMPTY_FUNCTION,
	warn = EMPTY_FUNCTION,
	error = EMPTY_FUNCTION,
}


---@type token.logger
local default_logger = {
	trace = function(_, msg, data) print("TRACE: " .. msg, data) end,
	debug = function(_, msg, data) print("DEBUG: " .. msg, data) end,
	info = function(_, msg, data) print("INFO: " .. msg, data) end,
	warn = function(_, msg, data) print("WARN: " .. msg, data) end,
	error = function(_, msg, data) error(msg) print(data) end
}


---@class token.logger
local M = {}
local METATABLE = { __index = default_logger }

function M.set_logger(logger)
	METATABLE.__index = logger or empty_logger
end

return setmetatable(M, METATABLE)
