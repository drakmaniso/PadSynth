local background = {}

local background_coroutine = nil
local background_feedback_function = nil
local background_finished_function = nil
local background_clock = 0

function background.continue()
    if background_coroutine then
        local status = coroutine.status(background_coroutine)
        if status == "suspended" then
            if background_feedback_function then
                background_feedback_function()
            end
            local ok, msg = coroutine.resume(background_coroutine)
            if not ok then
                print(msg)
            end
        elseif status == "dead" then
            if background_finished_function then
                background_finished_function()
            end
            background_coroutine = nil
            background_feedback_function = nil
            background_finished_function = nil
        end
    end
end

function background.start(f, feedback, finished)
    if not background_coroutine then
        background_coroutine = coroutine.create(f)
        background_feedback_function = feedback
        background_finished_function = finished
        background_clock = os.clock()
    end
end

function background.yield()
    local t = os.clock()
    if t - background_clock > 0.125 then
        background_clock = t
        coroutine.yield()
    end
end

function background.abort()
    background_coroutine = nil
    background_feedback_function = nil
    background_finished_function = nil
end

function background.is_running()
    return background_coroutine ~= nil
end

return background
