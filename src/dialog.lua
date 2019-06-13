--[[
    dialog.lua
    dialog rendering manager
]]--

local assets = require 'assets'

local dialog = {
    sequences = {},
    offset_y = 10,
    padding_x = 3,
    padding_y = 3,
    radius = 0,
    tri_size = 6,
}

function dialog.load()
    dialog.font = assets.font('pixeled', 5)
end

--[[
    dialog.run(sequence, target)

    starts a dialog sequence <sequence> following object target <target>
]]--

function dialog.run(sequence, target, options)
    local state = {
        type_speed = 0.03,
        end_wait = 1,
        interval_wait = 2,
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
    state.interval_timer = 0
    state.render = true

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
                v.render = false
            end
        elseif v.interval_timer > 0 then
            -- wait on the interval timer
            v.interval_timer = v.interval_timer - dt
        else
            -- interval is over, advance to the next line and reset everything
            v.current_line = v.current_line + 1
            v.current_char = 0
            v.char_timer = v.type_speed
            v.render = true

            -- remove this state from the sequence list if there are no more lines
            if v.seq[v.current_line] == nil then
                dialog.sequences[k] = nil
            end
        end
    end
end

function dialog.render()
    love.graphics.setFont(dialog.font)

    -- render all running sequences
    for _, v in pairs(dialog.sequences) do
        -- placeholder: just render the current line above the target
        local line = v.seq[v.current_line]
        local text = string.sub(line.text, 0, v.current_char)

        print('rendering line=' .. v.current_line .. ', char=' .. v.current_char .. ', fulltext=' .. line.text .. ', realtext=' .. text)

        -- if we're not between lines then render the current
        if v.render then
            local width = dialog.font:getWidth(text)
            local height = dialog.font:getHeight()
            local box_width = width + 2 * dialog.padding_x
            local box_height = height + 2 * dialog.padding_y
            local center_x = v.target.x + v.target.w / 2
            local center_y = v.target.y - dialog.offset_y - box_height / 2

            love.graphics.setColor(1, 1, 1, 1)

            -- render a white backdrop to fit the text
            love.graphics.rectangle('fill', center_x - box_width / 2, center_y - box_height / 2, box_width, box_height, dialog.radius, dialog.radius)

            -- render backdrop outline
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle('line', center_x - box_width / 2, center_y - box_height / 2, box_width, box_height, dialog.radius, dialog.radius)

            -- go back to white, render tri on the bottom
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.polygon('fill', center_x + dialog.tri_size, center_y + box_height / 2 - 1,
                                          center_x - dialog.tri_size, center_y + box_height / 2 - 1,
                                          center_x, center_y + box_height / 2 + dialog.tri_size)

            -- render outline on the bottom tri
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.line(center_x - dialog.tri_size, center_y + box_height / 2,
                               center_x, center_y + box_height / 2 + dialog.tri_size)
            love.graphics.line(center_x + dialog.tri_size, center_y + box_height / 2,
                               center_x, center_y + box_height / 2 + dialog.tri_size)

            love.graphics.print(text, center_x - box_width / 2 + dialog.padding_x, center_y - box_height / 2 + dialog.padding_y)
        end
    end
end

return dialog
