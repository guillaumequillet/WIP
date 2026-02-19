require 'gosu'
require 'opengl'
require 'glu'
require 'json'

module Config
  EXPORT_PATH = "E:/PROG/RUBY/WIP/scenes/export_blender"
  JSON_FILE = File.join(EXPORT_PATH, "scene_data.json")
  SPRITE_FILE = "gfx/jill.png"
  SCREEN_WIDTH, SCREEN_HEIGHT = 640, 480
  JILL_SIZE = 1.0
  JILL_SPEED = 0.12
  TOLERANCE = 0.8
end

OpenGL.load_lib; GLU.load_lib
include OpenGL, GLU

class Prototype < Gosu::Window
  def initialize
    super Config::SCREEN_WIDTH, Config::SCREEN_HEIGHT, false
    self.caption = "Survival Horror - Debug Mode"
    
    # 1. CHARGEMENT DATA
    unless File.exist?(Config::JSON_FILE)
      puts "ERREUR : #{Config::JSON_FILE} introuvable ! Vérifie ton export Blender."
      exit
    end
    
    data = JSON.parse(File.read(Config::JSON_FILE))
    @grid_data = data["grid"] || {}
    @cam_configs = data["cameras"] || {}
    
    @cameras = {}
    @cam_configs.each do |id, c|
      img_path = File.join(Config::EXPORT_PATH, "#{id}.png")
      img = File.exist?(img_path) ? Gosu::Image.new(img_path, retro: true) : nil
      
      # Si tx/ty n'existent pas dans ton JSON actuel, on regarde vers 0,0
      tx = c["tx"] || 0
      ty = c["ty"] || 0
      tz = c["tz"] || 0
      yaw = Math.atan2(ty - c["y"], tx - c["x"])
      
      @cameras[id] = { pos: c, img: img, yaw: yaw, tx: tx, ty: ty, tz: tz }
    end

    # 2. INITIALISATION POSITION (Basé sur ton JSON qui a beaucoup de CAM_1 en 19,10)
    @jill_x, @jill_y = 19.0, 10.0
    @current_cam_id = @grid_data["19,10"] || @cameras.keys.first
    
    # Vérification de sécurité pour éviter le crash au draw
    if @cameras[@current_cam_id].nil?
      puts "ALERTE : La caméra #{@current_cam_id} est introuvable dans le dossier export."
      @current_cam_id = @cameras.keys.first
    end

    @jill_tiles = Gosu::Image.load_tiles(Config::SPRITE_FILE, 32, 32, retro: true)
    @angle = 0.0
  end

  def can_move_to?(nx, ny)
    # On cherche s'il y a UNE tile autorisée dans le rayon de tolérance
    @grid_data.any? do |coords, _|
      cx, cy = coords.split(',').map(&:to_f)
      Math.sqrt((nx - cx)**2 + (ny - cy)**2) < Config::TOLERANCE
    end
  end

  def update
    dx = (Gosu.button_down?(Gosu::KB_RIGHT) ? 1 : 0) - (Gosu.button_down?(Gosu::KB_LEFT) ? 1 : 0)
    dy = (Gosu.button_down?(Gosu::KB_UP) ? 1 : 0) - (Gosu.button_down?(Gosu::KB_DOWN) ? 1 : 0)
    
    if (@moving = (dx != 0 || dy != 0))
      cam = @cameras[@current_cam_id]
      return unless cam # Sécurité

      input_angle = Math.atan2(dy, dx)
      @angle = cam[:yaw] + input_angle + Math::PI / 2.0
      
      mx = Math.cos(@angle) * Config::JILL_SPEED
      my = Math.sin(@angle) * Config::JILL_SPEED

      if can_move_to?(@jill_x + mx, @jill_y + my)
        @jill_x += mx
        @jill_y += my
      end
    end

    # Switch caméra fluide
    tk = "#{@jill_x.round},#{@jill_y.round}"
    if @grid_data[tk] && @grid_data[tk] != @current_cam_id
      new_id = @grid_data[tk]
      @current_cam_id = new_id if @cameras[new_id]
    end
  end

  def draw
    cam = @cameras[@current_cam_id]
    
    # SÉCURITÉ : Si cam est nil, on ne dessine rien pour éviter le NoMethodError
    return if cam.nil?

    # 1. DESSIN DU FOND
    cam[:img]&.draw(0, 0, 0)

    # 2. DESSIN OPENGL
    Gosu.gl(10) do
      glClear(GL_DEPTH_BUFFER_BIT)
      glEnable(GL_DEPTH_TEST)
      
      glMatrixMode(GL_PROJECTION); glLoadIdentity
      gluPerspective(45.0, 640.0/480.0, 0.1, 500.0)
      
      glMatrixMode(GL_MODELVIEW); glLoadIdentity
      c = cam[:pos]
      gluLookAt(c["x"], c["y"], c["z"], cam[:tx], cam[:ty], cam[:tz], 0, 0, 1)

      draw_jill(cam[:yaw])
    end
  end

  def draw_jill(cam_yaw)
    glPushMatrix
      glTranslatef(@jill_x, @jill_y, 0.05)
      
      # Ombre
      glDisable(GL_TEXTURE_2D); glColor4f(0, 0, 0, 0.4)
      glBegin(GL_TRIANGLE_FAN)
        glVertex3f(0,0,0); 12.times{|i| a=i*Math::PI*2/12; glVertex3f(Math.cos(a)*0.4, Math.sin(a)*0.4, 0)}
      glEnd; glEnable(GL_TEXTURE_2D)

      glRotatef(cam_yaw * 180 / Math::PI - 90, 0, 0, 1)
      
      # Sprite Jill
      frame = @moving ? (Gosu.milliseconds / 150 % 4) : 1
      tile = @jill_tiles[frame + 6] rescue nil
      return unless tile

      info = tile.gl_tex_info
      glBindTexture(GL_TEXTURE_2D, info.tex_name)
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
      
      glEnable(GL_ALPHA_TEST); glAlphaFunc(GL_GREATER, 0.1)
      glColor4f(1, 1, 1, 1)
      
      glBegin(GL_QUADS)
        s = Config::JILL_SIZE; hw = s/2.0
        glTexCoord2f(info.left, info.bottom); glVertex3f(-hw, 0, 0)
        glTexCoord2f(info.right, info.bottom); glVertex3f(hw, 0, 0)
        glTexCoord2f(info.right, info.top); glVertex3f(hw, 0, s*2)
        glTexCoord2f(info.left, info.top); glVertex3f(-hw, 0, s*2)
      glEnd
    glPopMatrix
  end

  def button_down(id)
    close if id == Gosu::KB_ESCAPE
  end
end

Prototype.new.show