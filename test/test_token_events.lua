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
			local last_delta = nil

			token.on_token_change:subscribe(function(container_id, token_id, value, reason, delta)
				counter = counter + 1
				last_container_id = container_id
				last_token_id = token_id
				last_value = value
				last_reason = reason
				last_delta = delta
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
			assert_equal(last_delta, 1)

			wallet:add("money", 500, "reward")
			assert_equal(counter, 2)
			assert_equal(last_container_id, WALLET_ID)
			assert_equal(last_token_id, "money")
			assert_equal(last_value, 500)
			assert_equal(last_reason, "reward")
			assert_equal(last_delta, 500)
		end)

		it("Should pass delta on container token change", function()
			local last_token_id = nil
			local last_amount = nil
			local last_reason = nil
			local last_delta = nil

			wallet.on_token_change:subscribe(function(token_id, amount, reason, delta)
				last_token_id = token_id
				last_amount = amount
				last_reason = reason
				last_delta = delta
			end)

			wallet:add("gold", 100, "reward")
			assert_equal(last_token_id, "gold")
			assert_equal(last_amount, 100)
			assert_equal(last_reason, "reward")
			assert_equal(last_delta, 100)

			wallet:add("gold", 50, "quest")
			assert_equal(last_amount, 150)
			assert_equal(last_reason, "quest")
			assert_equal(last_delta, 50)

			wallet:pay("gold", 30, "shop")
			assert_equal(last_amount, 120)
			assert_equal(last_reason, "shop")
			assert_equal(last_delta, -30)

			wallet:set("gold", 10, "reset")
			assert_equal(last_amount, 10)
			assert_equal(last_reason, "reset")
			assert_equal(last_delta, -110)
		end)

		it("Should pass clamped delta", function()
			token.register_tokens({
				energy = { max = 100 }
			})

			local last_amount = nil
			local last_delta = nil

			wallet.on_token_change:subscribe(function(_, amount, _, delta)
				last_amount = amount
				last_delta = delta
			end)

			wallet:add("energy", 80)
			assert_equal(last_amount, 80)
			assert_equal(last_delta, 80)

			wallet:add("energy", 50)
			assert_equal(last_amount, 100)
			assert_equal(last_delta, 20)
		end)

		it("Should pass delta on visual change", function()
			local last_token_id = nil
			local last_amount = nil
			local last_delta = nil
			local visual_counter = 0

			wallet.on_token_visual_change:subscribe(function(token_id, amount, delta)
				visual_counter = visual_counter + 1
				last_token_id = token_id
				last_amount = amount
				last_delta = delta
			end)

			wallet:add("gold", 100)
			assert_equal(visual_counter, 1)
			assert_equal(last_token_id, "gold")
			assert_equal(last_amount, 100)
			assert_equal(last_delta, 100)

			wallet:add("gold", 50, "quest", true)
			assert_equal(visual_counter, 1)
			assert_equal(wallet:get("gold"), 150)
			assert_equal(wallet:get_visual("gold"), 100)

			wallet:add_visual("gold", 20)
			assert_equal(visual_counter, 2)
			assert_equal(last_amount, 120)
			assert_equal(last_delta, 20)

			local synced = wallet:sync_visual("gold")
			assert_equal(synced, 30)
			assert_equal(visual_counter, 3)
			assert_equal(last_amount, 150)
			assert_equal(last_delta, 30)
		end)

		it("Should pass visual delta on global event", function()
			local last_container_id = nil
			local last_token_id = nil
			local last_amount = nil
			local last_delta = nil

			token.on_token_visual_change:subscribe(function(container_id, token_id, amount, delta)
				last_container_id = container_id
				last_token_id = token_id
				last_amount = amount
				last_delta = delta
			end)

			wallet:add_visual("gold", 25)
			assert_equal(last_container_id, WALLET_ID)
			assert_equal(last_token_id, "gold")
			assert_equal(last_amount, 25)
			assert_equal(last_delta, 25)
		end)
	end)
end
