class Camera
    attr_reader :debug_color
    def initialize(bg_filename, window, x, y, z, t_x, t_y, t_z, fovy)
        @window = window
        @fovy = fovy
        @x, @y, @z = x, y, z
        @t_x, @t_y, @t_z = t_x, t_y, t_z
        @background = Gosu::Image.new(bg_filename, retro: true)
        @debug_color = Gosu::Color.new(255, Gosu.random(0, 255).floor, Gosu.random(0, 255).floor, Gosu.random(0, 255).floor)
    end

    def draw_background
        @background.draw(0, 0, 0)
    end

    def angle_from_sprite(sprite_x, sprite_y)
        dx = @x - sprite_x
        dy = @y - sprite_y
        angle_rad = Math.atan2(dy, dx)
        angle_deg = angle_rad * 180.0 / Math::PI + 90.0
        return angle_deg
    end

    def opengl_setup
        glEnable(GL_DEPTH_TEST)
        glClear(GL_DEPTH_BUFFER_BIT)
        glEnable(GL_TEXTURE_2D)

        width = @window.fullscreen? ? Gosu.screen_width : @window.width
        height = @window.fullscreen? ? Gosu.screen_height : @window.height
        
        glMatrixMode(GL_PROJECTION)
        glLoadIdentity
        gluPerspective(@fovy, @window.width.to_f / @window.height, 0.1, 2000.0)
        
        glMatrixMode(GL_MODELVIEW)
        glLoadIdentity
        gluLookAt(@x, @y, @z, @t_x, @t_y, @t_z, 0, 0, 1)
    end
end