local lib_path = love.filesystem.getWorkingDirectory() .. '/src/lib/cimgui'
local extension = jit.os == 'Windows' and 'dll' or jit.os == 'Linux' and 'so' or jit.os == 'OSX' and 'dylib'
package.cpath = string.format('%s;%s/?.%s', package.cpath, lib_path, extension)
imgui = require('lib/cimgui/cimgui')

tablex = require('lib/batteries/tablex')

state_machine = require('lib/batteries/state_machine')

sti = require('lib/sti')

bump =  require('lib/bump')