local game_over = {
	init = function (self, machine, ...)

	end,
	enter = function (self, machine, ...)

	end,
	exit = function (self, machine, ...)

	end,
	update = function (self, machine, ...)

	end,
	draw = function (self, machine, ...)
		imgui.Text('Game Over')
		if imgui.Button('Confirm') then
			state_machine:set_state('title')
		end
	end,
}

return game_over