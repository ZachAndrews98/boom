--- Input mapping subsbystem.

local input = {
    keybinds = {
        left = 'left',
        right = 'right',
        down = 'crouch',
        z = 'jump',
        x = 'throw',
        up = 'jump',
        space = 'ok',
        ['return'] = 'ok',
        c = 'interact',
    }
}

function input.get_key(value)
  for k, _ in pairs(input.keybinds) do
    if input.keybinds[k] == value then
      return k
    end
  end
end

--- Translate a key value to an input name.
function input.translate(key)
    return input.keybinds[key]
end

return input
