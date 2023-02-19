local actions = require('actions')

local character_info_new = function (name, max_hp, str, def, spd, actions)
	return {
		name = name,
		max_hp = max_hp,
		hp = max_hp,
		str = str, 
		def = def, 
		spd = spd,

		actions = actions,

		is = {
			dead = false,
		}
	}
end
local character_infos = {
	debug = character_info_new('Debug', 50, 10, 10, 10, 
	{actions.kill_all, actions.kill_enemies, actions.kill_allies, actions.defend}),

	fighter = character_info_new('Fighter', 50, 10, 10, 10, 
	{actions.attack, actions.defend}),

	medic = character_info_new('Healer', 50, 10, 10, 11, 
	{actions.attack, actions.heal, actions.revive, actions.defend}),
	
	mage = character_info_new('Mage', 50, 10, 10, 12, 
	{actions.attack, actions.defend}),

	rat = character_info_new('Rat', 50, 10, 10, 13, {actions.attack, actions.defend}),
}

return character_infos