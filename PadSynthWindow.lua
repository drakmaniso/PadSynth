class "PadSynthWindow"

local status = nil

----------------------------------------------------------------------------------------------------


function PadSynthWindow:__init (pad_synth)

    self.vb = renoise.ViewBuilder ()

    self.pad_synth = pad_synth

    self.harmonics = {}
    for i = 1, 256 do self.harmonics[i] = 0 end
    for i, v in ipairs (pad_synth.harmonics) do
        self.harmonics[i] = v
    end

end


----------------------------------------------------------------------------------------------------


function PadSynthWindow:show_dialog ()

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


function PadSynthWindow:update_parameters ()

    local views = self.vb.views

    self.pad_synth.volume = views.volume.value
    self.pad_synth.sample_duration = views.duration.value
    self.pad_synth.nb_channels = views.nb_channels.value

    self.pad_synth.autofade = views.autofade.value
    self.pad_synth.new_note_action = views.new_note_action.value
    self.pad_synth.interpolation = views.interpolation.value
    self.pad_synth.oversample_enabled = views.oversample_enabled.value

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
    self.pad_synth.test_sample_rate = self.sample_rate_values[views.test_sample_rate.value]
    self.pad_synth.test_duration = views.test_duration.value

    self.pad_synth.base_function = views.base_function.value

    self.pad_synth.harmonics = { }
    for i = 1, 256 do
        self.pad_synth.harmonics[i] = self.harmonics[i] -- lin_to_ln (views["H" .. i].value)
    end

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

    local test_sample_rate = 1
    if     ps.test_sample_rate == 11025 then test_sample_rate = 1
    elseif ps.test_sample_rate == 22050 then test_sample_rate = 2
    elseif ps.test_sample_rate == 32000 then test_sample_rate = 3
    elseif ps.test_sample_rate == 44100 then test_sample_rate = 4
    elseif ps.test_sample_rate == 48000 then test_sample_rate = 5
    elseif ps.test_sample_rate == 88200 then test_sample_rate = 6
    elseif ps.test_sample_rate == 96000 then test_sample_rate = 7
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

    local result = vb:column
    {
        style = "body",
        margin = dialog_margin,
        spacing = dialog_spacing,
        uniform = true,

        vb:horizontal_aligner
        {
            spacing = dialog_spacing,
            mode = "justify",


            vb:row
            {
                style = "group",
                margin = control_margin,
                spacing = dialog_spacing,
                height = "100%",



                vb:column
                {


                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:text { font = "bold", text = "Global" },
                    },

                    vb:horizontal_aligner
                    {
                        mode = "distribute",

                        vb:column
                        {
                            uniform = true,
                            vb:horizontal_aligner
                            {
                                mode = "center",
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
                            vb:text { text = "Volume", align= "center", },
                        },

                        vb:column
                        {
                            uniform = true,
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
                            vb:text { text = "Duration", align= "center", },
                            tooltip = "Length of the wavetable",
                        },

                    },

                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:switch { id = "nb_channels", items = { "Mono", "Stereo", }, value = ps.nb_channels, width = 100, },
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


            vb:row
            {
                height = "100%",
                spacing = dialog_spacing,

                -- Spread --------------------------------------------------------------------------------------------------------------------------------

                vb:column
                {
                    style = "group",
                    margin = control_margin,
                    spacing = control_spacing,
                    height = "100%",


                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:text { font = "bold", text = "Spread" },
                    },

                    vb:horizontal_aligner
                    {
                        mode = "distribute",

                        vb:column
                        {
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
                            vb:text { text = "Bandwidth", align = "center", },
                            tooltip = 'Controls how much each harmonic is "spread"\naround its frequency'
                        },

                        vb:column
                        {
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
                            vb:text { text = "Growth", align = "center", width = 60, },
                            tooltip = 'Controls the increase in bandwidth\nfor higher frequencies',
                        },

                    },

                },


                -- Overtones -----------------------------------------------------------------------------------------------------------------------------

                vb:column
                {
                    style = "group",
                    margin = control_margin,
                    spacing = control_spacing,
                    height = "100%",


                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:text { font = "bold", text = "Placement" },
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
                            active=false},
                            vb:text { id = "param1_label", text = "-", align = "center", width = 60, },
                        visible = false},


                        vb:column
                        {
                            vb:horizontal_aligner
                            {
                                mode = "center",
                                vb:rotary
                                {
                                    id = "param2_rotary", value = ps.overtones_param2, min = 0, max = 1,
                                    notifier = function () vb.views.param2.value = vb.views.param2_rotary.value end,
                                active=false},
                            },
                            vb:valuefield
                            {
                                id = "param2", value = ps.overtones_param2, min = 0, max = 1, align = "center",
                                notifier = function () vb.views.param2_rotary.value = vb.views.param2.value end,
                            active=false},
                            vb:text { id = "param2_label", text = "-", align = "center", width = 60, },
                        visible = false},


                        vb:column
                        {
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
                            vb:text { id = "overtones_treshold_label", text = "-", align = "center", width = 60, },
                            tooltip = "Treshold: define at which harmonic start the placement method\nPeriod: for the Waved placement, define the length of the waves"
                        },


                        vb:column
                        {
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
                            vb:text { id = "overtones_amount_label", text = "-", align = "center", width = 60, },
                            tooltip = "Define how much deformation is applied to the placement",
                        },


                        vb:column
                        {
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
                            vb:text { id = "overtones_harmonize_label", text = "-", align = "center", width = 60, },
                            tooltip = "Shift overtones toward harmonic positions",
                        },

                    },

                },

            },


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

            },


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

                vb:text { text = "Key Range", font = "bold", width = "100%", align = "center", },

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
                    vb:text { text = "Step", width = 80, },
                    vb:valuebox { id = "keyzones_step", value = ps.keyzones_step, min = 1, max = 12, },
                },

            },


            -- Test Note --------------------------------------------------------------------------------------------------------------------------

            vb:column
            {
                style = "group",
                margin = control_margin,
                spacing = control_spacing,
                height = "100%",

                vb:text { text = "Test Note", font = "bold", width = "100%", align = "center", },

                vb:row
                {
                    id = "test_note_group1",
                    visible = true,
                    vb:text { text = "Note", width = 80, },
                    vb:valuebox { id = "test_note", value = ps.test_note, min = 0, max = 119, tostring = to_note_string, tonumber = to_note_number, },
                },

                vb:row
                {
                    vb:text { text = "Sample Rate", width = 80, },
                    vb:popup { id = "test_sample_rate", items = self.sample_rate_names, value = test_sample_rate, },
                },

                vb:row
                {
                    id = "test_note_group2",
                    visible = true,
                    vb:text { text = "Test Duration", width = 80, },
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

                vb:horizontal_aligner
                {
                    mode = "center",
                    vb:button
                    {
                        id = "do_generate_test",
                        width = 150,
                        height = 26,
                        text = "Generate Test Note",
                    },
                },

            },


        },


        -- Harmonics ---------------------------------------------------------------------------------------------------------------------------------

        vb:column
        {
            style = "group",
            margin = control_margin,
            spacing = control_spacing,


            vb:horizontal_aligner
            {
                spacing = dialog_spacing,
                mode = "justify",

                vb: row
                {
                    vb:text { text = "Base function", },

                    vb:popup
                    {
                        id = "base_function",
                        items = { "Sine", "Saw", "Square", "Soft Saw", "Triangle", "Circle" },
                        value = ps.base_function,
                    },
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
            },

            vb:horizontal_aligner
            {
                mode = "justify",

                vb:row
                {
                    spacing = dialog_spacing,

                    vb:button
                    {
                        text = "Clear",
                        notifier = function ()
                            for i = 1, 256 do
                                self.harmonics[i] = 0
                            end
                            self:update_harmonics_sliders ()
                        end
                    },

                    vb:button
                    {
                        text = "+ Saw",
                        notifier = function ()
                            for i = 1, 256 do
                                local h = self.harmonics[i]
                                h = h + 1 / i
                                if h > 1 then h = 1 end
                                self.harmonics[i] = h
                            end
                            self:update_harmonics_sliders ()
                        end
                    },

                    vb:button
                    {
                        text = "- Saw",
                        notifier = function ()
                            for i = 1, 64 do
                                local h = lin_to_ln (vb.views["H" .. i].value)
                                h = h - 1 / i
                                if h < 0 then h = 0 end
                                vb.views["H" .. i].value = ln_to_lin (h)
                            end
                        end
                    },

                    vb:button
                    {
                        text = "+ Square",
                        notifier = function ()
                            for i = 1, 64 do
                                local h = lin_to_ln (vb.views["H" .. i].value)
                                if i % 2 ~= 0 then
                                    h = h + 1 / i
                                end
                                if h > 1 then h = 1 end
                                vb.views["H" .. i].value = ln_to_lin (h)
                            end
                        end
                    },

                    vb:button
                    {
                        text = "- Square",
                        notifier = function ()
                            for i = 1, 64 do
                                local h = lin_to_ln (vb.views["H" .. i].value)
                                if i % 2 ~= 0 then
                                    h = h - 1 / i
                                end
                                if h < 0 then h = 0 end
                                vb.views["H" .. i].value = ln_to_lin (h)
                            end
                        end
                    },

                    vb:button
                    {
                        text = "+ Soft Saw",
                        notifier = function ()
                            for i = 1, 64 do
                                local h = lin_to_ln (vb.views["H" .. i].value)
                                h = h + 1 / (i * i)
                                if h > 1 then h = 1 end
                                vb.views["H" .. i].value = ln_to_lin (h)
                            end
                        end
                    },

                    vb:button
                    {
                        text = "- Soft Saw",
                        notifier = function ()
                            for i = 1, 64 do
                                local h = lin_to_ln (vb.views["H" .. i].value)
                                h = h - 1 / (i * i)
                                if h < 0 then h = 0 end
                                vb.views["H" .. i].value = ln_to_lin (h)
                            end
                        end
                    },

                    vb:button
                    {
                        text = "+ Triangle",
                        notifier = function ()
                            for i = 1, 64 do
                                local h = lin_to_ln ((vb.views["H" .. i].value))
                                if i % 2 ~= 0 then
                                    h = h + 1 / (i * i)
                                end
                                if h > 1 then h = 1 end
                                vb.views["H" .. i].value = ln_to_lin (h)
                            end
                        end
                    },

                    vb:button
                    {
                        text = "- Triangle",
                        notifier = function ()
                            for i = 1, 64 do
                                local h = lin_to_ln ((vb.views["H" .. i].value))
                                if i % 2 ~= 0 then
                                    h = h - 1 / (i * i)
                                end
                                if h < 0 then h = 0 end
                                vb.views["H" .. i].value = ln_to_lin (h)
                            end
                        end
                    },

                    vb:button
                    {
                        text = "+ Circle",
                        notifier = function ()
                            for i = 1, 64 do
                                local h = lin_to_ln (vb.views["H" .. i].value)
                                if i <= 8 then
                                    h = h + math.cos ((i / 8) * math.pi / 2)
                                end
                                if h > 1 then h = 1 end
                                vb.views["H" .. i].value = ln_to_lin (h)
                            end
                        end
                    },

                    vb:button
                    {
                        text = "- Circle",
                        notifier = function ()
                            for i = 1, 64 do
                                local h = lin_to_ln (vb.views["H" .. i].value)
                                if i <= 8 then
                                    h = h - math.cos ((i / 8) * math.pi / 2)
                                end
                                if h < 0 then h = 0 end
                                vb.views["H" .. i].value = ln_to_lin (h)
                            end
                        end
                    },

                    vb:button
                    {
                        text = "<< Shift",
                        notifier = function ()
                            for i = 2, 256 do
                                self.harmonics[i - 1] = self.harmonics[i]
                            end
                            self.harmonics[256] = 0
                            self:update_harmonics_sliders ()
                        end
                    },

                    vb:button
                    {
                        text = "Shift >>",
                        notifier = function ()
                            for i = 256, 2, -1 do
                                self.harmonics[i] = self.harmonics[i - 1]
                            end
                            self.harmonics[1] = 0
                            self:update_harmonics_sliders ()
                        end
                    },


                },

                vb:row
                {
                    spacing = control_spacing,

                    vb:text { text = "Modify" },

                    vb:popup
                    {
                        id = "modify_function",
                        items = { "Set", "Add", "Sub", "Multiply", "Divide" },
                        width = 60,
                    },

                    vb:valuefield
                    {
                        id = "modify_value",
                        align = "right",
                        min = 0, max = 100,
                        value = 2,
                        width = 40,
                        tonumber = tonumber,
                        tostring = tostring,
                    },

                    vb:button
                    {
                        text = "Apply",
                        notifier = function ()

                            local func = vb.views.modify_function.value
                            local value = vb.views.modify_value.value

                            if func == 1 then
                                for i = 1, 256 do
                                    self.harmonics[i] = value / 100
                                end
                            elseif func == 2 then
                                for i = 1, 256 do
                                    self.harmonics[i] = self.harmonics[i] + value / 100
                                    if self.harmonics[i] > 1 then self.harmonics[i] = 1 end
                                end
                            elseif func == 3 then
                                for i = 1, 256 do
                                    self.harmonics[i] = self.harmonics[i] - value / 100
                                    if self.harmonics[i] < 0 then self.harmonics[i] = 0 end
                                end
                            elseif func == 4 then
                                for i = 1, 256 do
                                    self.harmonics[i] = self.harmonics[i] * value
                                    if self.harmonics[i] > 1 then self.harmonics[i] = 1 end
                                end
                            elseif func == 5 then
                                for i = 1, 256 do
                                    self.harmonics[i] = self.harmonics[i] / value
                                    if self.harmonics[i] < 0 then self.harmonics[i] = 0 end
                                end
                            end

                            self:update_harmonics_sliders ()

                        end,
                    },
                },

            },
        },


        vb:horizontal_aligner
        {
            mode = "justify",
            height = 26,

            vb:column
            {
                style = "group",
                width = 800,
                height = "100%",
                uniform = true,
                margin = 2,
                vb:column
                {
                    style = "plain",
                    width = "100%",
                    vb:text { id = "status", text = "PadSynth Opened", height = 24, },
                },
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

    }

    for i = 1, 64 do
        vb.views.harmonics_group:add_child (vb:column
                {
                    uniform = true,
                    width = 12,
                    spacing = 0,
                    vb:text { id = "harmonic_label_top_" .. i, text = tostring(i), width = 16, align = "center" },
                    vb:horizontal_aligner
                    {
                        mode = "center",
                        margin = 0,
                        spacing = 0,
                        vb:minislider
                        {
                            id = "H" .. i,
                            width = 16, height = 300,
                            min = 0, max = 1, value = 0,
                            notifier = function ()
                                local offsets = { 0, 64, 128, 192 }
                                local offset = offsets[self.vb.views.harmonics_page.value]
                                local v = lin_to_ln (vb.views["H" .. i].value)
                                self.harmonics[i + offset] = v
                                vb.views.status.text = "Harmonic " .. i + offset .. " set to " .. string.format ("%.1f %%", 100 * v)
                            end
                        },
                    },
                    vb:text { id = "harmonic_label_bottom_" .. i, text = tostring(i), width = 16, align = "center" },
                } )
    end
    self:update_harmonics_sliders ()

    overtones_placement_notifier ()
    on_unison_multiplier_changed ()
    vb.views.do_generate:add_released_notifier (self, PadSynthWindow.generate_samples)
    vb.views.do_generate_test:add_released_notifier (self, PadSynthWindow.generate_test_note)

    status = vb.views.status

    return result

end


----------------------------------------------------------------------------------------------------


function PadSynthWindow:update_harmonics_sliders ()

    local offsets = { 0, 64, 128, 192 }
    local offset = offsets[self.vb.views.harmonics_page.value]

    for i = 1, 64 do
        self.vb.views["H" .. i].value = ln_to_lin (self.harmonics[i + offset])
        if i + offset < 100 then
            self.vb.views["harmonic_label_top_" .. i].text = string.format ("%d", i + offset)
            self.vb.views["harmonic_label_bottom_" .. i].text = string.format ("%d", i + offset)
        else
            self.vb.views["harmonic_label_top_" .. i].text = "-"
            self.vb.views["harmonic_label_bottom_" .. i].text = "-"
        end
    end

end


----------------------------------------------------------------------------------------------------
