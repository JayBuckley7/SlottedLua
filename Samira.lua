	
Combo_key = 1
Clear_key = 3
Harass_key = 4
CastedR = false
LastTick = 0
Q_range,Q_speed,Q_width,Q_windup = 950,2600,120/2,0.25 --slot pred uses width/2
W_range,W_speed,W_width,W_windup = 325,0,325/2,0.1 --slot pred uses width/2
E_range = 600
CastEQ = false

KrakenStacks = 0
--local Kraken = features.buff_cache:get_buff(g_local.index, "6672buff")
--local KrakenStacks = 0

-- if Kraken == false then
-- 	KrakenStacks = 0
-- end

Script_name = "Simple Sam"
local test_navigation = menu.get_main_window():push_navigation(Script_name, 10000)
local my_nav = menu.get_main_window():find_navigation(Script_name)
--AutoW
-- local evade_sect = my_nav:add_section("Use evade spells")
-- local w_config = g_config:add_bool(true, "W_CC")
-- local evadeWbox = evade_sect:checkbox("Use W", w_config)
-- evadeWbox:set_value(true)
--combo
local combo_sect = my_nav:add_section("Combo Settings")
local combo_q_config = g_config:add_bool(true, "Q_in_combo")
local combo_w_config = g_config:add_bool(true, "W_in_combo")
local combo_e_config = g_config:add_bool(true, "E_in_combo")
local combo_r_config = g_config:add_bool(true, "R_in_combo")
local combo_q_box = combo_sect:checkbox("Use Q", combo_q_config)
local combo_w_box = combo_sect:checkbox("Use W", combo_w_config)
local combo_e_box = combo_sect:checkbox("Use E", combo_e_config)
local combo_r_box = combo_sect:checkbox("Use R", combo_r_config)
combo_q_box:set_value(true)
combo_w_box:set_value(true)
combo_e_box:set_value(true)
combo_r_box:set_value(true)

--harass
local harass_sect = my_nav:add_section("Harass Settings")
local harass_q_config = g_config:add_bool(true, "Q in harass")
local harass_manaPercent = g_config:add_int(0, "harassmana")
local hslider = harass_sect:slider_int("Harass mana slider", harass_manaPercent, 0, 100, 1)
local harass_q_box = harass_sect:checkbox("Use Q", harass_q_config)
harass_q_box:set_value(true)
hslider:set_value(60)

--Lane/JungleClear
-- local clear_sect = my_nav:add_section("Clear Settings")
-- local clear_q_config = g_config:add_bool(true, "Q_in_harass")
-- local clear_q_mana = g_config:add_int(0, "Q_mana")
-- local clear_q_minions = g_config:add_int(0, "Q_mins")
-- local clear_q_box = clear_sect:checkbox("Use Q", clear_q_config)
-- clear_q_box:set_value(true)
-- local clear_q_minion_slider = clear_sect:slider_int("min Minions for [Q2]", clear_q_minions, 0, 5, 1)
-- local clear_q_mana_slider = clear_sect:slider_int("% mana to q in lane clear", clear_q_mana, 0, 100, 1)

--KillSteal
local ks_sect = my_nav:add_section("ks Settings")
local ks_q_config = g_config:add_bool(true, "Q_in_ks")
local ks_e_config = g_config:add_bool(true, "E_in_ks")
local ks_q_box = ks_sect:checkbox("Use Q", ks_q_config)
local ks_e_box = ks_sect:checkbox("Use E", ks_e_config)
ks_q_box:set_value(true)
ks_e_box:set_value(true)

--dmg calc
local dmg_sect = my_nav:add_section("damage calc")
local num_pierce = g_config:add_int(0, "armprc")
local num_piercePercent = g_config:add_int(0, "armprcp")
local pslider1 = dmg_sect:slider_int("armour piercing", num_pierce, 0, 100, 1)
local pslider2 = dmg_sect:slider_int("armour pierce %", num_piercePercent, 0, 100, 1)

-- q accuracy 
local acc_sect = my_nav:add_section("damage calc")
local acc_config = g_config:add_int(0, "Q acc")
local acc_q_slider = acc_sect:slider_int("Q accuracy", acc_config, 0, 5, 1)
acc_q_slider:set_value(2)


function Vec3_Extend(a,b, dist) 
    local distance = a:dist_to(b) 
    local offset = dist / distance 
    local dir = vec3:new((a.x - b.x), b.y, (a.z - b.z)) 
    local newPos = vec3:new((a.x + dir.x*offset), b.y, (a.z + dir.z*offset)) 
return newPos end

function CastQ(unit)

    if features.buff_cache:get_buff(g_local.index, "SamiraR") ~= nil  or features.buff_cache:get_buff(g_local.index, "SamiraW") ~= nil then
        return false
    end
    
    
    Prints("cast q from ".. g_local.position:dist_to(unit.position))
    if g_local.position:dist_to(unit.position) < 325 then
        Prints("close to us")
        local qHit = features.prediction:predict(unit.index, Q_range, Q_speed, Q_width, Q_windup, g_local.position) 
        if (qHit.valid and qHit.hitchance > acc_q_slider:get_value()) then
            g_input:cast_spell(e_spell_slot.q, qHit.position)
            features.orbwalker:set_cast_time(features.orbwalker:get_attack_cast_delay())
            Prints("combo q cast")
            return true
        end
    end
    -- q2
    
    if g_local.position:dist_to(unit.position) < 950 then
        Prints("far from us")
        local qHit = features.prediction:predict(unit.index, Q_range, Q_speed, Q_width, Q_windup, g_local.position) 
        local badMinion = features.prediction:minion_in_line(g_local.position, qHit.position, 120, -1)
        if (qHit.valid and qHit.hitchance > acc_q_slider:get_value() and badMinion == false) then
            Prints("no bad minion - long q")
            g_input:cast_spell(e_spell_slot.q, qHit.position)
            features.orbwalker:set_cast_time(features.orbwalker:get_attack_cast_delay())
            return true
        end
    end
    Prints("cast q did no cast")
    return false
end

function GetManaCost(espell)
    local cost = 0
    if espell == 0 then cost = 30
    elseif espell == 1 then cost = 60
    elseif espell == 2 then cost = 40
    end
    return 0
end

function Ready(spell)
    local slot = g_local:get_spell_book():get_spell_slot(spell)
    if slot == nil then Prints("slots nil mate ") return false end
    return slot:is_ready() and slot.level > 0 and GetManaCost(spell) < g_local.mana
end

function GetEnemyCount(range)
    local numAround = 0
    for _,unit in pairs(features.entity_list:get_enemies()) do
        if unit ~= nil then
            if not unit:is_invisible() and unit:is_alive() then 
                if unit:dist_to_local() <= range then
                    numAround = numAround + 1
                end
            end
        end
    end
    return numAround
end

function Prints(str)
    local dbg = 1
    if dbg == 1 then 
        print(os.date('%H:%M:%S') .." ".. str) 
    end
end

function IsDashPosTurret(target)
    local pos = Vec3_Extend(g_local.position, target.position, 700)
    local range = 850
	for _,unit in pairs(features.entity_list:get_enemy_turrets()) do
        if unit ~= nil and not unit:is_dead() then 
            local away = unit.position:dist_to(pos)
            if away < range then
				return true
			end
		end
	end	
    return false
end

function Is_channel()
    if features.buff_cache:get_buff(g_local.index, "SamiraR") ~= nil  then
        return true
    end
    if features.buff_cache:get_buff(g_local.index, "SamiraW") ~= nil  then
        return true
    end
    return false
end

function GetDmg(spell, target)
    if target == nil then return 0 end
    local totalDamage = 0
	local armorPen = pslider1:get_value()
    local armorPenPercent = pslider2:get_value()
    -- calculate initial damage multiplier for negative and positive armor
	local targetArmor = (target.total_armor * armorPenPercent) - armorPen
    
    if spell == "Q" then
        local base = g_local:get_spell_book():get_spell_slot(e_spell_slot.q).level * 10
        local ADMod =  (g_local:get_spell_book():get_spell_slot(e_spell_slot.q).level * 10 + 80)/100
        totalDamage = base + (g_local:get_attack_damage()*ADMod)

    end
    if spell == "E" then
        local base = g_local:get_spell_book():get_spell_slot(e_spell_slot.e).level * 10 + 50
        local ADMod =  0.2
        totalDamage = base + (g_local:get_attack_damage()*ADMod)
    end
    if spell == "AA" then
        local base = 57
        local mod = g_local.level *3
        totalDamage = base + mod + g_local:get_attack_damage()
    end

    local damageMultiplier = 100 / (100 + targetArmor) --*2  if crit
    return damageMultiplier * totalDamage
end

function KillSteal()
    Prints("check ks")
    for _,unit in pairs(features.entity_list:get_enemies()) do
        if unit ~= nil and not unit:is_invisible() and unit:dist_to_local() <= 1000 and unit:is_alive() then
            Prints("check ks " .. unit:get_object_name())
			local QDmg = GetDmg("Q", Target)
			local EDmg = GetDmg("E", Target)
            Prints("got dmg calcs")
			-- local AAdmg = GetDmg("AA", Target)
            -- local Kraken = features.buff_cache:get_buff(g_local.index, "6672buff")
			-- if Kraken then
			-- 	AAdmg = AAdmg + 60 + (0.45*g_local:get_bonus_attack_damage())
			-- end
			
			-- eq ks check
            if Target ~= nil or Target:is_invisible() or Target:is_dead() then
                print("wild.")
                return false
            end
            Prints("eq ka check")
            if Target ~= nil and Target.health < QDmg+EDmg +100 then
                Prints("maybe we ks the " .. Target:get_object_name())
                if ks_q_box:get_value() and ks_e_box:get_value() and Ready(e_spell_slot.q) and Ready(e_spell_slot.e) then
                    if g_local:dist_to_local(Target.position) <= 600 then
                        Prints("ks with EQ?")
                        if QDmg+EDmg > Target.health then
                            Prints("ks with EQ.")
                            --if g_input:cast_spell(e_spell_slot.e, Target) then
                                --CastQ(Target)
                                --return true
                            --end
                        end
                    end
                end

                Prints("got dmg calcs")   
                if Ready(e_spell_slot.q) and ks_q_box:get_value() and not Is_channel() then	 
                    Prints("ks with Q?")	
                    if g_local:dist_to_local(Target.position) <= 950 and QDmg > Target.health then
                        Prints("ks with Q")
                        CastQ(Target)	
                        return true
                    end	
                end
                
                if Ready(e_spell_slot.e) and ks_e_box:get_value() then
                    Prints("ks with E?")
                    if g_local:dist_to_local(Target.position) <= 600 and EDmg > Target.health then
                        Prints("ks with E!")
                        g_input:cast_spell(e_spell_slot.e, Target)
                        return true
                    end
                end
                Prints("Ksing wouldve been mean anyway")
                return false
            end
		end
	end	
end	

function GetMinionCount(range)
    Prints("getting num mins within " .. range)
    local numAround = 0
    for _,unit in pairs(features.entity_list:get_enemy_minions()) do
        Prints("is nil check")
        if unit == nil then 
            Prints("skipping a nil minion")
        elseif unit ~= nil and not unit:is_invisible() and unit:is_alive() and g_local.position:dist_to(unit.position) <= range  then
            numAround = numAround + 1
        end
        Prints("Not in range or nil")
    end
    
    return numAround
end


cheat.register_module({
    champion_name = "Samira",
    spell_q = function ()
        Prints("q in")
        if os.clock()*1000 < LastTick  then
            Prints("q to soon")
            return false
        end
        local q_cost = 30
        if q_cost > g_local.mana then
            Prints("no q mana ret")
            return false
        end
        Prints("q target select")
        Target = features.target_selector:get_default_target()
        Q_range,Q_speed,Q_width,Q_windup = 950,2600,120/2,0.25 --slot pred uses width/2
        if Target ~= nil and features.orbwalker:is_attackable(Target.index, Q_range, true) then
            if not Is_channel() then 
                Prints("check combo Q? " .. tostring(features.orbwalker:get_mode() == Combo_key))
                if features.orbwalker:get_mode() == Combo_key and combo_q_box:get_value() then
                    Prints("cast combo q")
                    CastQ(Target)
                    return true
                end
                Prints("maybe harass?")
                if features.orbwalker:get_mode() == Harass_key and harass_q_box:get_value() then 
                    if (g_local.mana / g_local.max_mana * 100) >  hslider:get_value() then
                        Prints("cast harass q")
                        CastQ(Target)
                        return false
                    end
                    Prints("no harass q mana ret")
                    return true
                end
                Prints("no harass")
                local didKS = KillSteal()
                if didKS then Prints("q ksd") return true end
                Prints(" no ks no harass q")
            end
        end

        -- if features.orbwalker:get_mode() == Clear_key and clear_q_box:get_value() then
        --     -- Prints("lance clear?")
        --     -- if  g_local.mana/g_local.max_mana >= clear_q_mana_slider:get_value() / 100 then
        --     --     Prints("have mana for clear")
        --     --     for _,minion in pairs(features.entity_list:get_enemy_minions()) do
        --     --         Prints("check dist")
        --     --         if minion == nil then
        --     --             print("nil")
        --     --         elseif minion and minion:is_alive() and g_local.position:dist_to(minion.position) < 325 then	
        --     --             Prints("getting adgjacent minions?")			
        --     --             local count = GetMinionCount(300)
        --     --             Prints("mins at ?" .. count)
        --     --             if count >= clear_q_minion_slider:get_value() and not Is_channel() then
        --     --                 Prints("lance clear Q at " .. g_local.position:dist_to(minion.position))
        --     --                 CastQ(minion)
        --     --                 return true
        --     --             end				
        --     --         end
        --     --     end
        --     -- end	
        -- end
        Prints("out q")
        return false
    end,
    spell_w = function(data)
        Prints("w in")
        if os.clock()*1000 < LastTick then
            Prints("w to soon")
            return false
        end
        local w_cost = 60
        if w_cost > g_local.mana then
            Prints("no w mana ret")
            return false
        end
        Prints("w target select")

        Target = features.target_selector:get_default_target()
        if Target == nil or not features.orbwalker:is_attackable(Target.index, W_range, true) then
            Prints("no w target")
            return false
        end
        -- combo
        if not Is_channel() then 
            if (features.orbwalker:get_mode() == Combo_key and combo_w_box:get_value()) then
                g_input:cast_spell(e_spell_slot.w, nil)
                return true
            end
        end
        KillSteal()
        Prints("no w ret")
        return false
    end,
    spell_e = function(data)
        Prints("e in")
        if os.clock()*1000 < LastTick then
            Prints("e to soon")
            return false
        end
        local e_cost = 60
        if e_cost > g_local.mana  then
            Prints("no e mana ret")
            return false
        end
        Prints("e target select")
        E_range,E_speed,E_width,E_windup = 600,1600,300/2,0 --slot pred uses width/2
        Target = features.target_selector:get_default_target()
        if Target == nil or not features.orbwalker:is_attackable(Target.index, E_range, true) then
            Prints("no E target")
            return false
        end
        -- combo
        if (features.orbwalker:get_mode() == Combo_key and combo_e_box:get_value() and features.orbwalker:should_reset_aa()) then
            -- check for turret dash
            local no_dash = IsDashPosTurret(Target)
            if(not no_dash) then 
                if g_local:dist_to_local(Target.position) <= E_range and no_dash == false then			
                    -- E Q or just E?		
                    Prints("check eq: " .. tostring(Ready(e_spell_slot.q)))
                    if combo_q_box:get_value() and Ready(e_spell_slot.q) then
                        if not Is_channel() then
                            g_input:cast_spell(e_spell_slot.e, Target)
                            features.orbwalker:set_cast_time(features.orbwalker:get_attack_cast_delay())
                            Prints("eq try q")
                            CastQ(Target)
                            return true
                        end
                    else
                        Prints("just e")

                        g_input:cast_spell(e_spell_slot.e, Target)
                        features.orbwalker:set_cast_time(features.orbwalker:get_attack_cast_delay())
                        return true
                    end
                end
            end
            print("no dash")
        end

        KillSteal()
        Prints("no e ret")
        return false
    end,
    spell_r = function(data)
        Prints("r in")
        if os.clock()*1000 < LastTick then
            Prints("r to soon")
            return false
        end
        local r_cost = 60
        if r_cost > g_local.mana  then
            Prints("no r mana ret")
            return false
        end
        Prints("r target select")
        R_range,R_speed,R_width,R_windup = 600,1600,600/2,0 --slot pred uses width/2
        Target = features.target_selector:get_default_target()
        if Target == nil then
            Prints("no R target in ... r")
            return false
        end
        if  not features.orbwalker:is_attackable(Target.index, E_range+100, true) then
            Prints("R no atkble")
            return false
        end
        -- combo
        if (features.orbwalker:get_mode() == Combo_key and combo_r_box:get_value()) then		 
            if GetEnemyCount(1500) == 1 then
                if g_local:dist_to_local(Target.position) <= 500 and features.buff_cache:get_buff(g_local.index, "samirarreadybuff") then
                    CastedR = true
                    g_input:cast_spell(e_spell_slot.r, nil)
                else 
                    if combo_e_box:get_value() and Ready(e_spell_slot.e) then
                        if g_local:dist_to_local(Target.position) <= 600 and not IsDashPosTurret(Target) then
                            if g_input:cast_spell(e_spell_slot.e, Target) and features.buff_cache:get_buff(g_local.index, "samirarreadybuff") then
                                CastedR = true
                                g_input:cast_spell(e_spell_slot.r, nil)
                            end									
                        end
                    end	
                end
            else
                if GetEnemyCount(1500) > 1 then
                    if combo_e_box:get_value() and Ready(e_spell_slot.e) then
                        if g_local:dist_to_local(Target.position) <= E_range and GetEnemyCount(E_range) >= 1 and not IsDashPosTurret(Target) then
                            if g_input:cast_spell(e_spell_slot.e, Target) then
                                CastedR = true
                                g_input:cast_spell(e_spell_slot.r, nil)
                            end	
                        end
                    else
                        if g_local:dist_to_local(Target.position) <= 500 and GetEnemyCount(600) >= 2 then
                            CastedR = true
                            g_input:cast_spell(e_spell_slot.r, nil)	
                        end	
                    end
                end	
            end      
        end

        KillSteal()
        Prints("no r ret")
        return false
    end,
    initialize = function()
        print(os.date('%H:%M:%S') .. " initializing sami 1.0?")
        LastTick = os.clock()*1000 + 2
        return true
    end,
    get_priorities = function() return {"spell_q","spell_w","spell_e","spell_r"} end
})
