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
            @scene.draw_prompt("[#{Gosu.button_name(VALIDATION_KEY)}] Open Door")
        end
    end
end