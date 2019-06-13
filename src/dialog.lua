--[[
    dialog.lua
    dialog rendering manager
]]--

local dialog = {
    sequences = {},
}

--[[
    dialog.run(sequence, target)

    starts a dialog sequence <sequence> following object target <target>
]]--

function dialog.run(sequence, target, options)
    local state = {
        type_speed = 0.03,
        end_wait = 0.4,
        interval_wait = 0.3,
    }

    for k, v in pairs(options or {}) do
        state[k] = v
    end

    state.seq = sequence
    state.target = target

    state.current_line = 1
    state.current_char = 0
    state.char_timer = 0
    state.line_end_timer = 0

    table.insert(dialog.sequences, state)
end

function dialog.update(dt)
    -- advance running sequences
    for k, v in pairs(dialog.sequences) do
        -- grab current sequence line
        local line = v.seq[v.current_line]

        -- are we still typing the line out?
        if v.current_char < string.len(line.text) then
            -- advance the character timer
            v.char_timer = v.char_timer - dt

            -- did the char timer expire?
            if v.char_timer < 0 then
                -- advance the char, reset the timer
                v.current_char = v.current_char + 1
                v.char_timer = v.type_speed

                if v.current_char == string.len(line.text) then
                    -- line finished. set the end wait timer
                    v.line_end_timer = v.end_wait
                end
            end
        elseif v.line_end_timer > 0 then
            -- line is full, wait on the line end timer
            v.line_end_timer = v.line_end_timer - dt

            if v.line_end_timer < 0 then
                -- timer just finished. now set the interval timer
                v.interval_timer = v.interval_wait
            end
        elseif v.interval_timer > 0 then
            -- wait on the interval timer
            v.interval_timer = v.interval_timer - dt
        else
            -- interval is over, advance to the next line and reset everything
            v.current_line = v.current_line + 1
            v.current_char = 0
            v.char_timer = v.type_speed

            -- remove this state from the sequence list if there are no more lines
            if v.seq[v.current_line] == nil then
                dialog.sequences[k] = nil
            end
        end
    end
end

function dialog.render()
    -- render all running sequences
    for _, v in pairs(dialog.sequences) do
        -- placeholder: just render the current line above the target
        local line = v.seq[v.current_line]
        local text = string.sub(line.text, 0, v.current_char)

        print('rendering line=' .. v.current_line .. ', char=' .. v.current_char .. ', fulltext=' .. line.text .. ', realtext=' .. text)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(text, v.target.x - 20, v.target.y - 20)
    end
end

return dialog
