local map = {
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

return map