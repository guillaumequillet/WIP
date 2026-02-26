class Hero
    attr_reader :sprite, :angle, :radius
    def initialize(scene, spritesheet, x, y, z = 0, orientation = :north)
        @scene = scene
        @sprite = Sprite.new(spritesheet, x, y, 0, 3)
        @speed = 0.005
        @angle = 0
        @radius = 0.25
        @walk, @rows = [1, 0, 1, 2], { dos: 0, droite: 1, face: 2, gauche: 3 }
        @frame = 1
        @shadow = Gosu::Image.new('gfx/shadow.png', retro: true)

        @sfx = {
            walk: [Gosu::Sample.new('sfx/step_1.mp3'), Gosu::Sample.new('sfx/step_2.mp3'), Gosu::Sample.new('sfx/step_3.mp3'), Gosu::Sample.new('sfx/step_4.mp3')]
        }

        orient(orientation)
    end

    def orient(orientation)
        camera = @scene.get_active_camera
        @angle = case orientation
        when :north then camera.yaw
        when :south then camera.yaw + Math::PI
        when :east then camera.yaw - (Math::PI / 2.0)
        when :west then camera.yaw + (Math::PI / 2.0)
        end
    end

    def update(dt, camera)
        l, r, u, d = Gosu.button_down?(Gosu::KB_LEFT), Gosu.button_down?(Gosu::KB_RIGHT), Gosu.button_down?(Gosu::KB_UP), Gosu.button_down?(Gosu::KB_DOWN)

        dx_screen = (r ? 1 : 0) - (l ? 1 : 0)
        dy_screen = (u ? 1 : 0) - (d ? 1 : 0)
        @moving = (dx_screen != 0 || dy_screen != 0)

        if @moving
            input_angle = Math.atan2(dy_screen, dx_screen)
            @angle = camera.yaw + input_angle - Math::PI / 2.0
            mv_x = Math.cos(@angle) * @speed * dt
            mv_y = Math.sin(@angle) * @speed * dt

            collisions = @scene.blocks
            @sprite.x += mv_x unless collisions.any? { |b| hit?(b, @sprite.x + mv_x, @sprite.y, @radius) }
            @sprite.y += mv_y unless collisions.any? { |b| hit?(b, @sprite.x, @sprite.y + mv_y, @radius) }
        end

        rel = (@angle - camera.yaw + Math::PI) % (2 * Math::PI) - Math::PI
        @dir = rel.abs < Math::PI * 0.25 ? :dos : (rel.abs > Math::PI * 0.75 ? :face : (rel > 0 ? :droite : :gauche))
    end

    def hit?(collision, px, py, r)
        x_min, y_min = collision[0], collision[1]
        x_max, y_max = x_min + 1, y_min + 1
        (px + r > x_min && px - r < x_max) && (py + r > y_min && py - r < y_max) 
    end

    def draw_shadow
        s_info = @shadow.gl_tex_info; return unless s_info
        glEnable(GL_TEXTURE_2D); glBindTexture(GL_TEXTURE_2D, s_info.tex_name)
        glEnable(GL_BLEND); glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
        s_sz = 0.75
        glPushMatrix
        glTranslatef(@sprite.x, @sprite.y, @sprite.z)
        glBegin(GL_QUADS)
            glTexCoord2f(s_info.left, s_info.bottom);  glVertex3f(-s_sz, -s_sz, 0.01)
            glTexCoord2f(s_info.right, s_info.bottom); glVertex3f(s_sz, -s_sz, 0.01)
            glTexCoord2f(s_info.right, s_info.top);    glVertex3f(s_sz, s_sz, 0.01)
            glTexCoord2f(s_info.left, s_info.top);     glVertex3f(-s_sz, s_sz, 0.01)
        glEnd
        glPopMatrix
        glDisable(GL_BLEND)
    end

    def draw(camera)
        frame = @moving ? @walk[(Gosu.milliseconds / 160) % 4] : 1

        # if we're moving and changing foot
        if frame != 1 && frame != @frame
            @frame = frame
            @sfx[:walk].sample.play(0.05)
        end

        tile = @rows[@dir] * 3 + frame
        draw_shadow
        @sprite.draw(camera.yaw, tile)
    end
end