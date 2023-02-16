local lib_path = love.filesystem.getWorkingDirectory() .. '/src/lib/cimgui'
local extension = jit.os == 'Windows' and 'dll' or jit.os == 'Linux' and 'so' or jit.os == 'OSX' and 'dylib'
package.cpath = string.format('%s;%s/?.%s', package.cpath, lib_path, extension)
imgui = require('lib/cimgui/cimgui')

tablex = require('lib/batteries/tablex')

state_machine = require('lib/batteries/state_machine')

sti = require('lib/sti')

bump =  require('lib/bump')

input = {
    keys_down_last_frame = {
        ["q"] = false,
        ["w"] = false,
        ["e"] = false,
        ["r"] = false,
        ["t"] = false,
        ["y"] = false,
        ["u"] = false,
        ["i"] = false,
        ["o"] = false,
        ["p"] = false,
        ["a"] = false,
        ["s"] = false,
        ["d"] = false,
        ["f"] = false,
        ["g"] = false,
        ["h"] = false,
        ["j"] = false,
        ["k"] = false,
        ["l"] = false,
        ["z"] = false,
        ["x"] = false,
        ["c"] = false,
        ["v"] = false,
        ["b"] = false,
        ["n"] = false,
        ["m"] = false,
        ["space"] = false,
        ["return"] = false,
        ["left"] = false,
        ["right"] = false,
        ["up"] = false,
        ["down"] = false,
        ["1"] = false,
        ["2"] = false,
        ["3"] = false,
        ["4"] = false,
        ["5"] = false,
        ["6"] = false,
        ["7"] = false,
        ["8"] = false,
        ["9"] = false,
        ["0"] = false,
    },
    key_alias = {
        left = 'a',
        right = 'd',
        up = 'w',
        down = 's',

        a = 'm',
        b = 'n'
    },
    -- buffer = {},
    -- command_list = {}

    update = function (self)
        for k, v in pairs(self.keys_down_last_frame) do
            self.keys_down_last_frame[k] = love.keyboard.isDown(k)
        end
    end,

    when_pressed = function (self, ...)
        local bit = false
        local t = {...}
    
        for i, v in ipairs(t) do
            if 
                not (self.keys_down_last_frame[v]) and
                love.keyboard.isDown(v)
            then
                bit = true
            end
        end
    
        return bit
    end,

    when_held = function (self, ...)
        local bit = false
        local t = {...}
    
        for i, v in ipairs(t) do
            if 
                self.keys_down_last_frame[v] and
                love.keyboard.isDown(v)
            then
                bit = true
            end
        end
    
        return bit
    end,

    when_released = function (self, ...)
        local bit = false
        local t = {...}
    
        for i, v in ipairs(t) do
            if 
                self.keys_down_last_frame[v] and
                not (love.keyboard.isDown(v))
            then
                bit = true 
            end
        end
    
        return bit
    end,
}
