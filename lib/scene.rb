class Scene
    def initialize(window)
        @window = window
    end

    def button_down(id)
    
    end

    def update(dt)

    end

    def draw

    end
end

class GameScene < Scene
    attr_reader :grid, :blocks
    def initialize(window, dirname)
        super(window)
        load_map(dirname)
        @debug = false
        @hero = Hero.new(self, 'gfx/jill.png', 16, 6)
    end

    def load_map(dirname)
        load_minimap(dirname)
        load_json(dirname)
    end
    
    def load_minimap(dirname)
        @grid = {}
        @blocks = []
        @minimap = Gosu::Image.new("scenes/#{dirname}/minimap.png", retro: true)

        @minimap.width.times do |x|
            @minimap.height.times do |y|
                color = @minimap.get_pixel(x, y)
                camera = case color
                when Gosu::Color::RED then 'CAM_01'
                when Gosu::Color::GREEN then 'CAM_02'
                when Gosu::Color::BLUE then 'CAM_03'
                end

                y = @minimap.height - y # Y is inverted between Gosu and Blender

                @grid[[x, y]] = camera unless camera.nil?
                @blocks.push [x, y] if camera.nil?
            end
        end
    end

    def load_json(dirname)
        data = JSON.parse(File.read("scenes/#{dirname}/cameras_data.json"))
        @cameras = {}

        data.each do |camera_name, infos|
            filename = "scenes/#{dirname}/#{camera_name}.png"
            @cameras[camera_name] = Camera.new(filename, @window, infos['x'], infos['y'], infos['z'], infos['tx'], infos['ty'], infos['tz'], infos['fovy'])
        end
        
        @active_camera = @cameras.keys.first
    end
    
    def get_active_camera(tile_x, tile_y)
        if @grid.has_key?([tile_x, tile_y])
            @active_camera = @grid[[tile_x, tile_y]]
        else
            puts("Error : no camera found for position [#{tile_x}, #{tile_y}]")
        end
    end

    def next_camera
        new_active_camera_index = @cameras.keys.index(@active_camera) + 1
        new_active_camera_index = 0 if new_active_camera_index > @cameras.keys.size - 1
        @active_camera = @cameras.keys[new_active_camera_index]
    end

    def draw_debug_tiles
        glDisable(GL_TEXTURE_2D)
        glBegin(GL_QUADS)
        @grid.each do |coords, camera_name|
            camera = @cameras[camera_name]
            glColor3ub(camera.debug_color.red, camera.debug_color.green, camera.debug_color.blue)
            x, y, z = coords[0], coords[1], 0
            glVertex3f(x, y, z)
            glVertex3f(x, y + 1, z)
            glVertex3f(x + 1, y + 1, z)
            glVertex3f(x + 1, y, z)
        end
        glEnd
        glEnable(GL_TEXTURE_2D)
    end

    def draw_gizmo
        size, width = 3.0, 3.0
        glDisable(GL_TEXTURE_2D)
        glPushMatrix
        glScalef(size, size, size)
        glLineWidth(width)
        glBegin(GL_LINES)
            # X axis
            glColor3f(1, 0, 0)
            glVertex3f(0, 0, 0)
            glVertex3f(1, 0, 0)
            # Y axis
            glColor3f(0, 1, 0)
            glVertex3f(0, 0, 0)
            glVertex3f(0, 1, 0)
            # Z axis
            glColor3f(0, 0, 1)
            glVertex3f(0, 0, 0)
            glVertex3f(0, 0, 1)
        glEnd
        glPopMatrix
        glEnable(GL_TEXTURE_2D)
    end

    def draw_minimap
        x, y, z = 10, 10, 10
        @minimap.draw(x, y, z)
        Gosu.draw_rect(@hero.sprite.x.floor + x, @minimap.height - @hero.sprite.y.floor + y, 1, 1, Gosu::Color::WHITE, z + 1)
    end

    def button_down(id)
        super(id)
        @debug = !@debug if id == Gosu::KB_D
        next_camera if id == Gosu::KB_SPACE
    end

    def update(dt)
        super(dt)
        @hero.update(dt, @cameras[@active_camera])
        get_active_camera(@hero.sprite.x.floor, @hero.sprite.y.floor)

        @window.caption = "Camera : #{@active_camera} | HERO : #{@hero.sprite.x.floor(2)}, #{@hero.sprite.y.floor(2)}, #{@hero.sprite.z.floor(2)}"
    end

    def draw
        super
        camera = @cameras[@active_camera] 
        camera.draw_background
        Gosu.gl(1) do
            camera.opengl_setup
            @hero.draw
            if @debug
                draw_debug_tiles
                draw_gizmo
            end
        end
        Gosu.scale(4, 4) { draw_minimap }        
    end
end