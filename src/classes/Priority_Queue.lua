local Priority_Queue = {
	new = function (self)
		local o = {}
		setmetatable(o, self)
		self.__index = self
		o:init()
		return o
    end,

	init = function (self)
		self.queue = {}
	end,

	insertion_sort = function (self, index, action_info)
		local insertion_index
		if not self.queue[index + action_info.turn] then
			self.queue[index + action_info.turn] = {}
		end
		for i, v in ipairs(self.queue[index + action_info.turn]) do
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
		insertion_index = insertion_index or (#self.queue[index + action_info.turn]+1)
		table.insert(self.queue[index + action_info.turn], insertion_index, action_info)
	end,
}

return Priority_Queue