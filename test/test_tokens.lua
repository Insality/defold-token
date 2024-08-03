local mock_time = require("deftest.mock.time")

local table_len = function(t)
	local count = 0
	for _ in pairs(t) do count = count + 1 end
	return count
end

return function()
	describe("Tokens", function()
		---@type token
		local token = {}

		local TEST_CONTAINER = "test_container"
		local WALLET_ID = "wallet"

		local CONFIG_TOKEN_GROUPS = {
			iap_2 = {
				money = 1000,
				energy = 10
			},
			reward2 = {
				energy = 50,
				level = 2
			},
			money = {
				money = 100
			},
			energy = {
				energy = 10
			},
		}

		local CONGIG_LOTS = {
			lot1 = {
				price = "money",
				reward = "energy"
			}
		}

		before(function()
			token = require("token.token")

			token.reset_state()
			token.init({
				tokens = {},
				groups = CONFIG_TOKEN_GROUPS,
				lots = CONGIG_LOTS
			})
			token.create_container(TEST_CONTAINER)
			token.create_container(WALLET_ID)

			mock_time.mock()
			mock_time.set(0)
		end)

		after(function()
			mock_time.unmock()
		end)

		it("Should add/pay/is_enough by tokens_group", function()
			local tokens = {
				money = 100,
				exp = 50,
				item = 10
			}

			assert(not token.is_enough_many(TEST_CONTAINER, tokens))
			token.add_many(TEST_CONTAINER, tokens)

			assert(token.is_enough_many(TEST_CONTAINER, tokens))
			assert(token.get(TEST_CONTAINER, "money") == 100)
			assert(token.get(TEST_CONTAINER, "exp") == 50)
			assert(token.get(TEST_CONTAINER, "item") == 10)

			token.pay_many(TEST_CONTAINER, tokens)
			assert(token.get(TEST_CONTAINER, "money") == 0)
			assert(token.get(TEST_CONTAINER, "exp") == 0)
			assert(token.get(TEST_CONTAINER, "item") == 0)
			assert(not token.is_enough_many(TEST_CONTAINER, tokens))
		end)

		it("Should add/pay/is_enough by token_group_id", function()
			assert(not token.is_enough_group(TEST_CONTAINER, "iap_2"))

			token.add_group(TEST_CONTAINER, "iap_2")
			assert(token.is_enough_group(TEST_CONTAINER, "iap_2"))
			assert(token.get(TEST_CONTAINER, "money") == 1000)
			assert(token.get(TEST_CONTAINER, "energy") == 10)

			token.pay_group(TEST_CONTAINER, "iap_2")
			assert(token.get(TEST_CONTAINER, "money") == 0)
			assert(token.get(TEST_CONTAINER, "energy") == 0)
		end)

		it("Should get tokens by group_id", function()
			local tokens = token.get_token_group("reward2")

			assert(table_len(tokens) == 2)

			token.add_many(TEST_CONTAINER, tokens)
			assert(token.get(TEST_CONTAINER, "energy") == 50)
			assert(token.get(TEST_CONTAINER, "level") == 2)
		end)

		it("Should get tokens from lot reward and lot price", function()
			local price = token.get_lot_price("lot1") --[[@as table<string, number>]]
			local reward = token.get_lot_reward("lot1") --[[@as table<string, number>]]

			assert(table_len(price) == 1)
			assert(table_len(reward) == 1)
			assert(price["money"] == 100)
		end)
	end)
end
