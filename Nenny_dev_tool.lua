
-- Made by nenny
--create menu
local Script_name = string.lower("Nenny Dev Assistant")
menu.get_main_window():push_navigation(Script_name, 10000)
local Test_nav = menu.get_main_window():find_navigation(Script_name)
--create section
local Info_nav = Test_nav:add_section("Nenny Dev Tools ")
--create configs
 local key_config= g_config:add_int(76, "e_key")
 local togle_example_config = g_config:add_bool(true, "example")


--create menu items 
local toggle_checkbox = Info_nav:checkbox("Press L to togle", togle_example_config)
local input_key = Info_nav:select("Custom Key", key_config , {"none", "lbutton","rbutton","cancel","mbutton","xbutton1","xbutton2","back","tab","clear","return_key","shift","control","menu","pause","capital","kana","hanguel","hangul","escape","convert","nonconvert","accept","modechange","space","prior","next","end_key","home","left","up","right","down","select","print","execute","snapshot","insert","delete_key","help","_0","_1","_2","_3","_4","_5","_6","_7","_8","_9","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","n0","n1","n2","n3","n4","n5","n6","n7","n8","n9","f1"})
--^^^^ TESTING CUSTOM  KEY INPUT ^^^--- currently broken cause i cba to add a bunch of nones where @tore skipped numbers will do in future
--Declare global vars
local toggle_limiter = 0


--Various functions
local function all_obj_name() --prints all object names filtering a few nil names
    for i, obj in pairs(features.entity_list:get_all()) do
        if obj:get_object_name() ~= nil then
            print("Object name: "..obj:get_object_name())
        end   
    end
end

local function local_buff_name() --prints all local buffs name
    for i, buff in pairs(features.buff_cache:get_all_buffs(g_local.index)) do
        print("local buff: "..buff.name)
    end
end

local function enemy_buff_name() ---prints all enemy buff names
    for i, enemy in pairs(features.entity_list:get_enemies()) do
        for j, buff in pairs(features.buff_cache:get_all_buffs(enemy.index)) do
            print(enemy.champion_name.text.." buff: "..buff.name)
        end
    end
end

local function ally_buff_name() --- prints all ally buffs names
    for i, ally in pairs(features.entity_list:get_allies()) do
        for j, buff in pairs(features.buff_cache:get_all_buffs(ally.index)) do
            print(ally.champion_name.text.." buff: "..buff.name)
        end
    end
end

local function Ori_ball_tracking() --- Example of OriannaBall tracking
    features.entity_list:force_update()
    for i, obj in pairs(features.entity_list:get_all()) do
        if obj:get_object_name() == "OriannaBall" then
            print("Object name: "..obj:get_object_name())
            print("Ball index: "..obj.index)
            print("Ball Position: X: "..obj.position.x.."Y: "..obj.position.y.."Z: "..obj.position.z)
        end   
    end
end

local function toggle()
   local key = input_key:get_value()
    if g_input:is_key_pressed(key) and toggle_limiter < g_time then  --  default key is L 
        if  toggle_checkbox:get_value()  then  
        toggle_checkbox:set_value(false)
        else
            toggle_checkbox:set_value(true)
        end
        toggle_limiter = g_time + 0.25
    end 
end

local function button_togle()
    --print(g_input:get_cursor_position().x)
   -- print("X: "..tostring(g_input:get_cursor_position().x > 60 and  g_input:get_cursor_position().x < 100) )
    --print("y: "..tostring(g_input:get_cursor_position().y > 60 and  g_input:get_cursor_position().y < 140))
   --print( tostring(g_input:get_cursor_position().y > 60 and  g_input:get_cursor_position().y < 140 ))
    if g_input:is_key_pressed(1)  and  g_input:get_cursor_position().x > 100 and  g_input:get_cursor_position().x < 180 and g_input:get_cursor_position().y > 60 and  g_input:get_cursor_position().y < 140  and toggle_limiter < g_time then 
        print("ok")
        if  toggle_checkbox:get_value()  then  
            toggle_checkbox:set_value(false)
        else
            toggle_checkbox:set_value(true)
        end
            toggle_limiter = g_time + 0.25
    end
    
end


local function test()
    toggle()
    button_togle()
    if g_input:is_key_pressed(74) then  -- press J to print
      ally_buff_name() --- Input function you want to print here
    end
end

-- ball name OriannaBall
--Local Buff name  orianaghostself
local function button()  

            local Square_color = color:new( 0,255,0)
            if toggle_checkbox:get_value() then
                Square_color = color:new( 0,255,0  )
            else
                Square_color = color:new( 255,0,0)
            end
            
            g_render:filled_box(vec2:new(100,150), vec2:new(80,40), Square_color, 3)

end
cheat.register_callback("render",button)
cheat.register_callback("feature",test)


