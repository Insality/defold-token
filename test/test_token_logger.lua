return function()
	describe("Token Logger", function()
		local token ---@type token
		local test_container ---@type token.container

	local debug_called = false
	local warn_called = false
	local error_called = false

	local EMPTY_FUNCTION = function(_, message, context) end

	local function reset_logger_state()
		debug_called = false
		warn_called = false
		error_called = false
	end

	local function create_test_logger()
		return {
			trace = EMPTY_FUNCTION,
			debug = function(_, message, context)
				debug_called = true
			end,
			info = EMPTY_FUNCTION,
			warn = function(_, message, context)
				warn_called = true
			end,
			error = function(_, message, context)
				error_called = true
			end,
		}
	end

	before(function()
		token = require("token.token")
		token.reset_state()
		reset_logger_state()
	end)

	it("Should call debug when creating container", function()
		token.set_logger(create_test_logger())
		token.init()

		assert(not debug_called, "Debug should not be called yet")

		test_container = token.container("test_wallet")

		assert(debug_called, "Debug should be called when creating container")
	end)


	it("Should call warn when clearing non-existing container", function()
		token.set_logger(create_test_logger())
		token.init()

		assert(not warn_called, "Warn should not be called yet")

		token.clear_container("non_existing_container")

		assert(warn_called, "Warn should be called for non-existing container")
	end)


	it("Should call error when using non-existing token group", function()
		token.set_logger(create_test_logger())
		token.init()
		test_container = token.container("test_wallet")

		reset_logger_state()
		assert(not error_called, "Error should not be called yet")

		test_container:add_group("non_existing_group")

		assert(error_called, "Error should be called for non-existing group")
	end)


	it("Should call error when getting non-existing token group", function()
		token.set_logger(create_test_logger())
		token.init()

		reset_logger_state()
		assert(not error_called, "Error should not be called yet")

		local group = token.get_token_group("non_existing_group")

		assert(error_called, "Error should be called for non-existing group")
		assert(group == nil, "Should return nil for non-existing group")
	end)


	it("Should call error when resetting non-existing restore timer", function()
		token.set_logger(create_test_logger())
		token.init()
		test_container = token.container("test_wallet")

		reset_logger_state()
		assert(not error_called, "Error should not be called yet")

		test_container:reset_restore_timer("energy")

		assert(error_called, "Error should be called when resetting non-existing timer")
	end)


		it("Should work without logger set", function()
			-- No logger set, operations should still work
			token.init()
			test_container = token.container("test_wallet")

			-- These should not crash even without logger
			test_container:add("money", 100)
			token.clear_container("non_existing")
			test_container:add_group("non_existing_group")

			assert(test_container:get("money") == 100)
		end)


		it("Should allow changing logger at runtime", function()
			local logger1 = create_test_logger()
			local logger2 = create_test_logger()

			token.set_logger(logger1)
			token.init()

			reset_logger_state()
			token.container("wallet1")
			assert(debug_called, "First logger should be called")

			reset_logger_state()
			token.set_logger(logger2)
			token.container("wallet2")
			assert(debug_called, "Second logger should be called")
		end)
	end)
end
