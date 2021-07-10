-- Renoise Hooks

renoise.tool():add_menu_entry {
    name = "Main Menu:Tools:PadSynth 2...",
    invoke = function()
        print("Hello, World!")
    end
}

renoise.tool():add_keybinding {
    name = "Global:Tools:PadSynth 2...",
    invoke = function()
        print("Hello, World!")
    end
}
