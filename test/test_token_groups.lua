local mock_time = require("deftest.mock.time")

local table_len = function(t)
	local count = 0
	for _ in pairs(t) do count = count + 1 end
	return count
end

return function()
	describe("Tokens", function()
		local token ---@type token
		local test_container ---@type token.container
		local wallet ---@type token.container

		local TEST_CONTAINER_ID = "test_container"
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
			token_configs = {},
			token_groups = CONFIG_TOKEN_GROUPS,
			lots = CONGIG_LOTS
		})
		test_container = token.create_container(TEST_CONTAINER_ID)
		wallet = token.create_container(WALLET_ID)

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

			assert(not test_container:is_enough_many(tokens))
			test_container:add_many(tokens)

			assert(test_container:is_enough_many(tokens))
			assert(test_container:get("money") == 100)
			assert(test_container:get("exp") == 50)
			assert(test_container:get("item") == 10)

			test_container:pay_many(tokens)
			assert(test_container:get("money") == 0)
			assert(test_container:get("exp") == 0)
			assert(test_container:get("item") == 0)
			assert(not test_container:is_enough_many(tokens))
		end)

		it("Should add/pay/is_enough by token_group_id", function()
			assert(not test_container:is_enough_group("iap_2"))

			test_container:add_group("iap_2")
			assert(test_container:is_enough_group("iap_2"))
			assert(test_container:get("money") == 1000)
			assert(test_container:get("energy") == 10)

			test_container:pay_group("iap_2")
			assert(test_container:get("money") == 0)
			assert(test_container:get("energy") == 0)
		end)

		it("Should get tokens by group_id", function()
			local tokens = token.get_token_group("reward2")

			assert(table_len(tokens) == 2)

			test_container:add_many(tokens)
			assert(test_container:get("energy") == 50)
			assert(test_container:get("level") == 2)
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
