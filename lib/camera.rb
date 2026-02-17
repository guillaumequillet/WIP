class Camera
    attr_reader :x, :y, :window, :height
    def initialize(window, target)
        @window = window
        @target = target
        @x, @y = @target.x, @target.y
        @height = 96
        @offset_x = 96
    end

    def update(dt)
        target_x = @target.x - @window.width / 2 + @offset_x
        target_y = @target.y - @window.height + @height
        @x = lerp(@x, target_x, 0.1)
        @y = target_y
    end

    def look
        Gosu.translate(-@x, -@y) do
            yield
        end
    end
end