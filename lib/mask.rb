class Mask
    def initialize(filename, x, y, z)
        @image = Gosu::Image.new(filename, retro: true)
        @x, @y, @z = x, y, z
    end

    def draw(offset_z)
        @image.draw(@x, @y, offset_z - @z)
    end
end