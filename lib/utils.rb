def lerp(a, b, t)
    a + (b - a) * t
end

class Gosu::Image
    def get_pixel(x, y)
        if x < 0 or x >= self.width or y < 0 or y >= self.height
            return nil
        else
            @blob ||= self.to_blob
            result = @blob[(y * self.width + x) * 4, 4].unpack("C*")
            return Gosu::Color.new(result[3], result[0], result[1], result[2])
        end    
    end
end