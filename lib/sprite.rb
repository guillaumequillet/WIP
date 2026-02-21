class Sprite
    FRAME_SIZE = 32 

    attr_accessor :x, :y, :z, :scale

    def initialize(filename, x, y, z, scale)
        @frames = Gosu::Image.load_tiles(filename, FRAME_SIZE, FRAME_SIZE, retro: true)

        @frames.each do |frame|
            glBindTexture(GL_TEXTURE_2D, frame.gl_tex_info.tex_name)
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
        end

        @x, @y, @z = x, y, z
        @scale = scale
    end

    def draw(billboard_angle, frame)
        tex = @frames[frame].gl_tex_info
        glColor3f(1, 1, 1)
        glBindTexture(GL_TEXTURE_2D, tex.tex_name)

        glEnable(GL_TEXTURE_2D)
        glEnable(GL_ALPHA_TEST)
        glAlphaFunc(GL_GREATER, 0)
        glDisable(GL_CULL_FACE)
        glPushMatrix
        glTranslatef(@x, @y, @z)
        glScalef(@scale, @scale, @scale)
        glRotatef(billboard_angle * 180.0 / Math::PI + 90, 0, 0, 1)
        glBegin(GL_QUADS)
            glTexCoord2d(tex.left, tex.top);     glVertex3f(-0.5, 0.0, 1.0)
            glTexCoord2d(tex.left, tex.bottom);  glVertex3f(-0.5, 0.0, 0.0)
            glTexCoord2d(tex.right, tex.bottom); glVertex3f(0.5, 0.0, 0.0)
            glTexCoord2d(tex.right, tex.top);    glVertex3f(0.5, 0.0, 1.0)
        glEnd
        glPopMatrix
        glDisable(GL_ALPHA_TEST)
    end
end