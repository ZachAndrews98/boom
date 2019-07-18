--[[
    button-quit.lua
--]]

local map = require 'map'
local util = require 'util'
local sprite = require 'sprite'
mouse_x, mouse_y = love.mouse.getPosition()


return {
    init = function(self)

        if self.image then
            self.image = sprite.create('assets/sprites/' .. util.basename(self.image), self.w, self.h, 0.25)
        end
    end,
    render = function(self)

        if self.hover then
            self.image:play()
        end

        if self.image then
            self.image:render(math.floor(self.x), math.floor(self.y), 0, self.direction == 'right')
        else
            love.graphics.rectangle('fill', -self.w / 2, -self.h / 2, self.w, self.h)
        end

    end,

    --function to check if the mouse is hovering the button
    hover = function(self)
        if self.x < mouse_x < self.x + self.w and self.y < mouse_y < self.y + self.g then
            return true
        end
        return false
    end
}
