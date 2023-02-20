local Character = require('classes/Character')
local character_infos = require('character_infos')

local title = {
	init = function (self, machine, ...)

	end,
	enter = function (self, machine, ...)

	end,
	exit = function (self, machine, ...)

	end,
	update = function (self, machine, ...)

	end,
	draw = function (self, machine, ...)
		imgui.Text('Title')
		if imgui.Button('New Game') then
			saved_characters = {
				fighter = Character:new()
				:set_info(character_infos.fighter),
			
				healer = Character:new()
				:set_info(character_infos.medic),
			
				mage = Character:new()
				:set_info(character_infos.mage),
			}
			state_machine:set_state('town')
		end
		--[[
		if imgui.Button('Load Game') then
			saved_characters = bitser.loadLoveFile('save.dat')
			state_machine:set_state('town')
		end
		--]]
	end,
}

return title