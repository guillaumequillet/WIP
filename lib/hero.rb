class Hero
    attr_reader :sprite
    def initialize(spritesheet, x, y, z = 0)
        @sprite = Sprite.new(spritesheet, x, y, 0, 2)
        @speed = 0.1
        @angle = 0
    end

    def update(dt, camera)
        @angle = camera.angle_from_sprite(@sprite.x, @sprite.y)
    end

    def draw
        @sprite.draw(@angle)
    end
end