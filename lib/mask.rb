class Mask
    def initialize(filename, x, y, z, opacity)
        @image = Gosu::Image.new(filename, retro: true)
        @x, @y, @z = x, y, z
        @color = Gosu::Color.new((opacity * 255).floor, 255, 255, 255)
    end

    def draw(offset_z)
        @image.draw(@x, @y, offset_z - @z, 1, 1, @color)
    end
end