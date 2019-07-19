local camera = require 'camera'
local log    = require 'log'
local object = require 'object'

return {
    init = function(this)
        -- Subscribe to input events so the character is controlled by the user.
        object.subscribe(this, 'inputdown')
        object.subscribe(this, 'inputup')

        object.add_component(this, 'character', { x = this.x, y = this.y })
    end,

    update = function(this)
        -- Focus the camera on the player.
        local char = this.components.character
        camera.set_focus_x(char.x + char.w / 2 + char.dx / 2)

        -- Point the camera in the right direction.
        camera.set_focus_flip(char.direction == 'left')

        if char.jump_enabled then
            camera.set_focus_y(char.y + char.h / 2)
        end

        -- Destroy the player if the character dies.
        if char.dead then
            object.destroy(this)
        end

        -- Our location is the character's location.
        -- We'll center for convienence.
        this.x = char.x + char.w / 2
        this.y = char.y + char.h / 2
    end,
}
