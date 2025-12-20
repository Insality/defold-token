return function()
	describe("Token Config", function()
		local token ---@type token
		local wallet ---@type token.container

	before(function()
		token = require("token.token")
		token.reset_state()
		token.init()
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

		-- Create container AFTER registering tokens
		wallet = token.container("wallet")

		local level = wallet:get("level")
		local money = wallet:get("money")
		assert(level == 1, "level is " .. tostring(level) .. ", expected 1")
		assert(money == 100, "money is " .. tostring(money) .. ", expected 100")
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


		it("should overwrite token config on re-registration", function()
			-- Register initial token config
			token.register_tokens({
				["gold"] = {
					default = 100,
					min = 0,
					max = 1000
				}
			})

			-- Create container to check initial value
			wallet = token.container("wallet1")
			local initial_gold = wallet:get("gold")
			assert(initial_gold == 100, "Initial gold should be 100, got " .. tostring(initial_gold))

			-- Overwrite token config
			token.register_tokens({
				["gold"] = {
					default = 500,
					min = 0,
					max = 5000
				}
			})

			-- Check that new container gets new default value
			local wallet2 = token.container("wallet2")
			local new_gold = wallet2:get("gold")
			assert(new_gold == 500, "New gold should be 500, got " .. tostring(new_gold))

			-- Check that existing container keeps its value
			local existing_gold = wallet:get("gold")
			assert(existing_gold == 100, "Existing gold should still be 100, got " .. tostring(existing_gold))

			-- Check that config limits were updated
			local config = token.get_token_config("gold")
			assert(config, "Config should exist")
			assert(config.max == 5000, "Max should be 5000, got " .. tostring(config.max))
		end)


		it("should overwrite token group on re-registration", function()
			-- Register initial token group
			token.register_token_groups({
				["reward_pack"] = {
					["gold"] = 100,
					["gems"] = 10
				}
			})

			local group = token.get_token_group("reward_pack")
			assert(group, "Group should exist")
			assert(group["gold"] == 100)
			assert(group["gems"] == 10)

			-- Overwrite token group
			token.register_token_groups({
				["reward_pack"] = {
					["gold"] = 500,
					["gems"] = 50,
					["energy"] = 20
				}
			})

			local updated_group = token.get_token_group("reward_pack")
			assert(updated_group, "Updated group should exist")
			assert(updated_group["gold"] == 500, "Gold should be 500")
			assert(updated_group["gems"] == 50, "Gems should be 50")
			assert(updated_group["energy"] == 20, "Energy should be 20")
		end)


		it("should overwrite lots on re-registration", function()
			token.register_token_groups({
				["price1"] = { ["gold"] = 100 },
				["reward1"] = { ["gems"] = 10 },
				["price2"] = { ["gold"] = 500 },
				["reward2"] = { ["gems"] = 50 }
			})

			-- Register initial lot
			token.register_lots({
				["shop_item"] = {
					price = "price1",
					reward = "reward1"
				}
			})

			assert(token.get_lot_price("shop_item")["gold"] == 100)
			assert(token.get_lot_reward("shop_item")["gems"] == 10)

			-- Overwrite lot
			token.register_lots({
				["shop_item"] = {
					price = "price2",
					reward = "reward2"
				}
			})

			assert(token.get_lot_price("shop_item")["gold"] == 500)
			assert(token.get_lot_reward("shop_item")["gems"] == 50)
		end)


		it("should handle different config groups", function()
			-- Register tokens for default group
			token.register_tokens({
				["coins"] = {
					default = 100,
					max = 1000
				}
			})

			-- Register tokens for premium group
			token.register_tokens({
				["coins"] = {
					default = 500,
					max = 10000
				}
			}, "premium")

			-- Create containers with different groups
			local default_wallet = token.container("default_wallet")
			local premium_wallet = token.container("premium_wallet", "premium")

			local default_coins = default_wallet:get("coins")
			local premium_coins = premium_wallet:get("coins")

			assert(default_coins == 100, "Default wallet should have 100 coins, got " .. tostring(default_coins))
			assert(premium_coins == 500, "Premium wallet should have 500 coins, got " .. tostring(premium_coins))

			-- Check max values
			local default_config = default_wallet:get_token_config("coins")
			local premium_config = premium_wallet:get_token_config("coins")

			assert(default_config.max == 1000, "Default max should be 1000")
			assert(premium_config.max == 10000, "Premium max should be 10000")
		end)


		it("should overwrite config group tokens", function()
			-- Register initial premium config
			token.register_tokens({
				["energy"] = {
					default = 50,
					max = 100
				}
			}, "vip")

			local wallet1 = token.container("vip_wallet1", "vip")
			assert(wallet1:get("energy") == 50)

			-- Overwrite vip config
			token.register_tokens({
				["energy"] = {
					default = 100,
					max = 500
				}
			}, "vip")

			local wallet2 = token.container("vip_wallet2", "vip")
			assert(wallet2:get("energy") == 100, "New VIP wallet should have 100 energy")
			assert(wallet1:get("energy") == 50, "Existing VIP wallet should keep 50 energy")
		end)


		it("should use updated token group in container operations", function()
			token.register_tokens({
				["gold"] = { default = 0 },
				["gems"] = { default = 0 }
			})

			token.register_token_groups({
				["bonus"] = {
					["gold"] = 100,
					["gems"] = 10
				}
			})

			wallet = token.container("test_wallet")
			wallet:add_group("bonus")

			assert(wallet:get("gold") == 100)
			assert(wallet:get("gems") == 10)

			-- Update the group
			token.register_token_groups({
				["bonus"] = {
					["gold"] = 500,
					["gems"] = 50
				}
			})

			-- Clear wallet and add group again
			wallet:set("gold", 0)
			wallet:set("gems", 0)
			wallet:add_group("bonus")

			assert(wallet:get("gold") == 500, "Gold should be 500 after group update")
			assert(wallet:get("gems") == 50, "Gems should be 50 after group update")
		end)
	end)
end
