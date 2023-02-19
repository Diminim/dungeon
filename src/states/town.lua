local town = {
	init = function (self, machine, ...)

	end,
	enter = function (self, machine, ...)

	end,
	exit = function (self, machine, ...)

	end,
	update = function (self, machine, ...)

	end,
	draw = function (self, machine, ...)
		imgui.Text('Town')
		if imgui.Button('Save Game') then
			bitser.dumpLoveFile('save.dat', saved_characters)
		end
		if imgui.Button('Heal Party') then
			for k, v in pairs(saved_characters) do
				v.info.hp = v.info.max_hp
			end
		end
		if imgui.Button('Enter Dungeon') then
			state_machine:set_state('map')
		end
	end,
}

return town