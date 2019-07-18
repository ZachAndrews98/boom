--[[
    button-new.lua
--]]

local map = require 'map'
local util = require 'util'
local sprite = require 'sprite'

return {
    init = function(self)

        if self.image then
            self.image = sprite.create('assets/sprites/' .. util.basename(self.image), self.w, self.h, 0.25)
        end
    end,
    render = function(self)

        if self.image then
            self.image:render(math.floor(self.x), math.floor(self.y), 0, self.direction == 'right')
        else
            love.graphics.rectangle('fill', -self.w / 2, -self.h / 2, self.w, self.h)
        end

    end
}
