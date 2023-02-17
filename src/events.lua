local events = {
	character_died = function (battle)
		for i, v in ipairs(battle.groups.all) do
			local message
			if (v.info.is_dead == false) and (v.info.hp <= 0) then
				v.info.is_dead = true
				message = ('%s %s'):format(
					v.info.name, 
					'died!'
				)
			end
			if message then 
				table.insert(battle.log, message) 
			end
		end
	end,

	allies_died = function (battle)
		local dead_number = 0
		for i, v in ipairs(battle.groups.allies) do
			if (v.info.is_dead == true) then
				dead_number = dead_number + 1
			end
		end
		if dead_number == #battle.groups.allies then
			local message = 'Allies have been defeated...'
			table.insert(battle.log, message)
			battle.should_exit = true
			battle.exit_func = function (machine)
				state_machine:set_state('game_over')
			end
		end
	end,

	enemies_died = function (battle)
		local dead_number = 0
		for i, v in ipairs(battle.groups.enemies) do
			if (v.info.is_dead == true) then
				dead_number = dead_number + 1
			end
		end
		if dead_number == #battle.groups.enemies then
			local message = 'Enemies have been defeated!'
			table.insert(battle.log, message)
			battle.should_exit = true
			battle.exit_func = function (machine)
				state_machine:set_state('victory')
			end
		end
	end,
}

return events