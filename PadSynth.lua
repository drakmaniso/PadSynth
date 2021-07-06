class "PadSynth"

require "PadSynthWindow"

complex = require "complex"
luafft = require "luafft"

require "utils"


----------------------------------------------------------------------------------------------------


function PadSynth:__init (instrument)

    self.instrument = instrument

    if
        instrument.name == ""
        and #self.instrument.samples == 0
    then
        self.instrument.name = "[PadSynth]"
    end

    self:load_parameters ()

    self.window = PadSynthWindow (self)

    self.window:show_dialog ()

end


----------------------------------------------------------------------------------------------------


function PadSynth:generate_samples ()

    -- Delete the samples previously generated

    local i = 1
    while i <= #self.instrument.samples do
        if string.sub (self.instrument:sample(i).name, 1, 13) == "PadSynth Note" then
            self.instrument:delete_sample_at (i)
        else
            i = i + 1
        end
    end

    self:save_parameters ()

    self:prepare_harmonics ()

    -- Generate the samples

    if self.is_test_note then
        self.sample_duration = self.test_duration
        self.sample_rate = self.test_sample_rate
        self:generate_one_sample (self.test_note, 0, 119, true)
        return
    end

    local first_note = self.first_note
    local last_note = self.last_note
    if first_note > last_note then
        first_note, last_note = last_note, first_note
    end

    local note = first_note
    local range_start, range_end

    repeat

        in_progress_yield ()
        if note == first_note then
            range_start = 0
        else
            range_start = note
        end
        if note + self.keyzones_step > last_note then
            range_end = 119
        else
            range_end = note + self.keyzones_step - 1
        end
        self:generate_one_sample (note, range_start, range_end, false)
        note = note + self.keyzones_step

    until note > last_note

end


----------------------------------------------------------------------------------------------------


function PadSynth:prepare_harmonics ()

    if self.base_function == 1 then

        self.prepared_harmonics = self.harmonics

    elseif self.base_function == 2 then

        -- Saw
        self.prepared_harmonics = { }
        for i = 1, 256 do
            self.prepared_harmonics[i] = 0
        end
        for i, v in ipairs (self.harmonics) do
            if v > 0 then
                for j = 1, 256 do
                    if i * j <= 256 then
                        local h = self.prepared_harmonics[i * j]
                        h = h + v / j
                        self.prepared_harmonics[i * j] = h
                    end
                end
            end
        end

    elseif self.base_function == 3 then

        -- Square
        self.prepared_harmonics = { }
        for i = 1, 256 do
            self.prepared_harmonics[i] = 0
        end
        for i, v in ipairs (self.harmonics) do
            if v > 0 then
                for j = 1, 256 do
                    if i * j <= 256 then
                        local h = self.prepared_harmonics[i * j]
                        if j % 2 ~= 0 then
                            h = h + v / j
                        end
                        self.prepared_harmonics[i * j] = h
                    end
                end
            end
        end

    elseif self.base_function == 4 then

        -- Soft Saw
        self.prepared_harmonics = { }
        for i = 1, 256 do
            self.prepared_harmonics[i] = 0
        end
        for i, v in ipairs (self.harmonics) do
            if v > 0 then
                for j = 1, 256 do
                    if i * j <= 256 then
                        local h = self.prepared_harmonics[i * j]
                        h = h + v / (j * j)
                        self.prepared_harmonics[i * j] = h
                    end
                end
            end
        end

    elseif self.base_function == 5 then

        -- Triangle
        self.prepared_harmonics = { }
        for i = 1, 256 do
            self.prepared_harmonics[i] = 0
        end
        for i, v in ipairs (self.harmonics) do
            if v > 0 then
                for j = 1, 256 do
                    if i * j <= 256 then
                        local h = self.prepared_harmonics[i * j]
                        if j % 2 ~= 0 then
                            h = h + v / (j * j)
                        end
                        self.prepared_harmonics[i * j] = h
                    end
                end
            end
        end

    elseif self.base_function == 6 then

        -- Circle
        self.prepared_harmonics = { }
        for i = 1, 256 do
            self.prepared_harmonics[i] = 0
        end
        for i, v in ipairs (self.harmonics) do
            if v > 0 then
                for j = 1, 256 do
                    if i * j <= 256 then
                        local h = self.prepared_harmonics[i * j]
                        if j <= 8 then
                            h = h + v * math.cos ((j / 8) * math.pi / 2)
                        end
                        self.prepared_harmonics[i * j] = h
                    end
                end
            end
        end

    else

        self.prepared_harmonics = self.harmonics

    end

    -- Normalize
    if self.base_function ~= 1 then
        local ampl_max = 0
        for i = 1, 256 do
            if self.prepared_harmonics[i] > ampl_max then
                ampl_max = self.prepared_harmonics[i]
            end
        end
        for i = 1, 256 do
            self.prepared_harmonics[i] = self.prepared_harmonics[i] / ampl_max
        end
    end

end


----------------------------------------------------------------------------------------------------


PadSynth.overtones_placement_functions =
{
    -- Harmonic
    function (self, n)
        return n
    end,

    -- Multplied
    function (self, n)
        local treshold = self.overtones_treshold
        if n < treshold then
            return n
        end
        local param = self.overtones_amount
        if param < 0 then
            param = to_display (param + 1)
        else
            param = 1 + math.pow (10, - (1 - param) * 3) * 8
        end
        local n0 = n - 1
        local t0 = treshold - 1
        local result = 1 + t0 + (n0 - t0) * param
        local result_int = math.floor (result + 0.5)
        local result_dec = result - result_int
        return result_int + (1 - self.overtones_harmonize) * result_dec
    end,

    -- Powered
    function (self, n)
        local treshold = self.overtones_treshold
        if n < treshold then
            return n
        end
        local param = self.overtones_amount
        if param < 0 then
            param = to_display (param + 1)
        else
            param = 1 + from_display (param)
        end
        local n0 = n - 1
        local t0 = treshold - 1
        local result = 1 + t0 + math.pow (n0 - t0, param)
        local result_int = math.floor (result + 0.5)
        local result_dec = result - result_int
        return result_int + (1 - self.overtones_harmonize) * result_dec
    end,

    -- Waved
    function (self, n)
        if n == 1 then
            return n
        end
        local period = math.floor (self.overtones_treshold)
        local param = self.overtones_amount
        --~ if param < 0 then
            --~ param = to_display (param + 1)
        --~ else
            --~ param = 1 + from_display (param)
        --~ end
        local n0 = n - 1
        local result = n0 + 1 + math.sin (((n % period) / period) * 2 * math.pi) * (period / 4) * param
        local result_int = math.floor (result + 0.5)
        local result_dec = result - result_int
        return result_int + (1 - self.overtones_harmonize) * result_dec
    end,

    -- Shift Higher
    function (self, n)
        local treshold = self.overtones_param1 * 63 + 1
        if n < treshold then
            return n
        end
        local param = math.pow (10, - (1 - self.overtones_param2) * 3)
        local n0 = n - 1
        local result = 1 + n0 + (n0 - treshold + 1) * param * 8
        local result_int = math.floor (result + 0.5)
        local result_dec = result - result_int
        return result_int + (1 - self.overtones_harmonize) * result_dec
    end,

    -- Shift Lower
    function (self, n)
        local treshold = self.overtones_param1 * 63 + 1
        if n < treshold then
            return n
        end
        local param = math.pow (10, - (1 - self.overtones_param2) * 3)
        local n0 = n - 1
        local result = 1 + n0 + (n0 - treshold + 1) * param * 0.9
        local result_int = math.floor (result + 0.5)
        local result_dec = result - result_int
        return result_int + (1 - self.overtones_harmonize) * result_dec
    end,

    -- PowerU
    function (self, n)
        local param1 = math.pow (10, - (1 - self.overtones_param1) * 3) * 100 + 1
        local n0 = n - 1
        local result = math.pow (n0 / param1, 1 - self.overtones_param2 * 0.8) * param1 + 1
        local result_int = math.floor (result + 0.5)
        local result_dec = result - result_int
        return result_int + (1 - self.overtones_harmonize) * result_dec
    end,

    -- PowerL
    function (self, n)
        local param1 = math.pow (10, - (1 - self.overtones_param1) * 3)
        local n0 = n - 1
        local result = n0 * (1 - param1) + math.pow (n0 * 0.1, self.overtones_param2 * 3 + 1) * param1 * 10 + 1
        local result_int = math.floor (result + 0.5)
        local result_dec = result - result_int
        return result_int + (1 - self.overtones_harmonize) * result_dec
    end,

    -- Sine
    function (self, n)
        local param1 = math.pow (10, - (1 - self.overtones_param1) * 3)
        local n0 = n - 1
        local result = n0 + math.sin (n0 * self.overtones_param2 * self.overtones_param2 * math.pi * 0.999) * math.sqrt(param1) * 2 + 1
        local result_int = math.floor (result + 0.5)
        local result_dec = result - result_int
        return result_int + (1 - self.overtones_harmonize) * result_dec
    end,
}


----------------------------------------------------------------------------------------------------


function PadSynth:generate_one_sample (note, range_start, range_end, render_frequency_table)

    local sample_rate = self.sample_rate
    local bit_depth = self.bit_depth
    local nb_channels = self.nb_channels

    local f = frequency_of_renoise_note (note) -- 440 -- 261.63
    local period = sample_rate / f

    local desired_length = self.sample_duration * sample_rate
    local nb_frames = 1024
    while nb_frames < desired_length do
        nb_frames = nb_frames * 2
    end

    local bw = self.bandwidth
    local harmonics = self.prepared_harmonics

    local freq = {}
    local freq_amp = {}

    -- Pad with zeros (for LuaFFT)

    for i = 1, nb_frames do
        freq_amp[i] = 0
        freq[i] = complex.new (0, 0)
    end
    in_progress_yield ()

    -- Create the table with spread harmonics

    local relf = PadSynth.overtones_placement_functions[self.overtones_placement]

    local ampl_max = 0

    for nh = 1, #harmonics do

        local bw_hz = (math.pow (2, bw / 1200) - 1.0) * f * math.pow (relf(self, nh), self.bandwidth_growth)
        local bwi = bw_hz / (2.0 * sample_rate)
        local fi = f * relf(self, nh) / sample_rate

        --TODO: break out of loop if harmonics[nh] == 0?
        if harmonics[nh] > 0 then
            for i = 1, nb_frames / 2 do
                local hprofile = self:harmonic_profile (((i - 1) / nb_frames) - fi, bwi)
                freq_amp[i] = freq_amp[i] + hprofile * harmonics[nh]
                if freq_amp[i] > ampl_max then ampl_max = freq_amp[i] end
            end
            in_progress_yield ()
        end

    end

    -- Render the frequency table for feedback (test note only)

    local index = 1
    while index <= #self.instrument.samples
          and string.sub (self.instrument:sample(index).name, 1, 19) ~= "PadSynth Parameters" do
        index = index + 1
    end
    if render_frequency_table then
        if index <= #self.instrument.samples then
            -- self.instrument.samples[index].sample_buffer:prepare_sample_data_changes ()
            self.instrument.samples[index].sample_buffer:create_sample_data (44100, 32, 1, nb_frames / 2)
            for i = 1, nb_frames / 2 do
                self.instrument.samples[index].sample_buffer:set_sample_data (1, i, 2 * to_display(freq_amp[i] / ampl_max) - 1)
            end
            -- self.instrument.samples[index].sample_buffer:finalize_sample_data_changes ()
        end
    end

    -- Randomize phases

    for i = 1, nb_frames / 2 do
        local phase = math.random () * math.pi * 2
        freq[i] = complex.new (freq_amp[i] * math.cos (phase) , freq_amp[i] * math.sin (phase) )
    end
    in_progress_yield ()

    -- Inverse Fourier Transform

    local wavetable = fft (freq, true)
    in_progress_yield ()

    -- Normalize samples

    ampl_max = 0
    for i = 1, #wavetable do
        if math.abs(wavetable[i][1]) > ampl_max then
            ampl_max = math.abs(wavetable[i][1])
        end
    end
    in_progress_yield ()
    if ampl_max < 0.00001 then ampl_max = 0.00001 end
    for i = 1, #wavetable do
        wavetable[i][1] = wavetable[i][1] / ampl_max
    end
    in_progress_yield ()

    -- Create and write the sample buffer

    local sample_index = self:create_sample (wavetable, note , {range_start, range_end})

    self:make_unison (sample_index, wavetable, note, {range_start, range_end})

end


----------------------------------------------------------------------------------------------------


function PadSynth:harmonic_profile (fi, bwi)

    local x = fi / bwi;

    x = x * x
    if x > 14.71280603 then return 0 end

    return math.exp (-x) / bwi;

end


----------------------------------------------------------------------------------------------------


function PadSynth:create_sample (wavetable, note, range)

    local index = 1
    while index <= #self.instrument.samples
          and string.sub (self.instrument:sample(index).name, 1, 19) ~= "PadSynth Parameters" do
        index = index + 1
    end
    local sample_index = #self.instrument.samples + 1
    if index <= #self.instrument.samples then
        sample_index = index + 1
    end
    local sample = self.instrument:insert_sample_at (sample_index)

    local success = sample.sample_buffer:create_sample_data(self.sample_rate, self.bit_depth, self.nb_channels, #wavetable)
    ---TODO: ?
    if not success then return end

    local sample_buffer = sample.sample_buffer
    sample_buffer:prepare_sample_data_changes ()

    -- Find a nice 0-crossing point to start the sample
    local start = math.floor (math.random (1, 3 * #wavetable / 8))
    while start < #wavetable and math.abs(wavetable[start][1]) > 0.001 do
        start = start + 1
    end
    local position = 1
    for i = start, #wavetable do
        sample_buffer:set_sample_data (1, position, wavetable[i][1])
        position = position + 1
    end
    in_progress_yield ()
    for i = 1, start - 1 do
        sample_buffer:set_sample_data (1, position, wavetable[i][1])
        position = position + 1
    end
    in_progress_yield ()

    if self.nb_channels > 1 then
        -- This time we start at mid-table
        start = math.floor (math.random (#wavetable / 2, 7 * #wavetable / 8))
        while start < #wavetable and math.abs(wavetable[start][1]) > 0.001 do
            start = start + 1
        end
        local position = 1
        for i = start, #wavetable do
            sample_buffer:set_sample_data (2, position, wavetable[i][1])
            position = position + 1
        end
        in_progress_yield ()
        for i = 1, start - 1 do
            sample_buffer:set_sample_data (2, position, wavetable[i][1])
            position = position + 1
        end
        in_progress_yield ()
    end

    sample_buffer:finalize_sample_data_changes ()

    -- self.instrument:insert_sample_mapping (renoise.Instrument.LAYER_NOTE_ON, sample_index, note, range)
    local sample_mapping = self.instrument:sample(sample_index).sample_mapping
    sample_mapping.layer = renoise.Instrument.LAYER_NOTE_ON
    sample_mapping.base_note = note
    sample_mapping.note_range = range
    sample.name = "PadSynth Note " .. name_of_renoise_note (note)
    sample.volume = self.volume
    if self.new_note_action == 2 then
        sample.new_note_action = renoise.Sample.NEW_NOTE_ACTION_NOTE_OFF
    elseif self.new_note_action == 3 then
        sample.new_note_action = renoise.Sample.NEW_NOTE_ACTION_SUSTAIN
    else
        sample.new_note_action = renoise.Sample.NEW_NOTE_ACTION_NOTE_CUT
    end
    sample.autofade = self.autofade
    if self.interpolation == 2 then
        sample.interpolation_mode = renoise.Sample.INTERPOLATE_LINEAR
    elseif self.interpolation == 3 then
        sample.interpolation_mode = renoise.Sample.INTERPOLATE_CUBIC
    elseif self.interpolation == 4 then
        sample.interpolation_mode = renoise.Sample.INTERPOLATE_SINC
    else
        sample.interpolation_mode = renoise.Sample.INTERPOLATE_NONE
    end
    sample.oversample_enabled = self.oversample_enabled

    return index

end


----------------------------------------------------------------------------------------------------


function PadSynth:make_unison (orig_index, wavetable, note, range)

    if self.unison_multiplier > 1 then

        local orig_sample = self.instrument:sample (orig_index)

        local new_index = self:create_sample (wavetable, note, range)
        local new_sample = self.instrument:sample (new_index)

        local detune = math.floor (self.unison_detune)
        local panning = self.unison_width / 100

        orig_sample.fine_tune = detune
        new_sample.fine_tune = - detune
        orig_sample.panning = 0.5 + panning
        new_sample.panning = 0.5 - panning

        if self.unison_multiplier > 2 then

            local multiplier = self.unison_multiplier - 1

            for i = 2, multiplier do

                local right_index = self:create_sample (wavetable, note, range)
                local right_sample = self.instrument:sample (right_index)

                local left_index = self:create_sample (wavetable, note, range)
                local left_sample = self.instrument:sample (left_index)

                local d = i * detune
                if d > 127 then d = 127 end
                right_sample.fine_tune = d
                left_sample.fine_tune = - d
                local p = i * panning
                if p > 0.5 then p = 0.5 end
                right_sample.panning = 0.5 + p
                left_sample.panning = 0.5 - p

            end

        end

    end

end


----------------------------------------------------------------------------------------------------

--TODO: cleaner approach for the 3 following functions


function PadSynth:initialize_parameters ()

    self.version = 4

    self.volume = 0.5
    self.sample_duration = 1
    self.nb_channels = 2

    self.autofade = true
    self.new_note_action = 2
    self.interpolation = 4
    self.oversample_enabled = true

    self.overtones_placement = 1
    self.overtones_treshold = 1
    self.overtones_amount = 0
    self.overtones_harmonize = 0

    self.bandwidth = 40
    self.bandwidth_growth = 1
    self.bandwidth_shape = 1

    self.unison_multiplier = 1
    self.unison_detune = 0
    self.unison_width = 0

    self.sample_rate = 44100
    self.bit_depth = 16

    self.first_note = 36
    self.last_note = 48
    self.keyzones_step = 6

    self.test_note = 48
    self.test_sample_rate = 44100
    self.test_duration = 0.4

    self.base_function = 1

    self.harmonics = { }
    for i = 1, 256 do
        self.harmonics[i] = 1 / i
    end

    self.random_part = { }
    for i = 1, 256 do
        self.random_part[i] = math.random()
    end

    self.formula_preset = 4
    self.formula_string = "return 1 / i"
    self.formula_randomness = 0
    self.formula_curvature = 0
    self.formula_torsion = 0
    self.formula_shape = 0

end


----------------------------------------------------------------------------------------------------


-- Save the synth parameters in the first sample name
-- (this sample is never used)
function PadSynth:save_parameters ()

    local index = 1
    while
        index <= #self.instrument.samples
        and string.sub (self.instrument:sample(index).name, 1, 19) ~= "PadSynth Parameters"
    do
        index = index + 1
    end
    if index > #self.instrument.samples then
        self.instrument:insert_sample_at (index)
    end

    self.instrument.samples[index].sample_buffer:create_sample_data (44100, 16, 1, 1)

    local name = "PadSynth Parameters { "

    name = name .. "version=" .. self.version .. ", "

    name = name .. "volume=" .. self.volume .. ", "
    name = name .. "sample_duration=" .. self.sample_duration .. ", "
    name = name .. "nb_channels=" .. self.nb_channels .. ", "

    name = name .. "autofade=" .. (self.autofade and "true" or "false") .. ", "
    name = name .. "new_note_action=" .. self.new_note_action .. ", "
    name = name .. "interpolation=" .. self.interpolation .. ", "
    name = name .. "oversample_enabled=" .. (self.oversample_enabled and "true" or "false") .. ", "

    name = name .. "overtones_placement=" .. self.overtones_placement .. ", "
    name = name .. "overtones_treshold=" .. self.overtones_treshold .. ", "
    name = name .. "overtones_amount=" .. self.overtones_amount .. ", "
    name = name .. "overtones_harmonize=" .. self.overtones_harmonize .. ", "

    name = name .. "bandwidth=" .. self.bandwidth .. ", "
    name = name .. "bandwidth_growth=" .. self.bandwidth_growth .. ", "
    name = name .. "bandwidth_shape=" .. self.bandwidth_shape .. ", "

    name = name .. "unison_multiplier=" .. self.unison_multiplier .. ", "
    name = name .. "unison_detune=" .. self.unison_detune .. ", "
    name = name .. "unison_width=" .. self.unison_width .. ", "

    name = name .. "sample_rate=" .. self.sample_rate .. ", "
    name = name .. "bit_depth=" .. self.bit_depth .. ", "

    name = name .. "first_note=" .. self.first_note .. ", "
    name = name .. "last_note=" .. self.last_note .. ", "
    name = name .. "keyzones_step=" .. self.keyzones_step .. ", "

    name = name .. "test_note=" .. self.test_note .. ", "
    name = name .. "test_sample_rate = " .. self.test_sample_rate .. ", "
    name = name .. "test_duration=" .. self.test_duration .. ", "

    name = name .. "base_function=" .. self.base_function .. ", "

    name = name .. "harmonics={ "
    for i = 1, #self.harmonics do
        name = name .. self.harmonics[i] .. ", "
    end
    name = name .. "}, "

    name = name .. "random_part={ "
    for i = 1, #self.random_part do
        name = name .. self.random_part[i] .. ", "
    end
    name = name .. "}, "

    name = name .. "formula_preset=" .. self.formula_preset .. ", "
    name = name .. "formula_string=\"" .. self.formula_string .. "\", "
    name = name .. "formula_randomness=" .. self.formula_randomness .. ", "
    name = name .. "formula_curvature=" .. self.formula_curvature .. ", "
    name = name .. "formula_torsion=" .. self.formula_torsion .. ", "
    name = name .. "formula_shape=" .. self.formula_shape .. ", "

    self.instrument.samples[index].name = name .. "}"

    self.instrument.samples[index].volume = 0.0
    self.instrument.samples[index].sample_mapping.note_range = {0, 0}
    self.instrument.samples[index].sample_mapping.velocity_range = {0, 0}

end


----------------------------------------------------------------------------------------------------


function PadSynth:load_parameters ()

    local index = 1
    while index <= #self.instrument.samples
          and string.sub (self.instrument:sample(index).name, 1, 19) ~= "PadSynth Parameters" do
        index = index + 1
    end

    self:initialize_parameters ()
    if index > #self.instrument.samples then
        return
    end

    local name = self.instrument.samples[index].name

    local data_string = "return" .. string.sub (name, 20)

    local f, err = loadstring (data_string)
    if f == nil then
        error(err)
    end

    local data = assert(f ())

    self.version = data.version
    self.volume = data.volume
    self.sample_duration = data.sample_duration
    self.nb_channels = data.nb_channels

    self.autofade = data.autofade
    self.new_note_action = data.new_note_action
    self.interpolation = data.interpolation

    self.overtones_placement = data.overtones_placement
    self.overtones_param1 = data.overtones_param1
    self.overtones_param2 = data.overtones_param2
    self.overtones_treshold = data.overtones_treshold
    self.overtones_amount = data.overtones_amount
    self.overtones_harmonize = data.overtones_harmonize

    self.bandwidth = data.bandwidth
    if data.bandwidth_growth then
        self.bandwidth_growth = data.bandwidth_growth
    else
        self.bandwidth_growth = 1
    end
    self.bandwidth_shape = data.bandwidth_shape

    self.unison_multiplier = data.unison_multiplier
    self.unison_detune = data.unison_detune
    self.unison_width = data.unison_width

    self.sample_rate = data.sample_rate
    self.bit_depth = data.bit_depth

    self.first_note = data.first_note
    self.last_note = data.last_note
    self.keyzones_step = data.keyzones_step

    self.test_note = data.test_note
    self.test_sample_rate = data.test_sample_rate
    self.test_duration = data.test_duration

    self.base_function = data.base_function

    self.harmonics = data.harmonics
    self.random_part = data.random_part

    self.formula_preset = data.formula_preset
    self.formula_string = data.formula_string
    self.formula_randomness = data.formula_randomness
    self.formula_curvature = data.formula_curvature
    self.formula_torsion = data.formula_torsion
    self.formula_shape = data.formula_shape

    if self.version == 0 then
        self.bandwidth_growth = 1
        self.version = 1
    end

    if self.version == 3 then
        self.autofade = self.autofade == 2
        self.interpolation = 4
        self.oversample_enabled = true
        --TODO: self.version = 4
    end

end

----------------------------------------------------------------------------------------------------
