require('globals')

local character = {
    info = {
        name = 'A',
        str = 10,
        def = 10,
        spd = 10
    }
}

local imgui_window = function (self)
    if imgui.Begin('Menu') then
        imgui.Text('Name: '..self.name)
        imgui.Text('Str: '..self.str)
        imgui.Text('Def: '..self.def)
        imgui.Text('Spd: '..self.spd)
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

    imgui_window(character.info)
    
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