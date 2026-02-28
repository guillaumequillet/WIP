class Bug
    VITESSE_MAX = 0.18
    TAILLE_MIN = 1.0
    TAILLE_MAX = 3.5
    ALPHA_MIN = 100 
    ALPHA_MAX = 255

    attr_reader :z

    def initialize(centre_x, centre_y)
        @centre_x = centre_x
        @centre_y = centre_y
        @angle = rand(0..2 * Math::PI)
        @speed = rand(0.06..VITESSE_MAX)
        @radius = rand(15..50)
        @base_y = rand(@centre_y - 15..@centre_y + 25)
        @y_jitter = rand(-10..10)
    end

    def update
        @angle += @speed
        @base_x = @centre_x + Math.cos(@angle) * @radius
        @z = Math.sin(@angle)
        @y = @base_y + rand(@y_jitter-2..@y_jitter+2)
    end

    def color_at_depth
        perspective_factor = (@z + 1.0) / 2.0
        alpha = (ALPHA_MIN + (ALPHA_MAX - ALPHA_MIN) * perspective_factor).to_i
        Gosu::Color.new(alpha, 10, 10, 10)
    end

    def scale_at_depth
        perspective_factor = (@z + 1.0) / 2.0
        TAILLE_MIN + (TAILLE_MAX - TAILLE_MIN) * perspective_factor
    end

    def draw
        scale = scale_at_depth
        color = color_at_depth
        draw_x = @base_x - scale/2
        draw_y = @y - scale/2
        Gosu.draw_rect(draw_x, draw_y, scale, scale, color, 1)
    end
end

class Bugs
    def initialize(x, y, qty)
        @x = x
        @y = y
        @bugs = []
        qty.times { @bugs << Bug.new(@x, @y) }
    end

    def update
        @bugs.each {|bug| bug.update}
    end

    def draw
        unless @bugs.empty?
            bugs_tries = @bugs.sort_by { |m| m.z }
            bugs_tries.each {|bug| bug.draw}
        end
    end
end