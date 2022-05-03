-- Made by nenny

local Script_name = string.lower(g_local.champion_name.text)

 local min_time_config = g_config:add_float(1.5, "Wait untill missing x")
 local ult_nav = menu.get_main_window():find_navigation(Script_name)
 local Info = ult_nav:add_section("DEACTIVATE R KS WITH NENNY ULT ")
 local ult_sect = ult_nav:add_section("Nenny's Ult ")
 local ult_timing = ult_sect:slider_float("missing seconds before recall end", min_time_config, 0.5, 6, 0.5)

function CalcDamage(target, rawDamage)
    print(rawDamage)
    local armor = target.total_armor
    return (rawDamage * ( 100 / ( 100 + armor )))
end

function CalcDamageAP(target, rawDamage)
    local mr = target.total_mr
    return (rawDamage * ( 100 / ( 100 + mr )))
end

function getRLevel()
    return g_local:get_spell_book():get_spell_slot(e_spell_slot.r).level
end

function BonusAD()
    Hero = g_local
    return Hero.bonus_attack
end

function getAP()
    return g_local:get_ability_power()
end

function ProjectVectorOnSegment(v1, v2, v)
    local cx, cy, ax, ay, bx, by = v.x, v.z, v1.x, v1.z, v2.x, v2.z
    local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
    local pointLine = vec3:new(ax + rL * (bx - ax), 0, ay + rL * (by - ay))
    local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
    local isOnSegment = rS == rL
    local pointSegment = isOnSegment and pointLine or vec3:new(ax + rS * (bx - ax), 0, ay + rS * (by - ay))
    
    return {PointSegment = pointSegment, PointLine = pointLine, IsOnSegment = isOnSegment}
end

function IsColliding(from, unit, width)

    for i, enemy in pairs(features.entity_list:get_enemies()) do
        if  enemy:is_alive( ) and unit.champion_name.text ~= enemy.champion_name.text then       
            local ProjectionInfo = ProjectVectorOnSegment(from, unit.position, enemy.position)
            local DistSegToEnemy = ProjectionInfo.PointSegment:dist_to(enemy.position)
            local DistToBase = from:dist_to(unit.position)
            local EnemyDistToBase = from:dist_to(from, enemy.position)
            if ProjectionInfo.IsOnSegment and DistSegToEnemy < width + 65 and DistToBase > EnemyDistToBase then             
                return true
            end
        end
    end
    return false
end

function get_jinx_multiplier(target)
    if g_local.position:dist_to(target.position) >= 1500 then
        return 1
    elseif g_local.position:dist_to(target.position) <= 100 then
        return 0.1
    else
        return 0.10 + (0.06*((g_local.position:dist_to(target.position))/100))
    end

end



function BaseUlt_Init()
    Recalling = {}
    
    Spell_Limiter = 1
    Casted = false

    Hero = g_local
    Hero_Champ = Hero.champion_name.text
    Spell_R_Level = g_local:get_spell_book():get_spell_slot(e_spell_slot.r).level

    SpellData = {
         ["Ezreal"] = {
        BaseAd = Hero.base_attack,
        Delay = 1,
        Width = 0,
        MissileSpeed = 2000,
        Collision = false,
        bonusad = BonusAD(),
        rlevel =200 +  (150*getRLevel()) + 13,
        Cost = 100,
        basedamage = ((200 + (150*getRLevel())) + BonusAD()),
        Damage = function(target) return CalcDamageAP (target , 200 +  (150*getRLevel()) + BonusAD() +(0.9*getAP())  ) end
        
      },

      ["Senna"] = {
        BaseAd = Hero.base_attack,
        Delay = 1,
        Width = 140,
        MissileSpeed = 20000,
        Collision = false,
        Cost = 100,
        Damage = function(target) return CalcDamage(target , (125 + (125*getRLevel())) +  BonusAD() + (0.7*getAP())) end
      },


      ["Jinx"] = {
        BaseAd = Hero.base_attack,
        Delay = 0.6,
        Width = 140,
        MissileSpeed = 2200,
        Collision = true,
        Cost = 100,
        Damage = function(target) return CalcDamage(target ,((100 + (150*getRLevel() + (BonusAD() *1.5)))*get_jinx_multiplier(target)) + (0.2 + (0.05*getRLevel()))*(target.max_health - target.health)) end
      }
    }
    
    
    Spell_Width = SpellData[Hero_Champ].Width
    Spell_Delay = SpellData[Hero_Champ].Delay
    Spell_MissileSpeed = SpellData[Hero_Champ].MissileSpeed
    Spell_Collision = SpellData[Hero_Champ].Collision
    Spell_Cost = SpellData[Hero_Champ].Cost
    


end





local function Can_R()

    if  g_local:get_spell_book():get_spell_slot(e_spell_slot.r):is_ready() and g_local.mana  > Spell_Cost then 
    
        return true
    end
   
    return false
end

local function ProcessRecall()
    
    local hero_Table = features.entity_list:get_enemies()
    for i, obj_hero in ipairs(hero_Table) do
        local exists = 0
            if obj_hero:is_recalling() then
                for ii, recall in pairs(Recalling) do
                    if recall.champ == obj_hero.index then
                        exists = 1
                    end
                end
                if exists == 0 then
                    table.insert(Recalling, {champ = obj_hero.index ,start = g_time, duration = 8})
                end
                
            else            
                for iii, recall in pairs(Recalling) do
                    local obj = features.entity_list:get_by_index( recall.champ )
                    
                    if not obj:is_recalling() or not obj:is_alive( )  then
                        
                        table.remove(Recalling, i)
                    end
                end
            end   
        
    end
end

BaseUlt_Init()

local function baseult()
    ProcessRecall()
    local Delay = 0.015
    Hero = g_local
   
        
    for i, recall in pairs(Recalling) do
        local enemy = features.entity_list:get_by_index( recall.champ )
        local Time_Till_Finished = recall.duration - (g_time - recall.start)
        local BaseDist = g_local.position:dist_to(enemy.position)
        local Time_To_Hit = Spell_Delay + BaseDist / Spell_MissileSpeed + Delay
        if Hero_Champ == "Jinx" then
                Time_To_Hit = 0.692 + Spell_Delay + (BaseDist-1350) / Spell_MissileSpeed + Delay
        end
        local dmg = SpellData[Hero_Champ].Damage(enemy)

        Killable = false
        if dmg >= (enemy.health + 30) then
            Killable = true
            
        end

        if Killable and Can_R() and Time_Till_Finished >=  Time_To_Hit and Time_To_Hit <= 7.8 and Time_Till_Finished - Time_To_Hit  <= ult_timing:get_value() and g_time > Spell_Limiter then --change ult settings ime_To_Hit <= 7.8 --- 
            
            if Spell_Collision then
                if not IsColliding(Hero.position, enemy, Spell_Width) then                                                                    
                   g_input:cast_spell(e_spell_slot.r, enemy.position)
                    Time_When_Hit = g_time + Time_To_Hit 
                    Spell_Limiter = g_time + 10                                                                                          
                end
            else                                                                              
                g_input:cast_spell(e_spell_slot.r, enemy.position) 
                Time_When_Hit = g_time + Time_To_Hit  
                Spell_Limiter = g_time + 10                                                                                          
            end                                                                                                                            
        end
    end
end

local function Recall_BarPos(Time_To_Hit, yoffset)
    local Res = g_render:get_screensize()
    local CastPos = Time_To_Hit / 8
    local Barpos_x = (Res.x/2) - 125
    local Barpos_y = Res.y - 200 - yoffset - 5
     g_render:line(vec2:new(Barpos_x + 250 - ( (250*CastPos) + 40), Barpos_y  ), vec2:new(Barpos_x + 250 - ( (250*CastPos) + 40),Barpos_y  +20  + 5), color:new( 255,0, 0 ), 3) -- jinx offset (250*CastPos) + 40)
end

local function draw()
    for i, recall in pairs(Recalling) do
        local enemy = features.entity_list:get_by_index( recall.champ )
        local BaseDist = g_local.position:dist_to(enemy.position)
        local Time_To_Hit = Spell_Delay + BaseDist / Spell_MissileSpeed + 0.015
            if Hero_Champ == "Jinx" then
                Time_To_Hit = 0.692 + Spell_Delay + (BaseDist-1350) / Spell_MissileSpeed + 0.015
            end
        if SpellData[Hero_Champ].Damage(enemy) >= (enemy.health + 30) then
            Recall_BarPos(Time_To_Hit, (i-1)*24)
        end
    end 
end

cheat.register_callback("feature",baseult)
cheat.register_callback("render",draw)

