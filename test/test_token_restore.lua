local mock_time = require("deftest.mock.time")

return function()
	describe("Token Restore", function()
		local token ---@type token
		local test_container ---@type token.container
		local wallet ---@type token.container

		local TEST_CONTAINER_ID = "test_container"
		local WALLET_ID = "wallet"

		local function set_time(time)
			mock_time.set(time)
		end

	before(function()
		token = require("token.token") --[[@as token]]
		token.reset_state()
		token.init({})
		test_container = token.container(TEST_CONTAINER_ID)
		wallet = token.container(WALLET_ID)

		mock_time.mock()
		mock_time.set(0)
	end)

		after(function()
			mock_time.unmock()
			token.update()
		end)

		it("Should correct work restoring", function()
			test_container:set_restore_config("energy", {
				timer = 60,
				value = 1,
				max = 20
			})
			set_time(60)
			token.update()
			assert(wallet:get("energy") == 0)

			assert_equal(test_container:get("energy"), 1)

			set_time(120)
			token.update()
			assert(test_container:get("energy") == 2)

			-- max 20 restore
			set_time(60 * 40)
			token.update()
			assert(test_container:get("energy") == 22)
		end)


		it("Should able to disable restore timer", function()
			wallet:set_restore_config("energy", {
				timer = 60,
				value = 1,
				max = 20
			})

			set_time(60)
			token.update()
			assert(wallet:get("energy") == 1)

			wallet:set_restore_config_enabled("energy", false)
			set_time(120)
			token.update()
			assert(wallet:get("energy") == 1)

			wallet:set_restore_config_enabled("energy", true)
			set_time(180)
			token.update()
			assert(wallet:get("energy") == 2)
		end)


		it("Should able to delete restore timer config", function()
			wallet:set_restore_config("energy", {
				timer = 60,
				value = 1,
				max = 20
			})

			set_time(60)
			token.update()
			assert(wallet:get("energy") == 1)

			wallet:remove_restore_config("energy")
			set_time(120)
			token.update()
			assert(wallet:get("energy") == 1)
		end)


		it("Should have restore timer", function()
			wallet:set_restore_config("energy", {
				timer = 5
			})

			assert(wallet:get("energy") == 0)
			set_time(5)
			token.update()
			assert(wallet:get("energy") == 1)
			set_time(50)
			token.update()
			assert(wallet:get("energy") == 10)
			set_time(0)
			token.update()
			assert(wallet:get("energy") == 10)
			assert(wallet:get_time_to_restore("energy") == 5)
			set_time(4)
			assert(wallet:get_time_to_restore("energy") == 1)
			set_time(3)
			assert(wallet:get_time_to_restore("energy") == 2)
			set_time(0)
			assert(wallet:get_time_to_restore("energy") == 5)
			set_time(4)
			token.update()
			assert(wallet:get("energy") == 10)
			set_time(5)
			token.update()
			assert(wallet:get("energy") == 11)
		end)


		it("Should have advanced restore params", function()
			wallet:set_restore_config("energy", {
				timer = 5,
				max = 5,
				value = 2
			})

			-- cur time = 0
			assert(wallet:get("energy") == 0)
			set_time(5)
			token.update()
			assert(wallet:get("energy") == 2)
			set_time(19)
			token.update()
			-- elapsed 14 secs, need to add 2 * 2
			assert(wallet:get("energy") == 6)
			set_time(20)
			token.update()
			assert(wallet:get("energy") == 8)
			set_time(100)
			token.update()
			assert(wallet:get("energy") == 13)
			-- elapsed 100 secs. want to add 16 * 2, but max restore 5, max value 15
			set_time(200)
			-- TODO: HACK, while now we can't setup max token value in restore config
			wallet:set("energy", 15)
			assert(wallet:get("energy") == 15)

			-- time return back (hackers?)
			set_time(0)
			token.update()
			assert(wallet:get("energy") == 15)
			assert(wallet:get_time_to_restore("energy") == 5)
			wallet:add("energy", -5)
			set_time(5)
			token.update()
			assert(wallet:get("energy") == 12)
			wallet:set("energy", 0)
			set_time(55) -- elapsed 50 secods, want to add 10 * 2, but max restore 5
			token.update()
			assert(wallet:get("energy") == 5)
		end)


		it("Should preserve restore state when re-setting config", function()
			-- Setup initial restore config
			wallet:set_restore_config("energy", {
				timer = 60,
				value = 1,
				max = 20
			})

			set_time(60)
			token.update()
			assert(wallet:get("energy") == 1, "Energy should be 1 after first restore")

			set_time(120)
			token.update()
			assert(wallet:get("energy") == 2, "Energy should be 2 after second restore")

			-- Re-set config (simulating game restart)
			wallet:set_restore_config("energy", {
				timer = 30,  -- Changed timer
				value = 2,   -- Changed value
				max = 50     -- Changed max
			})

			-- Time should be preserved, not reset!
			set_time(150)
			token.update()
			-- With new config: 30 seconds passed since last restore (120), so should add 2
			assert(wallet:get("energy") == 4, "Energy should be 4 (2 + 2) with preserved timer")
		end)


		it("Should update config parameters without resetting timer", function()
			wallet:set_restore_config("lives", {
				timer = 60,
				value = 1,
				max = 5
			})

			set_time(30)
			token.update()
			assert(wallet:get("lives") == 0, "No restore yet")

			-- Update config with different parameters
			wallet:set_restore_config("lives", {
				timer = 30,  -- Faster restore
				value = 2,   -- More per restore
				max = 10     -- Higher cap
			})

			-- Timer is preserved from time 0, so at time 60:
			-- elapsed = 60 seconds, timer = 30, so 2 intervals * 2 value = 4 lives
			set_time(60)
			token.update()
			assert(wallet:get("lives") == 4, "Lives should be 4 (2 intervals * 2 value)")
		end)


		it("Should allow manual reset of restore timer", function()
			wallet:set_restore_config("energy", {
				timer = 60,
				value = 1,
				max = 20
			})

			set_time(60)
			token.update()
			assert(wallet:get("energy") == 1, "Energy restored to 1")

			set_time(90)
			token.update()
			assert(wallet:get("energy") == 1, "Still 1, not enough time")

			-- Manually reset the timer (e.g., player watched an ad)
			wallet:reset_restore_timer("energy")

			-- Now only 30 seconds needed from current time (90)
			set_time(150)
			token.update()
			assert(wallet:get("energy") == 2, "Energy should restore from reset point")
		end)


		it("Should handle multiple config updates correctly", function()
			wallet:set_restore_config("stamina", {
				timer = 100,
				value = 5
			})

			-- First restore
			set_time(100)
			token.update()
			assert(wallet:get("stamina") == 5)

			-- Update config while timer is running
			set_time(150)
			wallet:set_restore_config("stamina", {
				timer = 50,
				value = 10
			})

			-- Timer should be preserved, so 50 more seconds needed
			set_time(200)
			token.update()
			-- From time 100 to 200 = 100 seconds
			-- With new timer=50, that's 2 intervals: 10 * 2 = 20
			assert(wallet:get("stamina") == 25, "Stamina should be 5 + 20")
		end)


		it("Should not reset timer when config exists on game restart", function()
			-- Simulate first game session
			wallet:set_restore_config("energy", {
				timer = 60,
				value = 1
			})

			set_time(0)
			token.update()
			assert(wallet:get("energy") == 0)

			-- Simulate time passing before restart
			set_time(120)
			token.update()
			assert(wallet:get("energy") == 2, "2 energy after 120 seconds")

			-- Simulate game restart - config set again (common pattern)
			wallet:set_restore_config("energy", {
				timer = 60,
				value = 1
			})

			-- Continue time
			set_time(180)
			token.update()
			assert(wallet:get("energy") == 3, "Should continue from 2, not reset to 0")
		end)
	end)
end

