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
        @hero = Hero.new(self, 'gfx/jill.png', 15, 5)
    end

    def load_map(dirname)
        load_minimap(dirname)
        load_json(dirname)
        load_masks(dirname)
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
                when Gosu::Color.new(255, 255, 0, 255) then 'CAM_04' # purple
                when Gosu::Color.new(255, 246, 111, 11) then 'CAM_05' # orange
                when Gosu::Color.new(255, 255, 255, 0) then 'CAM_06' # yellow
                when Gosu::Color.new(255, 0, 255, 255) then 'CAM_07' # cyan
                when Gosu::Color.new(255, 128, 128, 128) then 'CAM_08' # grey
                when Gosu::Color.new(255, 6, 112, 24) then 'CAM_09' # darker green
                end

                x = @minimap.width - x # X axis is inverted, Y was flipped in the image editor

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

    def load_masks(dirname)
        @masks = []
        path = "scenes/#{dirname}/masks/masks.json"

        return unless File.exist?(path)

        data = JSON.parse(File.read(path))

        data.each do |mask|
            camera = mask['camera']
            filename = "scenes/#{dirname}/masks/#{mask['image']}"
            x, y, z = mask['offset_2d_x'], mask['offset_2d_y'], @cameras[camera].distance_from(mask['x'], mask['y'], mask['z'])
            @cameras[camera].add_mask(filename, x, y, z, mask['opacity'])
        end
    end
    
    def get_active_camera(hero)
        x = hero.sprite.x
        y = hero.sprite.y
        angle = hero.angle
        tolerance = 0.25

        probe_x = x + Math.cos(angle) * tolerance
        probe_y = y + Math.sin(angle) * tolerance

        tile_x = probe_x.floor
        tile_y = probe_y.floor

        if [tile_x, tile_y] != [x.floor, y.floor] && @grid.has_key?([tile_x, tile_y])
            @active_camera = @grid[[tile_x, tile_y]]
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

    def draw_minimap(z)
        x, y, z = 10, 10, z
        @minimap.draw(x, y, z)
        Gosu.draw_rect(@minimap.width - @hero.sprite.x.floor + x, @hero.sprite.y.floor + y, 1, 1, Gosu::Color::WHITE, z + 1)
    end

    def button_down(id)
        super(id)
        @debug = !@debug if id == Gosu::KB_D
        next_camera if id == Gosu::KB_SPACE
    end

    def update(dt)
        super(dt)
        @hero.update(dt, @cameras[@active_camera])
        get_active_camera(@hero)

        distance = @cameras[@active_camera].distance_from(@hero.sprite.x, @hero.sprite.y, @hero.sprite.z).floor(2)
        @window.caption = "Camera : #{@active_camera} | HERO : #{@hero.sprite.x.floor(2)}, #{@hero.sprite.y.floor(2)}, #{@hero.sprite.z.floor(2)}, Distance camera : #{distance}"
    end

    def draw
        super
        z_offset = 1000
        camera = @cameras[@active_camera] 
        camera.draw_background

        hero_distance = camera.distance_from(@hero.sprite.x, @hero.sprite.y, @hero.sprite.z)
        Gosu.gl(z_offset - hero_distance) do
            camera.opengl_setup
            @hero.draw(camera)
            if @debug
                draw_debug_tiles
                draw_gizmo
            end
        end
        camera.draw_masks(z_offset)
        Gosu.scale(4, 4) { draw_minimap(1000) }        
    end
end