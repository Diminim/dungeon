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

local damage_calc = function (a, b)
	return math.floor(a * a/b)
end
local check_blacklist = function (blacklist)
	local bit = true
	for i, v in ipairs(blacklist) do
		if v[1] ~= v[2] then
			bit = false
			break
		end
	end
	return bit
end

local actions = {}

actions.pass = Action:new{
	name = 'Pass',
	execute = function (self, context)
	end
}

actions.attack = Action:new{
	name = 'Attack',
	execute = function (self, context)
		local actor = context.actor.info
		local target = context.target.info
		local blacklist = {
			{context.actor.info.is.dead, false}
		}


		if check_blacklist(blacklist) then
			target.hp = math.max(target.hp - damage_calc(actor.str, target.def), 0)
			local message = ('%s %s %s'):format(
				actor.name, 
				'attacked', 
				target.name
			)
			table.insert(context.battle.log, message)
		end
	end
}

actions.defend = Action:new{
	name = 'Defend',
	priority = 1,
	execute = function (self, context)
		local actor = context.actor.info
		local target = context.target.info
		actor.def = actor.def * 1.5
		local message = ('%s %s'):format(
			actor.name, 
			'put up their guard'
		)
		table.insert(context.battle.log, message)

		return self.chain[1]
	end,
	chain = {
		Action:new{
			priority = -1,
			execute = function (self, context)
				local actor = context.actor.info
				local target = context.target.info
				actor.def = actor.def / 1.5
				local message = ('%s %s'):format(
					actor.name, 
					'put down their guard'
				)
				table.insert(context.battle.log, message)
			end
		}
	}
}

actions.heal = Action:new{
	name = 'Heal',
	execute = function (self, context)
		local actor = context.actor.info
		local target = context.target.info
		target.hp = target.hp + 10
		local message = ('%s %s %s'):format(
			actor.name, 
			'healed', 
			target.name
		)
		table.insert(context.battle.log, message)
	end
}

actions.revive = Action:new{
	name = 'Revive',
	execute = function (self, context)
		local actor = context.actor.info
		local target = context.target.info
		local blacklist = {
			{context.actor.info.is.dead, false},
			{context.target.info.is.dead, true},
		}
		
		if check_blacklist(blacklist) then
			target.is.dead = false
			target.hp = math.min(target.hp + 10, target.max_hp)
			local message = ('%s %s %s'):format(
				actor.name, 
				'revived', 
				target.name
			)
			table.insert(context.battle.log, message)
		end
	end
}

actions.slow_attack = Action:new{
	name = 'Slow Attack',
	speed_modifier = -100,
	execute = function (self, context)
		local actor = context.actor.info
		local target = context.target.info
		target.hp = target.hp - math.max(actor.str*2 - target.def, 0)
		local message = self.name
		table.insert(context.battle.log, message)
	end
}

actions.delayed_attack = Action:new{
	name = 'Delayed Attack',
	turn_modifer = 1,
	execute = function (self, context)
		local actor = context.actor.info
		local target = context.target.info
		target.hp = target.hp - math.max(actor.str*2 - target.def, 0)
		local message = self.name
		table.insert(context.battle.log, message)
	end
}

actions.kill_all = Action:new{
	name = "Kill All",
	execute = function (self, context)
		for i, v in ipairs(context.battle.groups.all) do
			v.info.hp = v.info.hp - 1000
		end

		local message = self.name
		table.insert(context.battle.log, message)
	end
}

actions.kill_enemies = Action:new{
	name = "Kill Enemies",
	execute = function (self, context)
		for i, v in ipairs(context.battle.groups.enemies) do
			v.info.hp = 0
		end

		local message = self.name
		table.insert(context.battle.log, message)
	end
}

actions.kill_allies = Action:new{
	name = "Kill Allies",
	execute = function (self, context)
		for i, v in ipairs(context.battle.groups.allies) do
			v.info.hp = 0
		end

		local message = self.name
		table.insert(context.battle.log, message)
	end
}

actions.poison = Action:new{
	name = "Poison",
	priority = 0,
	execute = function (self, context)
		local actor = context.actor.info
		local target = context.target.info
		local turn_number = context.battle.current_turn
		local has_poison_ticked = false

		local function event_poison()
			if turn_number ~= context.battle.current_turn then
				has_poison_ticked = false
				turn_number = context.battle.current_turn
			end
			if has_poison_ticked == false then
				has_poison_ticked = true
				target.hp = target.hp - 10
				table.insert(context.battle.log, target.name..' takes poison damage')
			end
		end
		table.insert(context.battle.active_events, event_poison)
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