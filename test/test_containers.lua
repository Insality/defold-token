return function()
	describe("Token Containers", function()
		---@type token
		local token = {}
		local TEST_CONTAINER = "test_container"
		local WALLET_ID = "wallet"

		before(function()
			token = require("token.token")

			token.reset_state()
			token.set_logger(nil)
			token.init({})
			token.create_container(TEST_CONTAINER)
			token.create_container(WALLET_ID)
		end)

		it("Should work add tokens from other container", function()
			assert(token.get(TEST_CONTAINER, "money") == 0)
			token.add(TEST_CONTAINER, "money", 10)
			assert(token.get(TEST_CONTAINER, "money") == 10)

			assert(token.get(WALLET_ID, "money") == 0)
			local tokens = token.get_many(TEST_CONTAINER)
			token.add_many(WALLET_ID, tokens)
			assert(token.get(WALLET_ID, "money") == 10)
		end)

		it("Should clear container", function()
			token.add(TEST_CONTAINER, "money", 10)
			token.add(TEST_CONTAINER, "energy", 10)
			assert(token.get(TEST_CONTAINER, "money") == 10)
			assert(token.get(TEST_CONTAINER, "energy") == 10)

			token.clear_container(TEST_CONTAINER)
			assert(token.get(TEST_CONTAINER, "money") == 0)
			assert(token.get(TEST_CONTAINER, "energy") == 0)

			assert(token.is_container_exist(TEST_CONTAINER))
		end)

		it("Should delete container", function()
			token.add(TEST_CONTAINER, "money", 10)
			token.add(TEST_CONTAINER, "energy", 10)
			assert(token.get(TEST_CONTAINER, "money") == 10)
			assert(token.get(TEST_CONTAINER, "energy") == 10)

			token.delete_container(TEST_CONTAINER)
			assert(token.get(TEST_CONTAINER, "money") == nil)
			assert(token.get(TEST_CONTAINER, "energy") == nil)

			assert(not token.is_container_exist(TEST_CONTAINER))
		end)
	end)
end
