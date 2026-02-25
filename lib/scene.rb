class Scene
    attr_reader :window
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
    attr_reader :grid, :blocks, :hero
    def initialize(window, dirname, hero_tile_x = 0, hero_tile_y = 0)
        super(window)
        load_map(dirname)
        load_hero(hero_tile_x, hero_tile_y)
        @debug = false

        # temp
        @flames = {}
        @flames['CAM_01'] = []
        @flames['CAM_01'].push << Flame.new(self, 42, 259, 2.7, :candle)
        @flames['CAM_01'].push << Flame.new(self, 606, 259, 2.7, :candle)
        @flames['CAM_02'] = []
        @flames['CAM_02'].push << Flame.new(self, 186, 223, 1.5, :candle)
        @flames['CAM_02'].push << Flame.new(self, 457, 222, 1.5, :candle)
        @flames['CAM_02'].push << Flame.new(self, 640, 275, 2.0, :candle)
        @flames['CAM_03'] = []
        @flames['CAM_03'].push << Flame.new(self, 362, 194, 1.5, :candle)
        @flames['CAM_06'] = []
        @flames['CAM_06'].push << Flame.new(self, 248, 138, 2.5, :candle)
        @flames['CAM_05'] = []
        @flames['CAM_05'].push << Flame.new(self, 392, 181, 2.5, :candle)
        @flames['CAM_04'] = []
        @flames['CAM_04'].push << Flame.new(self, 276, 194, 1.5, :candle)
        @flames['CAM_07'] = []
        @flames['CAM_07'].push << Flame.new(self, 259, 278, 1.0, :candle)
        @flames['CAM_08'] = []
        @flames['CAM_08'].push << Flame.new(self, 373, 170, 1.0, :candle)
        @flames['CAM_09'] = []
        @flames['CAM_09'].push << Flame.new(self, 59, 54, 1.0, :candle)
        @flames['CAM_09'].push << Flame.new(self, 583, 51, 1.0, :candle)
    end
    
    def load_map(dirname)
        load_minimap(dirname)
        load_jsons(dirname)
        load_masks(dirname)
    end

    def load_hero(tile_x = 0, tile_y = 0, orientation = :north)
        unless defined?(@hero)
            @hero = Hero.new(self, 'gfx/jill.png', tile_x, tile_y, orientation)
        else
            @hero.sprite.x = tile_x
            @hero.sprite.y = tile_y
            @hero.orient(orientation)
        end
    end

    def teleport(dirname, tile_x, tile_y, orientation)
        load_map(dirname)
        load_hero(tile_x, tile_y, orientation)
    end
    
    def load_minimap(dirname)
        @grid = {}
        @blocks = []
        @minimap = Gosu::Image.new("scenes/#{dirname}/minimap.png", retro: true)
        @minimap_layout = Gosu::Image.new("scenes/#{dirname}/minimap_layout.png", retro: true)

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

                if !camera.nil?
                    @grid[[x, y]] = camera
                else
                    @blocks.push [x, y]
                end
            end
        end
    end

    def load_jsons(dirname)
        # events JSON file
        @events = []
        path = "scenes/#{dirname}/events.json"
        if File.exist?(path)
            data = JSON.parse(File.read(path))
            data.each do |event|
                if event['type'] == 'teleport'
                    @events.push TeleportEvent.new(self, event['trigger'], event['position'], { target_map: event['target_map'], target_position: event['target_position'], target_orientation: event['target_orientation'].to_sym})
                end
            end
        end

        # camera JSON file
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
    
    def set_active_camera(hero)
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

    def get_active_camera
        return @cameras[@active_camera]
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
        x, y, z = 2, 2, z
        if @debug
            @minimap.draw(x, y, z)
            Gosu.draw_rect(@minimap.width - @hero.sprite.x.floor + x, @hero.sprite.y.floor + y, 1, 1, Gosu::Color::WHITE, z + 1)
        else
            @minimap_layout.draw(x, y, z, 1, 1, Gosu::Color.new(200, 255, 255, 255))
            Gosu.draw_rect(@minimap.width - @hero.sprite.x.floor + x, @hero.sprite.y.floor + y, 1, 1, Gosu::Color::GREEN, z + 1)
        end
    end

    def button_down(id)
        super(id)
        @debug = !@debug if id == Gosu::KB_D
        @events.each {|event| event.button_down(id)}
    end

    def update(dt)
        super(dt)
        @hero.update(dt, @cameras[@active_camera])
        set_active_camera(@hero)

        @events.each {|event| event.update(dt, @hero)}

        # temp
        if @flames.has_key?(@active_camera)
            @flames[@active_camera].each {|flame| flame.update}
        end
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

        # temp
        if @flames.has_key?(@active_camera)
            @flames[@active_camera].each {|flame| flame.draw}
        end

        camera.draw_masks(z_offset)
        Gosu.scale(4, 4) { draw_minimap(1000) }        
    end
end