VERSION = "1.0.6"
LUA_NAME = "TinyTest.lua"
REPO_BASE_URL = "https://raw.githubusercontent.com/JayBuckley7/SlottedLua/main/"
REPO_SCRIPT_PATH = REPO_BASE_URL .. LUA_NAME

local function fetch_remote_version_number()
    local command = "curl -s " .. REPO_SCRIPT_PATH
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
    local current_file_path = resources_path:gsub("resources$", "lua/" .. LUA_NAME)

    local file, errorMessage = io.open(current_file_path, "w")

    if not file then
        print("Failed to open the current file for writing. Error: ", errorMessage)
        return false
    end

    file:write(latest_version_script)
    file:close()

    return true
end

local remote_version = fetch_remote_version_number()

if remote_version and remote_version > VERSION then
    local command = "curl -s " .. REPO_SCRIPT_PATH
    local handle = io.popen(command)
    local latest_version_script = handle:read("*a")
    handle:close()

    if latest_version_script then
        if replace_current_file_with_latest_version(latest_version_script) then
            print("Successfully updated " .. LUA_NAME .. " to version " .. remote_version .. ".")
            -- You may need to restart the program to use the updated script
        else
            print("Failed to update " .. LUA_NAME .. ".")
        end
    end
else
    print("You are running the latest version of " .. LUA_NAME .. ".")
end




cheat.register_module(
  {
    champion_name = "Jinx",
    spell_q = function(data)
      local target = features.target_selector:get_default_target()
      return false
    end,
    spell_w = function(data)
      return false
    end,
    spell_e = function(data)
        return false
    end,
    spell_r = function(data)
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
