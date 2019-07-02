--[[
    particle_dark.lua
    a dark partice which moves with an initial velocity and variation
--]]

local obj = require 'obj'
local map = require 'map'
local physics_groups = require 'physics_groups'
local sprite = require 'sprite'

return {
    init = function(self)
        self.alpha_decay = 1

        self.alpha_base = self.alpha_base or 0.9
        self.alpha_variation = self.alpha_variation or 0.1

        -- angular velocity variation
        self.da_variation = self.da_variation or 5

        self.dx = self.dx or 0
        self.dy = self.dy or -100
        self.dx_variation = self.dx_variation or 50
        self.dy_variation = self.dy_variation or self.dx_variation or 50

        -- const for dampening all the velocities
        self.velocity_dampening = 100

        self.spr = sprite.create('3x3_particle_dark.png', nil, nil, 0)
        self.color = self.color or {1, 1, 1, 1}

        self.w = self.spr.frame_w
        self.h = self.spr.frame_h

        self.alpha = self.alpha_base

        -- apply variation
        self.alpha = self.alpha + (math.random(-10, 10) / 10) * self.alpha_variation
        self.dx = self.dx + (math.random(-10, 10) / 10) * self.dx_variation
        self.dy = self.dy + (math.random(-10, 10) / 10) * self.dy_variation

        -- make a physics body that covers the sprite
        self.shape = love.physics.newRectangleShape(self.w, self.h)
        self.body = love.physics.newBody(map.get_physics_world(), self.x + self.w / 2, self.y + self.h / 2, 'dynamic')
        self.fixture = love.physics.newFixture(self.body, self.shape, 0.1)

        -- set the physics group
        self.fixture:setCategory(physics_groups.GIB)

        -- set the physics mask
        self.fixture:setMask(physics_groups.GIB, physics_groups.PHYSBOX)

        -- apply the particle force
        self.body:applyLinearImpulse(self.dx / self.velocity_dampening, self.dy / self.velocity_dampening)

        -- apply varying angular force
        self.body:applyAngularImpulse((math.random(-10, 10) / 10) * self.da_variation / self.velocity_dampening)
    end,

    destroy = function(self)
        self.body:destroy()
    end,

    update = function(self, dt)
        self.alpha = self.alpha - dt * self.alpha_decay

        if self.alpha < 0 then
            obj.destroy(self)
        end

        self.x, self.y = self.body:getPosition()
        self.angle = self.body:getAngle()

        self.color[4] = self.alpha
    end,

    render = function(self)
        love.graphics.setColor(self.color)
        love.graphics.draw(self.spr.image, self.spr:frame(),
                           self.x, self.y, self.angle, 1, 1,
                           self.w / 2, self.h / 2)
    end,
}
