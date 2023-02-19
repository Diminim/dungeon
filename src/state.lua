local states = {}
states.prototype = {
	init = function (self, machine, ...)

	end,
	enter = function (self, machine, ...)

	end,
	exit = function (self, machine, ...)

	end,
	update = function (self, machine, ...)

	end,
	draw = function (self, machine, ...)

	end,
}

states.battle = require('states/battle')
states.game_over = require('states/game_over')
states.map = require('states/map')
states.title = require('states/title')
states.town = require('states/town')
states.victory = require('states/victory')

state_machine:new(states)
for k, v in pairs(states) do
	v:init(state_machine)
end
state_machine:set_state('title')

