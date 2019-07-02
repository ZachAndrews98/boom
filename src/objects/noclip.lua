--[[
    noclip.lua
    noclip object
--]]

local map = require 'map'

return {
    init = function(self)
        self.terrain_colors = {
            stone = { 0.4, 0.4, 0.4, 1.0 },
            grass = { 0.3, 0.8, 0.3, 1.0 },
        }

        self.dust_color = self.terrain_colors[self.terrain] or self.terrain_colors.stone

        self.solid   = true
        self.body    = love.physics.newBody(map.get_physics_world(),
                                          self.x + self.w / 2,
                                          self.y + self.h / 2,
                                          'static')
        self.shape   = love.physics.newRectangleShape(self.w, self.h)
        self.fixture = love.physics.newFixture(self.body, self.shape)
    end
}
