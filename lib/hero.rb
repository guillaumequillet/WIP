class Hero
    attr_reader :sprite
    def initialize(spritesheet, x, y, z = 0)
        @sprite = Sprite.new(spritesheet, x, y, 0, 2)
        @speed = 0.1
        @angle = 0
    end

    def update(dt, camera)
        @angle = camera.angle_from_sprite(@sprite.x, @sprite.y)

        dx, dy = 0, 0
        dy = 1  if Gosu.button_down?(Gosu::KB_UP)
        dy = -1 if Gosu.button_down?(Gosu::KB_DOWN)
        dx = 1  if Gosu.button_down?(Gosu::KB_RIGHT)
        dx = -1 if Gosu.button_down?(Gosu::KB_LEFT)

        cam_angle = Math.atan2(camera.y - @sprite.y, camera.x - @sprite.x)

        world_dx = dx * Math.cos(cam_angle + Math::PI/2) - dy * Math.sin(cam_angle + Math::PI/2)
        world_dy = dx * Math.sin(cam_angle + Math::PI/2) + dy * Math.cos(cam_angle + Math::PI/2)        

        @sprite.x += world_dx * @speed
        @sprite.y += world_dy * @speed
    end

    def draw
        @sprite.draw(@angle)
    end
end