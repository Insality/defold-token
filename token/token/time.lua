--- Time utilities for token system
local M = {}

---Get current time in seconds
---Override this to use custom time source
---@return number
function M.get_time()
	return socket.gettime()
end

return M

