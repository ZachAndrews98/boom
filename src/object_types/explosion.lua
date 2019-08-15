--- Explosion object type.

local camera = require 'camera'
local map    = require 'map'
local object = require 'object'

return {
    init = function(this)
        -- Configuration.
        this.resolution   = this.resolution or 100
        this.radius       = this.radius or 150
        this.object_range = this.object_range or 50
        this.intensity    = this.intensity or 20

        -- Look for nearby objects to explode.
        map.foreach_object(function (other_obj)
            local dist = math.sqrt(math.pow(other_obj.x - this.x, 2) + math.pow(other_obj.y - this.y, 2))

            if dist < this.object_range then
                object.call(other_obj, 'explode', dist, (other_obj.x - this.x) / dist, (other_obj.y - this.y) / dist)
            end
        end)

        -- Shoot out explosion rays into the physics world.
        for i=1,this.resolution do
            local theta = (i / this.resolution) * 3.141 * 2.0

            map.get_physics_world():rayCast(
                this.x, this.y,
                this.x + this.radius * math.cos(theta),
                this.y + this.radius * math.sin(theta),
                function (fixture, x, y, _, _, fraction)
                    local impulse_vector = {
                        x = x - this.x,
                        y = y - this.y,
                    }

                    local impulse_length = fraction * this.radius

                    impulse_vector.x = impulse_vector.x * this.intensity / impulse_length
                    impulse_vector.y = impulse_vector.y * this.intensity / impulse_length

                    fixture:getBody():applyLinearImpulse(impulse_vector.x, impulse_vector.y)

                    return 0
                end
            )
        end

        -- Shake the camera a little.
        camera.setshake(0.2)
    end,

    render = function(this)
        love.graphics.circle('line', this.x, this.y, this.radius)

        object.destroy(this)
    end
}
