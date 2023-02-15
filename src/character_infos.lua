local actions = require('actions')

local character_info_new = function (name, hp, str, def, spd, actions)
	return {
		name = name, 
		hp = hp,
		str = str, 
		def = def, 
		spd = spd,

		actions = actions,

		--flags = {}
		is_dead = false,
	}
end
local character_infos = {
	fighter = character_info_new('Fighter', 100, 20, 10, 10, {actions.attack, actions.slow_attack, actions.delayed_attack, actions.burn_all, actions.defend}),
	healer = character_info_new('Healer', 100, 20, 10, 11, {actions.attack, actions.heal, actions.defend}),
	mage = character_info_new('Mage', 100, 20, 10, 12, {actions.attack, actions.defend}),
	d = character_info_new('D', 100, 20, 10, 13, {actions.attack, actions.defend}),
	e = character_info_new('E', 100, 20, 10, 14, {actions.attack, actions.defend}),
	f = character_info_new('F', 100, 20, 10, 15, {actions.attack}),
}

return character_infos