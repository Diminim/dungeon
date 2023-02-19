local victory = {
	init = function (self, machine, ...)

	end,
	enter = function (self, machine, ...)

	end,
	exit = function (self, machine, ...)

	end,
	update = function (self, machine, ...)

	end,
	draw = function (self, machine, ...)
		imgui.Text('Victory!')
		if imgui.Button('Confirm') then
			state_machine:set_state('map')
		end
	end,
}

return victory