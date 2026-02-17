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
    def button_down(id)
        super(id)
        shake_screen(10) if id == Gosu::KB_SPACE
    end
    
    def shake_screen(intensity)
        @shake_intensity = intensity
    end

    def check_for_shaking
        @shake_intensity ||= 0 

        if @shake_intensity > 0
            @shake_intensity *= 0.9
            if @shake_intensity < 0.1
                @shake_intensity = 0
                @shake_offset_x, @shake_offset_y = 0, 0
            else
                @shake_offset_x = Gosu.random(-@shake_intensity, @shake_intensity)
                @shake_offset_y = Gosu.random(-@shake_intensity, @shake_intensity)
            end
        else
            @shake_offset_x, @shake_offset_y = 0, 0
        end
    end

    def update(dt)
        super(dt)
        check_for_shaking
    end

    def draw_scene
        @bg ||= Gosu::Image.new('gfx/bg.png', retro: true)
        @bg.draw(0, 0, 0)
    end

    def draw_hud

    end

    def draw
        Gosu.translate(@shake_offset_x, @shake_offset_y) do
           draw_scene 
        end
        draw_hud 
    end
end