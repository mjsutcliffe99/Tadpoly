local keybinds = {}

keybinds.actions = {}   -- e.g. actions["fullscreen"] = "f11"

function keybinds.bind(action,keys)
    keybinds.actions[action] = keys
end

return keybinds