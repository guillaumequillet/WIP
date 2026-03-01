class Event
    VALIDATION_KEY = Gosu::KB_RETURN # temp
    
    attr_accessor :active
    def initialize(scene, type, trigger, position, size, parameters)
        @scene = scene
        @type = type
        @position = position
        @size = size
        @trigger = trigger
        @parameters = parameters
    end

    def button_down(id)
        process if (@trigger == 'validation_key' && id == VALIDATION_KEY && collides?(@scene.hero.sprite.x, @scene.hero.sprite.y, @scene.hero.radius))
    end

    def collides?(px, py, r)
        x_min, y_min = @position[0], @position[1]
        x_max, y_max = x_min + @size[0], y_min + @size[1]
        (px + r > x_min && px - r < x_max) && (py + r > y_min && py - r < y_max) 
    end

    def process

    end

    def update(dt, hero)
        
    end

    def draw_prompt(text, center = false)
        padding = 10
        max_width = @scene.window.width - padding * 2
        @lines = []
        @lines.push '' # first line
        max_line_width = 0

        text.split(' ').each_with_index do |word, i|
            current_line_width = @scene.font.text_width(@lines.last)
            next_word_width = @scene.font.text_width(word)

            if current_line_width + next_word_width <= max_width
                @lines[@lines.size - 1] += (word + ' ')
            else
                @lines.push (word + ' ')
            end

            last_line_width = @scene.font.text_width(@lines.last)
            max_line_width = last_line_width if last_line_width > max_line_width
        end

        height = @lines.size * @scene.font.height + 2 * padding

        Gosu.draw_rect(0, @scene.window.height - height, @scene.window.width, height, Gosu::Color.new(200, 0, 0, 0), 10000)
        @lines.each_with_index do |line, i|
            x = center ? (@scene.window.width - max_line_width) / 2 + padding : padding
            y = @scene.window.height - height + @scene.font.height * i + padding
            z = 10000
            @scene.font.draw_text(line, x, y, z)
        end
    end

    def draw(hero)
        
    end
end

class TeleportEvent < Event
    def initialize(scene, trigger, position, size, parameters)
        super(scene, 'teleport', trigger, position, size, parameters)
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
            draw_prompt("[#{Gosu.button_name(VALIDATION_KEY)}] Open Door", true)
        end
    end
end

class ExamineEvent < Event
    attr_reader :displaying_text
    def initialize(scene, trigger, position, size, parameters)    
        super(scene, 'examine', trigger, position, size, parameters)
        @cursor = 0
        @displaying_text = false
        @letter_duration = 2
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
            draw_prompt("[#{Gosu.button_name(VALIDATION_KEY)}] Examine", true)
        end
    end 
end