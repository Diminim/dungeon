local List = require('classes/List')
local Character = require('classes/Character')
local Battle = require('classes/Battle')

local actions = require('actions')
local character_infos = require('character_infos')
local events = require('events')

saved_characters = {
	fighter = Character:new()
	:set_info(character_infos.fighter),

	healer = Character:new()
	:set_info(character_infos.medic),

	mage = Character:new()
	:set_info(character_infos.mage),
}

local battle = {
	init = function (self, machine, ...)
		self.battle = nil

		self.gui = {
			ai = function (self, battle)
				if imgui.Button('End Turn') then
					for i, v in ipairs(battle.groups.enemies) do
						target = battle.groups.allies[love.math.random(1, #battle.groups.allies)]
						local target_index = battle.characters_menu_data[v].targets:search('pointer', target)
						battle.characters_menu_data[v].targets:select_index(target_index)
					end
					battle:turn_end()
				end
			end,

			character = function (self, character_menu_data)
				local function iterate_list_selectables (list)
					for i, v in ipairs(list.items) do
						if imgui.Selectable_Bool(v.name, v.bool) then
							list:select_index(i)
							imgui.OpenPopup_Str('targets')
						end
					end
				end

				if imgui.BeginTabItem(character_menu_data.character.info.name) then
			
					imgui.Text('NAME: '..character_menu_data.character.info.name)
					imgui.Text('HP: '..character_menu_data.character.info.hp.. '/'..character_menu_data.character.info.max_hp)
					imgui.Text('STR: '..character_menu_data.character.info.str)
					imgui.Text('DEF: '..character_menu_data.character.info.def)
					imgui.Text('SPD: '..character_menu_data.character.info.spd)
			
					iterate_list_selectables(character_menu_data.actions)
			
					if imgui.BeginPopup('targets') then
						iterate_list_selectables(character_menu_data.targets)
						imgui.EndPopup()
					end
			
			
					imgui.EndTabItem()
				end
			end,
			ally = function (self, battle)
				if imgui.BeginChild_Str('Allies', imgui.ImVec2_Float(200,200), true) then
					if imgui.BeginTabBar('') then
			
						for k, v in pairs(battle.characters_menu_data) do
							if not v.character.info.is.enemy then
								self:character(v)
							end
						end
			
						imgui.EndTabBar()
					end
				end
				imgui.EndChild()
			end,
			enemy = function (self, battle)
				if imgui.BeginChild_Str('Enemies', imgui.ImVec2_Float(200,200), true) then
					if imgui.BeginTabBar('') then
			
						for k, v in pairs(battle.characters_menu_data) do
							if v.character.info.is.enemy then
								self:character(v)
							end
						end
			
						imgui.EndTabBar()
					end
				end
				imgui.EndChild()
			end,
			manager = function (self, battle)
				if imgui.BeginChild_Str('Log', imgui.ImVec2_Float(200,200), true) then
					imgui.Text(tostring(battle.current_turn))
			
					for i, v in ipairs(battle.log) do
						imgui.Text(v)
					end
				end
				imgui.EndChild()
			end,
		}
	end,
	enter = function (self, machine, ...)
		local rat_1 = Character:new()
		:set_info(character_infos.rat)
		local rat_2 = Character:new()
		:set_info(character_infos.rat)
		local rat_3 = Character:new()
		:set_info(character_infos.rat)

		rat_1.info.is.enemy = true
		rat_2.info.is.enemy = true
		rat_3.info.is.enemy = true

		local characters = {
			saved_characters.fighter,
			saved_characters.healer,
			saved_characters.mage,

			rat_1,
			rat_2,
			rat_3
		}
		for i, v in ipairs(characters) do
			local same_names = {}
			table.insert(same_names, characters[i])
			for i2 = i+1, #characters do
				if characters[i].info.name == characters[i2].info.name then
					table.insert(same_names, characters[i2])
				end
			end
			if #same_names > 1 then
				for i2, v2 in ipairs(same_names) do
					v2.info.name = v2.info.name..' '..i2
				end
			end
		end
		self.battle = Battle:new(characters)
		table.insert(self.battle.active_events, events.character_died)
		table.insert(self.battle.active_events, events.allies_died)
		table.insert(self.battle.active_events, events.enemies_died)
		local function gui_generate_actions (character)
			local actions = List:new()
			for i, v in ipairs(character.info.actions) do
				actions:add(v.name, i == 1, v)
			end
		
			return actions
		end
		local function gui_generate_targets (characters)
			local targets = List:new()
			for i, v in ipairs(characters) do
				targets:add(v.info.name, i == 1, v)
			end
		
			return targets
		end
		local function new_characters_menu_data (battle)
			local characters_menu_data = {}
			for i, v in ipairs(battle.groups.all) do
				local t = {
					character = v,
					actions = gui_generate_actions(v),
					targets = gui_generate_targets(battle.groups.all)
				}
				
				characters_menu_data[v] = t
			end
		
			return characters_menu_data
		end
		self.battle.characters_menu_data = new_characters_menu_data(self.battle)
	end,
	exit = function (self, machine, ...)

	end,
	update = function (self, machine, ...)
		if self.battle.should_exit then
			--self.battle.exit_func(machine)
		end
	end,
	draw = function (self, machine, ...)
		self.gui:ai(self.battle)
		self.gui:ally(self.battle)
		imgui.SameLine()
		self.gui:manager(self.battle)
		imgui.SameLine()
		self.gui:enemy(self.battle)
	end,
}

return battle