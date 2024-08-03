return function()
	---@type token
	local token = {}

	describe("Token Logger", function()
		before(function()
			token = require("token.token")
		end)
		
		it("token Set logger", function()
			local EMPTY_FUNCTION = function(_, message, context) end
			local logger =  {
				trace = EMPTY_FUNCTION,
				debug = EMPTY_FUNCTION,
				info = EMPTY_FUNCTION,
				warn = EMPTY_FUNCTION,
				error = EMPTY_FUNCTION,
			}
			token.set_logger(logger)
			assert(token.get_logger() == logger)
		end)

		it("Should handle error in callback", function()
			local called = false

			local EMPTY_FUNCTION = function(_, message, context) end
			local logger =  {
				trace = EMPTY_FUNCTION,
				debug = EMPTY_FUNCTION,
				info = EMPTY_FUNCTION,
				warn = EMPTY_FUNCTION,
				error = function() called = true end,
			}
			token.set_logger(logger)
			
			local value = token.get("unknown_container", "some_token")
			assert(called == true)
			assert(value == nil)
		end)
	end)
end
