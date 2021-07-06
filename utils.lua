

function renoise_note_of (note, octave)

    return (octave - 1) * 12 + (note - 1)

end


function frequency_of_renoise_note (note)

    -- In the formula, A4 is 49
    -- For the value calculated above, A4 is 57
    local n = note - 57 + 49

    return 440 * math.pow(2, (n - 49) / 12)

end

function name_of_renoise_note (note)

    local n = math.floor (note % 12) + 1

    local o = math.floor (note / 12)

    local names = { "C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-", }

    return names[n] .. o

end

--------------------------------------------------------------------------------------------------------------------------

function lin_to_ln (v)

    local ee = math.exp (-1)

    local w = math.exp (- (1 - v))

    return (w - ee) / (1 - ee)

end

function ln_to_lin (v)

    local ee = math.exp (-1)

    local w = v * (1 - ee) + ee

    return 1 + math.log (w)

end

--------------------------------------------------------------------------------------------------------------------------


function from_display (v)

    local ee = 0.1

    local w = math.pow (10, - (1 - v))

    return (w - ee) / (1 - ee)

end


function to_display (v)

    local ee = 0.1

    local w = v * (1 - ee) + ee

    return 1 + math.log10 (w)

end

----------------------------------------------------------------------------------------------------

function curve(x, shape, torsion, curvature)

    local result

    local curve_a
    local curve_b
    if shape < 0.0 then
        shape = shape + 1.0
        curve_a = curve_logarithmic
        curve_b = curve_exponential
    else
        curve_a = curve_exponential
        curve_b = curve_half_sinusoidal
    end

    if curvature > 0.0 then
        torsion = -torsion
    end
    torsion = torsion + 1.0

    if torsion < 1.0 then
        local total_length = 1.0 + torsion
        local orig_a = curve_a(torsion, curvature)
        local height_a = 1.0 + orig_a
        local orig_b = curve_b(torsion, curvature)
        local height_b = 1.0 + orig_b
        if x > torsion / total_length then
            result = mix(
                orig_a/height_a + curve_a((x - torsion / total_length) * total_length, curvature) / height_a,
                orig_b/height_b + curve_b((x - torsion / total_length) * total_length, curvature) / height_b,
                shape
            )
        else
            result = mix(
                orig_a/height_a - curve_a(torsion - x * total_length, curvature) / height_a,
                orig_b/height_b - curve_b(torsion - x * total_length, curvature) / height_b,
                shape
            )
        end
    else
        torsion = 2.0 - torsion
        curvature = - curvature
        local total_length = 1.0 + torsion
        local extra_a = 1.0 - curve_a(1.0 - torsion, curvature)
        local height_a = (1.0 + extra_a)
        local extra_b = 1.0 - curve_b(1.0 - torsion, curvature)
        local height_b = (1.0 + extra_b)
        if x < 1.0 - torsion / total_length then
            result = mix(
                curve_a(x * total_length, curvature) / height_a,
                curve_b(x * total_length, curvature) / height_b,
                shape
            )
        else
            result = mix(
                (2.0 - curve_a(1.0 - (x * total_length - 1.0), curvature)) / height_a,
                (2.0 - curve_b(1.0 - (x * total_length - 1.0), curvature)) / height_b,
                shape
            )
        end
    end

    return result

end

----------------------------------------------------------------------------------------------------

function mix(x, y, a)
    return (1.0 - a) * x + a * y
end

function clamp(v, a, b)
    return math.max(a, math.min(v, b))
end

----------------------------------------------------------------------------------------------------

function curve_exponential(x, curvature)
    local scale = 2.0
    local sign = curvature < 0.0 and -1.0 or 1.0
    local b = (math.exp(scale * math.abs(curvature)) - 1.0) / (math.exp(scale) - 1.0)
    b = -5.0 * sign * b
    if math.abs(curvature) > 0.01 then
        return (math.exp(b * x) - 1.0) / (math.exp(b) - 1.0)
    else
        return x
    end
end


function curve_logarithmic(x, curvature)
    local scale = 2.0
    local sign = curvature < 0.0 and -1.0 or 1.0
    local b = (math.exp(scale * math.abs(curvature)) - 1.0) / (math.exp(scale) - 1.0)
    b = 5.0 * sign * b
    if math.abs(curvature) > 0.01 then
        return math.log(x * (math.exp(b) - 1.0) + 1.0) / b
    else
        return x
    end
end

function curve_circular(x, curvature)
    local b = curvature
    if math.abs(curvature) > 0.01 then
        local new_position = (b * x + (1.0 - b) * 0.5)
        local angle = math.acos(1.0 - new_position)
        local result = math.sin(angle)
        return (result - math.sin(math.acos(1.0 - ((1.0 - b) * 0.5))))
            / (math.sin(math.acos(1.0 - (b + (1.0 - b) * 0.5))) - math.sin(math.acos(1.0 - ((1.0 - b) * 0.5))))
    else
        return x
    end
end

function curve_half_sinusoidal(x, curvature)
    local b = math.abs(curvature)
    if curvature > 0.01 then
        if b <= 0.5 then
            b = 2.0 * b
            return (1.0 - b) * x + b * math.sin(x * math.pi/2.0)
        else
            return mix(
                math.sin(x * math.pi/2.0),
                math.sin(math.sin(x * math.pi/2.0) * math.pi/2.0),
                2.0 * curvature - 1.0
            )
        end
    elseif curvature < -0.01 then
        if b <= 0.5 then
            b = 2.0 * b
            return (1.0 - b) * x + b * (math.sin(3.0*math.pi/2.0 + x * math.pi/2.0) + 1.0)
        else
            return mix(
                math.sin(3.0*math.pi/2.0 + x * math.pi/2.0) + 1.0,
                math.sin(3.0*math.pi/2.0 + (math.sin(3.0*math.pi/2.0 + x * math.pi/2.0) + 1.0) * math.pi/2.0) + 1.0,
                2.0 * -curvature - 1.0
            )
        end
    else
        return x
    end
end

function curve_sinusoidal(x, curvature)
    local b = math.abs(curvature)
    if math.abs(curvature) > 0.01 then
        return (1.0 - b) * x + b * (math.sin((x - 0.5) * math.pi) / 2.0 + 0.5)
    else
        return x
    end
end

function curve_arcsinusoidal(x, curvature)
    local b = math.abs(curvature)
    if math.abs(curvature) > 0.01 then
        return (1.0 - b) * x + b * (math.asin(2.0 * x - 1.0) / math.pi + 0.5)
    else
        return x
    end
end

curve_functions =
{
    curve_exponential,
    curve_logarithmic,
    curve_half_sinusoidal,
    curve_sinusoidal,
    curve_circular,
    curve_arcsinusoidal,
}

----------------------------------------------------------------------------------------------------
