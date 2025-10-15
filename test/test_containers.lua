return function()
	describe("Token Containers", function()
		local token ---@type token
		local test_container ---@type token.container
		local wallet ---@type token.container

		local TEST_CONTAINER_ID = "test_container"
		local WALLET_ID = "wallet"

	before(function()
		token = require("token.token")

		token.reset_state()
		token.set_logger(nil)
		token.init()
		test_container = token.container(TEST_CONTAINER_ID)
		wallet = token.container(WALLET_ID)
	end)

		it("Should work add tokens from other container", function()
			assert(test_container:get("money") == 0)
			test_container:add("money", 10)
			assert(test_container:get("money") == 10)

			assert(wallet:get("money") == 0)
			local tokens = test_container:get_many()
			wallet:add_many(tokens)
			assert(wallet:get("money") == 10)
		end)

		it("Should clear container", function()
			test_container:add("money", 10)
			test_container:add("energy", 10)
			assert(test_container:get("money") == 10)
			assert(test_container:get("energy") == 10)

			token.clear_container(TEST_CONTAINER_ID)
			test_container = token.container(TEST_CONTAINER_ID)
			assert(test_container:get("money") == 0)
			assert(test_container:get("energy") == 0)

			assert(token.is_container_exist(TEST_CONTAINER_ID))
		end)

		it("Should delete container", function()
			test_container:add("money", 10)
			test_container:add("energy", 10)
			assert(test_container:get("money") == 10)
			assert(test_container:get("energy") == 10)

			token.delete_container(TEST_CONTAINER_ID)
			assert(not token.is_container_exist(TEST_CONTAINER_ID))
		end)
	end)
end
