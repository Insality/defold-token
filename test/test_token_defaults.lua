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

	describe("Token Default Seeding", function()
		local token ---@type token

		before(function()
			token = require("token.token")
			token.reset_state()
			token.init()
		end)

		it("Should put default 0 tokens into container on create", function()
			token.register_tokens({
				is_payer = { default = 0, min = 0, max = 1 },
				level = { default = 1, min = 1, max = 80 },
			}, "player")

			local player = token.container("player", "player")
			local tokens = player:get_many()

			assert(tokens.is_payer == 0, "is_payer should be 0, got " .. tostring(tokens.is_payer))
			assert(tokens.level == 1, "level should be 1, got " .. tostring(tokens.level))
			assert(token.get_state().containers.player.tokens.is_payer == 0)
			assert(token.get_state().containers.player.tokens.level == 1)
		end)

		it("Should seed default group tokens including 0 without calling get", function()
			token.register_tokens({
				flag = { default = 0, min = 0, max = 1 },
				money = { default = 100 },
			})

			local wallet = token.container("wallet")
			local tokens = wallet:get_many()

			assert(tokens.flag == 0, "flag should be 0, got " .. tostring(tokens.flag))
			assert(tokens.money == 100, "money should be 100, got " .. tostring(tokens.money))
		end)

		it("Should not overwrite saved values with defaults", function()
			token.register_tokens({
				is_payer = { default = 0, min = 0, max = 1 },
			}, "player")

			token.set_state({
				containers = {
					player = {
						tokens = { is_payer = 1 }
					}
				}
			})

			local player = token.container("player", "player")
			assert(player:get("is_payer") == 1)
			assert(player:get_many().is_payer == 1)
		end)
	end)
end
