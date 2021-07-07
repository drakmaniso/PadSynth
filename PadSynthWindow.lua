class "PadSynthWindow"

local status = nil

----------------------------------------------------------------------------------------------------


function PadSynthWindow:__init (pad_synth)

    self.vb = renoise.ViewBuilder ()

    self.pad_synth = pad_synth

    self.harmonics = {}
    for i, v in ipairs (pad_synth.harmonics) do
        self.harmonics[i] = v
    end

    self.harmonics_output = {}
    for i, v in ipairs (pad_synth.harmonics_output) do
        self.harmonics_output[i] = v
    end

    self.formula_custom_string = pad_synth.formula_custom_string
    self.formula_length = pad_synth.formula_length
    self.formula_curvature = pad_synth.formula_curvature
    self.formula_torsion = pad_synth.formula_torsion
    self.formula_shape = pad_synth.formula_shape

end


----------------------------------------------------------------------------------------------------


function PadSynthWindow:update_parameters ()

    local views = self.vb.views

    self.pad_synth.volume = views.volume.value
    self.pad_synth.sample_duration = views.duration.value
    self.pad_synth.nb_channels = views.nb_channels.value

    self.pad_synth.autofade = views.autofade.value
    self.pad_synth.new_note_action = views.new_note_action.value
    self.pad_synth.interpolation = views.interpolation.value
    self.pad_synth.oversample_enabled = views.oversample_enabled.value
    self.pad_synth.modulation_set_index = views.modulation_set_index.value
    self.pad_synth.device_chain_index = views.device_chain_index.value

    self.pad_synth.overtones_placement = views.overtones_placement.value
    self.pad_synth.overtones_treshold = views.overtones_treshold.value
    self.pad_synth.overtones_amount = views.overtones_amount.value
    self.pad_synth.overtones_harmonize = views.overtones_harmonize.value
    self.pad_synth.overtones_param1 = views.param1.value
    self.pad_synth.overtones_param2 = views.param2.value

    self.pad_synth.bandwidth = views.bandwidth.value
    self.pad_synth.bandwidth_growth = views.growth.value

    self.pad_synth.unison_multiplier = views.unison_multiplier.value
    self.pad_synth.unison_detune = views.unison_detune.value
    self.pad_synth.unison_width = views.unison_width.value

    self.pad_synth.sample_rate = self.sample_rate_values[views.sample_rate.value]
    self.pad_synth.bit_depth = self.bit_depth_values[views.bit_depth.value]

    self.pad_synth.first_note = views.first_note.value
    self.pad_synth.last_note = views.last_note.value
    self.pad_synth.keyzones_step = views.keyzones_step.value

    self.pad_synth.test_note = views.test_note.value
    self.pad_synth.test_duration = views.test_duration.value

    self.pad_synth.base_function = views.base_function.value

    self.pad_synth.harmonics = { }
    for i = 1, 256 do
        self.pad_synth.harmonics[i] = self.harmonics[i] -- lin_to_ln (views["H" .. i].value)
    end

    self.pad_synth.harmonics_output = { }
    for i = 1, 256 do
        self.pad_synth.harmonics_output[i] = self.harmonics_output[i]
    end

    self.pad_synth.formula_string = views.formula_string.value
    self.pad_synth.formula_curvature = views.formula_curvature.value
    self.pad_synth.formula_length = views.formula_length.value
    self.pad_synth.formula_torsion = views.formula_torsion.value
    self.pad_synth.formula_shape = views.formula_shape.value

end


----------------------------------------------------------------------------------------------------


local formula_context =
{
    i = 0,
    x = 0,

    alternate =
        function(i, ...)
            local args = {...}
            local j = i % #args
            if j == 0 then j = #args end
            return args[j]
        end,

    curve = function(x, curvature, torsion, shape) return curve(x, shape, torsion, curvature) end,
    exponential = function(...) return curve_exponential(...) end,
    logarithmic = function(...) return curve_logarithmic(...) end,
    circular = function(...) return curve_circular(...) end,
    half_sinusoidal = function(...) return curve_half_sinusoidal(...) end,
    sinusoidal = function(...) return curve_sinusoidal(...) end,
    arcsinusoidal = function(...) return curve_arcsinusoidal(...) end,
}
setmetatable(formula_context, {__index = math})

local formula_documentation =
[[
Any valid Lua expression.

Variables:
    i = index of the current overtone (integer between 1 and 256)
    x = position on the horizontal axis (between 0.0 and 1.0)

Functions:
    abs, acos, asin, atan, atan2, ceil, cos, cosh, deg, exp, floor,
    fmod, frexp, huge, ldexp, log, log10, max, min, modf, pi, pow,
    rad, random, randomseed, sin, sinh, sqrt, tan, tanh
]]


----------------------------------------------------------------------------------------------------


function PadSynthWindow:show_dialog ()

    self.modulation_sets = {}
    self.modulation_sets[1] = "None"
    for i,v in ipairs(self.pad_synth.instrument.sample_modulation_sets) do
        self.modulation_sets[i+1] = self.pad_synth.instrument.sample_modulation_sets[i].name
    end
    if self.vb.views.modulation_set_index then
        self.vb.views.modulation_set_index.value = clamp(self.pad_synth.modulation_set_index, 1, #self.modulation_sets)
    end

    self.device_chains = {}
    self.device_chains[1] = "None"
    for i,v in ipairs(self.pad_synth.instrument.sample_device_chains) do
        self.device_chains[i+1] = self.pad_synth.instrument.sample_device_chains[i].name
    end
    if self.vb.views.device_chain_index then
        self.vb.views.device_chain_index.value = clamp(self.pad_synth.device_chain_index, 1, #self.device_chains)
    end

    if self.dialog and self.dialog.visible then
        self.dialog:show ()
        return
    end

    if not self.dialog_content then
        self.dialog_content = self:gui ()
    end

    local kh = function (d, k) return self:key_handler (d, k) end
    self.dialog = renoise.app():show_custom_dialog ("PadSynth", self.dialog_content, kh)

end


----------------------------------------------------------------------------------------------------


function PadSynthWindow:key_handler (dialog, key)

    if key.modifiers == "" and key.name == "esc" then

        dialog:close()

    else

        return key

    end

end


----------------------------------------------------------------------------------------------------


PadSynthWindow.sample_rate_names = { "11025", "22050", "32000", "44100", "48000", "88200", "96000" }
PadSynthWindow.sample_rate_values = { 11025, 22050, 32000, 44100, 48000, 88200, 96000 }

PadSynthWindow.bit_depth_names = { "16", "24", "32", }
PadSynthWindow.bit_depth_values = { 16, 24, 32, }

PadSynthWindow.nb_channels_names = { "Mono", "Stereo", }


----------------------------------------------------------------------------------------------------


function PadSynthWindow:generate_samples ()

    self:update_parameters ()
    self.pad_synth.is_test_note = false

    local views = self.vb.views

    local counter = 1
    views.status.text = "Generating samples..."
    views.do_generate:remove_released_notifier (self, PadSynthWindow.generate_samples)
    views.do_generate:add_released_notifier (self, PadSynthWindow.cancel_generation)
    views.do_generate.text = "Cancel"
    views.do_generate_test:remove_released_notifier (self, PadSynthWindow.generate_test_note)
    views.do_generate_test:add_released_notifier (self, PadSynthWindow.cancel_generation)
    views.do_generate_test.text = "Cancel"
    in_progress_start (function ()
        self.pad_synth:generate_samples ()
    end,
    function ()
        views.status.text = "Generating samples: Step " .. counter
        views.progress_bitmap.bitmap = "data/progress-" .. math.floor(counter % 8) .. ".png"
        views.progress_bitmap.mode = "transparent"
        counter = counter + 1
    end,
    function ()
        views.status.text = "Samples generated."
        views.progress_bitmap.bitmap = "data/progress-empty.png"
        views.progress_bitmap.mode = "transparent"
        views.do_generate.text = "Generate All Samples"
        views.do_generate:remove_released_notifier (self, PadSynthWindow.cancel_generation)
        views.do_generate:add_released_notifier (self, PadSynthWindow.generate_samples)
        views.do_generate_test.text = "Generate Test Note"
        views.do_generate_test:remove_released_notifier (self, PadSynthWindow.cancel_generation)
        views.do_generate_test:add_released_notifier (self, PadSynthWindow.generate_test_note)
    end )

end


----------------------------------------------------------------------------------------------------


function PadSynthWindow:generate_test_note ()

    self:update_parameters ()
    self.pad_synth.is_test_note = true

    local views = self.vb.views

    local counter = 1
    views.status.text = "Generating test note..."
    views.do_generate:remove_released_notifier (self, PadSynthWindow.generate_samples)
    views.do_generate:add_released_notifier (self, PadSynthWindow.cancel_generation)
    views.do_generate.text = "Cancel"
    views.do_generate_test:remove_released_notifier (self, PadSynthWindow.generate_test_note)
    views.do_generate_test:add_released_notifier (self, PadSynthWindow.cancel_generation)
    views.do_generate_test.text = "Cancel"
    in_progress_start (function ()
        self.pad_synth:generate_samples ()
    end,
    function ()
        views.status.text = "Generating test note: Step " .. counter
        views.progress_bitmap.bitmap = "data/progress-" .. math.floor(counter % 8) .. ".png"
        views.progress_bitmap.mode = "transparent"
        counter = counter + 1
    end,
    function ()
        views.status.text = "Test note generated."
        views.progress_bitmap.bitmap = "data/progress-empty.png"
        views.progress_bitmap.mode = "transparent"
        views.do_generate.text = "Generate All Samples"
        views.do_generate:remove_released_notifier (self, PadSynthWindow.cancel_generation)
        views.do_generate:add_released_notifier (self, PadSynthWindow.generate_samples)
        views.do_generate_test.text = "Generate Test Note"
        views.do_generate_test:remove_released_notifier (self, PadSynthWindow.cancel_generation)
        views.do_generate_test:add_released_notifier (self, PadSynthWindow.generate_test_note)
    end )

end


----------------------------------------------------------------------------------------------------


function PadSynthWindow:cancel_generation ()

    in_progress_abort  ()
    self.vb.views.status.text = "Sample generation aborted."
    self.vb.views.progress_bitmap.bitmap = "data/progress-empty.png"
    self.vb.views.progress_bitmap.mode = "transparent"
    self.vb.views.do_generate.text = "Generate All Samples"
    self.vb.views.do_generate:remove_released_notifier (self, PadSynthWindow.cancel_generation)
    self.vb.views.do_generate:add_released_notifier (self, PadSynthWindow.generate_samples)
    self.vb.views.do_generate_test.text = "Generate Test Note"
    self.vb.views.do_generate_test:remove_released_notifier (self, PadSynthWindow.cancel_generation)
    self.vb.views.do_generate_test:add_released_notifier (self, PadSynthWindow.generate_test_note)

end


----------------------------------------------------------------------------------------------------


local function to_note_string (v)

    local octave = math.floor (v / 12)
    local note = v % 12 + 1
    local note_names = { "C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-" }
    local note_name = note_names[note]

    return note_name .. octave

end

local note_numbers = { ["C-"] = 0, ["C#"] = 1, ["D-"] = 2, ["D#"] = 3, ["E-"] = 4, ["F-"] = 5, ["F#"] = 6, ["G-"] = 7, ["G#"] = 8, ["A-" ]= 9, ["A#"] = 10, ["B-"] = 11,
                       ["c-"] = 0, ["c#"] = 1, ["d-"] = 2, ["d#"] = 3, ["e-"] = 4, ["f-"] = 5, ["f#"] = 6, ["g-"] = 7, ["g#"] = 8, ["a-" ]= 9, ["a#"] = 10, ["b-"] = 11 }

local function to_note_number (v)

    local note_name, octave_name = string.match (v, "([a-gA-G][%-#])([0-9])")
    if not note_name or not octave_name then
        return 48
    end

    local note = note_numbers[note_name]
    if note == nil then
        note = 0
    end

    local octave = tonumber (octave_name)

    return octave * 12 + note

end


----------------------------------------------------------------------------------------------------


function PadSynthWindow:gui ()

    local vb = self.vb
    local ps = self.pad_synth

    local dialog_margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
    local dialog_spacing = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
    local control_margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
    local control_spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
    local control_height = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT

    local sample_rate = 1
    if     ps.sample_rate == 11025 then sample_rate = 1
    elseif ps.sample_rate == 22050 then sample_rate = 2
    elseif ps.sample_rate == 32000 then sample_rate = 3
    elseif ps.sample_rate == 44100 then sample_rate = 4
    elseif ps.sample_rate == 48000 then sample_rate = 5
    elseif ps.sample_rate == 88200 then sample_rate = 6
    elseif ps.sample_rate == 96000 then sample_rate = 7
    end

    local bit_depth = 1
    if     ps.bit_depth == 16 then bit_depth = 1
    elseif ps.bit_depth == 24 then bit_depth = 2
    elseif ps.bit_depth == 32 then bit_depth = 3
    end

    local function overtones_placement_notifier ()
        local op = vb.views.overtones_placement.value
        local a = op > 1
        vb.views.param1.active = a
        vb.views.param1_rotary.active = a
        vb.views.param2.active = a
        vb.views.param2_rotary.active = a
        vb.views.overtones_treshold.active = a
        vb.views.overtones_treshold_rotary.active = a
        vb.views.overtones_amount.active = a
        vb.views.overtones_amount_rotary.active = a
        vb.views.overtones_harmonize.active = a
        vb.views.overtones_harmonize_rotary.active = a
        if op == 1 then
            vb.views.overtones_treshold_label.text = "-"
            vb.views.overtones_amount_label.text = "-"
            vb.views.overtones_harmonize_label.text = "-"
        elseif op == 4 then
            vb.views.overtones_treshold_label.text = "Period"
            vb.views.overtones_amount_label.text = "Amount"
            vb.views.overtones_harmonize_label.text = "Harmonize"
        else
            vb.views.overtones_treshold_label.text = "Treshold"
            vb.views.overtones_amount_label.text = "Amount"
            vb.views.overtones_harmonize_label.text = "Harmonize"
        end
    end

    local function on_keyzones_mode_changed ()
        if self.vb.views.keyzones_mode.value == 1 then
            self.vb.views.test_note_group1.visible = false
            self.vb.views.test_note_group2.visible = false
            self.vb.views.keyzones_group1.visible = true
            self.vb.views.keyzones_group2.visible = true
            if not is_in_progress () then self.vb.views.do_generate.text = "Generate All Samples" end
        else
            self.vb.views.keyzones_group1.visible = false
            self.vb.views.keyzones_group2.visible = false
            self.vb.views.test_note_group1.visible = true
            self.vb.views.test_note_group2.visible = true
            if not is_in_progress () then self.vb.views.do_generate.text = "Generate Test Note" end
        end
    end

    local function on_unison_multiplier_changed ()
        local a = vb.views.unison_multiplier.value > 1
        vb.views.unison_detune_rotary.active = a
        vb.views.unison_detune.active = a
        vb.views.unison_width_rotary.active = a
        vb.views.unison_width.active = a
        if a then
            vb.views.unison_detune_label.text = "Detune"
            vb.views.unison_width_label.text = "Width"
        else
            vb.views.unison_detune_label.text = "-"
            vb.views.unison_width_label.text = "-"
        end
    end

    ---------------------------------------------------------------------------------------------------------------------------------------

    local full_width = 1200

    local result = vb:column
    {
        style = "body",
        margin = dialog_margin,
        spacing = dialog_spacing,
        uniform = true,


        -- Top Panels ---------------------------------------------------------------------------------------------------------------------------------

        vb:column
        {
            width = full_width,
            margin = 0,
            spacing = 0,
            vb:horizontal_aligner
            {
                margin = 0,
                spacing = dialog_spacing,
                mode = "justify",
                width = "100%",
                
                -- Global --------------------------------------------------------------------------------------------------------------------------------

                vb:column
                {
                    style = "group",
                    margin = control_margin,
                    spacing = control_spacing,
                    height = "100%",

                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:text { font = "bold", text = "Global" },
                    },

                    vb:horizontal_aligner
                    {
                        mode = "distribute",
                        width = "100%",
                        vb:column
                        {
                            uniform = true,
                            margin = 0,
                            vb:text { text = "Volume", align= "center", },
                            vb:horizontal_aligner
                            {
                                mode = "center",
                                margin = 0,
                                vb:rotary
                                {
                                    id = "volume_rotary",
                                    value = ps.volume, min = 0, max = 1,
                                    notifier = function () vb.views.volume.value = vb.views.volume_rotary.value end
                                },
                            },
                            vb:valuefield
                            {
                                id = "volume",
                                value = ps.volume, min = 0, max = 1,
                                align= "center",
                                notifier = function ()
                                    vb.views.volume_rotary.value = vb.views.volume.value
                                    for i, sample in ipairs (ps.instrument.samples) do
                                        if string.sub (sample.name, 1, 13) == "PadSynth Note" then
                                            sample.volume = vb.views.volume.value
                                        end
                                    end
                                end
                            },
                        },

                        vb:column
                        {
                            uniform = true,
                            margin = 0,
                            vb:text { text = "Duration", align= "center", },
                            vb:horizontal_aligner
                            {
                                mode = "center",
                                vb:rotary
                                {
                                    id = "duration_rotary",
                                    value = ps.sample_duration, min = 0, max = 10,
                                    notifier = function () vb.views.duration.value = vb.views.duration_rotary.value end
                                },
                            },
                            vb:valuefield
                            {
                                id = "duration",
                                value = ps.sample_duration, min = 0, max = 10,
                                align= "center",
                                notifier = function () vb.views.duration_rotary.value = vb.views.duration.value end,
                                tonumber = tonumber,
                                tostring = function (v) return string.format ("%.2f s", v) end,
                            },
                            tooltip = "Length of the wavetable",
                        },
                    },

                    vb:horizontal_aligner
                    {
                        mode = "justify",
                        vb:row
                        {
                            margin = 0,
                            spacing = 0,
                            vb:text { text = "Mod" },
                            vb:popup
                            {
                                width = "75%",
                                id = "modulation_set_index",
                                items = self.modulation_sets,
                                value = clamp(ps.modulation_set_index, 1, #self.modulation_sets),
                                notifier = function ()
                                    for i, sample in ipairs (ps.instrument.samples) do
                                        if string.sub (sample.name, 1, 13) == "PadSynth Note" then
                                            sample.modulation_set_index = vb.views.modulation_set_index.value - 1
                                        end
                                    end
                                end,
                                -- tooltip = "Define what happens when a new note is triggered in the same column\nCut: the previous note is interrupted (without release)\nNote Off: the previous note ends normally (play the release part of the envelope)\nContinue: the previous note is held",
                                },
                        },

                        vb:row
                        {
                            margin = 0,
                            spacing = 0,
                            vb:text { text = "FX" },
                            vb:popup
                            {
                                width = "75%",
                                id = "device_chain_index",
                                items = self.device_chains,
                                value = clamp(ps.device_chain_index, 1, #self.device_chains),
                                notifier = function ()
                                    for i, sample in ipairs (ps.instrument.samples) do
                                        if string.sub (sample.name, 1, 13) == "PadSynth Note" then
                                            sample.device_chain_index = vb.views.device_chain_index.value - 1
                                        end
                                    end
                                end,
                                -- tooltip = "Define what happens when a new note is triggered in the same column\nCut: the previous note is interrupted (without release)\nNote Off: the previous note ends normally (play the release part of the envelope)\nContinue: the previous note is held",
                            }, 
                        },
                    },

                }, -- Global

                -- Overtones Spread --------------------------------------------------------------------------------------------------------------------------------

                vb:column
                {
                    style = "group",
                    margin = control_margin,
                    spacing = control_spacing,
                    height = "100%",


                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:text { font = "bold", text = "Overtone Spread" },
                    },

                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:popup
                        {
                            id = "base_function",
                            items = { "Sine", "Saw", "Square", "Soft Saw", "Triangle", "Circle" },
                            value = ps.base_function,
                            tooltip = 'Replace each overtone by an overtone serie',
                        },
                    },

                    vb:horizontal_aligner
                    {
                        mode = "distribute",
                        vb:column
                        {
                            margin = 0,
                            vb:text { text = "Spread", align = "center", width = 60, },
                            vb:horizontal_aligner
                            {
                                mode = "center",
                                vb:rotary
                                {
                                    id = "bandwidth_rotary", min = 1, max = 200, value = ps.bandwidth,
                                    notifier = function () vb.views.bandwidth.value = vb.views.bandwidth_rotary.value end,
                                },
                            },
                            vb:valuefield
                            {
                                id = "bandwidth", min = 1, max = 200, value = ps.bandwidth, align = "center",
                                notifier = function () vb.views.bandwidth_rotary.value = vb.views.bandwidth.value end,
                                tonumber = tonumber,
                                tostring = function (v) return string.format ("%d ct", v) end,
                            },
                            tooltip = 'Controls how much each overtone is "spread"\naround its frequency'
                        },

                        vb:column
                        {
                            margin = 0,
                            vb:text { text = "Growth", align = "center", width = 60, },
                            vb:horizontal_aligner
                            {
                                mode = "center",
                                vb:rotary
                                {
                                    id = "growth_rotary", value = ps.bandwidth_growth, min = 0, max = 3,
                                    notifier = function () vb.views.growth.value = vb.views.growth_rotary.value end,
                                },
                            },
                            vb:valuefield
                            {
                                id = "growth", value = ps.bandwidth_growth, min = 0, max = 3, align = "center",
                                notifier = function () vb.views.growth_rotary.value = vb.views.growth.value end,
                                tonumber = tonumber,
                                tostring = function (v) return string.format ("%.2f", v) end,
                            },
                            tooltip = 'Controls how much the spread grows\nfor higher frequencies',
                        },
                    },
                }, -- Overtones Spread

                -- Overtones Placement -----------------------------------------------------------------------------------------------------------------------------

                vb:column
                {
                    style = "group",
                    margin = control_margin,
                    spacing = control_spacing,
                    height = "100%",

                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:text { font = "bold", text = "Overtone Placement" },
                    },

                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:popup
                        {
                            id = "overtones_placement",
                            items = { "Harmonic", "Multiplied", "Powered", "Waved", }, -- "ShiftU", "ShiftL", "PowerU", "PowerL", "Sine" },
                            width = 100,
                            value = ps.overtones_placement,
                            notifier = overtones_placement_notifier,
                        },
                        tooltip = "Control the placement of the overtones\nHarmonic: natural placement (integer multiple of the base frequency)\nMultplied: the harmonic placement is scaled by a certain amount\nPowered: the harmonic placement is exponentially scaled by a certain amount\nWaved: a sine function is applied to the harmonic placement",
                    },

                    vb:horizontal_aligner
                    {
                        mode = "distribute",
                        vb:column
                        {
                            margin = 0,
                            vb:text { id = "param1_label", text = "-", align = "center", width = 60, },
                            vb:horizontal_aligner
                            {
                                mode = "center",
                                vb:rotary
                                {
                                    id = "param1_rotary", value = ps.overtones_param1, min = 0, max = 1,
                                    notifier = function () vb.views.param1.value = vb.views.param1_rotary.value end,
                                active=false},
                            },
                            vb:valuefield
                            {
                                id = "param1", value = ps.overtones_param1, min = 0, max = 1, align = "center",
                                notifier = function () vb.views.param1_rotary.value = vb.views.param1.value end,
                                active=false
                            },
                            visible = false
                        },


                        vb:column
                        {
                            margin = 0,
                            vb:text { id = "param2_label", text = "-", align = "center", width = 60, },
                            vb:horizontal_aligner
                            {
                                mode = "center",
                                vb:rotary
                                {
                                    id = "param2_rotary", value = ps.overtones_param2, min = 0, max = 1,
                                    notifier = function () vb.views.param2.value = vb.views.param2_rotary.value end,
                                    active=false
                                },
                            },
                            vb:valuefield
                            {
                                id = "param2", value = ps.overtones_param2, min = 0, max = 1, align = "center",
                                notifier = function () vb.views.param2_rotary.value = vb.views.param2.value end,
                                active=false
                            },
                            visible = false
                        },

                        vb:column
                        {
                            margin = 0,
                            vb:text { id = "overtones_treshold_label", text = "-", align = "center", width = 60, },
                            vb:horizontal_aligner
                            {
                                mode = "center",
                                vb:rotary
                                {
                                    id = "overtones_treshold_rotary", value = ps.overtones_treshold, min = 1, max = 64,
                                    notifier = function () vb.views.overtones_treshold.value = vb.views.overtones_treshold_rotary.value end,
                                },
                            },
                            vb:valuefield
                            {
                                id = "overtones_treshold", value = ps.overtones_treshold, min = 1, max = 64, align = "center",
                                notifier = function () vb.views.overtones_treshold_rotary.value = vb.views.overtones_treshold.value end,
                                tonumber = function (v) return tonumber(v) end,
                                tostring = function (v) return string.format ("%d", v) end,
                            },
                            tooltip = "Treshold: define at which harmonic start the placement method\nPeriod: for the Waved placement, define the length of the waves"
                        },

                        vb:column
                        {
                            margin = 0,
                            vb:text { id = "overtones_amount_label", text = "-", align = "center", width = 60, },
                            vb:horizontal_aligner
                            {
                                mode = "center",
                                vb:rotary
                                {
                                    id = "overtones_amount_rotary", value = ps.overtones_amount, min = -1, max = 1,
                                    notifier = function () vb.views.overtones_amount.value = vb.views.overtones_amount_rotary.value end,
                                },
                            },
                            vb:valuefield
                            {
                                id = "overtones_amount", value = ps.overtones_amount, min = -1, max = 1, align = "center",
                                notifier = function () vb.views.overtones_amount_rotary.value = vb.views.overtones_amount.value end,
                                tonumber = tonumber,
                                tostring = function (v) return string.format ("%.2f", v) end,
                            },
                            tooltip = "Define how much deformation is applied to the placement",
                        },


                        vb:column
                        {
                            margin = 0,
                            vb:text { id = "overtones_harmonize_label", text = "-", align = "center", width = 60, },
                            vb:horizontal_aligner
                            {
                                mode = "center",
                                vb:rotary
                                {
                                    id = "overtones_harmonize_rotary", value = ps.overtones_harmonize, min = 0, max = 1,
                                    notifier = function () vb.views.overtones_harmonize.value = vb.views.overtones_harmonize_rotary.value end,
                                active=false},
                            },
                            vb:valuefield
                            {
                                id = "overtones_harmonize", value = ps.overtones_harmonize, min = 0, max = 1, align = "center",
                                notifier = function () vb.views.overtones_harmonize_rotary.value = vb.views.overtones_harmonize.value end,
                                tonumber = function (v) return tonumber (v / 100) end,
                                tostring = function (v) return string.format ("%d %%", v * 100) end,
                            active=false},
                            tooltip = "Shift overtones toward harmonic positions",
                        },
                    },
                }, -- Overtones Placement


                -- Unison --------------------------------------------------------------------------------------------------------------------------------

                vb:column
                {
                    style = "group",
                    margin = control_margin,
                    spacing = control_spacing,
                    height = "100%",

                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:text { font = "bold", text = "Unison", },
                    },

                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:valuebox
                        {
                            id = "unison_multiplier",
                            value = ps.unison_multiplier,
                            min = 1, max = 5,
                            tonumber = tonumber, --TODO
                            tostring = function (v)
                                if v == 1 then return "Off"
                                else return tostring((v - 1) * 2)
                                end
                            end,
                            notifier = on_unison_multiplier_changed,
                        },
                    },

                    vb:row
                    {
                        spacing = control_spacing,

                        vb:column
                        {
                            uniform = true,
                            vb:horizontal_aligner
                            {
                                mode = "center",
                                vb:rotary
                                {
                                    id = "unison_detune_rotary",
                                    value = ps.unison_detune,
                                    min = 0, max = 50,
                                    notifier = function () vb.views.unison_detune.value = vb.views.unison_detune_rotary.value end,
                                    active=false
                                },
                            },
                            vb:valuefield
                            {
                                id = "unison_detune",
                                value = ps.unison_detune,
                                min = 0, max = 50,
                                align= "center",
                                notifier = function () vb.views.unison_detune_rotary.value = vb.views.unison_detune.value end,
                                tonumber = tonumber,
                                tostring = function (v) return string.format ("%d ct", v) end,
                                active=false
                            },
                            vb:text { id = "unison_detune_label", text = "Detune", align= "center", width = 60, },
                        },

                        vb:column
                        {
                            uniform = true,
                            vb:horizontal_aligner
                            {
                                mode = "center",
                                vb:rotary
                                {
                                    id ="unison_width_rotary",
                                    value = ps.unison_width,
                                    min = 0, max = 50,
                                    notifier = function () vb.views.unison_width.value = vb.views.unison_width_rotary.value end,
                                    active=false
                                },
                            },
                            vb:valuefield
                            {
                                id = "unison_width",
                                value = ps.unison_width,
                                min = 0, max = 50,
                                align= "center",
                                notifier = function () vb.views.unison_width_rotary.value = vb.views.unison_width.value end,
                                tonumber = tonumber,
                                tostring = function (v) return string.format ("%d", v) end,
                                active=false
                            },
                            vb:text { id = "unison_width_label", text = "Width", align= "center", width = 60, },
                        },
                    },
                }, -- Unison


                -- Sample Format -------------------------------------------------------------------------------------------------------------------------

                vb:column
                {
                    style = "group",
                    margin = control_margin,
                    spacing = control_spacing,
                    height = "100%",

                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:text { font = "bold", text = "Sample Format" },
                    },

                    vb:horizontal_aligner
                    {
                        -- style = "invisible",
                        mode = "distribute",
                        margin = 0,
                        spacing = 8*control_spacing,
                        height = "100%",

                        vb:column
                        {
                            style = "invisible",
                            margin = 0,
                            spacing = control_spacing,
                            height = "100%",

                            vb:horizontal_aligner
                            {
                                mode = "center",
                                vb:switch { id = "nb_channels", items = { "Mono", "Stereo", }, value = ps.nb_channels, width = 100, },
                            },

                            vb:row
                            {
                                vb:text { text = "Sample Rate", width = 80, },
                                vb:popup { id = "sample_rate", items = self.sample_rate_names, value = sample_rate, },
                            },

                            vb:row
                            {
                                vb:text { text = "Bit Depth", width = 80, },
                                vb:popup { id = "bit_depth", items = self.bit_depth_names, value = bit_depth, },
                            },

                        },

                        vb:vertical_aligner
                        {
                            mode = "top",

                            vb:horizontal_aligner
                            {
                                mode = "left",

                                vb:checkbox
                                {
                                    id = "autofade",
                                    value = ps.autofade,
                                    notifier = function ()
                                        for i, sample in ipairs (ps.instrument.samples) do
                                            if string.sub (sample.name, 1, 13) == "PadSynth Note" then
                                                sample.autofade = vb.views.autofade.value
                                            end
                                        end
                                    end,
                                    tooltip = "Raw: play the sample as is\nAutofade: apply a quick fade to the beginning and end to prevent clicking"
                                },

                                vb:text { text = "Attack Quick Fade" },
                            },

                            vb:horizontal_aligner
                            {
                                mode = "justify",

                                vb:text { text = "NNA" },

                                vb:popup
                                {
                                    id = "new_note_action",
                                    items = { "Cut", "Note Off", "Continue", },
                                    value = ps.new_note_action,
                                    notifier = function ()
                                        for i, sample in ipairs (ps.instrument.samples) do
                                            if string.sub (sample.name, 1, 13) == "PadSynth Note" then
                                                if vb.views.new_note_action.value == 2 then
                                                    sample.new_note_action = renoise.Sample.NEW_NOTE_ACTION_NOTE_OFF
                                                elseif vb.views.new_note_action.value == 3 then
                                                    sample.new_note_action = renoise.Sample.NEW_NOTE_ACTION_SUSTAIN
                                                else
                                                    sample.new_note_action = renoise.Sample.NEW_NOTE_ACTION_NOTE_CUT
                                                end
                                            end
                                        end
                                    end,
                                    tooltip = "Define what happens when a new note is triggered in the same column\nCut: the previous note is interrupted (without release)\nNote Off: the previous note ends normally (play the release part of the envelope)\nContinue: the previous note is held",
                                    },
                            },

                            vb:row { height = 8},

                            vb:horizontal_aligner
                            {
                                mode = "justify",

                                vb:text { text = "Interpolation" },

                                vb:popup
                                {
                                    id = "interpolation",
                                    items = { "None", "Linear", "Cubic", "Sinc", },
                                    value = ps.interpolation,
                                    notifier = function ()
                                        for i, sample in ipairs (ps.instrument.samples) do
                                            if string.sub (sample.name, 1, 13) == "PadSynth Note" then
                                                if vb.views.interpolation.value == 2 then
                                                    sample.interpolation_mode = renoise.Sample.INTERPOLATE_LINEAR
                                                elseif vb.views.interpolation.value == 3 then
                                                    sample.interpolation_mode = renoise.Sample.INTERPOLATE_CUBIC
                                                elseif vb.views.interpolation.value == 4 then
                                                    sample.interpolation_mode = renoise.Sample.INTERPOLATE_SINC
                                                else
                                                    sample.interpolation_mode = renoise.Sample.INTERPOLATE_NONE
                                                end
                                            end
                                        end
                                    end,
                                    tooltip = "Define the interpolation method used when repitching the sample.",
                                    },
                            },

                            vb:horizontal_aligner
                            {
                                mode = "left",

                                vb:checkbox
                                {
                                    id = "oversample_enabled",
                                    value = ps.oversample_enabled,
                                    notifier = function ()
                                        for i, sample in ipairs (ps.instrument.samples) do
                                            if string.sub (sample.name, 1, 13) == "PadSynth Note" then
                                                sample.oversample_enabled = vb.views.oversample_enabled.value
                                            end
                                        end
                                    end,
                                    tooltip = "Whether interpolation is oversampled or not."
                                },

                                vb:text { text = "Oversampling" },
                            },
                        },
                    },
                }, -- Sample Format


                -- Key Range --------------------------------------------------------------------------------------------------------------------------

                vb:column
                {
                    style = "group",
                    margin = control_margin,
                    spacing = control_spacing,
                    height = "100%",

                    vb:text { text = "Multi-Sample", font = "bold", width = "100%", align = "center", },

                    vb:row
                    {
                        id = "keyzones_group1",
                        vb:text { text = "Note Range", width = 80, },
                        vb:valuebox { id = "first_note", value = ps.first_note, min = 0, max = 119, tostring = to_note_string, tonumber = to_note_number, },
                        vb:valuebox { id = "last_note", value = ps.last_note, min = 0, max = 119, tostring = to_note_string, tonumber = to_note_number, },
                    },

                    vb:row
                    {
                        id = "keyzones_group2",
                        vb:text { text = "Size of keyzones", width = 80, },
                        vb:space { width = 24},
                        vb:valuebox { id = "keyzones_step", value = ps.keyzones_step, min = 1, max = 12, },
                    },

                    vb:space{height = 2 * control_spacing},

                    vb:row
                    {
                        id = "test_note_group1",
                        visible = true,
                        vb:text { text = "Test note", width = 80, },
                        vb:valuebox { id = "test_note", value = ps.test_note, min = 0, max = 119, tostring = to_note_string, tonumber = to_note_number, },
                        vb:valuefield
                        {
                            id ="test_duration",
                            min = 0, max = 10,
                            value = ps.test_duration,
                            width = 60,
                            tonumber = tonumber,
                            tostring = function (v) return string.format ("%.2f s", v) end,
                        },
                    },
                }, -- Key Range
            },
        }, -- Top Panels


        -- Formula ---------------------------------------------------------------------------------------------------------------------------------

        vb:row
        {
            width = full_width,
            margin = 0,
            spacing = 0,
            style = "group",

            -- Nested column necessary to prevent bug in Renoise layout system
            vb:column
            {
                width = 0.75 * full_width,
                uniform = true,
                margin = control_margin,
                spacing = control_spacing,

                vb:horizontal_aligner
                {
                    mode = "left",
                    vb:popup
                    {
                        id = "formula_presets",
                        width = 150,
                        items = 
                            {
                                "-- Overtone Formula --",
                                "All Overtones",
                                "Saw", "Bright Saw", "Extra Bright Saw", "Soft Saw", "Square", "Triangle",
                                "-- Scalable Presets: --",
                                "Linear Ramp",
                                "Cosinus Ramp", "Square Root Ramp", "Log Ramp",
                                "Triangle Cycle", "Half Cycle", "Square Cycle",
                                "Cosinus Cycle", "Sinus Cycle", "Many Cycles", "Helix",
                            },
                        value = 1,
                        notifier =
                            function(choice)
                                vb.views.formula_presets.value = 1
                                local items = vb.views.formula_presets.items
                                if items[choice] == "All Overtones" then
                                    vb.views.formula_string.value = "1"
                                elseif items[choice] == "Saw" then
                                    vb.views.formula_string.value = "1 / i"
                                elseif items[choice] == "Bright Saw" then
                                    vb.views.formula_string.value = "sqrt(1 / i)"
                                elseif items[choice] == "Extra Bright Saw" then
                                    vb.views.formula_string.value = "logarithmic(1 / i, 1)"
                                elseif items[choice] == "Square" then
                                    vb.views.formula_string.value = "(i % 2 == 1) and (1 / i) or 0"
                                elseif items[choice] == "Soft Saw" then
                                    vb.views.formula_string.value = "1 / (i * i)"
                                elseif items[choice] == "Triangle" then
                                vb.views.formula_string.value = "(i % 2 == 1) and (1 / (i * i)) or 0"
                                elseif items[choice] == "Cosinus Ramp" then
                                    vb.views.formula_string.value = "(x <= 1) and cos(x * pi/2) or 0"
                                elseif items[choice] == "Linear Ramp" then
                                    vb.views.formula_string.value = "1 - x"
                                elseif items[choice] == "Square Root Ramp" then
                                    vb.views.formula_string.value = "1 - sqrt(x)"
                                elseif items[choice] == "Log Ramp" then
                                    vb.views.formula_string.value = "1 - log10(1+10*x)"
                                elseif items[choice] == "Triangle Cycle" then
                                    vb.views.formula_string.value = "abs(x % 1 - 0.5)"
                                elseif items[choice] == "Square Cycle" then
                                    vb.views.formula_string.value = "(x % 1) < 0.5 and 1 or 0"
                                elseif items[choice] == "Half Cycle" then
                                    vb.views.formula_string.value = "1 - (x % 1)"
                                elseif items[choice] == "Cosinus Cycle" then
                                    vb.views.formula_string.value = "(1 + cos(x * pi))/ 2"
                                elseif items[choice] == "Sinus Cycle" then
                                    vb.views.formula_string.value = "(1 + sin(x * pi ))/ 2"
                                elseif items[choice] == "Many Cycles" then
                                    vb.views.formula_string.value = "(1 + cos(x * (2 * 16 + 1) * pi))/ 2"
                                elseif items[choice] == "Helix" then
                                    vb.views.formula_string.value = "(1 + cos(x * (2 * 32000 + 1) * pi))/ 2"
                                end
                            end
                    },
                },

                vb:textfield
                {
                    id = "formula_string",
                    width = "100%",
                    height = 1.5 * control_height,
                    text = ps.formula_string,
                    tooltip = formula_documentation,
                    notifier =
                        function()
                            self:apply_formula()
                        end,
                }, 

                vb:text
                {
                    id = "formula_error",
                    width = "100%",
                    text = "",
                    style = "strong",
                },   
            },

            vb:horizontal_aligner
            {
                width = 0.25 * full_width,
                mode = "justify",
                margin = control_margin,
                spacing = dialog_spacing,

                vb:column
                {
                    vb:text
                    {
                        text = "Curvature"
                    },
                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:rotary
                        {
                            id = "formula_curvature",
                            min = -1,
                            max = 1,
                            value = ps.formula_curvature,
                            notifier = function() self:apply_formula() end,
                        },
                    },
                },

                vb:column
                {
                    vb:text
                    {
                        text = "Curve Torsion"
                    },
                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:rotary
                        {
                            id = "formula_torsion",
                            min = -1,
                            max = 1,
                            value = ps.formula_torsion,
                            notifier = function() self:apply_formula() end,
                        },
                    },
                },

                vb:column
                {
                    vb:text
                    {
                        text = "Curve Shape"
                    },
                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:rotary
                        {
                            id = "formula_shape",
                            min = -1,
                            max = 1,
                            value = ps.formula_shape,
                            notifier = function() self:apply_formula() end,
                        },
                    },
                },

                vb:column
                {
                    vb:text
                    {
                        text = "X Axis Scale"
                    },
                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:rotary
                        {
                            id = "formula_length",
                            min = -249,
                            max = 0,
                            value = ps.formula_length,
                            notifier = function() self:apply_formula() end,
                        },
                    },
                    tooltip = "Scale the X axis\n(works only for formulas based on the x variable)",
                },
            },
        }, -- Formula


        -- Harmonics ---------------------------------------------------------------------------------------------------------------------------------

        vb:column
        {
            width = full_width,
            margin = control_margin,
            spacing = 0,
            style = "group",

            vb:horizontal_aligner
            {
                margin = 0,
                spacing = control_spacing,
                mode = "justify",

                vb:row
                {

                    vb:button
                    {
                        text = "  Reset All Overtones ",
                        notifier =
                            function()
                                for i = 1, 256 do
                                    self.harmonics[i] = 1
                                end
                                self:update_harmonics_sliders()
                            end
                    },

                    vb:space
                    {
                        width = 4 * control_spacing,
                    },

                    vb:button
                    {
                        text = " Some Overtones ",
                        notifier =
                            function()
                                self.harmonics[1] = 1
                                for i = 2, 256 do
                                    self.harmonics[i] = math.random(0, 1)
                                end
                                self:update_harmonics_sliders()
                            end
                    },

                    vb:button
                    {
                        text = " Random Values ",
                        notifier =
                            function()
                                for i = 1, 256 do
                                    self.harmonics[i] = math.random()
                                end
                                self:update_harmonics_sliders()
                            end
                    },

                    vb:space
                    {
                        width = 4 * control_spacing,
                    },

                    vb:button
                    {
                        text = " Random Ramp ",
                        notifier =
                            function()
                                local curvature = 2 * math.random() - 1
                                local torsion = 2 * math.random() - 1
                                local shape = 2 * math.random() - 1
                                for i = 1, 256 do
                                    local x = (256 - i)/(256 - 1)
                                    x = clamp(curve(x, shape, torsion, curvature), 0, 1)
                                    self.harmonics[i] = clamp(curve(x, shape, torsion, curvature), 0, 1)
                                end
                                self:update_harmonics_sliders()
                            end
                    },

                    vb:button
                    {
                        text = " Chaotic Ramps ",
                        notifier =
                            function()
                                for j = 0, 15 do
                                    local start_value = math.random()
                                    local end_value = math.random()
                                    for k = 1, 16 do
                                        local i = j * 16 + k
                                        local x = (16 - k)/(16 - 1)
                                        self.harmonics[i] = start_value * x + end_value * (1 - x)
                                    end
                                end
                                self:update_harmonics_sliders()
                            end
                    },

                    vb:space
                    {
                        width = 4 * control_spacing,
                    },

                    vb:button
                    {
                        text = " Chaotic Curve ",
                        notifier =
                            function()
                                local start_value = math.random()
                                local end_value = start_value
                                for j = 0, 31 do
                                    start_value = end_value
                                    end_value = math.random()
                                    local curvature = 2 * math.random() - 1
                                    local torsion = 2 * math.random() - 1
                                    local shape = 2 * math.random() - 1
                                    for k = 1, 8 do
                                        local i = j * 8 + k
                                        local x = (8 - k)/(8 - 1)
                                        x = clamp(curve(x, shape, torsion, curvature), 0, 1)
                                        x = clamp(curve(x, shape, torsion, curvature), 0, 1)
                                        self.harmonics[i] = start_value * x + end_value * (1 - x)
                                    end
                                end
                                self:update_harmonics_sliders()
                            end
                    },

                    vb:button
                    {
                        text = " Smooth Curve ",
                        notifier =
                            function()
                                local start_value = math.random()
                                local end_value = start_value
                                for j = 0, 15 do
                                    start_value = end_value
                                    end_value = clamp(end_value - 0.2 + 0.4 * math.random(), 0, 1)
                                    for k = 1, 16 do
                                        local i = j * 16 + k
                                        local x = (16 - k)/(16 - 1)
                                        x = clamp(curve(x, -1, 0, 0.5), 0, 1)
                                        self.harmonics[i] = start_value * x + end_value * (1 - x)
                                    end
                                end
                                self:update_harmonics_sliders()
                            end
                    },
                },

                vb:row
                {

                },

                vb:switch
                {
                    id = "harmonics_page",
                    items = { "1 - 64", "65 - 128", "129 - 192", "193 - 256" },
                    width = 300,
                    notifier = function () self:update_harmonics_sliders () end,
                },

            },

            vb:horizontal_aligner
            {
                id = "harmonics_group",
                mode = "distribute",
                spacing = 0,
            },

            vb:horizontal_aligner
            {
                margin = 0,
                spacing = control_spacing,
                mode = "left",


                vb:button
                {
                    text = " Clear Even ",
                    notifier =
                        function()
                            for i = 1, 256 do
                                local y = i % 2 == 1 and 1 or 0
                                self.harmonics[i] = self.harmonics[i] * y
                            end
                            self:update_harmonics_sliders()
                        end
                },

                vb:button
                {
                    text = " Clear Some ",
                    notifier =
                        function()
                            for i = 2, 256 do
                                local dice = math.random() < 0.25 and 0 or 1
                                self.harmonics[i] = dice * self.harmonics[i]
                            end
                            self:update_harmonics_sliders()
                        end
                },

                vb:space
                {
                    width = 4 * control_spacing,
                },

                vb:button
                {
                    text = " * Random ",
                    notifier =
                        function()
                            for i = 1, 256 do
                                self.harmonics[i] = self.harmonics[i] * math.random()
                            end
                            self:update_harmonics_sliders()
                        end
                },

                vb:button
                {
                    text = " + Random ",
                    notifier =
                        function()
                            for i = 1, 256 do
                                self.harmonics[i] = clamp(self.harmonics[i] + 0.25 * math.random(), 0, 1)
                            end
                            self:update_harmonics_sliders()
                        end
                },

                vb:button
                {
                    text = " - Random ",
                    notifier =
                        function()
                            for i = 1, 256 do
                                self.harmonics[i] = clamp(self.harmonics[i] - 0.25 * math.random(), 0, 1)
                            end
                            self:update_harmonics_sliders()
                        end
                },

                vb:space
                {
                    width = 4 * control_spacing,
                },

                vb:button
                {
                    text = " Amplify ",
                    notifier =
                        function()
                            for i = 1, 256 do
                                self.harmonics[i] = math.sqrt(self.harmonics[i])
                            end
                            self:update_harmonics_sliders()
                        end
                },

                vb:button
                {
                    text = " Reduce ",
                    notifier =
                        function()
                            for i = 1, 256 do
                                self.harmonics[i] = self.harmonics[i] * self.harmonics[i]
                            end
                            self:update_harmonics_sliders()
                        end
                },

                vb:button
                {
                    text = " Exagerate ",
                    notifier =
                        function()
                            for i = 1, 256 do
                                if self.harmonics[i] <= 0.5 then
                                    self.harmonics[i] = self.harmonics[i] * self.harmonics[i]
                                else
                                    self.harmonics[i] = math.sqrt(self.harmonics[i])
                                end
                            end
                            self:update_harmonics_sliders()
                        end
                },

                vb:space
                {
                    width = 4 * control_spacing,
                },

                vb:button
                {
                    text = " Invert ",
                    notifier =
                        function()
                            for i = 1, 256 do
                                self.harmonics[i] = 1 - self.harmonics[i]
                            end
                            self:update_harmonics_sliders()
                        end
                },

                vb:button
                {
                    text = " Reverse ",
                    notifier =
                        function()
                            local h = {}
                            for i = 1, 256 do
                                h[i] = self.harmonics[i]
                            end
                            for i = 1, 256 do
                                self.harmonics[i] = h[256 - i + 1]
                            end
                            self:update_harmonics_sliders()
                        end
                },
        },
        }, -- Harmonics


        -- Output ---------------------------------------------------------------------------------------------------------------------------------

        vb:column
        {
            width = full_width,
            margin = 0,
            spacing = 0,
            style = "invisible",
            vb:horizontal_aligner
            {
                mode = "justify",
                height = 104,
                spacing = control_spacing,
                margin = 0,
                vb:row
                {
                    id = "output_group",
                    style = "border",
                    spacing = 0,
                    margin = 0,
                    height = 104,
                },
                vb:vertical_aligner
                {
                    mode = "center",
                    margin = 0,
                    spacing = 0,
                    vb:column
                    {
                        style = "group",
                        margin = control_margin,
                        spacing = control_spacing,
                        width = 200,
                        uniform = true,
                        vb:button
                        {
                            width = "100%",
                            text = " Send to Formula ",
                            notifier =
                                function ()
                                    local formula = "(function() local h = {"
                                    for i = 1, 256 do
                                        formula = formula .. "[" .. i .. "]=" .. self.harmonics_output[i] .. ","
                                    end
                                    formula = formula .. "}; return h[i] end)()"
                                    vb.views.formula_string.value = formula
                                    for i = 1, 256 do
                                        self.harmonics[i] = 1
                                    end
                                    vb.views.formula_curvature.value = 0
                                    vb.views.formula_torsion.value = 0
                                    vb.views.formula_shape.value = 0
                                    vb.views.formula_length.value = 0
                                    self:update_harmonics_sliders()
                                end
                        },
                        vb:button
                        {
                            width = "100%",
                            text = " Send to Sliders ",
                            notifier =
                                function()
                                    for i = 1, 256 do
                                        self.harmonics[i] = self.harmonics_output[i]
                                    end
                                    vb.views.formula_string.value = "1"
                                    vb.views.formula_curvature.value = 0
                                    vb.views.formula_torsion.value = 0
                                    vb.views.formula_shape.value = 0
                                    vb.views.formula_length.value = 0
                                    self:update_harmonics_sliders()
                                end
                        },
                    },
                },
            },
        }, -- Output


        -- Status ---------------------------------------------------------------------------------------------------------------------------------

        vb:column
        {
            width = full_width,
            margin = control_margin,
            spacing = 0,
            vb:horizontal_aligner
            {
                mode = "distribute",
                margin = 0,
                spacing = control_margin,
                height = 26,
                width = "100%",

                vb:column
                {
                    style = "invisible",
                    width = 800,
                    height = "100%",
                    uniform = true,
                    margin = 2,
                    vb:column
                    {
                        style = "invisible",
                        width = "100%",
                        vb:text { id = "status", text = "PadSynth Opened", height = 24, },
                    },
                },

                vb:button
                {
                    id = "do_generate_test",
                    width = 150,
                    height = 26,
                    text = "Generate Test Note",
                },

                vb:bitmap
                {
                    id = "progress_bitmap",
                    bitmap = "data/progress-empty.png",
                    mode = "transparent",
                },

                vb:button
                {
                    id = "do_generate",
                    width = 200,
                    height = "100%",
                    text = "Generate All Samples",
                },
            },
        }, -- Status
    }

    -----------------------------------------------------------------------------------------------------------------------------------------------

    for i = 1, 64 do
        vb.views.harmonics_group:add_child (
            vb:column
            {
                width = 16,
                margin = 0,
                spacing = 0,
                vb:minislider
                {
                    width = 16,
                    id = "H" .. i,
                    height = 150,
                    min = 0, max = 1, value = 0,
                    notifier = function ()
                        local offsets = { 0, 64, 128, 192 }
                        local offset = offsets[self.vb.views.harmonics_page.value]
                        local v = vb.views["H" .. i].value
                        self.harmonics[i + offset] = v
                        self:apply_formula()
                        vb.views.status.text = "Overtone " .. i + offset .. " set to " .. string.format ("%.1f %%", 100 * v)
                    end
                },
            } 
        )
    end

    vb.views.output_group:add_child(
        vb:space{
            width = 2,
            height = 156,
        }
    )
    for i = 1, 256 do
        local y = (256 - i)/255
        local h = 100
        local yy = math.floor(y * h + 0.5)
        vb.views.output_group:add_child(
            vb:column
            {
                vb:space{
                    id = "output_above_" .. i,
                    width = 4,
                    height = 1,
                },
                vb:bitmap
                {
                    width = 4,
                    height = 4,
                    bitmap = "data/pixel.png",
                    mode = "body_color",
                },
                vb:space{
                    id = "output_below_" .. i,
                    width = 4,
                    height = 1,
                },
            }
        )
    end
    vb.views.output_group:add_child(
        vb:space{
            width = 2,
            height = 156,
        }
    )

    self:update_harmonics_sliders ()
    self:apply_formula ()

    overtones_placement_notifier ()
    on_unison_multiplier_changed ()
    vb.views.do_generate:add_released_notifier (self, PadSynthWindow.generate_samples)
    vb.views.do_generate_test:add_released_notifier (self, PadSynthWindow.generate_test_note)

    status = vb.views.status

    return result

end


----------------------------------------------------------------------------------------------------

function PadSynthWindow:apply_formula ()
    local vb = self.vb

    vb.views.formula_error.text = ""
    local formula, err = loadstring("return " .. vb.views.formula_string.value)
    if formula == nil then
        vb.views.formula_error.text = "ERROR: " .. err
        return
    end
    setfenv(formula, formula_context)
    local length = vb.views.formula_length.value + 255
    for i = 1, 256 do
        formula_context.i = i
        formula_context.x = (i - 1) / length
        local status, val = xpcall(formula,
            function(err)
                vb.views.formula_error.text = "ERROR: " .. err
            end
        )
        if status and type(val) ~= "number" then
            vb.views.formula_error.text = "ERROR: The formula returns " .. type(val) .. " instead of a number"
            return
        end
        if status then
            val = curve(val, vb.views.formula_shape.value, vb.views.formula_torsion.value, vb.views.formula_curvature.value)
            val = curve(val, vb.views.formula_shape.value, vb.views.formula_torsion.value, vb.views.formula_curvature.value)
            self.harmonics_output[i] = self.harmonics[i] * clamp(val, 0.0, 1.0)
        end
    end
    self:update_harmonics_output_display ()
end


----------------------------------------------------------------------------------------------------


function PadSynthWindow:update_harmonics_sliders ()

    local offsets = { 0, 64, 128, 192 }
    local offset = offsets[self.vb.views.harmonics_page.value]

    for i = 1, 64 do
        self.vb.views["H" .. i].value = self.harmonics[i + offset]
        self.vb.views["H" .. i].tooltip = "Overtone " .. (i + offset) .. " = " ..  string.format ("%.1f %%", 100 * self.harmonics[i + offset])
    end
end

function PadSynthWindow:update_harmonics_output_display ()

    local maximum = 0
    for i = 1, 256 do
        if self.harmonics_output[i] > maximum then
            maximum = self.harmonics_output[i]
        end
    end

    for i = 1, 256 do
        local y = clamp(self.harmonics_output[i] / maximum, 0, 1)
        local h = 150
        local yy = math.floor(y * h + 0.5)
        self.vb.views["output_above_" .. i].height = 1 + h - yy
    end

end


----------------------------------------------------------------------------------------------------
