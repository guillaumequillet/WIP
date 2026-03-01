class Scene
    attr_reader :window
    def initialize(window)
        @window = window
        @sounds = {}
    end

    def button_down(id)
    
    end

    def update(dt)

    end

    def draw

    end
end

class GameScene < Scene
    attr_reader :grid, :blocks, :hero, :font
    def initialize(window, dirname, hero_tile_x = 0, hero_tile_y = 0)
        super(window)
        load_map(dirname)
        load_hero(hero_tile_x, hero_tile_y)
        load_sounds
        @debug = false

        #fading
        @fade_alpha = 0
        @fade_state = :none # :none, :out, :in
        @fade_speed = 8

        @font = Gosu::Font.new(24, { name: Gosu.default_font_name })
    end

    def load_sounds
        @sounds['door'] = Gosu::Sample.new('sfx/369618__cribbler__door-close-open-int.mp3')
        @sounds['unlock_door'] = Gosu::Sample.new('sfx/unlock_door.mp3')
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

    def teleport
        if @sounds.has_key?(@teleport_sound)
            @sounds[@teleport_sound].play(0.05)
        end
        load_map(@teleport_dirname)
        load_hero(@teleport_tile_x, @teleport_tile_y, @teleport_orientation)
    end

    def ask_for_teleport(dirname, tile_x, tile_y, orientation, sound)
        @teleport_dirname = dirname
        @teleport_tile_x = tile_x
        @teleport_tile_y = tile_y
        @teleport_orientation = orientation
        @teleport_sound = sound
        @fade_state = :out
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
                    @events.push TeleportEvent.new(self, event['trigger'], event['position'], { target_map: event['target_map'], target_position: event['target_position'], target_orientation: event['target_orientation'].to_sym, sound: event['sound']})
                elsif event['type'] == 'examine'
                    @events.push ExamineEvent.new(self, event['trigger'], event['position'], { text: event['text'] })
                end
            end
        end

        # events JSON file
        @particles = {}
        path = "scenes/#{dirname}/particles.json"
        if File.exist?(path)
            data = JSON.parse(File.read(path))
            data.each do |particle|
                @particles[particle['camera']] ||= []
                case particle['type']
                    when 'Candle' then @particles[particle['camera']].push Candle.new(particle['x'], particle['y'], particle['scale'])
                    when 'Bugs'   then @particles[particle['camera']].push Bugs.new(particle['x'], particle['y'], particle['qty'])
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

    def update_fading
        case @fade_state
        when :out
            @fade_alpha += @fade_speed
            if @fade_alpha >= 255
                @fade_alpha = 255
                @fade_state = :in
                teleport # we can now teleport because fade out is over
            end
        when :in
            @fade_alpha -= @fade_speed
            if @fade_alpha <= 0
                @fade_alpha = 0
                @fade_state = :none
            end
        end
    end

    def should_freeze_inputs?
        displaying_text =  @events.any? {|event| event.is_a?(ExamineEvent) && event.displaying_text}
        fading = @fade_state != :none
        return [displaying_text, fading].any?
    end

    def update(dt)
        super(dt)
        update_fading
        
        @hero.update(dt, @cameras[@active_camera])
        set_active_camera(@hero)
        
        if @particles.has_key?(@active_camera)
            @particles[@active_camera].each {|particle| particle.update}
        end
        
        @events.each {|event| event.update(dt, @hero)}
        
        @window.caption = "Hero Position [#{@hero.sprite.x.floor}, #{@hero.sprite.y.floor}]"
    end

    def draw_fading
        if @fade_state != :none && @fade_alpha > 0
            Gosu.draw_rect(0, 0, @window.width, @window.height, Gosu::Color.new(@fade_alpha, 0, 0, 0), 10000)
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

        if @particles.has_key?(@active_camera)
            @particles[@active_camera].each {|particle| particle.draw}
        end

        @events.each {|event| event.draw(@hero)}

        camera.draw_masks(z_offset)
        Gosu.scale(4, 4) { draw_minimap(1000) }        
        draw_fading
    end
end