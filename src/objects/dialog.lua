--[[
    dialog.lua
    dialog box

    parameters:
        lines <Table>               : array of lines to display, each element should have 'text' set
        type_del <Number> (0.05)    : second delay between characters while typing
        hold_del <Number> (2)       : seconds to wait after text is completely typed
        interval_del <Number> (1)   : seconds to wait after hold_del before showing the next line
        padding_x <Number> (3)      : horizontal dialog box padding
        padding_y <Number> (3)      : vertical dialog box padding
        tri_size <Number> (6)       : bottom triangle edge length
        offset_y <Number> (10)      : vertical distance between box and followed object
        explodable <Bool> (true)    : enable shattering if exploded
        follow <Object> (<self>)    : object to follow

    member functions:
        on_end(ud, callback) : adds a callback function <callback> to be called
                             | once the dialog object is destroyed. <ud> will be
                             | passed as the first argument, followed by the dialog object itself.
--]]

local assets = require 'assets'
local obj = require 'obj'

local dialog_lock = nil

return {
    init = function(self)
        -- config
        self.lines = self.lines or {}
        self.type_del = self.type_del or 0.05
        self.hold_del = self.hold_del or 1
        self.interval_del = self.interval_del or 1
        self.explodable = self.explodable or false
        self.padding_x = self.padding_x or 3
        self.padding_y = self.padding_y or 3
        self.tri_size = self.tri_size or 6
        self.offset_y = self.offset_y or 10
        self.font = assets.font('pixeled', 6)
        self.shatter_points = 8

        -- state
        self.callbacks = {}
        self.timer = 0
        self.state = 0
        self.render = true
        self.current_line = 1
        self.current_char = 0
        self.num_lines = #self.lines

        -- initialize lines
        for _, v in ipairs(self.lines) do
            v.type_del = v.type_del or self.type_del
            v.hold_del = v.hold_del or self.hold_del
            v.interval_del = v.interval_del or self.interval_del
            v.num_chars = string.len(v.text)
            v.follow = v.follow or self.follow
        end

        --[[
            dialog states:
                0: typing
                1: waiting
                2: interval
        --]]

        self.on_end = function(this, ud, callback)
            table.insert(this.callbacks, { ud = ud, callback = callback })
        end
    end,

    destroy = function(self)
        -- release the lock if we're holding it (we always should be)
        if dialog_lock == self then
            dialog_lock = nil
        end

        for _, v in ipairs(self.callbacks) do
            v.callback(v.ud)
        end
    end,

    explode = function(self, _, _)
        print('Exploding dialog, render = ' .. tostring(self.render))

        if self.render then
            -- shatter the box
            -- here we'll subdivide the backdrop into a bunch of pieces

            local line = self.lines[self.current_line]
            local line_to_render = string.sub(line.text, 0, self.current_char)
            local text_width, text_height = self.font:getWidth(line_to_render), self.font:getHeight()
            local box_width, box_height = text_width + 2 * self.padding_x, text_height + 2 * self.padding_y

            -- center point of the dialog box
            local center_x, center_y = line.follow.x + line.follow.w / 2, line.follow.y - self.offset_y - box_height / 2

            -- compute top and bottom shatter points
            local top_points, bottom_points = {}, {}

            for _=1,self.shatter_points do
                table.insert(top_points, math.random(box_width))
                table.insert(bottom_points, math.random(box_width))
            end

            table.sort(top_points)
            table.sort(bottom_points)

            local box_left = center_x - box_width / 2
            local box_top = center_y - box_height / 2
            local box_right = center_x + box_width / 2
            local box_bottom = center_y + box_height / 2

            -- from shatter points, construct gib objects
            for i=0,self.shatter_points do
                local x1, x2, x3, x4 -- x values

                if i == 0 then
                    x1 = box_left
                    x2 = box_left
                else
                    x1 = top_points[i] + box_left
                    x2 = bottom_points[i] + box_left
                end

                if i == self.shatter_points then
                    x3 = box_right
                    x4 = box_right
                else
                    x3 = top_points[i + 1] + box_left
                    x4 = bottom_points[i + 1] + box_left
                end

                obj.create(self.__layer, 'gib_dialog', {
                    points = { x1, box_top, x3, box_top, x4, box_bottom, x2, box_bottom }
                })
            end
        end

        obj.destroy(self)
    end,

    update = function(self, dt)
        -- try and capture the lock
        if dialog_lock then
            if dialog_lock ~= self then
                return
            end
        else
            dialog_lock = self
        end

        local line = self.lines[self.current_line]

        self.x = line.follow.x
        self.y = line.follow.y
        self.w = line.follow.w
        self.h = line.follow.h

        if self.state == 0 then
            -- typing, advance chars until full
            self.timer = self.timer - dt

            if self.timer <= 0 then
                self.current_char = self.current_char + 1
                self.timer = line.type_del
            end

            -- check if we've typed every char
            if self.current_char >= line.num_chars then
                self.state = 1
                self.timer = line.hold_del
            end
        elseif self.state == 1 then
            -- holding, wait for the timer to expire
            self.timer = self.timer - dt

            -- destroy once the hold timer is up
            if self.timer <= 0 then
                self.state = 2
                self.timer = line.interval_del
                self.render = false
            end
        elseif self.state == 2 then
            self.timer = self.timer - dt

            if self.timer <= 0 then
                self.render = true
                self.current_char = 0
                self.current_line = self.current_line + 1
                self.state = 0

                if self.current_line > #self.lines then
                    obj.destroy(self)
                end
            end
        end
    end,

    render = function(self)
        -- don't render if we don't own the lock
        if dialog_lock ~= self then
            return
        end

        if not self.render then
            return
        end

        local line = self.lines[self.current_line]

        -- don't render if we're out of range
        if not line then
            return
        end

        -- compute what we've typed so far
        local line_to_render = string.sub(line.text, 0, self.current_char)

        -- compute the bounds of the text
        local text_width, text_height = self.font:getWidth(line_to_render), self.font:getHeight()

        -- actual bounds including padding
        local box_width, box_height = text_width + 2 * self.padding_x, text_height + 2 * self.padding_y

        -- center point of the dialog box
        local center_x, center_y = line.follow.x + line.follow.w / 2, line.follow.y - self.offset_y - box_height / 2

        -- render the backdrop
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle('fill', center_x - box_width / 2, center_y - box_height / 2, box_width, box_height)

        -- render backdrop outline
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle('line', center_x - box_width / 2, center_y - box_height / 2, box_width, box_height)

        -- render bottom tri
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.polygon('fill', center_x + self.tri_size, center_y + box_height / 2 - 1,
                                      center_x - self.tri_size, center_y + box_height / 2 - 1,
                                      center_x, center_y + box_height / 2 + self.tri_size)

        -- render tri outline
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.line(center_x - self.tri_size, center_y + box_height / 2,
                           center_x, center_y + box_height / 2 + self.tri_size)
        love.graphics.line(center_x + self.tri_size, center_y + box_height / 2,
                           center_x, center_y + box_height / 2 + self.tri_size)

        -- finally render the actual text
        love.graphics.setFont(self.font)
        love.graphics.print(line_to_render, center_x - box_width / 2 + self.padding_x,
                                            center_y - box_height / 2 + self.padding_y)
    end,
}
