require 'gosu'
require 'opengl'
require 'glu'
require 'json'

# --- CONFIGURATION ---
module Config
  BASE_PATH = "E:/PROG/RUBY/WIP/scenes"
  JSON_FILE = "scenes_data.json"
  SPRITE_FILE = "gfx/jill.png"
  
  SCREEN_WIDTH = 640
  SCREEN_HEIGHT = 480
  
  JILL_SIZE = 16.0
  JILL_SPEED = 0.5
end

# --- INIT OPENGL ---
begin
  OpenGL.load_lib
  GLU.load_lib
rescue LoadError
  puts "Erreur : OpenGL ou GLU introuvable."
  exit
end

include OpenGL
include GLU

# --- ZONE DE DÉCLENCHEMENT (AABB) ---
class TriggerZone
  attr_reader :cam_id
  def initialize(data)
    @cam_id = data["cam_id"]
    @x_min = data["x_min"].to_f
    @x_max = data["x_max"].to_f
    @y_min = data["y_min"].to_f
    @y_max = data["y_max"].to_f
  end

  def inside?(px, py)
    px >= @x_min && px <= @x_max && py >= @y_min && py <= @y_max
  end
end

# --- CAMERA ---
class Camera
  attr_reader :id, :pos, :look_at, :fov, :image, :yaw

  def initialize(id, data, base_path)
    @id = id
    @pos = data["pos"]
    @look_at = data["look_at"]
    @fov = data["fov"]
    
    img_path = File.join(base_path, "#{id}.png")
    @image = Gosu::Image.new(img_path, retro: true) if File.exist?(img_path)
    
    dx = @look_at[0] - @pos[0]
    dy = @look_at[1] - @pos[1]
    @yaw = Math.atan2(dy, dx)
  end

  def vectors
    dx = @look_at[0] - @pos[0]
    dy = @look_at[1] - @pos[1]
    @yaw = Math.atan2(dy, dx)
    
    step = Math::PI / 4.0 
    snapped_angle = (@yaw / step).round * step
    
    fwd = [Math.cos(snapped_angle), Math.sin(snapped_angle)]
    rgt = [fwd[1], -fwd[0]]
    
    return fwd, rgt
  end

  def apply_view(window)
    glMatrixMode(GL_PROJECTION); glLoadIdentity
    gluPerspective(@fov, window.width.to_f / window.height.to_f, 0.1, 2000.0)
    glMatrixMode(GL_MODELVIEW); glLoadIdentity
    gluLookAt(@pos[0], @pos[1], @pos[2], @look_at[0], @look_at[1], @look_at[2], 0, 0, 1)
  end

  def draw_background(window)
    return unless @image
    sx = window.width.to_f / @image.width
    sy = window.height.to_f / @image.height
    @image.draw(0, 0, 0, sx, sy)
  end
end

# --- ENTITÉ (JILL) ---
class Entity
  attr_accessor :x, :y, :z

  def initialize(file, x, y)
    @tiles = Gosu::Image.load_tiles(file, 32, 32, retro: true)
    @x, @y, @z = x, y, 0.0
    
    @dir_idx = 2
    @moving = false
    @walk_seq = [1, 0, 1, 2]
    @rows = { dos: 0, droite: 1, face: 2, gauche: 3 }

    @shadow_tex = Gosu.render(16, 16, retro: true) do
      color = Gosu::Color.new(120, 0, 0, 0)
      radius = 6.5
      center = 8
      16.times { |y| 16.times { |x| 
        dist = Math.sqrt((x - center)**2 + (y - center)**2)
        Gosu.draw_rect(x, y, 1, 1, color) if dist <= radius 
      }}
    end
  end

  def update(ix, iy, camera)
    @moving = (ix != 0 || iy != 0)
    return unless @moving

    fwd, rgt = camera.vectors
    speed = (ix != 0 && iy != 0) ? Config::JILL_SPEED * 0.7 : Config::JILL_SPEED
    
    move_fwd = -iy 
    move_rgt = ix
    
    @x += (fwd[0] * move_fwd + rgt[0] * move_rgt) * speed
    @y += (fwd[1] * move_fwd + rgt[1] * move_rgt) * speed

    if ix > 0;    @dir_idx = @rows[:gauche]
    elsif ix < 0; @dir_idx = @rows[:droite]
    elsif iy < 0; @dir_idx = @rows[:dos]
    elsif iy > 0; @dir_idx = @rows[:face]
    end
  end

  def draw(camera)
    frame = @moving ? @walk_seq[(Gosu.milliseconds / 150) % 4] : 1
    tile = @tiles[@dir_idx * 3 + frame]
    info = tile.gl_tex_info rescue nil
    return unless info

    glEnable(GL_BLEND)
    glDisable(GL_CULL_FACE) 

    glPushMatrix
      glTranslatef(@x, @y, 0.0)
      
      shadow_info = @shadow_tex.gl_tex_info rescue nil
      if shadow_info
        glEnable(GL_TEXTURE_2D); glBindTexture(GL_TEXTURE_2D, shadow_info.tex_name)
        glColor4f(1, 1, 1, 1)
        glEnable(GL_POLYGON_OFFSET_FILL); glPolygonOffset(-1.0, -1.0)
        s_size = Config::JILL_SIZE * 0.18
        glBegin(GL_QUADS)
          glTexCoord2f(shadow_info.left, shadow_info.bottom); glVertex3f(-s_size, -s_size, 0.05)
          glTexCoord2f(shadow_info.right, shadow_info.bottom);glVertex3f(s_size, -s_size, 0.05)
          glTexCoord2f(shadow_info.right, shadow_info.top);   glVertex3f(s_size, s_size, 0.05)
          glTexCoord2f(shadow_info.left, shadow_info.top);    glVertex3f(-s_size, s_size, 0.05)
        glEnd
        glDisable(GL_POLYGON_OFFSET_FILL)
      end

      glColor3f(1, 1, 1); glEnable(GL_TEXTURE_2D); glBindTexture(GL_TEXTURE_2D, info.tex_name)
      billboard_angle = camera.yaw * 180.0 / Math::PI
      glRotatef(billboard_angle + 90, 0, 0, 1)

      s = Config::JILL_SIZE; hw = s / 2.0
      glBegin(GL_QUADS)
        glTexCoord2f(info.left, info.bottom);  glVertex3f(-hw, 0, 0)
        glTexCoord2f(info.right, info.bottom); glVertex3f(hw, 0, 0)
        glTexCoord2f(info.right, info.top);    glVertex3f(hw, 0, s)
        glTexCoord2f(info.left, info.top);     glVertex3f(-hw, 0, s)
      glEnd
    glPopMatrix
    
    glDisable(GL_TEXTURE_2D)
    glEnable(GL_CULL_FACE)
  end
end

# --- FENÊTRE PRINCIPALE ---
class GameWindow < Gosu::Window
  def initialize
    super Config::SCREEN_WIDTH, Config::SCREEN_HEIGHT, false
    @font = Gosu::Font.new(20)
    
    @cameras = []
    @zones = []
    @cam_idx = 0
    
    load_data
    @jill = Entity.new(Config::SPRITE_FILE, 52.0, 21.0)
    
    # Init caption
    update_caption
  end

  def load_data
    path = File.join(Config::BASE_PATH, Config::JSON_FILE)
    return unless File.exist?(path)
    
    raw_data = JSON.parse(File.read(path))
    raw_data["cameras"].each { |n, c| @cameras << Camera.new(n, c, Config::BASE_PATH) }
    if raw_data["zones"]
      raw_data["zones"].each { |z_data| @zones << TriggerZone.new(z_data) }
    end
  end

  def update_caption
    cam = @cameras[@cam_idx]
    self.caption = cam ? cam.id : "No Camera"
  end

  def update
    return if @cameras.empty?
    
    ix = (Gosu.button_down?(Gosu::KB_RIGHT)?1:0) - (Gosu.button_down?(Gosu::KB_LEFT)?1:0)
    iy = (Gosu.button_down?(Gosu::KB_DOWN)?1:0) - (Gosu.button_down?(Gosu::KB_UP)?1:0)
    
    @jill.update(ix, iy, @cameras[@cam_idx])
    
    # AUTOMATISME CAMÉRA
    found_zone = @zones.find { |z| z.inside?(@jill.x, @jill.y) }
    if found_zone
      new_idx = @cameras.find_index { |c| c.id == found_zone.cam_id }
      if new_idx && new_idx != @cam_idx
        @cam_idx = new_idx
        update_caption # On met à jour la caption lors du changement
      end
    end
  end

  def draw
    cam = @cameras[@cam_idx]
    return unless cam
    cam.draw_background(self)
    Gosu.gl(10) do
      glClear(GL_DEPTH_BUFFER_BIT); glEnable(GL_DEPTH_TEST)
      cam.apply_view(self)
      @jill.draw(cam)
    end
  end

  def button_down(id)
    close if id == Gosu::KB_ESCAPE
  end
end

GameWindow.new.show