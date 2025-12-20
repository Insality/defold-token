local mock_time = require("deftest.mock.time")

return function()
	describe("Token State", function()
		local token ---@type token
		local wallet ---@type token.container

		local SAVED_STATE = nil
		local WALLET_ID = "wallet"
		local CONFIG_TOKEN = {
				level = { default = 1, min = 1, max = 80 }
		}

	before(function()
		token = require("token.token")

		if not SAVED_STATE then
			token.reset_state()
		end

		if SAVED_STATE then
			token.set_state(SAVED_STATE)
		end

		token.init()
		token.register_tokens(CONFIG_TOKEN)
		wallet = token.container(WALLET_ID)

		mock_time.mock()
		mock_time.set(0)
	end)

		after(function()
			mock_time.unmock()
			token.update()
		end)

		it("Should save token values on game save/load. Part1", function()
			assert(wallet:get("ruby") == 0)
			wallet:add("ruby", 100)
			assert(wallet:get("ruby") == 100)

			local state = token.get_state()
			local is_ok, encoded = pcall(json.encode, state)
			if is_ok and encoded then
				SAVED_STATE = json.decode(encoded)
			end
		end)


		it("Should save token values on game save/load. Part2", function()
			assert(wallet:get("ruby") == 100)
			SAVED_STATE = nil
		end)
	end)
end

