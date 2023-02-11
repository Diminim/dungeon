require('globals')

local Character = {
	new = function (self)
		local o = {}
		setmetatable(o, self)
		self.__index = self
		return o
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

character_a = Character:new()
:set_info(info_a)

character_b = Character:new()
:set_info(info_b)

character_c = Character:new()
:set_info(info_c)

local selections = {
	true, false
}

local List = {
	new = function (self)
		local o = {}
		setmetatable(o, self)
		self.__index = self

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

local list_actions = List:new()
:init()
:add('Attack', true)
:add('Defend', false)

local list_targets = List:new()
:init()
:add('A', true)
:add('B', false)

local imgui_tab_character = function (self)
    if imgui.BeginTabItem(self.name) then

        imgui.Text('NAME: '..self.name)
		imgui.Text('HP: '..self.hp)
        imgui.Text('STR: '..self.str)
        imgui.Text('DEF: '..self.def)
        imgui.Text('SPD: '..self.spd)

		for i, v in ipairs(list_actions.items.names) do
			if imgui.Selectable_Bool(v, list_actions.items.bools[i]) then
				list_actions:select_index(i)
			end
		end

		if imgui.Button('Select Target') then
			imgui.OpenPopup_Str('targets')
		end

		if imgui.BeginPopup('targets') then

			for i, v in ipairs(list_targets.items.names) do
				if imgui.Selectable_Bool(v, list_targets.items.bools[i]) then
					list_targets:select_index(i)
				end
			end

			imgui.EndPopup()
		end


		imgui.EndTabItem()
    end
end

local imgui_window = function ()
    if imgui.Begin('Menu') then
		if imgui.BeginTabBar('') then

        	imgui_tab_character(character_a.info)
			imgui_tab_character(character_b.info)
			imgui_tab_character(character_c.info)

			imgui.EndTabBar()
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

    imgui_window()
    
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