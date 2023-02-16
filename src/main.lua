require('globals')

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
		self.action_priority_queue = {}
		self.log = {}
		self.groups = {}
		self.active_events = {}

		self:init_groups()
	end,

	init_groups = function (self)
		self.groups.all = self.characters
		self.groups.allies = {self.characters[1], self.characters[2], self.characters[3]}
		self.groups.enemies = {self.characters[4], self.characters[5], self.characters[6]}
	end,

}



-- -------------------------------------------------------------------------- --

local map_texture = love.graphics.newImage('maps/map/tiles.png')
local map = sti('maps/map/tiles.lua')

local world = bump.newWorld(16)

for k, v in pairs(map.objects) do
	world:add(v, v.x, v.y, 16, 16)
end

map.layers['Object Layer 1'].update = function(self)
	for i, v in ipairs(self.objects) do
		if v.name == "player" then
			local goal_x, goal_y = v.x, v.y
			if input:when_pressed(input.alias.up) then
				goal_y = goal_y - 16
			elseif input:when_pressed(input.alias.left) then
				goal_x = goal_x - 16
			elseif input:when_pressed(input.alias.down) then
				goal_y = goal_y + 16
			elseif input:when_pressed(input.alias.right) then
				goal_x = goal_x + 16
			end

			local actual_x, actual_y, cols = world:move(v, goal_x, goal_y)
			v.x, v.y = actual_x, actual_y
		end
	end
end

map.layers['Object Layer 1'].draw = function(self)
	for i, v in ipairs(self.objects) do
		local quad = map.tiles[v.gid].quad
		love.graphics.draw(map_texture, quad, v.x, v.y)
	end
end


-- -------------------------------------------------------------------------- --



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


local function iterate_list_selectables (list)
	for i, v in ipairs(list.items) do
		if imgui.Selectable_Bool(v.name, v.bool) then
			list:select_index(i)
		end
	end
end


local action_info_new = function (action, context)

	local action_info = {
		action = function ()
			return action:execute(context)
		end,
		actor = context.actor,
		target = context.target,
		turn = action.turn_modifer,
		priority = action.priority,
		speed = context.actor.info.spd + action.speed_modifier,
	}

	return action_info
end
local action_priority_queue_insertion_sort = function (battle, action_info)
	local insertion_index
	if not battle.action_priority_queue[battle.current_turn + action_info.turn] then
		battle.action_priority_queue[battle.current_turn + action_info.turn] = {}
	end
	for i, v in ipairs(battle.action_priority_queue[battle.current_turn + action_info.turn]) do
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
	insertion_index = insertion_index or (#battle.action_priority_queue[battle.current_turn + action_info.turn]+1)
	table.insert(battle.action_priority_queue[battle.current_turn + action_info.turn], insertion_index, action_info)
end




local imgui_tab_character = function (self)
    if imgui.BeginTabItem(self.character.info.name) then

        imgui.Text('NAME: '..self.character.info.name)
		imgui.Text('HP: '..self.character.info.hp)
        imgui.Text('STR: '..self.character.info.str)
        imgui.Text('DEF: '..self.character.info.def)
        imgui.Text('SPD: '..self.character.info.spd)

		iterate_list_selectables(self.actions)


		if imgui.Button('Select Target') then
			imgui.OpenPopup_Str('targets')
		end

		if imgui.BeginPopup('targets') then

			iterate_list_selectables(self.targets)

			imgui.EndPopup()
		end


		imgui.EndTabItem()
    end
end
local imgui_child_ally = function (battle)
    if imgui.BeginChild_Str('Allies', imgui.ImVec2_Float(200,200), true) then
		if imgui.BeginTabBar('') then

        	imgui_tab_character(battle.characters_menu_data[1])
			imgui_tab_character(battle.characters_menu_data[2])
			imgui_tab_character(battle.characters_menu_data[3])

			imgui.EndTabBar()
		end
    end
    imgui.EndChild()
end
local imgui_child_enemy = function (battle)
    if imgui.BeginChild_Str('Enemies', imgui.ImVec2_Float(200,200), true) then
		if imgui.BeginTabBar('') then

        	imgui_tab_character(battle.characters_menu_data[4])
			imgui_tab_character(battle.characters_menu_data[5])
			imgui_tab_character(battle.characters_menu_data[6])

			imgui.EndTabBar()
		end
    end
    imgui.EndChild()
end
local turn_end = function (battle)
	for i, v in ipairs(battle.characters_menu_data) do
		local action_index = v.actions:search('bool', true)
		local target_index = v.targets:search('bool', true)

		local character = v.character
		local action = v.actions.items[action_index].pointer
		local target = v.targets.items[target_index].pointer

		local context = {
			actor = v.character,
			target = v.targets.items[target_index].pointer,
			battle = battle,
		}

		local action_info = action_info_new(action, context)
		action_priority_queue_insertion_sort(battle, action_info)
	end

	for i, v in ipairs(battle.action_priority_queue[battle.current_turn]) do
		local message, chained_action = v.action()
		if chained_action then
			local context = {
				actor = v.actor,
				target = v.target,
				battle = battle,
			}

			local action_info = action_info_new(chained_action, context)
			action_priority_queue_insertion_sort(battle, action_info)
		end
		if message then
			table.insert(battle.log, message)
		end
		for i, v in ipairs(battle.active_events) do
			v(battle)
		end
	end
	battle.current_turn = battle.current_turn + 1
end
local imgui_child_manager = function (battle)
    if imgui.BeginChild_Str('Log', imgui.ImVec2_Float(200,200), true) then
		imgui.Text(tostring(battle.current_turn))
		if imgui.Button('End Turn') then
			turn_end(battle)
		end

		for i, v in ipairs(battle.log) do
			imgui.Text(v)
		end
    end
    imgui.EndChild()
end

-- -------------------------------------------------------------------------- --
local character_infos = require('character_infos')
local events = require('events')

local states = {
	prototype = {
		enter = function (self, machine, ...)

		end,
		exit = function (self, machine, ...)

		end,
		update = function (self, machine, ...)

		end,
		draw = function (self, machine, ...)

		end,
	},

	map = {
		canvas = love.graphics.newCanvas(800, 800, {type = "2d", format = "normal", readable = true}),
		enter = function (self, machine, ...)

		end,
		exit = function (self, machine, ...)

		end,
		update = function (self, machine, ...)
			map:update(dt)
		end,
		draw = function (self, machine, ...)
			love.graphics.setCanvas(self.canvas)
				love.graphics.clear()
				map:draw()
			love.graphics.setCanvas()

			imgui.Image(self.canvas, imgui.ImVec2_Float(800,800))
		end,
	},

	battle = {
		battle = nil,
		enter = function (self, machine, ...)
			local characters = {
				Character:new()
				:set_info(character_infos.fighter),
			
				Character:new()
				:set_info(character_infos.healer),
			
				Character:new()
				:set_info(character_infos.mage),
			
				Character:new()
				:set_info(character_infos.d),
			
				Character:new()
				:set_info(character_infos.e),
			
				Character:new()
				:set_info(character_infos.f)
			}
			self.battle = Battle:new(characters)
			table.insert(self.battle.active_events, events.character_died)
			table.insert(self.battle.active_events, events.allies_died)
			table.insert(self.battle.active_events, events.enemies_died)
			self.battle.characters_menu_data = new_characters_menu_data(self.battle)
		end,
		exit = function (self, machine, ...)

		end,
		update = function (self, machine, ...)

		end,
		draw = function (self, machine, ...)
			imgui_child_ally(self.battle)
			imgui.SameLine()
			imgui_child_manager(self.battle)
			imgui.SameLine()
			imgui_child_enemy(self.battle)
		end,
	},
}
state_machine:new(states)
state_machine:set_state('map')

-- -------------------------------------------------------------------------- --

local imgui_window = function ()
	if imgui.Begin('All') then
		if imgui.Button('Enter Battle') then
			state_machine:set_state('battle')
		end
		imgui.SameLine()
		if imgui.Button('Exit Battle') then
			state_machine:set_state('map')
		end

		state_machine:draw()
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