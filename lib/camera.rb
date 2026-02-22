class Camera
    attr_reader :debug_color, :x, :y, :z, :yaw
    def initialize(bg_filename, window, x, y, z, t_x, t_y, t_z, fovy)
        @window = window
        @fovy = fovy
        @x, @y, @z = x, y, z
        @t_x, @t_y, @t_z = t_x, t_y, t_z
        @background = Gosu::Image.new(bg_filename, retro: true)
        @debug_color = Gosu::Color.new(255, Gosu.random(0, 255).floor, Gosu.random(0, 255).floor, Gosu.random(0, 255).floor)
        @yaw = Math.atan2(@t_y - @y, @t_x - @x)
        @masks = []
    end

    def add_mask(filename, x, y, z, opacity)
        @masks.push Mask.new(filename, x, y, z, opacity)
    end

    def draw_background
        width = @window.fullscreen? ? Gosu.screen_width : @window.width
        scale = width.to_f / width
        @background.draw(0, 0, 0, scale, scale)
    end

    def distance_from(x, y, z)
        dx = @x - x
        dy = @y - y
        dz = @z - z
        Math.sqrt(dx*dx + dy*dy + dz*dz)
    end

    def opengl_setup
        glEnable(GL_DEPTH_TEST)
        glClear(GL_DEPTH_BUFFER_BIT)
        glEnable(GL_TEXTURE_2D)

        width = @window.fullscreen? ? Gosu.screen_width : @window.width
        height = @window.fullscreen? ? Gosu.screen_height : @window.height
        
        glMatrixMode(GL_PROJECTION)
        glLoadIdentity
        gluPerspective(@fovy, width.to_f / height, 0.01, 2000.0)
        
        glMatrixMode(GL_MODELVIEW)
        glLoadIdentity
        gluLookAt(@x, @y, @z, @t_x, @t_y, @t_z, 0, 0, 1)
    end

    def draw_masks(offset_z)
        @masks.each {|mask| mask.draw(offset_z)}
    end
end