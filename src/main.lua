require('globals')
require('state')

love.window.setMode(900, 900)
love.window.setTitle('Dungeon')
love.graphics.setDefaultFilter('nearest', 'nearest')

local List = {
	new = function (self)
		local o = {}
		setmetatable(o, self)
		self.__index = self
		o:init()
		return o
    end,

	init = function (self)
		self.items = {}

		return self
	end,

	-- I'd like to be able to abstract the things I add from the List
	add = function (self, name, bool, pointer)
		self.items[pointer] = {
			name = name,
			bool = bool,
			pointer = pointer,
		}

		table.insert(self.items, {
			name = name,
			bool = bool,
			pointer = pointer,
		})
	
		return self
	end,

	-- This is too specific for List
	select_index = function (self, selected_index)
		for i, v in ipairs(self.items) do
			if i == selected_index then 
				v.bool = true
			else
				v.bool = false
			end
		end
	end,

	select_key = function (self, selected_key)
		for k, v in pairs(self.items) do
			if k == selected_key then 
				v.bool = true
			else
				v.bool = false
			end
		end
	end,

	search = function(self, field, critera)
		for i, v in ipairs(self.items) do
			if v[field] == critera then
				return i
			end
		end
	end
}
local Character = {
	new = function (self)
		local o = {}
		setmetatable(o, self)
		self.__index = self
		o:init()
		return o
    end,

	init = function (self)
		self.info = {}
	end,

    set_info = function (self, info)
        self.info = tablex.deep_copy(info)

        return self
    end,
}
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
local Priority_Queue = {
	new = function (self)
		local o = {}
		setmetatable(o, self)
		self.__index = self
		o:init()
		return o
    end,

	init = function (self)
		self.queue = {}
	end,

	insertion_sort = function (self, index, action_info)
		local insertion_index
		if not self.queue[index + action_info.turn] then
			self.queue[index + action_info.turn] = {}
		end
		for i, v in ipairs(self.queue[index + action_info.turn]) do
			if action_info.priority > v.priority then
				insertion_index = i
				break
			elseif action_info.priority == v.priority then
				if action_info.speed > v.speed then
					insertion_index = i
					break
				end
			end
		end
		insertion_index = insertion_index or (#self.queue[index + action_info.turn]+1)
		table.insert(self.queue[index + action_info.turn], insertion_index, action_info)
	end,
}
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

-- -------------------------------------------------------------------------- --
local actions = require('actions')
local character_infos = require('character_infos')
local events = require('events')

bitser.registerClass('Character', Character, getmetatable(Character:new()), nil, setmetatable)
for k, v in pairs(actions) do
	bitser.register(k, v)
end

saved_characters = {
	fighter = Character:new()
	:set_info(character_infos.fighter),

	healer = Character:new()
	:set_info(character_infos.medic),

	mage = Character:new()
	:set_info(character_infos.mage),
}

-- -------------------------------------------------------------------------- --

local imgui_window = function ()
	if imgui.Begin('All') then
		imgui.PushStyleVar_Float(12, 10)
		state_machine:draw()
		imgui.PopStyleVar(1)
		--style:ScaleAllSizes(1)
	end
	imgui.End()
end

-- -------------------------------------------------------------------------- --

love.load = function ()
    imgui.love.Init()
end
love.update = function (dt)
	state_machine:update()
    imgui.love.Update(dt)
    imgui.NewFrame()
	input:update()
end
love.draw = function ()
    imgui.ShowDemoWindow()
	imgui_window()
    imgui.Render()
    imgui.love.RenderDrawLists()
end

-- -------------------------------------------------------------------------- --

love.mousemoved = function (x, y, ...)
    imgui.love.MouseMoved(x, y)
    if not imgui.love.GetWantCaptureMouse() then
        -- your code here
    end
end
love.mousepressed = function (x, y, button, ...)
    imgui.love.MousePressed(button)
    if not imgui.love.GetWantCaptureMouse() then
        -- your code here 
    end
end
love.mousereleased = function (x, y, button, ...)
    imgui.love.MouseReleased(button)
    if not imgui.love.GetWantCaptureMouse() then
        -- your code here 
    end
end
love.wheelmoved = function (x, y)
    imgui.love.WheelMoved(x, y)
    if not imgui.love.GetWantCaptureMouse() then
        -- your code here 
    end
end
love.keypressed = function (key, ...)
    imgui.love.KeyPressed(key)
    if not imgui.love.GetWantCaptureKeyboard() then
        -- your code here 
    end
end
love.keyreleased = function (key, ...)
    imgui.love.KeyReleased(key)
    if not imgui.love.GetWantCaptureKeyboard() then
        -- your code here 
    end
end
love.textinput = function (t)
    imgui.love.TextInput(t)
    if imgui.love.GetWantCaptureKeyboard() then
        -- your code here 
    end
end
love.quit = function ()
    return imgui.love.Shutdown()
end