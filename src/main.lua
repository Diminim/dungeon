require('globals')

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
        self.info = tablex.shallow_copy(info)

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
		self.groups.allies = {self.characters[1], self.characters[2], self.characters[3]}
		self.groups.enemies = {self.characters[4], self.characters[5], self.characters[6]}
	end,

	turn_end = function (self)
		for i, v in ipairs(self.characters_menu_data) do
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

local saved_characters = {
	fighter = Character:new()
	:set_info(character_infos.fighter),

	healer = Character:new()
	:set_info(character_infos.medic),

	mage = Character:new()
	:set_info(character_infos.mage),
}

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
states.title = {
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
states.town = {
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
states.map = {
	init = function (self, machine, ...)
		self.canvas = love.graphics.newCanvas(400, 400, {type = "2d", format = "normal", readable = true})

		local map_texture = love.graphics.newImage('maps/tiles.png')
		local maps = {
			current_index = 1,

			sti('maps/tiles_1.lua'),
			sti('maps/tiles_2.lua'),
			sti('maps/tiles_3.lua'),
		}


		for i, map in ipairs(maps) do
			map.world = bump.newWorld(16)

			for k2, v2 in pairs(map.objects) do
				map.world:add(v2, v2.x, v2.y, 16, 16)
			end

			map.layers['Object Layer 1'].update = function(self)
				for i2, v2 in ipairs(self.objects) do
					if v2.name == 'player' then
						local goal_x, goal_y = v2.x, v2.y
						if input:when_pressed(input.alias.up) then
							goal_y = goal_y - 16
						elseif input:when_pressed(input.alias.left) then
							goal_x = goal_x - 16
						elseif input:when_pressed(input.alias.down) then
							goal_y = goal_y + 16
						elseif input:when_pressed(input.alias.right) then
							goal_x = goal_x + 16
						end
	
						local actual_x, actual_y, cols = map.world:move(v2, goal_x, goal_y)
						if cols[1] and cols[1].other.name == 'enemy' then
							machine:set_state('battle')
						end
	
						if cols[1] and cols[1].other.name == 'stair_up' then
							if maps.current_index ~= 1 then
								maps.current_index = maps.current_index - 1
							else
								machine:set_state('town')
							end
						end
						if cols[1] and cols[1].other.name == 'stair_down' then
							maps.current_index = maps.current_index + 1
						end
						v2.x, v2.y = actual_x, actual_y
					end
				end
			end
			map.layers['Object Layer 1'].draw = function(self)
				for i2, v2 in ipairs(self.objects) do
					local quad = map.tiles[v2.gid].quad
					love.graphics.draw(map_texture, quad, v2.x, v2.y)
				end
			end
		end

		self.maps = maps
	end,
	enter = function (self, machine, ...)

	end,
	exit = function (self, machine, ...)

	end,
	update = function (self, machine, ...)
		self.maps[self.maps.current_index]:update(dt)
	end,
	draw = function (self, machine, ...)
		if imgui.Button('Return to Town') then
			state_machine:set_state('town')
		end
		love.graphics.setCanvas(self.canvas)
			love.graphics.clear()
			self.maps[self.maps.current_index]:draw()

		love.graphics.setCanvas()

		imgui.Image(self.canvas, imgui.ImVec2_Float(800,800))
	end,
}
states.battle = {
	init = function (self, machine, ...)
		self.battle = nil

		self.gui = {
			character = function (self, character_menu_data)
				local function iterate_list_selectables (list)
					for i, v in ipairs(list.items) do
						if imgui.Selectable_Bool(v.name, v.bool) then
							list:select_index(i)
						end
					end
				end

				if imgui.BeginTabItem(character_menu_data.character.info.name) then
			
					imgui.Text('NAME: '..character_menu_data.character.info.name)
					imgui.Text('HP: '..character_menu_data.character.info.hp)
					imgui.Text('STR: '..character_menu_data.character.info.str)
					imgui.Text('DEF: '..character_menu_data.character.info.def)
					imgui.Text('SPD: '..character_menu_data.character.info.spd)
			
					iterate_list_selectables(character_menu_data.actions)
			
			
					if imgui.Button('Select Target') then
						imgui.OpenPopup_Str('targets')
					end
			
					if imgui.BeginPopup('targets') then
			
						iterate_list_selectables(character_menu_data.targets)
			
						imgui.EndPopup()
					end
			
			
					imgui.EndTabItem()
				end
			end,
			ally = function (self, battle)
				if imgui.BeginChild_Str('Allies', imgui.ImVec2_Float(200,200), true) then
					if imgui.BeginTabBar('') then
			
						self:character(battle.characters_menu_data[1])
						self:character(battle.characters_menu_data[2])
						self:character(battle.characters_menu_data[3])
			
						imgui.EndTabBar()
					end
				end
				imgui.EndChild()
			end,
			enemy = function (self, battle)
				if imgui.BeginChild_Str('Enemies', imgui.ImVec2_Float(200,200), true) then
					if imgui.BeginTabBar('') then
			
						self:character(battle.characters_menu_data[4])
						self:character(battle.characters_menu_data[5])
						self:character(battle.characters_menu_data[6])
			
						imgui.EndTabBar()
					end
				end
				imgui.EndChild()
			end,
			manager = function (self, battle)
				if imgui.BeginChild_Str('Log', imgui.ImVec2_Float(200,200), true) then
					imgui.Text(tostring(battle.current_turn))
					if imgui.Button('End Turn') then
						battle:turn_end()
					end
			
					for i, v in ipairs(battle.log) do
						imgui.Text(v)
					end
				end
				imgui.EndChild()
			end,
		}
	end,
	enter = function (self, machine, ...)
		local characters = {
			saved_characters.fighter,
			saved_characters.healer,
			saved_characters.mage,
		
			Character:new()
			:set_info(character_infos.rat),

			Character:new()
			:set_info(character_infos.rat),

			Character:new()
			:set_info(character_infos.rat),

		}
		for i, v in ipairs(characters) do
			local same_names = {}
			table.insert(same_names, characters[i])
			for i2 = i+1, #characters do
				if characters[i].info.name == characters[i2].info.name then
					table.insert(same_names, characters[i2])
				end
			end
			if #same_names > 1 then
				for i2, v2 in ipairs(same_names) do
					v2.info.name = v2.info.name..' '..i2
				end
			end
		end
		self.battle = Battle:new(characters)
		table.insert(self.battle.active_events, events.character_died)
		table.insert(self.battle.active_events, events.allies_died)
		table.insert(self.battle.active_events, events.enemies_died)
		local function gui_generate_actions (character)
			local actions = List:new()
			for i, v in ipairs(character.info.actions) do
				actions:add(v.name, i == 1, v)
			end
		
			return actions
		end
		local function gui_generate_targets (characters)
			local targets = List:new()
			for i, v in ipairs(characters) do
				targets:add(v.info.name, i == 1, v)
			end
		
			return targets
		end
		local function new_characters_menu_data (battle)
			local characters_menu_data = {}
			for i, v in ipairs(battle.groups.all) do
				local t = {
					character = v,
					actions = gui_generate_actions(v),
					targets = gui_generate_targets(battle.groups.all)
				}
				
				table.insert(characters_menu_data, t)
			end
		
			return characters_menu_data
		end
		self.battle.characters_menu_data = new_characters_menu_data(self.battle)
	end,
	exit = function (self, machine, ...)

	end,
	update = function (self, machine, ...)
		if self.battle.should_exit then
			self.battle.exit_func(machine)
		end
	end,
	draw = function (self, machine, ...)
		self.gui:ally(self.battle)
		imgui.SameLine()
		self.gui:manager(self.battle)
		imgui.SameLine()
		self.gui:enemy(self.battle)
	end,
}
states.game_over = {
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
states.victory = {
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
state_machine:new(states)
for k, v in pairs(states) do
	v:init(state_machine)
end
state_machine:set_state('title')

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