require 'gosu'
require 'opengl'
require 'glu'
require 'json'

# ==========================================
# CONFIGURATION
# ==========================================
module Config
  BASE_PATH = "E:/PROG/RUBY/WIP/scenes"
  JSON_FILE = "scenes_data.json"
  SPRITE_FILE = "gfx/jill.png" 
  
  SCREEN_WIDTH, SCREEN_HEIGHT = 640, 480
  JILL_SIZE   = 16.0
  JILL_SPEED  = 0.5
  ROT_SPEED   = 0.07
  ALIGN_SPEED = 0.1 
  
  JILL_RADIUS = 2.5 
end

OpenGL.load_lib
GLU.load_lib
include OpenGL, GLU

# --- Fonctions utilitaires ---
def draw_wire_box(x1, x2, y1, y2, h)
  glBegin(GL_LINE_LOOP); glVertex3f(x1, y1, 0.1); glVertex3f(x2, y1, 0.1); glVertex3f(x2, y2, 0.1); glVertex3f(x1, y2, 0.1); glEnd
  glBegin(GL_LINES)
    glVertex3f(x1, y1, 0.1); glVertex3f(x1, y1, h); glVertex3f(x2, y1, 0.1); glVertex3f(x2, y1, h)
    glVertex3f(x2, y2, 0.1); glVertex3f(x2, y2, h); glVertex3f(x1, y2, 0.1); glVertex3f(x1, y2, h)
  glEnd
end

# --- Obstacles (Rouge) ---
class CollisionBox
  def initialize(data)
    @x_min, @x_max = data["x_min"], data["x_max"]
    @y_min, @y_max = data["y_min"], data["y_max"]
  end
  def hit?(px, py, r)
    (px + r > @x_min && px - r < @x_max) && (py + r > @y_min && py - r < @y_max)
  end
  def draw_debug
    glColor4f(1, 0, 0, 0.7)
    draw_wire_box(@x_min, @x_max, @y_min, @y_max, 5.0)
  end
end

# --- Triggers (Vert) ---
class TriggerZone
  attr_reader :cam_id
  def initialize(data)
    @cam_id = data["cam_id"]
    @x_min, @x_max = data["x_min"], data["x_max"]
    @y_min, @y_max = data["y_min"], data["y_max"]
  end
  def inside?(px, py, r)
    (px + r >= @x_min && px - r <= @x_max) && (py + r >= @y_min && py - r <= @y_max)
  end
  def draw_debug
    glColor4f(0, 1, 0, 0.7)
    draw_wire_box(@x_min, @x_max, @y_min, @y_max, 2.0)
  end
end

# --- Caméra ---
class Camera
  attr_reader :id, :pos, :look_at, :fov, :image, :yaw
  def initialize(id, data, base_path)
    @id, @pos, @look_at, @fov = id, data["pos"], data["look_at"], data["fov"]
    img_path = File.join(base_path, "#{id}.png")
    @image = Gosu::Image.new(img_path, retro: true) if File.exist?(img_path)
    @yaw = Math.atan2(@look_at[1] - @pos[1], @look_at[0] - @pos[0])
  end
  def apply_view(window)
    aspect = window.fullscreen? ? Gosu.screen_width.to_f / Gosu.screen_height : window.width.to_f / window.height
    glMatrixMode(GL_PROJECTION); glLoadIdentity; gluPerspective(@fov, aspect, 0.1, 2000.0)
    glMatrixMode(GL_MODELVIEW); glLoadIdentity; gluLookAt(@pos[0], @pos[1], @pos[2], @look_at[0], @look_at[1], @look_at[2], 0, 0, 1)
  end
end

# --- Entité Jill ---
class Entity
  attr_accessor :x, :y, :angle

  def initialize(file, x, y)
    @tiles = Gosu::Image.load_tiles(file, 32, 32, retro: true)
    @x, @y, @angle = x, y, 0.0
    @walk, @rows = [1, 0, 1, 2], { dos: 0, droite: 1, face: 2, gauche: 3 }
    
    @shadow = Gosu.render(8, 8, retro: true) do
      c = Gosu::Color.new(90, 0, 0, 0)
      8.times { |py| 8.times { |px| Gosu.draw_rect(px, py, 1, 1, c) if Math.sqrt((px-4)**2 + (py-4)**2) <= 3.5 } }
    end
  end

  def update(camera, collisions)
    turning = false
    if Gosu.button_down?(Gosu::KB_LEFT); @angle += Config::ROT_SPEED; turning = true
    elsif Gosu.button_down?(Gosu::KB_RIGHT); @angle -= Config::ROT_SPEED; turning = true
    end

    unless turning
      q = Math::PI / 2.0
      target = (@angle / q).round * q
      @angle += (target - @angle) * Config::ALIGN_SPEED
    end
    
    mv = Gosu.button_down?(Gosu::KB_UP) ? 1 : (Gosu.button_down?(Gosu::KB_DOWN) ? -0.5 : 0)
    @moving = (mv != 0)

    if @moving
      dx = Math.cos(@angle) * mv * Config::JILL_SPEED
      dy = Math.sin(@angle) * mv * Config::JILL_SPEED
      @x += dx unless collisions.any? { |b| b.hit?(@x + dx, @y, Config::JILL_RADIUS) }
      @y += dy unless collisions.any? { |b| b.hit?(@x, @y + dy, Config::JILL_RADIUS) }
    end

    rel = (@angle - camera.yaw + Math::PI) % (2 * Math::PI) - Math::PI
    @dir = rel.abs < Math::PI * 0.25 ? :dos : (rel.abs > Math::PI * 0.75 ? :face : (rel > 0 ? :droite : :gauche))
  end

  def draw(camera, debug)
    frame = @moving ? @walk[(Gosu.milliseconds / 150) % 4] : 1
    tile = @tiles[@rows[@dir] * 3 + frame]
    info = tile.gl_tex_info rescue nil; return unless info

    glEnable(GL_BLEND); glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); glDisable(GL_CULL_FACE)
    glPushMatrix
      glTranslatef(@x, @y, 0.0)
      draw_shadow
      draw_sprite(info, camera)
      draw_jill_debug if debug
    glPopMatrix
  end

  private

  def draw_shadow
    s_info = @shadow.gl_tex_info; return unless s_info
    glEnable(GL_TEXTURE_2D); glBindTexture(GL_TEXTURE_2D, s_info.tex_name); glColor4f(1,1,1,1)
    glEnable(GL_POLYGON_OFFSET_FILL); glPolygonOffset(1.0, 1.0)
    s_sz = Config::JILL_SIZE * 0.14 
    glBegin(GL_QUADS)
      glTexCoord2f(s_info.left, s_info.bottom);  glVertex3f(-s_sz, -s_sz, 0.01)
      glTexCoord2f(s_info.right, s_info.bottom); glVertex3f( s_sz, -s_sz, 0.01)
      glTexCoord2f(s_info.right, s_info.top);    glVertex3f( s_sz,  s_sz, 0.01)
      glTexCoord2f(s_info.left, s_info.top);     glVertex3f(-s_sz,  s_sz, 0.01)
    glEnd
    glDisable(GL_POLYGON_OFFSET_FILL); glDisable(GL_TEXTURE_2D)
  end

  def draw_sprite(info, camera)
    glEnable(GL_TEXTURE_2D); glEnable(GL_ALPHA_TEST); glAlphaFunc(GL_GREATER, 0.1); glDepthMask(GL_TRUE)
    glBindTexture(GL_TEXTURE_2D, info.tex_name); glColor4f(1,1,1,1)
    glPushMatrix
      glRotatef(camera.yaw * 180.0 / Math::PI + 90, 0, 0, 1)
      s = Config::JILL_SIZE; hw = s / 2.0
      glBegin(GL_QUADS)
        glTexCoord2f(info.left, info.bottom); glVertex3f(-hw, 0, 0)
        glTexCoord2f(info.right, info.bottom); glVertex3f(hw, 0, 0)
        glTexCoord2f(info.right, info.top);    glVertex3f(hw, 0, s)
        glTexCoord2f(info.left, info.top);     glVertex3f(-hw, 0, s)
      glEnd
    glPopMatrix; glDisable(GL_ALPHA_TEST)
  end

  def draw_jill_debug
    glDisable(GL_TEXTURE_2D); glColor4f(0, 0.5, 1, 1); r = Config::JILL_RADIUS
    glBegin(GL_LINE_LOOP); 16.times{|i| a=i*Math::PI*2/16; glVertex3f(Math.cos(a)*r, Math.sin(a)*r, 0.2)}; glEnd
  end
end

class Game < Gosu::Window
  def initialize
    super Config::SCREEN_WIDTH, Config::SCREEN_HEIGHT, false
    @cameras, @zones, @collisions, @idx, @debug = [], [], [], 0, false
    load_json
    @jill = Entity.new(Config::SPRITE_FILE, 52.0, 21.0)
  end
  def load_json
    path = File.join(Config::BASE_PATH, Config::JSON_FILE)
    return unless File.exist?(path)
    data = JSON.parse(File.read(path))
    data["cameras"].each { |id, v| @cameras << Camera.new(id, v, Config::BASE_PATH) }
    data["zones"].each { |v| @zones << TriggerZone.new(v) }
    data["collisions"].each { |v| @collisions << CollisionBox.new(v) }
  end
  def update
    return if @cameras.empty?
    @jill.update(@cameras[@idx], @collisions)
    zone = @zones.find { |z| z.inside?(@jill.x, @jill.y, Config::JILL_RADIUS) }
    if zone
      new_idx = @cameras.find_index { |c| c.id == zone.cam_id }
      @idx = new_idx if new_idx && new_idx != @idx
    end
  end
  def draw
    c = @cameras[@idx]; return unless c
    c.image&.draw(0, 0, 0, width.to_f/c.image.width, height.to_f/c.image.height)
    Gosu.gl(10) do
      glClear(GL_DEPTH_BUFFER_BIT); glEnable(GL_DEPTH_TEST); c.apply_view(self)
      @jill.draw(c, @debug)
      if @debug; glDisable(GL_TEXTURE_2D); @collisions.each(&:draw_debug); @zones.each(&:draw_debug); end
    end
  end
  def button_down(id); super; close if id == Gosu::KB_ESCAPE; @debug = !@debug if id == Gosu::KB_D; end
end

Game.new.show