Combo_key = 1
Harass_key = 4
Q_range,Q_speed,Q_width,Q_windup = 850,0,200/2,0.25 --slot pred uses width/2
R_range,R_speed,R_width,R_windup = 1800,850,450/2,0.5 --slot pred uses width/2
E_range = 850
LastTick = 0
Script_name = "Poggers nami"

-- Add new navigation item
local test_navigation = menu.get_main_window():push_navigation(Script_name, 10000)
-- Create new config var
local q_config = g_config:add_bool(true, "Use_Q")
local w_config = g_config:add_bool(true, "Use_W")
local e_config = g_config:add_bool(true, "Use_E")
local r_config = g_config:add_bool(true, "Use_R")
local num_nmeR = g_config:add_int(2, "R if en")
local nami_nav = menu.get_main_window():find_navigation(Script_name)
local spell_sect = nami_nav:add_section("Use spells")
local r_sect = nami_nav:add_section("Auto R Config")

local checkboxq = spell_sect:checkbox("Use Q", q_config)
local checkboxw = spell_sect:checkbox("Use W", w_config)
local checkboxe = spell_sect:checkbox("Use E", e_config)
local checkboxr = spell_sect:checkbox("Use R", r_config)
checkboxq:set_value(true)
checkboxw:set_value(true)
checkboxe:set_value(true)
checkboxr:set_value(true)

local rslider = r_sect:slider_int("R if it will hit X enemies", num_nmeR, 1, 5, 1)

function Vec3_Rotate(c , p, angle) -- Center, Point, Angle
    angle = angle * (math.pi/180)
    local rotatedX = math.cos(angle) * (p.x - c.x) - math.sin(angle) * (p.z - c.z) + c.x
    local rotatedZ = math.sin(angle) * (p.x - c.x) + math.cos(angle) * (p.z - c.z) + c.z
    return vec3:new(rotatedX, p.y ,rotatedZ)
end

function Rectangle_Polygon(start_pos, target_pos, width, range)
    local pol = {}  
    local temp = Vec3_Extend(start_pos,target_pos, width/2)
    pol[1] = Vec3_Rotate(start_pos,temp,90)
    pol[2] = Vec3_Rotate(start_pos,temp,-90)
    temp = Vec3_Extend(target_pos,start_pos, range)
    local temp2 = Vec3_Extend(temp,target_pos, width/2)
    pol[3] = Vec3_Rotate(temp,temp2,90)
    pol[4] = Vec3_Rotate(temp,temp2,-90)
    return pol
end

function Vec3_Extend(a,b, dist) 
    local distance = a:dist_to(b) 
    local offset = dist / distance 
    local dir = vec3:new((a.x - b.x), b.y, (a.z - b.z)) 
    local newPos = vec3:new((a.x + dir.x*offset), b.y, (a.z + dir.z*offset)) 
    return newPos end

function isInsidePolygon(point, polygon)
    local oddNodes = false
    local j = #polygon
    for i = 1, j do
        if (polygon[i].z < point.z and polygon[j].z >= point.z or polygon[j].z < point.z and polygon[i].z >= point.z) then
            if (polygon[i].x + ( point.z - polygon[i].z ) / (polygon[j].z - polygon[i].z) * (polygon[j].x - polygon[i].x) < point.x) then
                oddNodes = not oddNodes;
            end
        end
        j = i;
    end
    return oddNodes
end

function getEnimiesHitBy(poly)
    local n = 0
    for _,entity in pairs(features.entity_list:get_enemies()) do
        if  entity ~= nil and not entity:is_invisible() and entity:is_alive() then
            local inside = isInsidePolygon(entity.position, poly)
            if inside then
                Prints("ult the ".. entity:get_object_name())
                n = n + 1
            end
        end
    end
    return n
end

function NumAlliesAroundMe()
    local numAround = 0
    for _,ally in pairs(features.entity_list:get_allies()) do
        if ally ~= nil and ally:is_alive() and ally.position:dist_to(g_local.position) <= E_range then
            numAround = numAround + 1
        end
    end
    return numAround
end

function NumEnemiesInRange(range)
    Prints("num around r")
    local numAround = 0
    for _,entity in pairs(features.entity_list:get_enemies()) do
        if  entity ~= nil and not entity:is_invisible() and entity:is_alive() and entity.position:dist_to(g_local.position) <= range  then
            numAround = numAround + 1
        end
    end
    Prints("num around r - end")
    return numAround
end

function Prints(str)
    local dbg = 1
    if dbg == 1 then print(str) end
end
cheat.register_module({
    champion_name = "Nami",
    spell_q = function ()
        Prints("q in")
        local ret = true
        if os.clock()*1000 < LastTick  or checkboxq:get_value() == false then
            Prints("q to soon")
            ret = false
        end
        q_cost = 60
        if q_cost > g_local.mana  and ret then
            Prints("no q mana ret")
            return false
        end
        Prints("q target select")
        Target = features.target_selector:get_default_target()
        if Target == nil or not features.orbwalker:is_attackable(Target.index, Q_range, true) then
            Prints("no q target")
            return false
        end

        Prints("checking for q auto cc")
        -- AUTOCC CHAIN CHECK
        for _,enemy in pairs(features.entity_list:get_enemies()) do
            -- todo: and will remain immobile
            -- if they aint going anywhere
            Prints("checking hard cc ")
            if enemy ~= nil and not enemy:is_invisible() and features.buff_cache:is_immobile(enemy.index) or  features.buff_cache:has_hard_cc(enemy.index) then
                local qHit = features.prediction:predict(Target.index, Q_range, Q_speed, Q_width, Q_windup+0.726, g_local.position) 
                if (qHit.valid and qHit.hitchance > 1.0) then
                    g_input:cast_spell(e_spell_slot.q, qHit.position)
                    features.orbwalker:set_cast_time(features.orbwalker:get_attack_cast_delay())
                    Prints("auto cc q cast")
                    return false
                end
            end
        end

        if features.orbwalker:get_mode() == Combo_key or features.orbwalker:get_mode() == Harass_key then
            Q_range,Q_speed,Q_width,Q_windup = 850,0,200/2,0.25 --slot pred uses width/2
            local qHit = features.prediction:predict(Target.index, Q_range, Q_speed, Q_width, Q_windup+0.726, g_local.position) 
            
            if (qHit.valid and qHit.hitchance > 1.0) then
                g_input:cast_spell(e_spell_slot.q, qHit.position)
                features.orbwalker:set_cast_time(features.orbwalker:get_attack_cast_delay())
                Prints("combo q cast")
                return true
            end
        end
        Prints("out q")
        return false
    end,
    spell_w = function(data)
        Prints("w in")
        if os.clock()*1000 < LastTick or checkboxw:get_value() == false then
            Prints("too soon w")
            return false
        end
        LastTick = os.clock()*1000 + 2
        local w_cost = (g_local:get_spell_book():get_spell_slot(e_spell_slot.w).level) * 10 + 60
        if w_cost > g_local.mana then
            Prints("no mana w")
            return false
        end
        Prints("w get target")
        Target = features.target_selector:get_default_target()
        if Target == nil or not features.orbwalker:is_attackable(Target.index, R_range, true) then
            Prints("no w target")
            return false
        end
        if features.orbwalker:get_mode() == Combo_key or features.orbwalker:get_mode() == Harass_key then
            Prints("w start combo")
            --in range of us hit them
            local w_range = 725
            if features.orbwalker:is_attackable(Target.index, w_range, true) then
                g_input:cast_spell(e_spell_slot.w, Target)
                Prints("cast w enemy")
                return true
            end
            Prints("w get allies?")
            -- not in my range? try for a bounce man
            local num = NumAlliesAroundMe()-1
            Prints("w got allies? " .. num)
            if num > 0 then
                for _,ally in pairs(features.entity_list:get_allies()) do
                    if ally ~=  nil and ally ~= g_local and ally:is_alive() then
                        if features.orbwalker:get_mode() == Combo_key or features.orbwalker:get_mode() == Harass_key then
                            Prints("w valid aly")
                            if ally.position:dist_to(g_local.position) <= w_range then 
                                Prints("w get allies?")
                                if ally.position:dist_to(Target.position) <= w_range then
                                    Prints("w cast")
                                    g_input:cast_spell(e_spell_slot.w, ally)
                                    Prints("no w mana ally")
                                    return true
                                end
                            end
                        end
                    end
                end
            end  
        end
        Prints("no w ret")
        return false
    end,
    spell_e = function(data)
        Prints("e in")
        if os.clock()*1000 < LastTick or checkboxe:get_value() == false then
            Prints("e too soon")
            return false
        end
        local e_cost = (g_local:get_spell_book():get_spell_slot(e_spell_slot.e).level) * 5 + 55
        if e_cost > g_local.mana then
            Prints("no w mana ret")
            return false
        end
        LastTick = os.clock()*1000 + 2
        Target = features.target_selector:get_default_target()
        if Target == nil or not features.orbwalker:is_attackable(Target.index, R_range, true) then
            Prints("no w tgt")
            return false
        end
        -- ima just e the person with the highest dps
        if features.orbwalker:get_mode() == Combo_key then
            -- print("combo e")
            local topDps = g_local
            for _,ally in pairs(features.entity_list:get_allies()) do
                if ally ~= nil and ally:is_alive() and ally.position:dist_to(Target.position) <= E_range   then
                    if ally.attack_speed > topDps.attack_speed then
                        topDps=ally
                    end
                end
            end
            -- print("e target " .. topDps:get_object_name())
            Prints("no w cast dps")
            g_input:cast_spell(e_spell_slot.e, topDps)
            return true
        end
        Prints("no w cast")
        return false
    end,
    spell_r = function(data)
        Prints("r in")
        if os.clock()*1000 < LastTick or checkboxr:get_value() == false then
            Prints("r too soon")
            return false
        end
        local r_cost = 100
        if r_cost > g_local.mana then
            Prints("no r mana")
            return false
        end
        Target = features.target_selector:get_default_target()
        if Target == nil or not features.orbwalker:is_attackable(Target.index, R_range, true) then
            Prints("no r mana")
            return false
        end
        -- auto R if hits X menu slider enemies
        if features.orbwalker:get_mode() == Combo_key then
            Prints("r do combo")
            local num = NumEnemiesInRange(R_range)
            Prints("num in range was" .. num)
            if num > 0 then
                local rHit = features.prediction:predict(Target.index, R_range, R_speed, R_width, R_windup, g_local.position) 
                if (rHit.valid and rHit.hitchance > 1.0) then
                    Prints("r pred doing rect")
                    local poly = Rectangle_Polygon(g_local.position,Target.position,R_width,R_range)
                    Prints("r get x hit by rect ")
                    local num = getEnimiesHitBy(poly)
                    if num >= rslider:get_value() then
                        g_input:cast_spell(e_spell_slot.r, rHit.position)
                        Prints("r cast")
                        return true
                    end
                end
            end
        end
        -- anti gap close auto r pog tm
        Prints("no r ret")
        return false
    end,
    initialize = function()
        print(os.date('%H:%M:%S') .. " initializing nami 1.0?")
        LastTick = os.clock()*1000 + 2
        return true
    end,
    get_priorities = function() return {"spell_e","spell_w","spell_q","spell_r"} end
})
