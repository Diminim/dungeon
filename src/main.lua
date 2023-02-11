require('globals') -- tablex, imgui

local List = {
	new = function (self)
		local o = {}
		setmetatable(o, self)
		self.__index = self
		o:init()
		return o
    end,

	init = function (self)
		self.items = {
			size = 0,
			names = {},
			bools = {},
			references = {},
		}

		return self
	end,

	add = function (self, name, bool, reference)
		self.items.size = self.items.size + 1
		table.insert(self.items.names, name)
		table.insert(self.items.bools, bool)
		table.insert(self.items.references, reference)
	
		return self
	end,

	select_index = function (self, selected_index)
		for i, v in ipairs(self.items.bools) do
			if i == selected_index then 
				self.items.bools[i] = true
			else 
				self.items.bools[i] = false
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

local actions = {
	attack = {
		name = "Attack",
		execute = function (self, target)
			target.hp = target.hp - math.max(self.str - target.def, 0)
		end,
	},

	defend = {
		name = "Defend",
		execute = function (self, target)

		end,
	},
}

local new_info = function (name, hp, str, def, spd, actions)
	return {
		name = name, 
		hp = hp,
		str = str, 
		def = def, 
		spd = spd,

		actions = actions,
	}
end

local info_a = new_info('A', 100, 20, 10, 10, {actions.attack, actions.defend})
local info_b = new_info('B', 100, 20, 10, 11, {actions.attack, actions.defend})
local info_c = new_info('C', 100, 20, 10, 12, {actions.attack, actions.defend})
local info_d = new_info('D', 100, 20, 10, 13, {actions.attack, actions.defend})
local info_e = new_info('E', 100, 20, 10, 14, {actions.attack, actions.defend})
local info_f = new_info('F', 100, 20, 10, 14, {actions.attack})

local characters = {
	Character:new()
	:set_info(info_a),

	Character:new()
	:set_info(info_b),

	Character:new()
	:set_info(info_c),

	Character:new()
	:set_info(info_d),

	Character:new()
	:set_info(info_e),

	Character:new()
	:set_info(info_f)
}

local function generate_actions (character)
	local actions = List:new()
	for i, v in ipairs(character.info.actions) do
		local bool = (i == 1) and true or false
		actions:add(v.name, bool, v)
	end

	return actions
end

local function generate_targets (characters)
	local targets = List:new()
	for i, v in ipairs(characters) do
		local bool = (i == 1) and true or false
		targets:add(v.info.name, bool, v)
	end

	return targets
end

local characters_menu_data = {}
for i, v in ipairs(characters) do
	local t = {
		character = v,
		actions = generate_actions(v),
		targets = generate_targets(characters)
	}
	
	table.insert(characters_menu_data, t)
end

local function iterate_list_selectables (list)
	for i, v in ipairs(list.items.names) do
		if imgui.Selectable_Bool(v, list.items.bools[i]) then
			list:select_index(i)
		end
	end
end

local battle_log = {}

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

local imgui_window_ally = function ()
    if imgui.Begin('Allies') then
		if imgui.BeginTabBar('') then

        	imgui_tab_character(characters_menu_data[1])
			imgui_tab_character(characters_menu_data[2])
			imgui_tab_character(characters_menu_data[3])

			imgui.EndTabBar()
		end
    end
    imgui.End()
end

local imgui_window_enemy = function ()
    if imgui.Begin('Enemies') then
		if imgui.BeginTabBar('') then

        	imgui_tab_character(characters_menu_data[4])
			imgui_tab_character(characters_menu_data[5])
			imgui_tab_character(characters_menu_data[6])

			imgui.EndTabBar()
		end
    end
    imgui.End()
end

local imgui_window_manager = function ()
    if imgui.Begin('Log') then
		if imgui.Button('End Turn') then
			for i, v in ipairs(characters_menu_data) do
				local character = v.character
				local target_index
				local action_index
				for i2, v2 in ipairs(v.actions.items.bools) do
					if v2 == true then
						action_index = i2
						break
					end
				end
				for i2, v2 in ipairs(v.targets.items.bools) do
					if v2 == true then
						target_index = i2
						break
					end
				end
				local str = ''
				str = str..character.info.name..' '
				str = str..v.actions.items.names[action_index]..' '
				str = str..v.targets.items.names[target_index]

				v.actions.items.references[action_index].execute(character.info, v.targets.items.references[target_index].info)
				table.insert(battle_log, str)
			end
		end

		for i, v in ipairs(battle_log) do
			imgui.Text(v)
		end
    end
    imgui.End()
end

love.load = function ()
    imgui.love.Init()
end

love.update = function (dt)
    imgui.love.Update(dt)
    imgui.NewFrame()
end

love.draw = function ()
    imgui.ShowDemoWindow()

    imgui_window_ally()
	imgui_window_enemy()
	imgui_window_manager()
    
    imgui.Render()
    imgui.love.RenderDrawLists()
end

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