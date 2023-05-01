VERSION = "1.0.5"
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
