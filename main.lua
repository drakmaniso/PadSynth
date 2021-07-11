local utils = require "utils"

-- CONSTANTS ------------------------------------------------------------------

local MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
local SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
local CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
local MINI_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
local DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT

-- GLOBALS --------------------------------------------------------------------

local window
local vb, views

local main_display

-- DISPLAY --------------------------------------------------------------------

local function new_display(width, height, step)
    local display = {
        width = width,
        height = height,
        step = step,
        tops = {},
        bottoms = {},
        view = vb:row {style = "invisible", spacing = 0, margin = 0, height = height}
    }
    display.view:add_child(vb:space {width = 1, height = height + 2})
    for i = 1, width do
        local x = (i - 1) / (width - 1)
        local y = x * height
        local bottom = math.floor(y + 0.5)
        local top = height - y
        display.tops[i] = vb:space {width = step, height = top + 1}
        display.bottoms[i] = vb:row {style = "plain", width = step, height = bottom + 1}
        display.view:add_child(
            vb:column {
                display.tops[i],
                display.bottoms[i]
            }
        )
    end
    display.view:add_child(vb:space {width = 1, height = height + 2})
    return display
end

local function update_display(display, fn)
    for i = 1, display.width do
        local x = (i - 1) / (display.width - 1)
        local y = fn(x) * display.height --TODO: clamp fn(x)
        local bottom = math.floor(y + 0.5)
        local top = display.height - bottom
        display.tops[i].height = top + 1
        display.bottoms[i].height = bottom + 1
    end
end

-- MAIN WINDOW ----------------------------------------------------------------

local function create_main_window()
    vb = renoise.ViewBuilder()
    views = vb.views

    main_display = new_display(768, 200, 1)

    return vb:column {
        style = "body",
        uniform = true,
        width = 800,
        margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
        spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
        vb:row {
            style = "group",
            margin = MARGIN,
            vb:rotary {
                id = "foo_rotary",
                min = 0,
                max = 1,
                notifier = function()
                    update_display(
                        main_display,
                        function(x)
                            return (1 - x) * views.foo_rotary.value
                        end
                    )
                end
            }
        },
        vb:row {
            style = "group",
            margin = MARGIN,
            main_display.view
        }
    }
end

local function show_main_window()
    if window and window.visible then
        window:show()
    else
        window = renoise.app():show_custom_dialog("PadSynth 2", create_main_window())
    end
end

-- RENOISE HOOKS --------------------------------------------------------------

_AUTO_RELOAD_DEBUG = true

renoise.tool():add_menu_entry {
    name = "Main Menu:Tools:PadSynth 2...",
    invoke = function()
        show_main_window()
    end
}

renoise.tool():add_menu_entry {
    name = "Scripting Menu:Tools:PadSynth 2...",
    invoke = function()
        show_main_window()
    end
}

renoise.tool():add_keybinding {
    name = "Global:Tools:PadSynth 2...",
    invoke = function()
        show_main_window()
    end
}
