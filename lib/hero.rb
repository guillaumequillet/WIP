class Hero
    attr_reader :sprite
    def initialize(scene, spritesheet, x, y, z = 0)
        @scene = scene
        @sprite = Sprite.new(spritesheet, x, y, 0, 2)
        @speed = 0.01
        @angle = 0
    end

    def update(dt, camera)
        @angle = camera.angle_from_sprite(@sprite.x, @sprite.y)
        speed = @speed * dt

        if Gosu.button_down?(Gosu::KB_UP)
            @sprite.x -= Gosu.offset_x(@angle, speed)
            @sprite.y -= Gosu.offset_y(@angle, speed)
        elsif Gosu.button_down?(Gosu::KB_DOWN)
            @sprite.x += Gosu.offset_x(@angle, speed)
            @sprite.y += Gosu.offset_y(@angle, speed)
        elsif Gosu.button_down?(Gosu::KB_RIGHT)
            @sprite.x -= Gosu.offset_x(@angle - 90, speed)
            @sprite.y -= Gosu.offset_y(@angle - 90, speed)
        elsif Gosu.button_down?(Gosu::KB_LEFT)
            @sprite.x += Gosu.offset_x(@angle - 90, speed)
            @sprite.y += Gosu.offset_y(@angle - 90, speed)
        end

        @frame = 0
    end

    def draw
        @sprite.draw(@angle, @frame)
    end
end