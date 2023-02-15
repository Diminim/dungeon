local Action = {
	new = function (self, data)
		local o = {}
		setmetatable(o, self)
		self.__index = self
		o:init(data)
		return o
	end,

	init = function (self, data)
		self.name = data.name or ''
		self.priority = data.priority or 0
		self.turn_modifer = data.turn_modifer or 0
		self.speed_modifier = data.speed_modifier or 0

		self.chain = data.chain or {}

		self.execute = data.execute or function () end

		return self
	end,
}

local actions = {}
actions.attack = Action:new{
	name = 'Attack',
	execute = function (self, context)
		context.target.info.hp = context.target.info.hp - math.max(context.actor.info.str - context.target.info.def, 0)
		local message = ('%s %s %s'):format(
			context.actor.info.name, 
			'attacked', 
			context.target.info.name
		)

		return message
	end
}

actions.defend = Action:new{
	name = 'Defend',
	priority = 1,
	execute = function (self, context)
		context.actor.info.def = context.actor.info.def + 10
		local message = ('%s %s'):format(
			context.actor.info.name, 
			'put up their guard'
		)

		return message, self.chain[1]
	end,
	chain = {
		Action:new{
			priority = -1,
			execute = function (self, context)
				context.actor.info.def = context.actor.info.def - 10
				local message = ('%s %s'):format(
					context.actor.info.name, 
					'put down their guard'
				)

				return message
			end
		}
	}
}

actions.heal = Action:new{
	name = 'Heal',
	execute = function (self, context)
		context.target.info.hp = context.target.info.hp + 10
		local message = ('%s %s %s'):format(
			context.actor.info.name, 
			'healed', 
			context.target.info.name
		)

		return message
	end
}

actions.slow_attack = Action:new{
	name = 'Slow Attack',
	speed_modifier = -100,
	execute = function (self, context)
		context.target.info.hp = context.target.info.hp - math.max(context.actor.info.str*2 - context.target.info.def, 0)
		local message = self.name

		return message
	end
}

actions.delayed_attack = Action:new{
	name = 'Delayed Attack',
	turn_modifer = 1,
	execute = function (self, context)
		context.target.info.hp = context.target.info.hp - math.max(context.actor.info.str*2 - context.target.info.def, 0)
		local message = self.name

		return message
	end
}

actions.burn_all = Action:new{
	name = "Overheat",
	execute = function (self, context)
		for i, v in ipairs(context.battle.groups.all) do
			v.info.hp = v.info.hp - 1000
		end

		local message = self.name
	end
}

actions.poison = Action:new{
	name = "Poison",
	priority = 0,
	execute = function (self, context)
	end
}

actions.counter = Action:new{
	name = "Counter",
	priority = 1,
	execute = function (self, context)
		-- Counter On
	end,
	chain = {
		Action:new{
			priority = -1,
			execute = function (self, context)
				-- Counter Off
			end
		}
	}
}

return actions