require 'gosu'
require 'opengl'
require 'glu'
require 'json'

module Config
  BASE_PATH = File.dirname(__FILE__)
  JSON_FILE = "scenes/scenes_data.json"
  SPRITE_FILE = "gfx/jill.png"
  SCREEN_WIDTH, SCREEN_HEIGHT = 640, 480
  JILL_SIZE, JILL_SPEED, JILL_RADIUS = 16.0, 0.5, 2.5
  TURN_COOLDOWN = 200 
end

OpenGL.load_lib; GLU.load_lib
include OpenGL, GLU

# --- CLASSES TECHNIQUES ---

class CollisionBox
  def initialize(data); @x_min, @x_max, @y_min, @y_max = data["x_min"], data["x_max"], data["y_min"], data["y_max"] end
  def hit?(px, py, r); (px + r > @x_min && px - r < @x_max) && (py + r > @y_min && py - r < @y_max) end
  def draw_debug; glColor4f(1, 0, 0, 0.7); glBegin(GL_LINE_LOOP); glVertex3f(@x_min, @y_min, 0.1); glVertex3f(@x_max, @y_min, 0.1); glVertex3f(@x_max, @y_max, 0.1); glVertex3f(@x_min, @y_max, 0.1); glEnd; end
end

class TriggerZone
  attr_reader :cam_id
  def initialize(data); @cam_id, @x_min, @x_max, @y_min, @y_max = data["cam_id"], data["x_min"], data["x_max"], data["y_min"], data["y_max"] end
  def inside?(px, py, r); (px + r >= @x_min && px - r <= @x_max) && (py + r >= @y_min && py - r <= @y_max) end
  def draw_debug; glColor4f(0, 1, 0, 0.7); glBegin(GL_LINE_LOOP); glVertex3f(@x_min, @y_min, 0.2); glVertex3f(@x_max, @y_min, 0.2); glVertex3f(@x_max, @y_max, 0.2); glVertex3f(@x_min, @y_max, 0.2); glEnd; end
end

class Camera
  attr_reader :id, :pos, :look_at, :fov, :image, :yaw
  def initialize(id, data, base_path)
    @id, @pos, @look_at, @fov = id, data["pos"], data["look_at"], data["fov"]
    img_path = File.join(base_path, "scenes", "#{id}.png")
    @image = Gosu::Image.new(img_path, retro: true) if File.exist?(img_path)
    @yaw = Math.atan2(@look_at[1] - @pos[1], @look_at[0] - @pos[0])
  end
  def apply_view(window)
    glMatrixMode(GL_PROJECTION); glLoadIdentity; gluPerspective(@fov, window.width.to_f/window.height, 0.1, 2000.0)
    glMatrixMode(GL_MODELVIEW); glLoadIdentity; gluLookAt(@pos[0], @pos[1], @pos[2], @look_at[0], @look_at[1], @look_at[2], 0, 0, 1)
  end
end

class Entity
  attr_accessor :x, :y, :angle, :control_mode
  def initialize(file, x, y)
    @tiles = Gosu::Image.load_tiles(file, 32, 32, retro: true)
    @x, @y, @angle, @control_mode = x, y, 0.0, :tank
    @walk, @rows = [1, 0, 1, 2], { dos: 0, droite: 1, face: 2, gauche: 3 }
    @last_turn_time = 0
    # Création de l'ombre ronde
    @shadow = Gosu.render(8, 8, retro: true) do
      c = Gosu::Color.new(90, 0, 0, 0)
      8.times { |py| 8.times { |px| Gosu.draw_rect(px, py, 1, 1, c) if Math.sqrt((px-4)**2 + (py-4)**2) <= 3.5 } }
    end
  end

  def update(camera, collisions)
    l, r = Gosu.button_down?(Gosu::KB_LEFT), Gosu.button_down?(Gosu::KB_RIGHT)
    u, d = Gosu.button_down?(Gosu::KB_UP), Gosu.button_down?(Gosu::KB_DOWN)

    if @control_mode == :tank
      if Gosu.milliseconds - @last_turn_time > Config::TURN_COOLDOWN
        if l; @angle += Math::PI/2; @last_turn_time = Gosu.milliseconds
        elsif r; @angle -= Math::PI/2; @last_turn_time = Gosu.milliseconds; end
      end
      mv = u ? 1 : (d ? -0.5 : 0)
      @moving = (mv != 0)
      apply_movement(Math.cos(@angle)*mv*Config::JILL_SPEED, Math.sin(@angle)*mv*Config::JILL_SPEED, collisions) if @moving
    else
      # --- MODE CAMERA : DIRECTIONS ECRAN ---
      dx_screen = (r ? 1 : 0) - (l ? 1 : 0)
      dy_screen = (u ? 1 : 0) - (d ? 1 : 0)
      @moving = (dx_screen != 0 || dy_screen != 0)
      if @moving
        input_angle = Math.atan2(dy_screen, dx_screen)
        @angle = camera.yaw + input_angle - Math::PI / 2.0
        apply_movement(Math.cos(@angle)*Config::JILL_SPEED, Math.sin(@angle)*Config::JILL_SPEED, collisions)
      end
    end

    rel = (@angle - camera.yaw + Math::PI) % (2 * Math::PI) - Math::PI
    @dir = rel.abs < Math::PI * 0.25 ? :dos : (rel.abs > Math::PI * 0.75 ? :face : (rel > 0 ? :droite : :gauche))
  end

  def apply_movement(dx, dy, collisions)
    @x += dx unless collisions.any? { |b| b.hit?(@x + dx, @y, Config::JILL_RADIUS) }
    @y += dy unless collisions.any? { |b| b.hit?(@x, @y + dy, Config::JILL_RADIUS) }
  end

  def draw(camera)
    frame = @moving ? @walk[(Gosu.milliseconds / 150) % 4] : 1
    tile = @tiles[@rows[@dir] * 3 + frame]
    info = tile.gl_tex_info rescue nil; return unless info

    glPushMatrix; glTranslatef(@x, @y, 0.0)
      # 1. Dessin de l'ombre
      draw_shadow
      
      # 2. Dessin du Sprite avec transparence
      glRotatef(camera.yaw * 180.0 / Math::PI + 90, 0, 0, 1)
      glEnable(GL_TEXTURE_2D); glBindTexture(GL_TEXTURE_2D, info.tex_name)
      glEnable(GL_ALPHA_TEST); glAlphaFunc(GL_GREATER, 0.1) # Rétablit le fond transparent
      glBegin(GL_QUADS)
        s = Config::JILL_SIZE; hw = s/2.0
        glTexCoord2f(info.left, info.bottom); glVertex3f(-hw, 0, 0)
        glTexCoord2f(info.right, info.bottom); glVertex3f(hw, 0, 0)
        glTexCoord2f(info.right, info.top); glVertex3f(hw, 0, s)
        glTexCoord2f(info.left, info.top); glVertex3f(-hw, 0, s)
      glEnd
      glDisable(GL_ALPHA_TEST)
    glPopMatrix
  end

  private

  def draw_shadow
    s_info = @shadow.gl_tex_info; return unless s_info
    glEnable(GL_TEXTURE_2D); glBindTexture(GL_TEXTURE_2D, s_info.tex_name)
    glEnable(GL_BLEND); glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    s_sz = Config::JILL_SIZE * 0.15
    glBegin(GL_QUADS)
      glTexCoord2f(s_info.left, s_info.bottom); glVertex3f(-s_sz, -s_sz, 0.01)
      glTexCoord2f(s_info.right, s_info.bottom); glVertex3f(s_sz, -s_sz, 0.01)
      glTexCoord2f(s_info.right, s_info.top); glVertex3f(s_sz, s_sz, 0.01)
      glTexCoord2f(s_info.left, s_info.top); glVertex3f(-s_sz, s_sz, 0.01)
    glEnd
    glDisable(GL_BLEND)
  end
end

class Prototype < Gosu::Window
  def initialize
    super Config::SCREEN_WIDTH, Config::SCREEN_HEIGHT, false
    @cameras, @zones, @collisions, @idx, @debug = [], [], [], 0, false
    @font = Gosu::Font.new(20)
    load_json
    @jill = Entity.new(Config::SPRITE_FILE, 52.0, 21.0)
  end

  def load_json
    path = File.join(Config::BASE_PATH, Config::JSON_FILE)
    data = JSON.parse(File.read(path))
    data["cameras"].each { |id, v| @cameras << Camera.new(id, v, Config::BASE_PATH) }
    data["zones"].each { |v| @zones << TriggerZone.new(v) }
    data["collisions"].each { |v| @collisions << CollisionBox.new(v) }
  end

  def update
    @jill.update(@cameras[@idx], @collisions)
    
    # ANTI-CLIGNOTEMENT
    all_active = @zones.select { |z| z.inside?(@jill.x, @jill.y, Config::JILL_RADIUS) }
    if all_active.any?
      current_cam_id = @cameras[@idx].id
      unless all_active.any? { |z| z.cam_id == current_cam_id }
        new_cam_id = all_active.first.cam_id
        new_idx = @cameras.find_index { |c| c.id == new_cam_id }
        @idx = new_idx if new_idx
      end
    end
  end

  def draw
    c = @cameras[@idx]
    c.image&.draw(0, 0, 0, width.to_f/c.image.width, height.to_f/c.image.height)
    @font.draw_text("MODE: #{@jill.control_mode.to_s.upcase} (ESPACE)", 10, 10, 10, 1, 1, Gosu::Color::YELLOW)
    Gosu.gl(10) do
      glClear(GL_DEPTH_BUFFER_BIT); glEnable(GL_DEPTH_TEST); c.apply_view(self)
      @jill.draw(c)
      if @debug; glDisable(GL_TEXTURE_2D); @collisions.each(&:draw_debug); @zones.each(&:draw_debug); end
    end
  end

  def button_down(id)
    @jill.control_mode = (@jill.control_mode == :tank ? :camera : :tank) if id == Gosu::KB_SPACE
    @debug = !@debug if id == Gosu::KB_D
    close if id == Gosu::KB_ESCAPE
  end
end

Prototype.new.show