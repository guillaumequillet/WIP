require 'gosu'
require 'opengl'
require 'glu'
require 'json'

# --- CONFIGURATION ---
module Config
  BASE_PATH = "E:/PROG/RUBY/WIP/scenes"
  JSON_FILE = "scenes_data.json"
  SPRITE_FILE = "gfx/jill.png" 
  SCREEN_WIDTH, SCREEN_HEIGHT = 640, 480
  JILL_SIZE = 16.0
  # RÉGLAGES VALIDÉS
  JILL_SPEED = 0.5
  ROT_SPEED = 0.07
end

OpenGL.load_lib; GLU.load_lib
include OpenGL, GLU

# --- TRIGGER ZONE ---
class TriggerZone
  attr_reader :cam_id
  def initialize(d); @cam_id=d["cam_id"]; @x=d["x_min"]..d["x_max"]; @y=d["y_min"]..d["y_max"]; end
  def inside?(px, py); @x.cover?(px) && @y.cover?(py); end
end

# --- CAMERA ---
class Camera
  attr_reader :id, :pos, :look_at, :fov, :image, :yaw
  def initialize(id, data, base_path)
    @id = id; @pos, @look_at, @fov = data["pos"], data["look_at"], data["fov"]
    img = File.join(base_path, "#{id}.png")
    @image = Gosu::Image.new(img, retro: true) if File.exist?(img)
    @yaw = Math.atan2(@look_at[1] - @pos[1], @look_at[0] - @pos[0])
  end
  def apply_view(w)
    glMatrixMode(GL_PROJECTION); glLoadIdentity; gluPerspective(@fov, w.width.to_f/w.height, 0.1, 2000.0)
    glMatrixMode(GL_MODELVIEW); glLoadIdentity; gluLookAt(@pos[0], @pos[1], @pos[2], @look_at[0], @look_at[1], @look_at[2], 0, 0, 1)
  end
end

# --- ENTITY (JILL 4-DIR + COMPASS) ---
class Entity
  attr_accessor :x, :y, :angle
  def initialize(f, x, y)
    @tiles = Gosu::Image.load_tiles(f, 32, 32, retro: true)
    @x, @y, @angle = x, y, 0.0
    @dir_idx = 2
    @moving = false
    @walk_seq = [1, 0, 1, 2]
    @rows = { dos: 0, droite: 1, face: 2, gauche: 3 }
    
    # Ombre (z=0.05)
    @shadow_tex = Gosu.render(32, 32, retro: true) do
      c = Gosu::Color.new(100, 0, 0, 0); r = 14.0; center = 16
      32.times{|y| 32.times{|x| Gosu.draw_rect(x,y,1,1,c) if Math.sqrt((x-center)**2+(y-center)**2) <= r }}
    end

    # Boussole (z=0.06)
    @compass_tex = Gosu.render(32, 32, retro: true) do
      c = Gosu::Color.new(255, 255, 255, 200)
      Gosu.draw_triangle(28, 16, c, 16, 4, c, 16, 28, c)
      Gosu.draw_rect(4, 12, 14, 8, c)
    end
  end

  def update(camera)
    # TANK CONTROL : Tourner à gauche augmente l'angle
    @angle += Config::ROT_SPEED if Gosu.button_down?(Gosu::KB_LEFT)
    @angle -= Config::ROT_SPEED if Gosu.button_down?(Gosu::KB_RIGHT)
    
    move = 0
    move = 1 if Gosu.button_down?(Gosu::KB_UP)
    move = -0.5 if Gosu.button_down?(Gosu::KB_DOWN)
    
    @moving = (move != 0)
    if @moving
      @x += Math.cos(@angle) * move * Config::JILL_SPEED
      @y += Math.sin(@angle) * move * Config::JILL_SPEED
    end

    # SÉLECTION ANIMATION : LE FIX FINAL
    rel = (@angle - camera.yaw + Math::PI) % (2 * Math::PI) - Math::PI
    if rel.abs < Math::PI * 0.25      then @dir_idx = @rows[:dos]
    elsif rel.abs > Math::PI * 0.75    then @dir_idx = @rows[:face]
    elsif rel > 0                     then @dir_idx = @rows[:droite] # Fleche à gauche -> Sprite Droite
    else                                   @dir_idx = @rows[:gauche] # Fleche à droite -> Sprite Gauche
    end
  end

  def draw(camera)
    frame = @moving ? @walk_seq[(Gosu.milliseconds / 150) % 4] : 1
    tile = @tiles[(@dir_idx * 3) + frame]
    info = tile.gl_tex_info rescue nil; return unless info

    glEnable(GL_BLEND); glDisable(GL_CULL_FACE)
    glPushMatrix
      glTranslatef(@x, @y, 0.0)
      
      # 1. OMBRE
      s_info = @shadow_tex.gl_tex_info
      if s_info
        glEnable(GL_TEXTURE_2D); glBindTexture(GL_TEXTURE_2D, s_info.tex_name)
        glEnable(GL_POLYGON_OFFSET_FILL); glPolygonOffset(1.0, 1.0) 
        glColor4f(1, 1, 1, 1); s_sz = Config::JILL_SIZE * 0.3
        glBegin(GL_QUADS)
          glTexCoord2f(s_info.left, s_info.bottom); glVertex3f(-s_sz, -s_sz, 0.05)
          glTexCoord2f(s_info.right, s_info.bottom);glVertex3f(s_sz, -s_sz, 0.05)
          glTexCoord2f(s_info.right, s_info.top);   glVertex3f(s_sz, s_sz, 0.05)
          glTexCoord2f(s_info.left, s_info.top);    glVertex3f(-s_sz, s_sz, 0.05)
        glEnd; glDisable(GL_POLYGON_OFFSET_FILL)
      end

      # 2. BOUSSOLE
      c_info = @compass_tex.gl_tex_info
      if c_info
        glEnable(GL_TEXTURE_2D); glBindTexture(GL_TEXTURE_2D, c_info.tex_name)
        glColor4f(1.0, 1.0, 0.5, 0.8)
        glPushMatrix
          glRotatef(@angle * 180.0 / Math::PI, 0, 0, 1)
          c_sz = Config::JILL_SIZE * 0.4
          glBegin(GL_QUADS)
            glTexCoord2f(c_info.left, c_info.bottom); glVertex3f(-c_sz, -c_sz, 0.06)
            glTexCoord2f(c_info.right, c_info.bottom);glVertex3f(c_sz, -c_sz, 0.06)
            glTexCoord2f(c_info.right, c_info.top);   glVertex3f(c_sz, c_sz, 0.06)
            glTexCoord2f(c_info.left, c_info.top);    glVertex3f(-c_sz, c_sz, 0.06)
          glEnd
        glPopMatrix
      end
      
      # 3. BILLBOARD JILL
      glColor4f(1, 1, 1, 1); glBindTexture(GL_TEXTURE_2D, info.tex_name)
      glRotatef(camera.yaw * 180.0 / Math::PI + 90, 0, 0, 1)
      s = Config::JILL_SIZE; hw = s/2.0
      glBegin(GL_QUADS)
        glTexCoord2f(info.left, info.bottom); glVertex3f(-hw, 0, 0)
        glTexCoord2f(info.right, info.bottom);glVertex3f(hw, 0, 0)
        glTexCoord2f(info.right, info.top);   glVertex3f(hw, 0, s)
        glTexCoord2f(info.left, info.top);     glVertex3f(-hw, 0, s)
      glEnd
    glPopMatrix
    glDisable(GL_TEXTURE_2D)
  end
end

class GameWindow < Gosu::Window
  def initialize
    super Config::SCREEN_WIDTH, Config::SCREEN_HEIGHT, false
    @cameras, @zones, @cam_idx = [], [], 0
    load_data
    @jill = Entity.new(Config::SPRITE_FILE, 52.0, 21.0)
  end
  def load_data
    path = File.join(Config::BASE_PATH, Config::JSON_FILE); return unless File.exist?(path)
    raw = JSON.parse(File.read(path))
    raw["cameras"].each{|n,c| @cameras << Camera.new(n,c,Config::BASE_PATH)}
    raw["zones"].each{|z| @zones << TriggerZone.new(z)} if raw["zones"]
  end
  def update
    @jill.update(@cameras[@cam_idx])
    z = @zones.find{|z| z.inside?(@jill.x, @jill.y)}
    if z; idx = @cameras.find_index{|c| c.id == z.cam_id}
      if idx && idx != @cam_idx; @cam_idx = idx; end
    end
    self.caption = @cameras[@cam_idx].id
  end
  def draw
    c = @cameras[@cam_idx]; return unless c; c.image&.draw(0,0,0, width.to_f/c.image.width, height.to_f/c.image.height)
    Gosu.gl(10){ glClear(GL_DEPTH_BUFFER_BIT); glEnable(GL_DEPTH_TEST); c.apply_view(self); @jill.draw(c) }
  end
  def button_down(id); close if id == Gosu::KB_ESCAPE; end
end
GameWindow.new.show