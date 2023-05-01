VERSION = "1.0.5"
LUA_NAME = "TinyTest.lua"

local function fetch_remote_version_number()
    local url = "https://raw.githubusercontent.com/JayBuckley7/SlottedLua/main/TinyTest.lua"
    local command = "curl -s " .. url
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
    local updated_script_url = "https://raw.githubusercontent.com/JayBuckley7/SlottedLua/main/TinyTest.lua"
    local command = "curl -s " .. updated_script_url
    local handle = io.popen(command)
    local latest_version_script = handle:read("*a")
    handle:close()

    if latest_version_script then
        if replace_current_file_with_latest_version(latest_version_script) then
            print("Successfully updated TinyTest to version " .. remote_version .. ".")
            -- You may need to restart the program to use the updated script
        else
            print("Failed to update TinyTest.")
        end
    end
else
    print("You are running the latest version of TinyTest.")
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
