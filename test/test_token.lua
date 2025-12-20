local mock_time = require("deftest.mock.time")

return function()
	describe("Defold Token", function()
		local token ---@type token
		local test_container ---@type token.container

		local TEST_CONTAINER_ID = "test_container"
		local CONFIG_TOKEN = {
				level = { default = 1, min = 1, max = 80 }
		}

	before(function()
		token = require("token.token") --[[@as token]]
		token.reset_state()
		token.init()
		token.register_tokens(CONFIG_TOKEN)
		test_container = token.container(TEST_CONTAINER_ID)

		mock_time.mock()
		mock_time.set(0)
	end)

		after(function()
			mock_time.unmock()
			token.update()
		end)

		it("Should have basic api get/set/add/pay", function()
			assert(test_container:get("money") == 0)

			local new_value = test_container:add("money", 10)
			assert(new_value == 10)
			assert(test_container:get("money") == 10)

			new_value = test_container:set("money", 20)
			assert(new_value == 20)
			assert(test_container:get("money") == 20)

			local is_paid = test_container:pay("money", 5)
			assert(is_paid)
			assert(test_container:get("money") == 15)
		end)


		it("Should correct work check functions", function()
			test_container:add("money", 100)
			assert(not test_container:is_empty("money"))
			assert(test_container:is_empty("exp"))

			assert(test_container:is_enough("money", 50))
			assert(test_container:is_enough("money", 100))
			assert(not test_container:is_enough("money", 150))

			assert(not test_container:is_max("money"))

			local new_value = test_container:add("level", 90)
			-- Default: 1, max: 80
			assert(new_value == 80)
			assert(test_container:is_max("level"))
		end)


		it("Token have a total_sum value", function()
			test_container:add("money", 100)
			test_container:add("money", 100)
			test_container:pay("money", 50)

			assert(test_container:get_total_sum("money") == 200)
		end)
	end)
end
