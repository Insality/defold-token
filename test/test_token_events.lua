local mock_time = require("deftest.mock.time")

return function()
	describe("Token Events", function()
		local token ---@type token
		local wallet ---@type token.container

		local WALLET_ID = "wallet"

		local function set_time(time)
			mock_time.set(time)
		end

	before(function()
		token = require("token.token") --[[@as token]]
		token.reset_state()
		token.init({})
		wallet = token.container(WALLET_ID)

			mock_time.mock()
			mock_time.set(0)
		end)

		after(function()
			mock_time.unmock()
			token.update()
		end)

		it("Should throw event on token change", function()
			wallet:set_restore_config("energy", {
				timer = 60,
				value = 1,
				max = 20
			})

			local counter = 0
			local last_container_id = nil
			local last_token_id = nil
			local last_value = nil
			local last_reason = nil

			token.on_token_change:subscribe(function(container_id, token_id, value, reason)
				counter = counter + 1
				last_container_id = container_id
				last_token_id = token_id
				last_value = value
				last_reason = reason
			end)

			assert_equal(counter, 0)
			assert(wallet:get("energy") == 0)

			set_time(60)
			token.update()
			assert(wallet:get("energy") == 1)
			assert_equal(counter, 1)
			assert_equal(last_container_id, WALLET_ID)
			assert_equal(last_token_id, "energy")
			assert_equal(last_value, 1)

			wallet:add("money", 500)
			assert_equal(counter, 2)
			assert_equal(last_container_id, WALLET_ID)
			assert_equal(last_token_id, "money")
			assert_equal(last_value, 500)
		end)
	end)
end

