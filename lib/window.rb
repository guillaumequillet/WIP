require 'json'

class Window < Gosu::Window
    def initialize
        load_config_file
        super(@width, @height, @fullscreen)
        self.caption = @title
        @scene = GameScene.new(self, 'vestiaire', 8, 6)
        # @scene = GameScene.new(self, 'hall', 16, 8)
    end

    def load_config_file
        config_file = 'config.json'
        config_data = JSON.parse(File.read(config_file))

        @title = config_data['window']['title']
        @width = config_data['window']['width']
        @height = config_data['window']['height']
        @fullscreen = config_data['window']['fullscreen']
        @needs_cursor = config_data['window']['mouse_cursor']

        @keys = {
            exit: config_data['keys']['exit'].map {|e| eval(e)}
        }
    end

    def button_down(id)
        super
        close! if action_key_press?(:exit, id)
        @scene.button_down(id)
    end

    def action_key_press?(action, id)
        @keys[action].any? {|key| key == id}
    end
    
    def toggle_fullscreen
        self.fullscreen = !self.fullscreen?
    end

    def toggle_cursor
        @needs_cursor = !@needs_cursor
    end

    def needs_cursor?
        @needs_cursor
    end

    def calculate_elapsed_time
        @delta_time_tick ||= Gosu.milliseconds
        @delta_time = Gosu.milliseconds - @delta_time_tick
        @delta_time_tick = Gosu.milliseconds
    end

    def update
        calculate_elapsed_time
        @scene.update(@delta_time)
    end

    def draw
        @scene.draw
    end
end
