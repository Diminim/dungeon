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
		self.items[pointer] = {
			name = name,
			bool = bool,
			pointer = pointer,
		}

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

	select_key = function (self, selected_key)
		for k, v in pairs(self.items) do
			if k == selected_key then 
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

return List