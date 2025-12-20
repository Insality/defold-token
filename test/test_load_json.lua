return function()
	describe("Token Load JSON config", function()
		local token ---@type token
		local wallet ---@type token.container
		local WALLET_ID = "wallet"

	before(function()
		token = require("token.token")
		token.reset_state()
	end)

		it("Load token config from resources JSON file", function()
			token.init()
			token.register_tokens("/test/resources/token_config.json")
			token.register_token_groups("/test/resources/token_groups.json")
			token.register_lots("/test/resources/token_lots.json")
			wallet = token.container(WALLET_ID)

			local money = wallet:get("money")
			local level = wallet:get("level")
			assert(money == 0, "money is " .. tostring(money) .. ", expected 0")
			assert(level == 1, "level is " .. tostring(level) .. ", expected 1")

			local group_1 = token.get_token_group("reward_1")
			assert(group_1)
			assert(group_1["money"] == 100)
			assert(group_1["crystal"] == 10)

			local lot_price = token.get_lot_price("shop_1")
			assert(lot_price)
			assert(lot_price["money"] == 100)

			local lot_reward = token.get_lot_reward("shop_1")
			assert(lot_reward)
			assert(lot_reward["energy"] == 10)

			local lot_price = token.get_lot_price("shop_2")
			assert(lot_price)
			assert(lot_price["money"] == 200)

			local lot_reward = token.get_lot_reward("shop_2")
			assert(lot_reward)
			assert(lot_reward["energy"] == 20)
		end)
	end)
end
