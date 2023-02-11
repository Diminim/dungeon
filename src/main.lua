require('globals')

local Character = {
    set_info = function (self, info)
        self.info = tablex.shallow_copy(info)

        return self
    end,

	new = function (self, o)
		o = o or {}
		setmetatable(o, self)
		self.__index = self
		return o
    end,
}

local new_info = function (name, str, def, spd)
	return {
		name = name, 
		str = str, 
		def = def, 
		spd = spd
	}
end

local info_a = new_info('A', 10, 10, 10)
local info_b = new_info('B', 10, 10, 10)
local info_c = new_info('C', 10, 10, 10)

character_a = Character:new()
:set_info(info_a)

character_b = Character:new()
:set_info(info_b)

character_c = Character:new()
:set_info(info_c)


local imgui_header_character = function (self)
    if imgui.CollapsingHeader_TreeNodeFlags(self.name) then

        imgui.Text('Name: '..self.name)
        imgui.Text('Str: '..self.str)
        imgui.Text('Def: '..self.def)
        imgui.Text('Spd: '..self.spd)
    end
end

local imgui_window = function ()
    if imgui.Begin('Menu') then
        imgui_header_character(character_a.info)
		imgui_header_character(character_b.info)
		imgui_header_character(character_c.info)
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