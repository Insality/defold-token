---@class token.config
---@field tokens table<string, token.token_config_data>|nil @Key is token_id
---@field groups table<string, table<string, number>>|nil @Key is group_id
---@field lots table<string, token.lot>|nil @Key is lot_id
---@field containers table<string, token.container>|nil @Key is container_id

---@class token.state
---@field containers table<string, token.container>

---@class token.container
---@field tokens table<string, number> Container tokens data
---@field restore_config table<string, token.token_restore_config>|nil
---@field infinity_timers table<string, number>|nil

---@class token.token_restore_config
---@field is_enabled boolean
---@field last_restore_time number @Last restore time in seconds since epoch
---@field disabled_time number|nil
---@field timer number @Timer in seconds for restore
---@field value number @Value for restore per timer
---@field max number @Max accumulated value for restore offline

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
---@field price string @Group id
---@field reward string @Group id

---Logger interface
---@class token.logger
---@field trace fun(logger: token.logger, message: string, data: any|nil)
---@field debug fun(logger: token.logger, message: string, data: any|nil)
---@field info fun(logger: token.logger, message: string, data: any|nil)
---@field warn fun(logger: token.logger, message: string, data: any|nil)
---@field error fun(logger: token.logger, message: string, data: any|nil)
