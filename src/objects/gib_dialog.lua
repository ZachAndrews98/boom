--[[
    gib.lua
    gib object
--]]

local obj = require 'obj'
local map = require 'map'
local sprite = require 'sprite'

return {
    init = function(self)
        self.flash_timer      = 0
        self.flash_timer_base = 0.1
        self.flash_threshold  = 0.4
        self.clean_timer      = 5 + math.random(1, 4)
        self.angle            = 0
        self.in_flash         = false

        self.color = self.color or {1, 1, 1, 1}

        -- compute the center of the poly
        local center_x = (self.points[1] + self.points[3] + self.points[5] + self.points[7]) / 4
        local center_y = (self.points[2] + self.points[4] + self.points[6] + self.points[8]) / 4

        print('Center: ' .. center_x .. ' , ' .. center_y)

        -- translate the points relative to the center
        for i, v in ipairs(self.points) do
            if (i % 2) == 1 then
                self.points[i] = v - center_x
            else
                self.points[i] = v - center_y
            end
        end

        print('Points: ')
        for _, v in ipairs(self.points) do
            print(v)
        end

        -- construct the poly shape
        self.shape = love.physics.newPolygonShape(self.points)
        self.body = love.physics.newBody(map.get_physics_world(), center_x, center_y, 'dynamic')
        self.fixture = love.physics.newFixture(self.body, self.shape)

        self.x = center_x
        self.y = center_y
    end,

    destroy = function(self)
        self.body:destroy()
    end,

    update = function(self, dt)
        self.clean_timer = self.clean_timer - dt

        if self.clean_timer < self.flash_threshold then
            self.flash_timer = self.flash_timer - dt

            if self.flash_timer <= 0 then
                self.flash_timer = self.flash_timer_base
                self.in_flash = not self.in_flash
            end
        end

        if self.clean_timer < 0 then
            obj.destroy(self)
        end

        self.x, self.y = self.body:getPosition()
        self.angle = self.body:getAngle()
    end,

    render = function(self)
        if not self.in_flash then
            love.graphics.setColor(self.color)
            love.graphics.polygon('fill', self.body:getWorldPoints(self.shape:getPoints()))
        end
    end,
}
