class Event
    VALIDATION_KEY = Gosu::KB_RETURN # temp
    def initialize(scene, type, trigger, position, parameters)
        @scene = scene
        @type = type
        @position = position
        @trigger = trigger
        @parameters = parameters
    end

    def button_down(id)
        process if (@trigger == 'validation_key' && id == VALIDATION_KEY && collides?(@scene.hero.sprite.x, @scene.hero.sprite.y, @scene.hero.radius))
    end

    def collides?(px, py, r)
        x_min, y_min = @position[0], @position[1]
        x_max, y_max = x_min + 1, y_min + 1
        (px + r > x_min && px - r < x_max) && (py + r > y_min && py - r < y_max) 
    end

    def process

    end

    def update(dt, hero)
        
    end

    def draw_prompt(text)
        height = 30
        Gosu.draw_rect(0, @scene.window.height - height - 10, @scene.window.width, height, Gosu::Color.new(128, 0, 0, 0), 10000)
        @scene.font.draw_text(text, (@scene.window.width - @scene.font.text_width(text)) / 2, @scene.window.height - height - 7, 10000)
    end

    def draw(hero)
        
    end
end

class TeleportEvent < Event
    def initialize(scene, trigger, position, parameters)
        super(scene, 'teleport', trigger, position, parameters)
    end

    def process
        super
        teleport
    end

    def teleport
        dirname, x, y = @parameters[:target_map], @parameters[:target_position][0], @parameters[:target_position][1]
        orientation = @parameters[:target_orientation]
        sound = @parameters[:sound]
        @scene.ask_for_teleport(dirname, x, y, orientation, sound)
    end

    def draw(hero)
        super(hero)
        if collides?(hero.sprite.x, hero.sprite.y, hero.radius)
            draw_prompt("[#{Gosu.button_name(VALIDATION_KEY)}] Open Door")
        end
    end
end

class ExamineEvent < Event
    attr_reader :displaying_text
    def initialize(scene, trigger, position, parameters)    
        super(scene, 'examine', trigger, position, parameters)
        @cursor = 0
        @displaying_text = false
        @letter_duration = 5
    end
    
    def process
        super

        if @displaying_text
            if @cursor.floor < @parameters[:text].size
                @cursor = @parameters[:text].size
            # if we press VALIDATION_KEY and the text was already fully displayed, we don't display it anymore
            else
                @displaying_text = false
                @cusor = 0
            end
        else
            @cursor = 0
            @displaying_text = true
            @cursor_tick = Gosu.milliseconds
        end
    end
        
    def update(dt, hero)
        super(dt, hero)
        if @displaying_text
            if Gosu.milliseconds - @cursor_tick >= @letter_duration && @cursor < @parameters[:text].size
                @cursor += 1
                @cursor_tick = Gosu.milliseconds
            end
        end
    end

    def draw(hero)
        super(hero)
        
        if @displaying_text
            draw_prompt(@parameters[:text].slice(0, @cursor))
        elsif collides?(hero.sprite.x, hero.sprite.y, hero.radius)
            draw_prompt("[#{Gosu.button_name(VALIDATION_KEY)}] Examine")
        end
    end 
end