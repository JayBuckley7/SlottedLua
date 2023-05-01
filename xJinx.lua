-- xJinx by Jay and a bit of ampx.

Jinx_VERSION = "1.0.1"
Jinx_LUA_NAME = "xJinx.lua"
Jinx_REPO_BASE_URL = "https://raw.githubusercontent.com/JayBuckley7/SlottedLua/main/"
Jinx_REPO_SCRIPT_PATH = Jinx_REPO_BASE_URL .. Jinx_LUA_NAME

local core = require("xCore")
core:init()

local function fetch_remote_version_number()
    local command = "curl -s -H 'Cache-Control: no-cache, no-store, must-revalidate' " .. Jinx_REPO_SCRIPT_PATH
    local handle = io.popen(command)
    local content = handle:read("*a")
    handle:close()

    if content == "" then
        print("Failed to fetch the remote version number.")
        return nil
    end

    local remote_version = content:match("VERSION%s*=%s*\"(%d+%.%d+%.%d+)\"")

    return remote_version
end

local function replace_current_file_with_latest_version(latest_version_script)
    local resources_path = cheat:get_resource_path()
    local current_file_path = resources_path:gsub("resources$", "lua/" .. Jinx_LUA_NAME)

    local file, errorMessage = io.open(current_file_path, "w")

    if not file then
        print("Failed to open the current file for writing. Error: ", errorMessage)
        return false
    end

    file:write(latest_version_script)
    file:close()

    return true
end

local function check_for_update()
  local remote_version = fetch_remote_version_number()
  Prints("local version: " .. Jinx_VERSION .. " remote version: " .. remote_version, 0)
  if remote_version and remote_version > Jinx_VERSION then
      local command = "curl -s " .. Jinx_REPO_SCRIPT_PATH
      local handle = io.popen(command)
      local latest_version_script = handle:read("*a")
      handle:close()
  
      if latest_version_script then
          if replace_current_file_with_latest_version(latest_version_script) then
            Prints("Please click reload lua ", 0)
              Prints("Successfully updated " .. Jinx_LUA_NAME .. " to version " .. remote_version .. ".", 0)
              Prints("Please click reload lua  ", 0)
              -- You may need to restart the program to use the updated script
          else
              Prints("Failed to update " .. Jinx_LUA_NAME .. ".", 0)
          end
      end
  else
      Prints("You are running the latest version of " .. Jinx_LUA_NAME .. ".", 0)
  end
end


local std_math = math
local Idle_key = 0
local Combo_key = 1
local Clear_key = 3
local Harass_key = 4
local Flee_key = 5


-- Should be way better than current Jinx. Any more suggestions? DM me on Discord: dizzy#6092 :).
local name = "xAIO - Jinx"

local add_nav = menu.get_main_window():push_navigation(name, 10000)
local navigation = menu.get_main_window():find_navigation(name)

-- Sections
local combo_sect = navigation:add_section("combo")
local harass_sect = navigation:add_section("harass")
local clear_sect = navigation:add_section("clear")
local agc_sect = navigation:add_section("gap close")
local auto_sect = navigation:add_section("auto")
local msc_sect = navigation:add_section("misc")
local draw_sect = navigation:add_section("drawings")

-- Config
local q_combo_aoe_count_cfg = g_config:add_int(3, "q_aoe_count")
local q_clear_aoe_count_cfg = g_config:add_int(3, "q_aoe_count")

-- Combo
local q_combo = combo_sect:checkbox("use Q", g_config:add_bool(true, "q_combo"))
local q_combo_aoe = combo_sect:checkbox("^ try AOE", g_config:add_bool(true, "q_combo_aoe"))
local q_combo_aoe_count = combo_sect:slider_int("^ if x enemies", q_combo_aoe_count_cfg, 0, 5, 1)

local w_combo = combo_sect:checkbox("use W", g_config:add_bool(true, "w_combo"))
local w_combo_not_in_range = combo_sect:checkbox("^ if outside of aa range", g_config:add_bool(true, "w_combo_in_range"))
local w_combo_hitchance = combo_sect:select("W hitchance", g_config:add_int(3, "w_combo_hitchance"),
  { "low", "medium", "high", "very_high", "immobile" })


local e_combo = combo_sect:checkbox("use E", g_config:add_bool(true, "e_combo"))
local e_combo_mode = combo_sect:select("E Logic:", g_config:add_int(1, "e_combo_mode"),
  { "always", "advanced", "undodgable" })

local r_combo = combo_sect:checkbox("use R", g_config:add_bool(true, "r_combo"))
local r_combo_hitchance = combo_sect:select("R hitchance", g_config:add_int(3, "r_combo_hitchance"),
  { "low", "medium", "high", "very_high", "immobile" })

-- Clear
local q_clear_cfg = g_config:add_bool(true, "q_clear")
local q_clear = clear_sect:checkbox("use Q", q_clear_cfg)
local q_clear_aoe = clear_sect:checkbox("^ try AOE", g_config:add_bool(true, "q_clear_aoe"))
local q_clear_aoe_count = clear_sect:slider_int("^ if x enemies", q_clear_aoe_count_cfg, 0, 5, 1)

-- Harass
local splash_harass_cfg = g_config:add_bool(true, "splash_harass")
local checkboxJinxSplashHarass = harass_sect:checkbox("extend aa range with Q splash", splash_harass_cfg)


-- Auto
local q_auto = auto_sect:checkbox("auto Q swapping", g_config:add_bool(true, "q_auto"))
local extend_q_auto = auto_sect:checkbox("auto Q harass", g_config:add_bool(true, "auto q splash harass"))

local w_auto = auto_sect:checkbox("auto W", g_config:add_bool(true, "w_auto"))

local e_auto = auto_sect:checkbox("auto E", g_config:add_bool(true, "e_auto"))


local r_auto = auto_sect:checkbox("auto R", g_config:add_bool(true, "r_auto"))
local r_auto_dashless = auto_sect:checkbox("^ if no dash", g_config:add_bool(true, "r_auto_dashless"))

local w_agc = agc_sect:checkbox("W on dash", g_config:add_bool(true, "W on dash"))
local e_agc = agc_sect:checkbox("E on dash", g_config:add_bool(true, "E on dash"))

-- add a multi select
local Dash_list = {}
local Dash_list_cfg = {}

core.permashow:set_title(name)

-- Clear
core.permashow:register("farm", "farm", "A", true, q_clear_cfg)
core.permashow:register("Fast W", "Fast W", "control")
core.permashow:register("Semi-Auto Ult", "Semi-Auto Ult", "U")
core.permashow:register("Extend AA To Harass", "Extend AA To Harass", "I", true, splash_harass_cfg)




-- 0 = nothing
-- 1 = default
-- 2 = lots
-- 3 = trace
Debug_level = 1
Res = g_render:get_screensize()
Font = 'roboto-regular'
colors = core.debug.Colors
White = color:new(255, 255, 255)
Red = color:new(255, 0, 0)
Green = color:new(0, 255, 0)
Blue = color:new(0, 0, 200)
COLOR = White

MinionInRange = {}
MinionToHarass = {}
SplashableTargetIndex = nil
SplashableMinionIndex = nil
MinionTable = {}
Last_Q_swap_time = g_time
Last_cast_time = g_time
Last_dbg_msg_time = g_time

function Prints(str, level)
  core.debug:Print(str, level)
end

local dash_blacklist = auto_sect:multi_select("^ dash blacklist", Dash_list, Dash_list_cfg)

-- misc
local checkboxManR = msc_sect:checkbox("Manual Ult on U", g_config:add_bool(true, "Semi Auto Cast R"))


-- Lasthit

-- Mana

-- AntiGapClose

-- Flee

-- Permashow

-- Draw
-- local checkboxDBG = draw_sect:checkbox("debug messages", g_config:add_bool(true, "debug messages"))
local checkboxVisualDmg = draw_sect:checkbox("damage visual", g_config:add_bool(true, "visualize damage"))
local checkboxDrawQ = draw_sect:checkbox("Draw alternate Q range", g_config:add_bool(true, "Draw alternate Q range"))
local checkboxDrawW = draw_sect:checkbox("Draw W off cooldown", g_config:add_bool(true, "Draw W off cooldown"))



local Data = {
  Q = {
    manaCost = { 20, 20, 20, 20, 20 },
    spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.q),
    spellSlot = e_spell_slot.q,
    Range = { 80, 110, 140, 170, 200 },
    Level = 0,
  },
  W = {
    manaCost = { 40, 45, 50, 55, 60 },
    spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.w),
    spellSlot = e_spell_slot.w,
    Range = 1450,
    Width = 120 / 2,
    castTime = 0.4,
    Damage = 0,
    Speed = 3300,
    Level = 0,
  },
  E = {
    manaCost = { 90, 90, 90, 90, 90 },
    spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.e),
    spellSlot = e_spell_slot.e,
    Range = 925,
    Damage = g_local:get_attack_damage(),
    castTime = 0.9,
    Width = 100 / 2,
    Speed = 1700,
    Level = 0,
  },
  R = {
    manaCost = { 100, 100, 100, 100, 100 },
    spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.r),
    spellSlot = e_spell_slot.r,
    Range = 3000,
    Width = 280 / 2,
    castTime = 0.6,
    Damage = 0,
    Speed = 1700,
    Level = 0,
  },
  AA = {
    Damage = g_local:get_attack_damage(),
    short_range = 0,
    long_range = 0,
    rocket_launcher = false,
    enemy_close = false,
    enemy_far = false,
  },
}

function Data:refresh_data()
  Prints("refreshing", 3)
  self['AA'].Damage = g_local:get_attack_damage()
  self['AA'].rocket_launcher = self:has_rocket_launcher()
  local range = g_local.attack_range + g_local:get_bounding_radius()
  -- Prints("aa: " .. g_local.attack_range, 3)
  -- Prints("bound: " .. g_local:get_bounding_radius() + 15, 3)
  -- Prints("Q_level: " .. Data['Q'].Level,3)
  -- Prints("Long range:" .. range + (50 + (30 * Data['Q'].Level)),3)
  local long_range = range
  if Data['AA'].rocket_launcher then
    range = range - (50 + 30 * Data['Q'].Level)
  else
    long_range = range + (50 + 30 * Data['Q'].Level)
    -- 80 / 110 / 140 / 170 / 200
  end

  self['AA'].short_range = range

  self['AA'].long_range = long_range
  self['AA'].enemy_close = self:is_enemy_near(range)
  self['AA'].enemy_far = self:is_enemy_near(long_range)

  self['Q'].Level = g_local:get_spell_book():get_spell_slot(e_spell_slot.q).level
  self['Q'].spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.q)
  self['Q'].spellSlot = e_spell_slot.q

  self['W'].Level = g_local:get_spell_book():get_spell_slot(e_spell_slot.w).level
  self['W'].spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.w)
  self['W'].castTime = std_math.max(0.6 - 0.02 * std_math.floor(g_local.bonus_attack_speed / 0.25), 0.4)

  self['E'].Level = g_local:get_spell_book():get_spell_slot(e_spell_slot.e).level
  self['E'].spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.e)
  self['E'].spellSlot = e_spell_slot.e

  self['R'].Level = g_local:get_spell_book():get_spell_slot(e_spell_slot.r).level
  self['R'].spell = g_local:get_spell_book():get_spell_slot(e_spell_slot.r)
  self['R'].spellSlot = e_spell_slot.r

  Prints("refreshed", 3)
end

function Data:is_ready(spell)
  if self[spell].spell:is_ready() then
    return true
  end
  return false
end

function Data:has_enough_mana(spell)
  local costs = self[spell].manaCost
  local level = self[spell].Level
  local cost = costs[level]

  if g_local and spell and cost then
    --Prints("Cost of  " .. spell .. " at " .. level .. " level is " .. cost, 3)
    if g_local.mana >= cost then
      return true
    else
      return false
    end
  end
end

function Data:can_cast(spell)
  if self:is_ready(spell) and self:has_enough_mana(spell) then
    return true
  end
  return false
end

function Data:has_rocket_launcher()
  local buffs = features.buff_cache:get_all_buffs(g_local.index)
  for _, buff in pairs(buffs) do
    if (buff.name == "JinxQ") then
      return true
    end
  end
  return false
end

function Data:in_range(spell, target)
  if target ~= nil and target.position:dist_to(g_local.position) <= self[spell].Range then
    return true
  else
    return false
  end
end

function Data:is_enemy_near(range, override)
  for _, entity in pairs(features.entity_list:get_enemies()) do
    if entity.position:dist_to(g_local.position) <= range then
      return true
    end
  end
  return false
end

function Data:count_enemies(range, position)
  local numAround = 0
  for _, entity in pairs(features.entity_list:get_enemies()) do
    if entity ~= nil and entity.position:dist_to(position) <= range then
      numAround = numAround + 1
    end
  end
  return numAround
end


function Show_splash_harass()
  Prints("draw harass", 3)
  if SplashabletargetIndex then
    local tgt = features.entity_list:get_by_index(SplashabletargetIndex)
    if tgt then
      Get_harass_minions_near(SplashabletargetIndex, 235)
      -- circle the target
      g_render:circle_3d(tgt.position, Red, 235, 2, 90, 2)
      if MinionTable and #MinionTable > 0 then
        --Prints("splash?", 2)
        for ii, alive in ipairs(MinionTable) do
          local min = features.entity_list:get_by_index(alive.idx)
          if min then
            local hmm = min.position:extend(tgt.position, tgt.position:dist_to(min.position))
            -- print distance from tgt to min
            if tgt ~= nil and min ~= nil and tgt.position:dist_to(min.position) < 260 then g_render:line_3d(min.position, tgt.position, Red, 1) end
          end
        end
      end
    end
  end
  if SplashableMinionIndex then
    local min = features.entity_list:get_by_index(SplashableMinionIndex)
    if min then g_render:circle_3d(min.position, Green, 80, 2, 90, 2) end
  else
    Prints("no splashable minion to draw lines too ", 3)
  end
end

function IsUnderTurret(pos)
  local range = 850
  for _, unit in pairs(features.entity_list:get_enemy_turrets()) do
    if unit ~= nil and not unit:is_dead() then
      local away = unit.position:dist_to(pos)
      if away < range then return true end
    end
  end
  return false
end

function Get_target()
 -- if core.target_selector:GET_STATUS() then print("ts: true") else print("ts: false") end
  local target = core.target_selector:get_main_target()
  -- if we are on core ts return core ts else return get_default_target
  if core.target_selector:GET_STATUS() then
    target = core.target_selector:get_main_target()
  else return features.target_selector:get_default_target() end
  return target
end


function Visualize_damage()
  if g_time - Last_cast_time <= 0.15 then return end
  Prints("draw dmg in", 3)

  for i, enemy in pairs(features.entity_list:get_enemies()) do
    if core.helper:is_alive(enemy) and enemy:is_visible() and g_local.position:dist_to(enemy.position) < 3000 then
      local approx = 0
      local Killable = false

      local aadmg = core.damagelib:calc_aa_dmg(g_local, enemy)
      local AAtoKill = std_math.ceil(enemy.health / aadmg)
      local wdmg = 0
      local rdmg = 0
      local nmehp = enemy.health

      approx = 3 * aadmg
      if Data:can_cast('W') then
        wdmg = core.damagelib:calc_spell_dmg("W", g_local, enemy, 1, Data['W'].Level)
        approx = approx + wdmg
      end
      if Data:can_cast('R') then
        rdmg = core.damagelib:calc_spell_dmg("R", g_local, enemy, 1, Data['R'].Level)
        approx = approx + rdmg
      end
      if g_local.bonus_attack_speed + g_local.attack_speed > 1.5 then
        approx = approx + aadmg
      end

      local screen = g_render:get_screensize()
      local width_offset = 0.055
      local height_offset = 0.010
      local base_x_offset = 0.43
      local base_y_offset_ratio = 0.002 -- New variable for y offset ratio
      local bar_width = (screen.x * width_offset)
      local bar_height = (screen.y * height_offset)
      local base_position = enemy:get_hpbar_position()

      -- Calculate the base_y_offset based on screen height
      local base_y_offset = screen.y * base_y_offset_ratio

      base_position.x = base_position.x - bar_width * base_x_offset
      base_position.y = base_position.y - bar_height * base_y_offset

      local modifier = enemy.health / enemy.max_health
      local damage_mod = approx / enemy.max_health

      local box_start = vec2:new(base_position.x + bar_width * modifier, base_position.y)
      local box_size_x = 0
      if damage_mod * bar_width > box_start.x - base_position.x then
        box_size_x = base_position.x - box_start.x
      else
        box_size_x = (bar_width * damage_mod) * -1
      end

      local box_size = vec2:new(box_size_x, bar_height)


      g_render:filled_box(box_start, box_size, colors.transparent.purple)
      local pos = enemy.position
      if pos:to_screen() ~= nil then
        local aa_msg_pos = vec2:new(pos:to_screen().x, pos:to_screen().y - 50)
        g_render:text(aa_msg_pos, color:new(255, 255, 255), tostring(AAtoKill) .. " AA till kill", Font, 30)

        if approx >= (enemy.health + 5) then
          Killable = true
          Square_color = color:new(255, 0, 200, 100)
          g_render:circle_3d(pos, Square_color, 65, 1, 90, 2)
          g_render:text(pos:to_screen(), color:new(255,255,255), "KILLABLE", Font, 30 )
        end
      end
    end
  end
  Prints("tick exit", 3)
end

function Visualize_spell_range()
  Prints("draw ranges", 3)
  if checkboxDrawQ:get_value() then
    if Data['AA'].rocket_launcher then
      g_render:circle_3d(g_local.position, Blue, Data['AA'].short_range, 2, 50, 1)
    else
      g_render:circle_3d(g_local.position, Blue, Data['AA'].long_range, 2, 50, 1)
    end
  end
  if checkboxDrawW:get_value() and Data:can_cast('W') then
    g_render:circle_3d(g_local.position, Blue, Data['W'].Range, 2, 50, 1)
  end
end

function Draw()
  Prints("Draws", 3)
  if checkboxJinxSplashHarass:get_value() then
    Prints("draw harass", 3)
    Show_splash_harass()
  end
  if checkboxVisualDmg:get_value() then
    Visualize_damage()
  end
  if checkboxDrawQ:get_value() or checkboxDrawW:get_value() then
    Prints("draw Q", 3)
    Visualize_spell_range()
  end
end

function Get_harass_minions_near(obj_hero_idx, range)
  Prints("get harass", 3)
  local obj_hero = features.entity_list:get_by_index(obj_hero_idx)
  local minions = features.entity_list:get_enemy_minions()
  --Prints("getting harass minions in range of " .. tostring(obj_hero:get_object_name()) .. " x= " .. tostring(range) )
  --Prints("getting harass minions out of " .. tostring(#minions))
  for i, obj_minion in ipairs(minions) do
    if obj_hero and obj_minion then
      if obj_hero and obj_minion and core.helper:is_alive(obj_minion) and obj_minion:is_visible() and obj_minion:is_minion() and obj_minion:is_targetable() then
        if true then   -- (obj_minion:get_object_name() == "SRU_ChaosMinionRanged" or obj_minion:get_object_name() == "SRU_ChaosMinionMelee" or obj_minion:get_object_name() == "SRU_ChaosMinionSiege")
          local exists = 0
          --Prints(" i can see and is alive: " .. tostring(obj_minion:get_object_name()))
          if obj_hero.position:dist_to(obj_minion.position) < range then
            --Prints("i see one " .. tostring(obj_hero.position:dist_to(obj_minion.position)))
            if MinionTable and #MinionTable > 0 then
              -- Prints("checking if our list already has " .. obj_minion.index)
              for ii, alive in ipairs(MinionTable) do
                --Prints("have: " .. alive.idx .. " check: " .. obj_minion.index)
                if alive.idx == obj_minion.index then
                  --Prints("we do!", 1)
                  exists = 1
                end
              end
            end
          end
          if exists == 0 then
            table.insert(MinionTable, { idx = obj_minion.index })
          end
        end
        if MinionTable and #MinionTable > 0 then
          for ii, alive_idx in ipairs(MinionTable) do
            local remove = false
            local alive = features.entity_list:get_by_index(alive_idx.idx)
            if alive then
              if obj_hero.position:dist_to(alive.position) > range then remove = true end
              if core.helper:is_alive(alive) == false then remove = true end
              if alive:is_visible() == false then remove = true end
            else
              remove = true
            end
            if remove then
              table.remove(MinionTable, ii)
            end
          end
        end
      end
    end
  end
  -- Prints("after a full loop ive got... " .. tostring(#MinionTable))

  return true
end

function ValidateSplashMinionAndtarget()
  if SplashabletargetIndex then
    local hero_obj = features.entity_list:get_by_index(SplashabletargetIndex)
    if g_local.position:dist_to(hero_obj.position) < Data['AA'].long_range then
      SplashabletargetIndex = nil
    elseif hero_obj.position:dist_to(hero_obj.position) > Data['AA'].long_range + 260 then
      SplashabletargetIndex = nil
    elseif core.helper:is_alive(hero_obj) == false then
      SplashabletargetIndex = nil
    elseif hero_obj:is_visible() == false then
      SplashabletargetIndex = nil
    end
    -- if SplashabletargetIndex then Prints("Splashable target valid", 1) else Prints("Splashable target removed", 1) end
    if SplashableMinionIndex then
      local min_obj = features.entity_list:get_by_index(SplashableMinionIndex)
      if g_local.position:dist_to(min_obj.position) > Data['AA'].long_range then
        SplashableMinionIndex = nil
      elseif hero_obj.position:dist_to(min_obj.position) > 235 then
        SplashableMinionIndex = nil
      elseif core.helper:is_alive(min_obj) == false then
        SplashableMinionIndex = nil
      elseif min_obj:is_visible() == false then
        SplashableMinionIndex = nil
      elseif min_obj:is_minion() == false then
        SplashableMinionIndex = nil
      elseif min_obj:is_targetable() == false then
        SplashableMinionIndex = nil
      end
      -- if SplashableMinionIndex then Prints("Splashable Minion valid", 1) else Prints("Splashable Minion removed", 1) end
    end
  end
end

function FindSplashableMinion()
  local target = Get_target()
  if target == nil then return false end
  --update the global minion table nearby the target
  --Prints("finding splash minion", 1)
  Get_harass_minions_near(target.index, 250)
  --get all the minions in AA range of me out of this table.
  if MinionTable and #MinionTable > 0 then
    for i, minionIdx in ipairs(MinionTable) do
      if SplashableMinionIndex == nil then
        local minion = features.entity_list:get_by_index(minionIdx.idx)
        if target.position:dist_to(minion.position) < 236 and g_local.position:dist_to(minion.position) < Data['AA'].long_range then
          --Prints("idx is minions is at " .. g_local.position:dist_to(minion.position))
          SplashableMinionIndex = minion.index
        end
      end
    end
  end
end

function Get_minions(range)
  local minions_in_range = {}
  local all_enemy_minions = features.entity_list:get_enemy_minions()

  for _, minion in ipairs(all_enemy_minions) do
    if minion ~= nil and core.helper:is_alive(minion) and minion:is_visible() and minion:is_minion() and minion:is_targetable() then
      if g_local.position:dist_to(minion.position) <= range then
          table.insert(minions_in_range, minion)
      end
    end
  end

  return minions_in_range
end

function Splash_harass()
  if g_local:is_recalling() then return false end
  if checkboxJinxSplashHarass:get_value() == false then return false end
  if features.orbwalker:is_in_attack() or features.evade:is_active() or not Data:can_cast('Q') then return false end
  local target = Get_target()
  if target == nil then return false end
  SplashabletargetIndex = target.index
  ValidateSplashMinionAndtarget()

  --is target outside normal Q range?
  if core.helper:is_alive(target) and target:is_visible() and g_local.position:dist_to(target.position) > Data['AA'].long_range then
    if g_local.position:dist_to(target.position) < Data['AA'].long_range + 260 then
      --Prints("target is inside splash range.", 1)
      -- if we already have a splash minion then why are we still searching
      if SplashableMinionIndex == nil then FindSplashableMinion() end
      -- we may have found a minion so
      if SplashableMinionIndex then
        Prints("splash minion found", 1)
        local min_obj = features.entity_list:get_by_index(SplashableMinionIndex)
        if min_obj then
          if features.orbwalker:get_mode() == Harass_key or extend_q_auto:get_value() then
            local min_pred = features.prediction:predict(SplashableMinionIndex, Data['AA'].long_range, 1500, 0,
              g_local.attack_speed, g_local.position)
            local nme_pred = features.prediction:predict(SplashableMinionIndex, Data['AA'].long_range, 1500, 0,
              g_local.attack_speed, g_local.position)

            if g_local.position:dist_to(min_pred.position) < Data['AA'].long_range then
              Prints("sending extendo attack to " .. min_obj:get_object_name(), 1)
              if nme_pred.position:dist_to(min_pred.position) < 235 then
                if Data['AA'].rocket_launcher == false then g_input:cast_spell(e_spell_slot.q) end
                if features.orbwalker:can_attack() and not features.orbwalker:is_in_attack() then
                  features.orbwalker:send_attack(min_obj.network_id)
                end
                return true
              end
            end
          end
        end
      end
    end
  end
end

function IsBadTarget(target_index)
  return features.target_selector:is_bad_target(target_index)
end
local function enemy_buff_name() --- prints all ally buffs names
  
  for i, ally in pairs(features.entity_list:get_enemies()) do
      for j, buff in pairs(features.buff_cache:get_all_buffs(ally.index)) do
          Prints(ally.champion_name.text.." buff: "..buff.name)
          print("active: " .. tostring(buff.active))
          print("hard_cc: " .. tostring(buff.hard_cc))
          print("disabling: " .. tostring(buff.disabling))
          print("knock_up: " .. tostring(buff.knock_up))
          print("silence: " .. tostring(buff.silence))
          print("cripple: " .. tostring(buff.cripple))
          print("invincible: " .. tostring(buff.invincible))
          print("slow: " .. tostring(buff.slow))
          print("type: " .. tostring(buff.type))
          print("start_time: " .. tostring(buff.start_time))
          print("end_time: " .. tostring(buff.end_time))
          print("alt_amount: " .. tostring(buff.alt_amount))
          print("name: " .. tostring(buff.name))
          print("amount: " .. tostring(buff.amount))
      end
  end
end
function PrintBuffs()
  if g_input:is_key_pressed(85) == true then
    if g_input:is_key_pressed(85) == true then
      enemy_buff_name() -- prints all enemy buffs names
    end
  end
end
function SemiAutoR()
  if g_local:is_recalling() then return false end
  if checkboxManR:get_value() == false then return false end
  if features.orbwalker:is_in_attack() or features.evade:is_active() or not Data:can_cast('R') then return false end
  if g_input:is_key_pressed(85) == true then   -- 85 is U key T is 84, Y is 89
    Prints("Auto R.....", 1)
    local target = Get_target()
    -- dont do it if: nil or invis or bad target or not attackable or out of range XD
    if target == nil then
      Prints("nil target manual ulti", 1)
      return false
    end

    local is_bad_target, result = pcall(IsBadTarget, target.index)
    if is_bad_target then
      Prints("bad target manual ulti", 1)
      return false
    end
    if not features.orbwalker:is_attackable(target.index, 3500, true) then
      Prints("not atkble manual ulti", 1)
      return false
    end
    if not (core.helper:is_alive(target) and target:is_visible()) then
      Prints("dead or invis tgt manual ulti", 1)
      return false
    end
    if g_local.position:dist_to(target.position) > 3500 then
      Prints("man ult target to far away", 1)
      return false
    end
    local hitchance = features.prediction:predict(target.index, Data['R'].Range, Data['R'].Speed, Data['R'].Width, 0,
      g_local.position)
    if hitchance.valid and hitchance.hitchance >= 0 then g_input:cast_spell(e_spell_slot.r, hitchance.position) end
  end
end

function Time_remaining_for_dash(cai)
  local dx = cai.path_end.x - cai.path_start.x
  local dy = cai.path_end.y - cai.path_start.y
  local dz = cai.path_end.z - cai.path_start.z

  local distance = std_math.sqrt(dx * dx + dy * dy + dz * dz)
  local time_remaining = distance / cai.dash_speed

  return time_remaining
end

function OnDash(index)
  local tgt = features.entity_list:get_by_index(index)
  local champion_name = string.lower(tgt.champion_name.text)
  local cai = tgt:get_ai_manager()
  local spell_book = tgt:get_spell_book()
  local cast_info = spell_book:get_spell_cast_info()

 if (e_agc:get_value() or e_agc:get_value()) then
	local has_dash = core.database:has_dash(tgt) 

    if cast_info ~= nil and has_dash then
      Prints(champion_name .. ": enter cast check" .. tostring(cast_info.slot), 2)
      local casted_slot = cast_info.slot
      if casted_slot >= 0 and casted_slot <= 50  then
        Prints("looking at " .. string.lower(tgt.champion_name.text), 1)
		Prints("casted slot: " .. tostring(cast_info.name), 1)
        Prints("casted slot: " .. tostring(cast_info.slot), 1)
	  
        -- Check if the local champion is in the dash_list_cfg
        local is_dash = false

		local champion_dash_list = core.database.DASH_LIST[champion_name]
		if champion_dash_list ~= nil then
		  for _, ability_slot in ipairs(champion_dash_list) do
			if casted_slot == ability_slot then
			  is_dash = true
			  break
			end
		  end
		end

        if is_dash then Prints(tostring(casted_slot) .. " is a dash!!!") else Prints(tostring(casted_slot) .. " is not a dash") end
      else Prints(champion_name .. ": slot came back -1", 3) end
    else Prints(champion_name .. ": no cast info", 3) end
  end


  if (e_agc:get_value() or e_agc:get_value()) and cai.is_dashing then
    Prints("checking for dashes", 2)
    if g_local.position:dist_to(cai.path_end) > Data['W'].Range then
      Prints("is dashing out of range of w :(", 2)
      return false
    end
    Prints("is dashing...", 2)
    local time_remaining = Time_remaining_for_dash(cai)
    Prints("Time Remaining: " .. tostring(time_remaining), 2)
    local trapped = false

    if e_agc:get_value() and time_remaining > (Data['E'].castTime - 0.5) and g_local.position:dist_to(cai.path_end) < Data['E'].Range and Data:can_cast('E') then
      Prints("lets e?", 3)
      g_input:cast_spell(e_spell_slot.e, cai.path_end)
      features.orbwalker:set_cast_time(0.25)
      Last_cast_time = g_time
      return true
    end

    -- dont w under tower unless already in combo mode
    if (IsUnderTurret(g_local.position) and not features.orbwalker:get_mode() == Combo_key) then return false end

    if w_agc:get_value() and time_remaining > (Data['W'].castTime - 0.5) and Data:can_cast('W') then
      local minion_block = features.prediction:minion_in_line(g_local.position, cai.path_end, 120)
      if not minion_block and g_local.position:dist_to(cai.path_end) > 300 then
        g_input:cast_spell(e_spell_slot.w, cai.path_end)
        Prints("attempted to cast W", 2)
        return true
      end
    end

    return false
  end
  Prints("exit OnDash", 3)
end

function Has_stasis(enemy)
  local stasis_end_time = 0
  local has_stasis = false

  for _, buff in ipairs(features.buff_cache:get_all_buffs(enemy.index)) do
    if buff.name == "ChronoRevive" or buff.name == "ZhonyasRingShield" then
      stasis_end_time = buff.end_time
      Prints("found stasis of type" .. buff.name .. " ending at " .. tostring(stasis_end_time).. " on " .. enemy.champion_name.text, 3)
      has_stasis = true
    end
  end

  return has_stasis, stasis_end_time
end

function On_stasis_special_channel(index)
  local enemy = features.entity_list:get_by_index(index)
  if enemy then
    local has_stasis_buff, stasis_end_time = Has_stasis(enemy)
    if has_stasis_buff then
      local should_cast_w = false
      local should_cast_e = false

      if w_auto:get_value() and Data:can_cast('W') and Data:in_range('W', enemy) then
        should_cast_w = true
      end

      if e_auto:get_value() and Data:can_cast('E') and Data:in_range('E', enemy) then
        should_cast_e = true
      end
      if should_cast_e == false and should_cast_w == false then return end
      local remaining_stasis_time = stasis_end_time - g_time
  
      if should_cast_e or should_cast_w then
        Prints("okay lets try hand stasis",3)
        if should_cast_e then
          local time_to_cast_e = 0.9
          Prints("E stasis cast: " .. tostring(remaining_stasis_time), 2)
          if remaining_stasis_time <= time_to_cast_e then
            local eHit = features.prediction:predict(enemy.index, Data['E'].Range, Data['E'].Speed, Data['E'].Width, 0, g_local.position)
            if eHit.valid and eHit.hitchance >= 2 then
              g_input:cast_spell(e_spell_slot.e, eHit.position)
              features.orbwalker:set_cast_time(0.25)
              Last_cast_time = g_time
              return true
            end
          end
        end

        if should_cast_w then
          Prints("okay lets try hand w stasis", 2)

          local time_to_cast_w = g_time + remaining_stasis_time - Data['W'].castTime
          Prints("we want to cast at: " .. tostring(time_to_cast_w) .. "now it's: " .. tostring(g_time), 2)

          if g_time >= time_to_cast_w and g_time <= time_to_cast_w + 0.25 then
            Prints("casting w for stasis g_time:" .. tostring(g_time), 2)
            local wHit = features.prediction:predict(enemy.index, Data['W'].Range, Data['W'].Speed, Data['W'].Width, 0, g_local.position)
            if wHit.valid and wHit.hitchance >= 2 then
              g_input:cast_spell(e_spell_slot.w, wHit.position)
              features.orbwalker:set_cast_time(0.25)
              Last_cast_time = g_time
              return true
            end
          end
        end
      end
    end
  end
end
function On_cc_special_channel(index)
	if g_local:is_recalling() then return false end
	Prints("cc check", 3)
	local enemy = features.entity_list:get_by_index(index)
	if enemy then
		local cai = enemy:get_ai_manager()
		-- w_auto
		-- w_auto_cc  w_auto_channel w_auto_special
		if core.helper:is_alive(enemy) and not enemy:is_invisible() then
			Prints("checking if " .. enemy:get_object_name() .. " is ccd or immobile or stasis", 3)

			local should_cast_w = false
			local should_cast_e = false

			local is_immobile = false
			local is_ccd = false
			--local is_channeling = false

			if features.buff_cache:is_immobile(enemy.index) then is_ccd = true end
			if features.buff_cache:has_hard_cc(enemy.index) then is_immobile = true end
			if Has_stasis(enemy) then return On_stasis_special_channel(index) end

			if is_immobile or is_ccd then
				Prints("is ccd or immobile looking to cast", 2)

				if w_auto:get_value() and Data:can_cast('W') and Data:in_range('W', enemy) then
					should_cast_w = true
				end
				-- please dont laser under enemy tower lol
				if (IsUnderTurret(g_local.position) and not features.orbwalker:get_mode() == Combo_key) then
					should_cast_w = false
				end

				if e_auto:get_value() and Data:can_cast('E') and Data:in_range('E', enemy) then
					should_cast_e = true
				end
			end
			if should_cast_e or should_cast_w then
				Prints("lets cast something", 2)

				if e_auto:get_value() and Data:can_cast('E') and Data:in_range('E', enemy) then
					local eHit = features.prediction:predict(enemy.index, Data['E'].Range, Data['E'].Speed,
						Data['E'].Width, 0,
						g_local.position)
					if eHit.valid and eHit.hitchance >= 2 then
						g_input:cast_spell(e_spell_slot.e, eHit.position)
					end
					features.orbwalker:set_cast_time(0.25)
					Last_cast_time = g_time
				end
				Prints("lets cast something 2", 2)
				if w_auto:get_value() and Data:can_cast('W') and Data:in_range('W', enemy) then
					local wHit = features.prediction:predict(enemy.index, Data['W'].Range, Data['W'].Speed,
						Data['W'].Width, 0,
						g_local.position)
					if wHit.valid and wHit.hitchance >= 2 then
						g_input:cast_spell(e_spell_slot.w, wHit.position)
						features.orbwalker:set_cast_time(0.25)
						Last_cast_time = g_time
					end
				end
			end
		end
	end
end

function KS(enemy)
	if g_local:is_recalling() then return false end
	Prints("ks in", 3)
	local chance = 2
	if g_input:is_key_pressed(17) then chance = 1 end
  
	local delay = 0.25 -- you can adjust this delay to match the time it takes for spells to hit the target
  
	if Data:can_cast('W') and Data:in_range('W', enemy) then
	  local wHit = features.prediction:predict(enemy.index, Data['W'].Range, Data['W'].Speed, Data['W'].Width, 0, g_local.position)
	  local wdmg = core.damagelib:calc_spell_dmg("W", g_local, enemy, 1, Data['W'].Level)
	  local hpPred = features.prediction:predict_health(enemy, delay, true)
	  Prints("w ks chance: " .. tostring(wHit.hitchance) .. " wDmg is: " .. tostring(wdmg), 3)
	  if wdmg > hpPred and hpPred > 1 then
		if wHit.valid and wHit.hitchance >= chance then
		  g_input:cast_spell(e_spell_slot.w, wHit.position)
		  features.orbwalker:set_cast_time(0.25)
		  Last_cast_time = g_time
		  return true
		end
	  end
	end
  
	if Data:can_cast('R') and Data:in_range('R', enemy) then
	  local rHit = features.prediction:predict(enemy.index, Data['R'].Range, Data['R'].Speed, Data['R'].Width, 0, g_local.position)
	  local rdmg = core.damagelib:calc_spell_dmg("R", g_local, enemy, 1, Data['R'].Level)
	  local hpPred = features.prediction:predict_health(enemy, delay, true)
	  Prints("r ks chance: " .. tostring(rHit.hitchance) .. " rDmg is: " .. tostring(rdmg), 3)
	  if rdmg > hpPred + 15 and hpPred > 1 then
		if rHit.valid and rHit.hitchance >= chance then
		  g_input:cast_spell(e_spell_slot.r, rHit.position)
		  features.orbwalker:set_cast_time(0.25)
		  Last_cast_time = g_time
		  return true
		end
	  end
	end
  end

function Get_q_travel_time(minion)
  local missile_speed = 1700 -- Jinx's Q missile speed in rocket launcher form
  local distance = g_local.position:dist_to(minion.position)
  return distance / missile_speed
end


function OnTick()
  if g_time - Last_cast_time <= 0.05 then return end
  if g_local:is_recalling() then return false end
  Prints("tick...", 3)
  for i, enemy in pairs(features.entity_list:get_enemies()) do
    if core.helper:is_alive(enemy) and enemy:is_visible() and g_local.position:dist_to(enemy.position) < 3000 then
      --Prints("check dash", 2)
      if not features.orbwalker:is_in_attack() and not features.evade:is_active() and not core.helper:is_invincible(enemy) then
        -- if is dashing
		Prints("check ks", 3)
        KS(enemy)
        Prints("check dash is dashing", 3)
        OnDash(enemy.index)
        if enemy:get_ai_manager().is_dashing then
        end
        --chain cc
        On_cc_special_channel(enemy.index)
      end
    end
  end
  Prints("tick exit", 3)
end

function Refresh() Data:refresh_data() end


check_for_update()

---@diagnostic disable-next-line: missing-parameter
cheat.register_module(
  {
    champion_name = "Jinx",
    spell_q = function(data)
      Prints("q spell in", 3)

      local mode = features.orbwalker:get_mode()
      local target = Get_target()

      if features.orbwalker:is_in_attack() or features.evade:is_active() or not Data:can_cast('Q') then
      end
      -- Farming logic
      local should_q_farm =  (mode == Clear_key and q_clear:get_value()) or (mode == Harass_key and q_clear:get_value())
      if should_q_farm then
        if not Data['AA'].rocket_launcher and features.orbwalker:can_attack() then
            Prints("getting mins in long range", 3)

            local minions_in_range = Get_minions(Data['AA'].long_range)
            for _, minion in ipairs(minions_in_range) do
                if g_local.position:dist_to(minion.position) > Data['AA'].short_range then
                    local delay = Get_q_travel_time(minion) + 0.35
                    local hpPred = features.prediction:predict_health(minion, delay, true)
                    if hpPred ~= minion.health then
                      local aa_dmg = core.damagelib:calc_aa_dmg(g_local, minion)
                    
                      if hpPred < aa_dmg * 1.1 and hpPred > 5 then
                          Prints("Forcing target for q clear save", 2)
                          g_input:cast_spell(e_spell_slot.q)
                          Last_Q_swap_time = g_time
                          return true
                      end
                    end
                end
            end
        end
      end

      if mode == Combo_key and q_combo:get_value() then
        if q_combo_aoe:get_value() and target ~= nil and Data:count_enemies(250, target.position) >= q_combo_aoe_count:get_value() then
          if not Data['AA'].rocket_launcher then
            g_input:cast_spell(e_spell_slot.q)
            Last_Q_swap_time = g_time
            return true
          end
          -- we need more range...
        else
          if (not Data['AA'].rocket_launcher and Data['AA'].enemy_far and not Data['AA'].enemy_close) then
            g_input:cast_spell(e_spell_slot.q)
            Last_Q_swap_time = g_time
          else
            if (Data['AA'].rocket_launcher and Data['AA'].enemy_far and Data['AA'].enemy_close) then
              -- we need more attack speed...
              g_input:cast_spell(e_spell_slot.q)
              Last_Q_swap_time = g_time
              return true
            end
          end
        end
      end
      if mode == Clear_key and q_auto:get_value() then
        local turrets = features.entity_list:get_enemy_turrets()

        -- spellfarm check
        if Data['AA'].rocket_launcher and (target ~= nil or turrets[target] ~= nil) then
          g_input:cast_spell(e_spell_slot.q)
          Last_Q_swap_time = g_time
          return true
        end
      end
      -- if q is still active and nothing else happend we should turn it off
      local mode = features.orbwalker:get_mode()
      
      if Data['AA'].rocket_launcher and not features.orbwalker:is_in_attack() and mode ~= Combo_key and mode ~= Idle_key then
        if g_time - Last_Q_swap_time > 0.5 then
          Prints("exit rocket mode, bored", 2)
          g_input:cast_spell(e_spell_slot.q)
          Last_Q_swap_time = g_time
          return false
        end
      end
      return false
    end,
    spell_w = function(data)
      local mode = features.orbwalker:get_mode()
      local target = Get_target()

      if features.orbwalker:is_in_attack() or features.evade:is_active() or not Data:can_cast('W') then
        return false
      end
      if w_combo:get_value() then
        Prints("w spell in", 3)
        if (mode == Combo_key and w_combo:get_value()) or mode == Harass_key then
          if target == nil then return false end
		  if g_local.position:dist_to(target.position) > Data['W'].Range then return false end
          local skip_cast = false
          local hit_chance_setting = w_combo_hitchance:get_value()

          local full_combo = g_input:is_key_pressed(17)
          if full_combo then hit_chance_setting = 0 end
          local should_w_in_aa_range = w_combo_not_in_range:get_value()
          local aadmg = core.damagelib:calc_aa_dmg(g_local, target)
          local aa_to_kill = std_math.ceil(target.health / aadmg)
          local near_death = aa_to_kill <= 2
          local in_Q_range = Data['AA'].enemy_far
          local in_w_range = Data:in_range('W', target)
          local wHit = features.prediction:predict(target.index, Data['W'].Range, Data['W'].Speed, Data['W'].Width,
            Data['W'].castTime, g_local.position)
          local minion_block = features.prediction:minion_in_line(g_local.position, wHit.position, 120)
          local can_weave = features.orbwalker:should_reset_aa()
          if full_combo then should_w_in_aa_range = true end


          -- aa range logic
          if in_Q_range then
            if not can_weave or not should_w_in_aa_range or near_death then
              skip_cast = true
              Prints("Skip W, target in AA range waiting to weave auto", 2)
            end
          end
		  Prints("wHit valid:" ..tostring(wHit.valid) ..  " wSkip: " .. tostring(skip_cast) .. " hitRequire:  " .. tostring(hit_chance_setting) .. " chance: ".. tostring(wHit.hitchance) .. " minion block: " .. tostring(minion_block), 2)
          if wHit.valid and wHit.hitchance >= hit_chance_setting and not minion_block and not skip_cast then
			Prints("W Cast", 2)
            g_input:cast_spell(e_spell_slot.w, wHit.position)
            return true
          end
        end
      else
        Prints("dont w in combo")
      end
      return false
    end,
    spell_e = function(data)
      local mode = features.orbwalker:get_mode()
      local target = Get_target()

      if features.orbwalker:is_in_attack() or features.evade:is_active() or not Data:can_cast('E') then
      end

      if mode == Combo_key and q_combo:get_value() then
        if (e_combo_mode:get_value() == 0) then
          if Data:in_range('E', target) then
            local eHit = features.prediction:predict(target.index, Data['E'].Range, Data['E'].Speed, Data['E'].Width, 0,
              g_local.position)
            if eHit.valid and eHit.hitchance >= 3 then   --TODO: set hitchance on 3
              g_input:cast_spell(e_spell_slot.e, eHit.position)
            end
          end
        end
      end
      return false
    end,
    spell_r = function(data)
      Prints("r spell in", 3)
      local mode = features.orbwalker:get_mode()
   

      local target = Get_target()
      if target == nil then return false end
      local dmg = 5 > std_math.ceil(target.health / core.damagelib:calc_aa_dmg(g_local, target))
      if features.orbwalker:is_in_attack() or features.evade:is_active() or not Data:can_cast('R') then
      end
      

      if mode == Combo_key and r_combo:get_value() then
        if Data:in_range('R', target) and dmg and not Data['AA'].enemy_far then
          local hitchance = features.prediction:predict(target.index, Data['R'].Range, Data['R'].Speed, Data['R'].Width,
            0, g_local.position)
          if hitchance.valid and hitchance.hitchance >= 0 then   --TODO: set hitchance on 3
            g_input:cast_spell(e_spell_slot.r, hitchance.position)
          end
        end
      end
      Prints("r spell exit", 3)
      return false
    end,
    get_priorities = function()
      return {
        "spell_q",
        "spell_w",
        "spell_e",
        "spell_r",
      }
    end
  })


---@diagnostic disable-next-line: undefined-field
cheat.register_callback("render", Draw)
---@diagnostic disable-next-line: undefined-field
cheat.register_callback("feature", Refresh)
---@diagnostic disable-next-line: undefined-field
cheat.register_callback("feature", Splash_harass)
---@diagnostic disable-next-line: undefined-field
cheat.register_callback("feature", SemiAutoR)
---@diagnostic disable-next-line: undefined-field
cheat.register_callback("feature", OnTick)
