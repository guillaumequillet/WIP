class Hero
    def initialize(spritesheet, x, y, z = 0)
        @sprite = Sprite.new(spritesheet, x, y, 0, 2)
    end

    def update(dt)

    end

    def draw(camera)
        billboard_angle = camera.angle_from_sprite(@sprite.x, @sprite.y)
        @sprite.draw(billboard_angle)
    end
end