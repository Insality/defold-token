return function()
	describe("Token Defaults", function()
		local token ---@type token
		local wallet ---@type token.container

		local WALLET_ID = "wallet"
		local CONFIG = {
			money = { default = 10000, min = 0 },
		}

		local SAVED_STATE = nil

		before(function()
			token = require("token.token")

			if not SAVED_STATE then
				token.reset_state()
			end

			if SAVED_STATE then
				token.set_state(SAVED_STATE)
			end

			token.init(CONFIG)
			wallet = token.container(WALLET_ID)
		end)

		it("Should apply default on first get and persist to state", function()
			assert(wallet:get("money") == 10000)
			assert(token.get_state().containers[WALLET_ID].tokens.money == 10000)
		end)

		it("Should keep default after save/load without spending", function()
			local state = token.get_state()
			local is_ok, encoded = pcall(json.encode, state)
			assert(is_ok, "State should be encodable")
			SAVED_STATE = json.decode(encoded)
		end)

		it("Should restore default after reload", function()
			assert(wallet:get("money") == 10000)
			assert(token.get_state().containers[WALLET_ID].tokens.money == 10000)
			SAVED_STATE = nil
		end)
	end)
end
