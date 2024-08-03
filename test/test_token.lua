local mock_time = require("deftest.mock.time")

return function()
	describe("Defold Token", function()
		---@type token
		local token = {}

		local SAVED_STATE = nil
		local TEST_CONTAINER = "test_container"
		local WALLET_ID = "wallet"
		local CONFIG_TOKEN = {
			tokens = {
				level = {
					default = 1,
					min = 1,
					max = 80
				}
			},
			containers = {
				[TEST_CONTAINER] = {},
				[WALLET_ID] = {}
			}
		}

		local function set_time(time)
			mock_time.set(time)
			token.update()
		end

		before(function()
			token = require("token.token") --[[@as token]]

			if SAVED_STATE then
				token.state = SAVED_STATE
			else
				token.reset_state()
			end

			token.init(CONFIG_TOKEN)
			token.create_container(TEST_CONTAINER)
			token.create_container(WALLET_ID)

			mock_time.mock()
			mock_time.set(0)
		end)

		after(function()
			mock_time.unmock()
		end)

		it("Should have basic api get/set/add/pay", function()
			assert(token.get(TEST_CONTAINER, "money") == 0)

			local new_value = token.add(TEST_CONTAINER, "money", 10)
			assert(new_value == 10)
			assert(token.get(TEST_CONTAINER, "money") == 10)

			new_value = token.set(TEST_CONTAINER, "money", 20)
			assert(new_value == 20)
			assert(token.get(TEST_CONTAINER, "money") == 20)

			local is_paid = token.pay(TEST_CONTAINER, "money", 5)
			assert(is_paid)
			assert(token.get(TEST_CONTAINER, "money") == 15)
		end)

		it("Should correct work check functions", function()
			token.add(TEST_CONTAINER, "money", 100)
			assert(not token.is_empty(TEST_CONTAINER, "money"))
			assert(token.is_empty(TEST_CONTAINER, "exp"))

			assert(token.is_enough(TEST_CONTAINER, "money", 50))
			assert(token.is_enough(TEST_CONTAINER, "money", 100))
			assert(not token.is_enough(TEST_CONTAINER, "money", 150))

			assert(not token.is_max(TEST_CONTAINER, "money"))

			local new_value = token.add(TEST_CONTAINER, "level", 90)
			-- Default: 1, max: 80
			assert(new_value == 80)
			assert(token.is_max(TEST_CONTAINER, "level"))
		end)

		it("Should save token values on game save/load. Part1", function()
			assert(token.get(WALLET_ID, "ruby") == 0)
			token.add(WALLET_ID, "ruby", 100)
			assert(token.get(WALLET_ID, "ruby") == 100)

			SAVED_STATE = json.decode(json.encode(token.state))
		end)

		it("Should save token values on game save/load. Part2", function()
			assert(token.get(WALLET_ID, "ruby") == 100)
			SAVED_STATE = nil
		end)

		it("Should correct work with infinity values", function()
			token.add(TEST_CONTAINER, "money", 100)
			token.add_infinity_time(TEST_CONTAINER, "money", 10)

			token.pay(TEST_CONTAINER, "money", 50)
			assert_equal(token.get(TEST_CONTAINER, "money"), 100)

			token.pay(TEST_CONTAINER, "money", 50)
			assert(token.get(TEST_CONTAINER, "money") == 100)

			token.set(TEST_CONTAINER, "money", 50)
			assert(token.get(TEST_CONTAINER, "money") == 50)

			assert(token.is_infinity(TEST_CONTAINER, "money"))
			assert(token.get_infinity_time(TEST_CONTAINER, "money") == 10)
			assert(not token.is_infinity(TEST_CONTAINER, "level"))
			assert(token.get_infinity_time(TEST_CONTAINER, "level") == 0)

			assert(token.is_enough(TEST_CONTAINER, "money", 50))
			assert(token.is_enough(TEST_CONTAINER, "money", 100))
			assert(token.is_enough(TEST_CONTAINER, "money", 150))
		end)

		it("Should correct work visual api", function()
			token.add(TEST_CONTAINER, "money", 1000)
			assert(token.get(TEST_CONTAINER, "money") == 1000)
			assert(token.get_visual(TEST_CONTAINER, "money") == 1000)

			token.add_visual(TEST_CONTAINER, "money", -100)
			assert(token.get_visual(TEST_CONTAINER, "money") == 900)

			token.sync_visual(TEST_CONTAINER, "money")
			assert(token.get_visual(TEST_CONTAINER, "money") == 1000)

			token.add(TEST_CONTAINER, "money", 100, "test", true)
			assert(token.get(TEST_CONTAINER, "money") == 1100)
			assert(token.get_visual(TEST_CONTAINER, "money") == 1000)

			token.add_visual(TEST_CONTAINER, "money", 50)
			assert(token.get_visual(TEST_CONTAINER, "money") == 1050)

			local delta = token.sync_visual(TEST_CONTAINER, "money")
			assert(token.get_visual(TEST_CONTAINER, "money") == 1100)
			assert(delta == 50)
		end)

		it("Should correct work restoring", function()
			token.set_restore_config(TEST_CONTAINER, "energy", {
				timer = 60,
				value = 1,
				max = 20
			})
			set_time(60)
			assert(token.get(WALLET_ID, "energy") == 0)

			assert_equal(token.get(TEST_CONTAINER, "energy"), 1)

			set_time(120)
			assert(token.get(TEST_CONTAINER, "energy") == 2)

			-- max 20 restore
			set_time(60 * 40)
			assert(token.get(TEST_CONTAINER, "energy") == 22)
		end)

		it("Should throw event on token change", function()
			token.set_restore_config(WALLET_ID, "energy", {
				timer = 60,
				value = 1,
				max = 20
			})

			local counter = 0
			token.on_token_change:subscribe(function(container_id, token_id, value, reason)
				counter = counter + 1
			end)

			assert_equal(counter, 0)
			assert(token.get(WALLET_ID, "energy") == 0)

			set_time(60)
			assert(token.get(WALLET_ID, "energy") == 1)
			assert_equal(counter, 1)

			token.add(WALLET_ID, "money", 500)
			assert_equal(counter, 2)
		end)

		it("Should able to disable restore timer", function()
			token.set_restore_config(WALLET_ID, "energy", {
				timer = 60,
				value = 1,
				max = 20
			})

			set_time(60)
			assert(token.get(WALLET_ID, "energy") == 1)

			token.set_restore_config_enabled(WALLET_ID, "energy", false)
			set_time(120)
			assert(token.get(WALLET_ID, "energy") == 1)

			token.set_restore_config_enabled(WALLET_ID, "energy", true)
			set_time(180)
			assert(token.get(WALLET_ID, "energy") == 2)
		end)

		it("Should able to delete restore timer config", function()
			token.set_restore_config(WALLET_ID, "energy", {
				timer = 60,
				value = 1,
				max = 20
			})

			set_time(60)
			assert(token.get(WALLET_ID, "energy") == 1)

			token.remove_restore_config(WALLET_ID, "energy")
			set_time(120)
			assert(token.get(WALLET_ID, "energy") == 1)
		end)

		it("Should have restore timer", function()
			token.set_restore_config(WALLET_ID, "energy", {
				timer = 5
			})

			assert(token.get(WALLET_ID, "energy") == 0)
			set_time(5)
			assert(token.get(WALLET_ID, "energy") == 1)
			set_time(50)
			assert(token.get(WALLET_ID, "energy") == 10)
			set_time(0)
			assert(token.get(WALLET_ID, "energy") == 10)
			assert(token.get_time_to_restore(WALLET_ID, "energy") == 5)
			set_time(4)
			assert(token.get_time_to_restore(WALLET_ID, "energy") == 1)
			set_time(3)
			assert(token.get_time_to_restore(WALLET_ID, "energy") == 2)
			set_time(0)
			assert(token.get_time_to_restore(WALLET_ID, "energy") == 5)
			set_time(4)
			assert(token.get(WALLET_ID, "energy") == 10)
			set_time(5)
			assert(token.get(WALLET_ID, "energy") == 11)
		end)


		it("Should have advanced restore params", function()
			token.set_restore_config(WALLET_ID, "energy", {
				timer = 5,
				max = 5,
				value = 2
			})

			-- cur time = 0
			assert(token.get(WALLET_ID, "energy") == 0)
			set_time(5)
			assert(token.get(WALLET_ID, "energy") == 2)
			set_time(19)
			-- elapsed 14 secs, need to add 2 * 2
			assert(token.get(WALLET_ID, "energy") == 6)
			set_time(20)
			assert(token.get(WALLET_ID, "energy") == 8)
			set_time(100)
			assert(token.get(WALLET_ID, "energy") == 13)
			-- elapsed 100 secs. want to add 16 * 2, but max restore 5, max value 15
			set_time(200)
			-- TODO: HACK, while now we can't setup max token value in restore config
			token.set(WALLET_ID, "energy", 15)
			assert(token.get(WALLET_ID, "energy") == 15)

			-- time return back (hackers?)
			set_time(0)
			assert(token.get(WALLET_ID, "energy") == 15)
			assert(token.get_time_to_restore(WALLET_ID, "energy") == 5)
			token.add(WALLET_ID, "energy", -5)
			set_time(5)
			assert(token.get(WALLET_ID, "energy") == 12)
			token.set(WALLET_ID, "energy", 0)
			set_time(55) -- elapsed 50 secods, want to add 10 * 2, but max restore 5
			assert(token.get(WALLET_ID, "energy") == 5)
		end)

		it("Should have correct infinity timer", function()
			token.set(WALLET_ID, "energy", 10)

			token.add_infinity_time(WALLET_ID, "energy", 10)

			local is_paid = token.pay(WALLET_ID, "energy", 5)
			assert(is_paid)
			assert(token.get(WALLET_ID, "energy") == 10)

			is_paid = token.pay(WALLET_ID, "energy", 10)
			assert(is_paid)
			assert(token.get(WALLET_ID, "energy") == 10)


			is_paid = token.pay(WALLET_ID, "energy", 15)
			assert(is_paid)
			assert(token.get(WALLET_ID, "energy") == 10)

			assert(token.is_infinity(WALLET_ID, "energy"))
			assert(token.get_infinity_time(WALLET_ID, "energy") == 10)
		end)

		it("Token have a total_sum value", function()
			token.add(TEST_CONTAINER, "money", 100)
			token.add(TEST_CONTAINER, "money", 100)
			token.pay(TEST_CONTAINER, "money", 50)


			assert(token.get_total_sum(TEST_CONTAINER, "money") == 200)
		end)
	end)
end
