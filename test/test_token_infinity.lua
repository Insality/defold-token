local mock_time = require("deftest.mock.time")

return function()
	describe("Token Infinity", function()
		local token ---@type token
		local test_container ---@type token.container
		local wallet ---@type token.container

		local TEST_CONTAINER_ID = "test_container"
		local WALLET_ID = "wallet"
		local CONFIG_TOKENS = {
			level = { default = 1, min = 1, max = 80 }
		}

	before(function()
		token = require("token.token") --[[@as token]]
		token.reset_state()
		token.init()
		token.register_tokens(CONFIG_TOKENS)
		test_container = token.container(TEST_CONTAINER_ID)
		wallet = token.container(WALLET_ID)

		mock_time.mock()
		mock_time.set(0)
	end)

		after(function()
			mock_time.unmock()
			token.update()
		end)

		it("Should correct work with infinity values", function()
			test_container:add("money", 100)
			test_container:add_infinity_time("money", 10)

			test_container:pay("money", 50)
			assert(test_container:get("money") == 100)

			test_container:pay("money", 50)
			assert(test_container:get("money") == 100)

			test_container:set("money", 50)
			assert(test_container:get("money") == 50)

			assert(test_container:is_infinity("money"))
			assert(test_container:get_infinity_time("money") == 10)
			assert(not test_container:is_infinity("level"))
			assert(test_container:get_infinity_time("level") == 0)

			assert(test_container:is_enough("money", 50))
			assert(test_container:is_enough("money", 100))
			assert(test_container:is_enough("money", 150))
		end)


		it("Should have correct infinity timer", function()
			wallet:set("energy", 10)

			wallet:add_infinity_time("energy", 10)

			local is_paid = wallet:pay("energy", 5)
			assert(is_paid)
			assert(wallet:get("energy") == 10)

			is_paid = wallet:pay("energy", 10)
			assert(is_paid)
			assert(wallet:get("energy") == 10)


			is_paid = wallet:pay("energy", 15)
			assert(is_paid)
			assert(wallet:get("energy") == 10)

			assert(wallet:is_infinity("energy"))
			assert(wallet:get_infinity_time("energy") == 10)
		end)
	end)
end

