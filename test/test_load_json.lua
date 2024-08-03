return function()
	describe("Token Load JSON config", function()
		---@type token
		local token = {}
		local WALLET_ID = "wallet"

		before(function()
			token = require("token.token")
			token.reset_state()
		end)

		it("Load token config from resources JSON file", function()
			token.init("/resources/token_config.json")
			token.create_container(WALLET_ID)

			assert(token.get(WALLET_ID, "money") == 0)
			assert(token.get(WALLET_ID, "level") == 1)

			local group_1 = token.get_token_group("reward_1")
			assert(group_1)
			assert(group_1["money"] == 100)
			assert(group_1["crystal"] == 10)

			local lot_price = token.get_lot_price("shop_1")
			assert(lot_price)
			assert(lot_price["crystal"] == 1)

			local lot_reward = token.get_lot_reward("shop_1")
			assert(lot_reward)
			assert(lot_reward["level"] == 1)
		end)
	end)
end
