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
    def initialize(window, dirname)
        super(window)
        load_map(dirname)
    end

    def load_map(dirname)
        data = JSON.parse(File.read("scenes/#{dirname}/scene_data.json"))
        
        @grid = {}
        @cameras = {}

        data['grid'].each do |line|
            x, y, cam = *line
            @grid[[x, y]] = cam
        end

        data['cameras'].each do |line|
            name = line[0]
            filename = "scenes/#{dirname}/#{name}.png"
            @cameras[name] = Camera.new(filename, @window, *(line.drop(1)))
        end
        
        @active_camera = @cameras.keys.first
    end
    
    def get_active_camera(tile_x, tile_y)
        if @grid.has_key?([tile_x, tile_y])
            @active_camera = @grid[[tile_x, tile_y]]
        else
            raise("Error : no camera found for position [#{x}, #{y}]")
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
        glDisable(GL_TEXTURE_2D)
        glPushMatrix
        glScalef(1, 1, 1)
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

    def button_down(id)
        super(id)
        next_camera if id == Gosu::KB_SPACE
    end

    def update(dt)
        super(dt)
    end

    def draw
        super
        camera = @cameras[@active_camera] 
        camera.draw_background
        Gosu.gl do
            camera.opengl_setup
            draw_debug_tiles
            draw_gizmo
        end
    end
end