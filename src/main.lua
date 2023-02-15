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

		self:init_groups()
	end,

	init_groups = function (self)
		self.groups.all = self.characters
		self.groups.allies = {self.characters[1], self.characters[2], self.characters[3]}
		self.groups.enemies = {self.characters[4], self.characters[5], self.characters[6]}
	end,

}

-- -------------------------------------------------------------------------- --

local map = sti('maps/map/tiles.lua')
local spriteLayer = map:addCustomLayer('Sprite Layer', 3)
spriteLayer.sprites = {
	player = {
		image = love.graphics.newImage('guy2.png'),
		x = 16*0,
		y = 16*0,
		r = 0,
	}
}
spriteLayer.update = function(self, dt)
	local player = self.sprites.player
	if love.keyboard.isDown('w') then
		player.y = player.y - 16
	elseif love.keyboard.isDown('a') then
		player.x = player.x - 16
	elseif love.keyboard.isDown('s') then
		player.y = player.y + 16
	elseif love.keyboard.isDown('d') then
		player.x = player.x + 16
	end
end
spriteLayer.draw = function(self)
	for _, sprite in pairs(self.sprites) do
		local x = math.floor(sprite.x)
		local y = math.floor(sprite.y)
		local r = sprite.r
		love.graphics.draw(sprite.image, x, y, r)
	end
end

-- -------------------------------------------------------------------------- --
local character_infos = require('character_infos')

local battle
local characters_menu_data
local active_events

local event = {
	character_died = function ()
		for i, v in ipairs(battle.groups.all) do
			local message
			if (v.info.is_dead == false) and (v.info.hp <= 0) then
				v.info.is_dead = true
				message = ('%s %s'):format(
					v.info.name, 
					'died!'
				)
			end
			if message then 
				table.insert(battle.log, message) 
			end
		end
	end,

	allies_died = function ()
		local dead_number = 0
		for i, v in ipairs(battle.groups.allies) do
			if (v.info.is_dead == true) then
				dead_number = dead_number + 1
			end
		end
		if dead_number == #battle.groups.allies then
			local message = 'Allies have been defeated...'
			table.insert(battle.log, message)
		end
	end,

	enemies_died = function ()
		local dead_number = 0
		for i, v in ipairs(battle.groups.enemies) do
			if (v.info.is_dead == true) then
				dead_number = dead_number + 1
			end
		end
		if dead_number == #battle.groups.enemies then
			local message = 'Enemies have been defeated!'
			table.insert(battle.log, message)
		end
	end,
}

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


local function action_priority_queue_insertion_sort (action_info)
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





local function turn_end ()
	for i, v in ipairs(characters_menu_data) do
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
		action_priority_queue_insertion_sort(action_info)
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
			action_priority_queue_insertion_sort(action_info)
		end
		if message then
			table.insert(battle.log, message)
		end

		for i, v in ipairs(active_events) do
			v()
		end
	end
	battle.current_turn = battle.current_turn + 1
end

local canvas = love.graphics.newCanvas(800, 800, {type = "2d", format = "normal", readable = true})

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
local imgui_child_ally = function ()
    if imgui.BeginChild_Str('Allies', imgui.ImVec2_Float(200,200), true) then
		if imgui.BeginTabBar('') then

        	imgui_tab_character(characters_menu_data[1])
			imgui_tab_character(characters_menu_data[2])
			imgui_tab_character(characters_menu_data[3])

			imgui.EndTabBar()
		end
    end
    imgui.EndChild()
end
local imgui_child_enemy = function ()
    if imgui.BeginChild_Str('Enemies', imgui.ImVec2_Float(200,200), true) then
		if imgui.BeginTabBar('') then

        	imgui_tab_character(characters_menu_data[4])
			imgui_tab_character(characters_menu_data[5])
			imgui_tab_character(characters_menu_data[6])

			imgui.EndTabBar()
		end
    end
    imgui.EndChild()
end
local imgui_child_manager = function ()
    if imgui.BeginChild_Str('Log', imgui.ImVec2_Float(200,200), true) then
		imgui.Text(tostring(battle.current_turn))
		if imgui.Button('End Turn') then
			turn_end()
		end

		for i, v in ipairs(battle.log) do
			imgui.Text(v)
		end
    end
    imgui.EndChild()
end

-- -------------------------------------------------------------------------- --

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
		enter = function (self, machine, ...)

		end,
		exit = function (self, machine, ...)

		end,
		update = function (self, machine, ...)
			map:update(dt)
		end,
		draw = function (self, machine, ...)
			love.graphics.setCanvas(canvas)
				love.graphics.clear()
				map:draw()
			love.graphics.setCanvas()

			imgui.Image(canvas, imgui.ImVec2_Float(800,800))
		end,
	},

	battle = {
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
			active_events = {}
			table.insert(active_events, event.character_died)
			table.insert(active_events, event.allies_died)
			table.insert(active_events, event.enemies_died)
			battle = Battle:new(characters)
			characters_menu_data = new_characters_menu_data(battle)
		end,
		exit = function (self, machine, ...)

		end,
		update = function (self, machine, ...)

		end,
		draw = function (self, machine, ...)
			imgui_child_ally()
			imgui.SameLine()
			imgui_child_manager()
			imgui.SameLine()
			imgui_child_enemy()
		end,
	},
}
state_machine:new(states)
state_machine:set_state('battle')

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