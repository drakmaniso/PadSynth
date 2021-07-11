local utils = {}

function utils.mix(x, y, a)
    return x * (1 - a) + y * a
end

function utils.clamp(x, bottom, top)
    return math.max(bottom, math.min(x, top))
end

utils.bend_funcs = {
    [-10] = function(x)
        return x * x * x * x * x * x * x * x * x * x * x
    end,
    [-9] = function(x)
        return x * x * x * x * x * x * x * x * x * x
    end,
    [-8] = function(x)
        return x * x * x * x * x * x * x * x * x
    end,
    [-7] = function(x)
        return x * x * x * x * x * x * x * x
    end,
    [-6] = function(x)
        return x * x * x * x * x * x * x
    end,
    [-5] = function(x)
        return x * x * x * x * x * x
    end,
    [-4] = function(x)
        return x * x * x * x * x
    end,
    [-3] = function(x)
        return x * x * x * x
    end,
    [-2] = function(x)
        return x * x * x
    end,
    [-1] = function(x)
        return x * x
    end,
    [0] = function(x)
        return x
    end,
    [1] = function(x)
        local xx = 1 - x
        return 1 - xx * xx
    end,
    [2] = function(x)
        local xx = 1 - x
        return 1 - xx * xx * xx
    end,
    [3] = function(x)
        local xx = 1 - x
        return 1 - xx * xx * xx * xx
    end,
    [4] = function(x)
        local xx = 1 - x
        return 1 - xx * xx * xx * xx * xx
    end,
    [5] = function(x)
        local xx = 1 - x
        return 1 - xx * xx * xx * xx * xx * xx
    end,
    [6] = function(x)
        local xx = 1 - x
        return 1 - xx * xx * xx * xx * xx * xx * xx
    end,
    [7] = function(x)
        local xx = 1 - x
        return 1 - xx * xx * xx * xx * xx * xx * xx * xx
    end,
    [8] = function(x)
        local xx = 1 - x
        return 1 - xx * xx * xx * xx * xx * xx * xx * xx * xx
    end,
    [9] = function(x)
        local xx = 1 - x
        return 1 - xx * xx * xx * xx * xx * xx * xx * xx * xx * xx
    end,
    [10] = function(x)
        local xx = 1 - x
        return 1 - xx * xx * xx * xx * xx * xx * xx * xx * xx * xx * xx
    end,
    -- Last function is repeated to allow for simpler bend function
    [11] = function(x)
        local xx = 1 - x
        return 1 - xx * xx * xx * xx * xx * xx * xx * xx * xx * xx * xx
    end
}

function utils.bend(x, curvature)
    local c_i = math.floor(curvature)
    local c_f = curvature - c_i
    return utils.mix(utils.bend_funcs[c_i](x), utils.bend_funcs[c_i + 1](x), c_f)
end

return utils
