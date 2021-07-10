local gui = require "gui"

-- GUI --

local window

local function show_window()
    if window and window.visible then
        window:show()
    else
        window = renoise.app():show_custom_dialog("PadSynth 2", gui.create())
    end
end

-- RENOISE HOOKS --

_AUTO_RELOAD_DEBUG = true

renoise.tool():add_menu_entry {
    name = "Main Menu:Tools:PadSynth 2...",
    invoke = function()
        show_window()
    end
}

renoise.tool():add_menu_entry {
    name = "Scripting Menu:Tools:PadSynth 2...",
    invoke = function()
        show_window()
    end
}

renoise.tool():add_keybinding {
    name = "Global:Tools:PadSynth 2...",
    invoke = function()
        show_window()
    end
}
