class Sprite
    FRAME_SIZE = 32 

    attr_accessor :x, :y, :z

    def initialize(filename, x, y, z, scale)
        @texture = Gosu::Image.load_tiles(filename, FRAME_SIZE, FRAME_SIZE, retro: true)
        @x, @y, @z = x, y, z
        @scale = scale
    end

    def draw(billboard_angle = 0.0)
        frame = @texture.first # temp
        tex = frame.gl_tex_info

        glEnable(GL_ALPHA_TEST)
        glAlphaFunc(GL_GREATER, 0)
        glPushMatrix
        glTranslatef(@x, @y, @z)
        glScalef(@scale, @scale, @scale)
        glRotatef(billboard_angle, 0, 0, 1)
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