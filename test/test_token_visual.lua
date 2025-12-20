local mock_time = require("deftest.mock.time")

return function()
	describe("Token Visual API", function()
		local token ---@type token
		local test_container ---@type token.container

		local TEST_CONTAINER_ID = "test_container"

	before(function()
		token = require("token.token") --[[@as token]]
		token.reset_state()
		token.init({})
		test_container = token.container(TEST_CONTAINER_ID)

		mock_time.mock()
		mock_time.set(0)
	end)

		after(function()
			mock_time.unmock()
			token.update()
		end)

		it("Should correct work visual api", function()
			test_container:add("money", 1000)
			assert(test_container:get("money") == 1000)
			assert(test_container:get_visual("money") == 1000)

			test_container:add_visual("money", -100)
			assert(test_container:get_visual("money") == 900)

			test_container:sync_visual("money")
			assert(test_container:get_visual("money") == 1000)

			test_container:add("money", 100, "test", true)
			assert(test_container:get("money") == 1100)
			assert(test_container:get_visual("money") == 1000)

			test_container:add_visual("money", 50)
			assert(test_container:get_visual("money") == 1050)

			local delta = test_container:sync_visual("money")
			assert(test_container:get_visual("money") == 1100)
			assert(delta == 50)
		end)
	end)
end

