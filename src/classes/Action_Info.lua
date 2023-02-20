local Action_Info = {
	new = function (self, action, context)
		local o = {}
		setmetatable(o, self)
		self.__index = self
		o:init(action, context)
		return o
    end,

	init = function (self, action, context)
		self.action = function ()
			return action:execute(context)
		end
		self.actor = context.actor
		self.target = context.target
		self.turn = action.turn_modifer
		self.priority = action.priority
		self.speed = context.actor.info.spd + action.speed_modifier
	end,
}

return Action_Info