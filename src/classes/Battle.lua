local Priority_Queue = require('classes/Priority_Queue')
local Action_Info = require('classes/Action_Info')

local Battle = {
	new = function (self, character_list)
		local o = {}
		setmetatable(o, self)
		self.__index = self
		o:init(character_list)
		return o
    end,

	init = function (self, character_list)
		self.characters = character_list
		self.current_turn = 1
		self.action_priority_queue = Priority_Queue:new()
		self.log = {}
		self.groups = {}
		self.active_events = {}
		self.should_exit = false
		self.exit_func = function (machine) end

		self:init_groups()
	end,

	init_groups = function (self)
		self.groups.all = self.characters
		self.groups.allies = {}
		self.groups.enemies = {}
		for k, v in pairs(self.characters) do
			if v.info.is.enemy then
				table.insert(self.groups.enemies, v)
			else
				table.insert(self.groups.allies, v)
			end
		end
	end,

	turn_end = function (self)
		for k, v in pairs(self.characters_menu_data) do
			local action_index = v.actions:search('bool', true)
			local target_index = v.targets:search('bool', true)
	
			local character = v.character
			local action = v.actions.items[action_index].pointer
			local target = v.targets.items[target_index].pointer
	
			local context = {
				actor = v.character,
				target = v.targets.items[target_index].pointer,
				battle = self,
			}
	
			local action_info = Action_Info:new(action, context)
			self.action_priority_queue:insertion_sort(self.current_turn, action_info)
		end
	
		for i, v in ipairs(self.action_priority_queue.queue[self.current_turn]) do
			local chained_action = v.action()
			if chained_action then
				local context = {
					actor = v.actor,
					target = v.target,
					battle = self,
				}
	
				local action_info = Action_Info:new(chained_action, context)
				self.action_priority_queue:insertion_sort(self.current_turn, action_info)
			end
			for i, v in ipairs(self.active_events) do
				v(self)
			end
		end
		self.current_turn = self.current_turn + 1
	end

}

return Battle