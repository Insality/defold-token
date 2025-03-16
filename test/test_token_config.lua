return function()
	describe("Token Config", function()
		local token ---@type token

		before(function()
			token = require("token.token")
			token.init()
			token.create_container("wallet")
		end)

		it("should register tokens", function()
			token.register_tokens({
				["level"] = {
					default = 1,
					min = 1,
					max = 80
				},
				["money"] = {
					default = 100,
					min = 0,
				}
			})

			assert(token.get("wallet", "level") == 1)
			assert(token.get("wallet", "money") == 100)
		end)

		it("should register token groups", function()
			token.register_token_groups({
				["group1"] = {
					["level"] = 1,
					["money"] = 100
				}
			})

			assert(token.get_token_group("group1")["level"] == 1)
			assert(token.get_token_group("group1")["money"] == 100)
		end)

		it("should register lots", function()
			token.register_token_groups({
				["group1"] = {
					["level"] = 1,
				},
				["group2"] = {
					["money"] = 200
				}
			})

			token.register_lots({
				["shop1"] = {
					price = "group1",
					reward = "group2"
				}
			})

			assert(token.get_lot_price("shop1")["level"] == 1)
			assert(token.get_lot_reward("shop1")["money"] == 200)
		end)
	end)
end
