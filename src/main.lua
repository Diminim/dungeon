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
		self.items = {
			size = 0,
			names = {},
			bools = {},
		}

		return self
	end,

	add = function (self, name, bool)
		self.items.size = self.items.size + 1
		table.insert(self.items.names, name)
		table.insert(self.items.bools, bool)
	
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

local new_info = function (name, hp, str, def, spd)
	return {
		name = name, 
		hp = hp,
		str = str, 
		def = def, 
		spd = spd
	}
end

local info_a = new_info('A', 100, 10, 10, 10)
local info_b = new_info('B', 100, 10, 10, 10)
local info_c = new_info('C', 100, 10, 10, 10)
local info_d = new_info('D', 100, 10, 10, 10)
local info_e = new_info('E', 100, 10, 10, 10)
local info_f = new_info('F', 100, 10, 10, 10)

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

local function generate_actions ()
	local actions = List:new()
	:add('Attack', true)
	:add('Defend', false)

	return actions
end

local function generate_targets ()
	local targets = List:new()
	for i, v in ipairs(characters) do
		local bool = (i == 1) and true or false
		targets:add(v.info.name, bool)
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
	
	characters_menu_data[v.info.name] = t
end

local function iterate_list_selectables (list)
	for i, v in ipairs(list.items.names) do
		if imgui.Selectable_Bool(v, list.items.bools[i]) then
			list:select_index(i)
		end
	end
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

local imgui_window_ally = function ()
    if imgui.Begin('Allies') then
		if imgui.BeginTabBar('') then

        	imgui_tab_character(characters_menu_data.A)
			imgui_tab_character(characters_menu_data.B)
			imgui_tab_character(characters_menu_data.C)

			imgui.EndTabBar()
		end
    end
    imgui.End()
end

local imgui_window_enemy = function ()
    if imgui.Begin('Enemies') then
		if imgui.BeginTabBar('') then

        	imgui_tab_character(characters_menu_data.D)
			imgui_tab_character(characters_menu_data.E)
			imgui_tab_character(characters_menu_data.F)

			imgui.EndTabBar()
		end
    end
    imgui.End()
end

local imgui_window_manager = function ()
    if imgui.Begin('Log') then
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