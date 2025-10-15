--- Token state management module
--- This module can be replaced before loading the token system

---@class token.state
---@field containers table<string, token.container_data>

---@class token.container_data
---@field tokens table<string, number>
---@field restore_config table<string, token.token_restore_config>|nil
---@field infinity_timers table<string, number>|nil

local M = {}

---Internal state storage
---@type token.state
local state = {
	containers = {}
}


---Reset state to default
function M.reset()
	state = {
		containers = {}
	}
end


---Get the entire state (for serialization)
---@return token.state
function M.get_state()
	return state
end


---Set the entire state (for deserialization)
---@param new_state token.state
function M.set_state(new_state)
	state = new_state
end


---Get container data from state
---@param container_id string
---@return token.container_data|nil
function M.get_container(container_id)
	return state.containers[container_id]
end


---Get all containers
---@return table<string, token.container_data>
function M.get_all_containers()
	return state.containers
end


---Create container in state
---@param container_id string
---@return token.container_data
function M.create_container(container_id)
	state.containers[container_id] = {
		tokens = {}
	}
	return state.containers[container_id]
end


---Delete container from state
---@param container_id string
function M.delete_container(container_id)
	state.containers[container_id] = nil
end


---Clear all tokens from container but keep the container
---@param container_id string
function M.clear_container(container_id)
	local container = state.containers[container_id]
	if container then
		container.tokens = {}
		container.restore_config = nil
		container.infinity_timers = nil
	end
end


---Check if container exists in state
---@param container_id string
---@return boolean
function M.has_container(container_id)
	return state.containers[container_id] ~= nil
end


return M

