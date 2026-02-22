require 'gosu'

# Classe de base pour les particules
class Particle
  def initialize(x, y, type, age_aleatoire = false)
    @x, @y = x, y
    @type = type # :candle ou :fire
    
    if @type == :candle
      @vel_y = rand(-0.6..-0.3)
      @vel_x = rand(-0.1..0.1)
      @size = rand(1.5..2.5)
      @decay = 7
    else # :fire (la toute première flamme mais améliorée)
      @vel_y = rand(-3.0..-1.0)
      @vel_x = rand(-1.5..1.5)
      @size = rand(8.0..15.0)
      @decay = 5
    end

    @alpha = age_aleatoire ? rand(0..255) : 255
  end

  def update
    @x += @vel_x if @type == :fire
    @y += @vel_y
    @alpha -= @decay
    @size *= (@type == :candle ? 0.98 : 0.95)
  end

  def dead? = @alpha <= 0

  def draw
    # Couleurs : Orange chaud pour la bougie, dégradé vers le rouge pour le feu
    r, g, b = @type == :candle ? [255, 140, 20] : [255, rand(50..150), 0]
    color = Gosu::Color.rgba(r, g, b, @alpha)
    Gosu.draw_rect(@x - @size/2, @y, @size, @size, color, 2, :add)
  end
end

class FlameWindow < Gosu::Window
  def initialize
    super 600, 400
    self.caption = "Bougie vs Feu - Boucle Parfaite"
    
    @candle_pos = [200, 250]
    @fire_pos = [400, 250]
    
    @candle_particles = []
    @fire_particles = []

    # Initialisation (Pre-warming) pour les deux
    30.times { @candle_particles << Particle.new(@candle_pos[0], @candle_pos[1], :candle, true) }
    80.times { @fire_particles << Particle.new(@fire_pos[0], @fire_pos[1], :fire, true) }
  end

  def update
    # Gestion Bougie
    @candle_particles.each(&:update)
    @candle_particles.map! { |p| p.dead? ? Particle.new(@candle_pos[0], @candle_pos[1], :candle) : p }

    # Gestion Feu
    @fire_particles.each(&:update)
    @fire_particles.map! { |p| p.dead? ? Particle.new(@fire_pos[0], @fire_pos[1], :fire) : p }
  end

  def draw
    # Halos lumineux ronds
    draw_circular_glow(@candle_pos[0], @candle_pos[1], 80, [255, 120, 0]) # Petit halo
    draw_circular_glow(@fire_pos[0], @fire_pos[1], 180, [255, 50, 0])   # Gros halo rougeoyant

    @candle_particles.each(&:draw)
    @fire_particles.each(&:draw)

    # Mèche de la bougie
    Gosu.draw_rect(@candle_pos[0] - 0.5, @candle_pos[1], 1, 4, 0xff_333333, 3)
  end

  def draw_circle(x, y, radius, color)
    steps = 20
    angle_step = 360.0 / steps
    steps.times do |i|
      angle1 = i * angle_step * Math::PI / 180
      angle2 = (i + 1) * angle_step * Math::PI / 180
      draw_triangle(x, y, color, x + Math.cos(angle1) * radius, y + Math.sin(angle1) * radius, color,
                    x + Math.cos(angle2) * radius, y + Math.sin(angle2) * radius, color, 0, :add)
    end
  end

  def draw_circular_glow(x, y, max_radius, rgb)
    vibration = Math.sin(Gosu.milliseconds / 150.0) * 2
    [0.3, 0.6, 1.0].each_with_index do |mult, i|
      radius = max_radius * mult
      alpha = (15 / (i + 1)) + vibration
      color = Gosu::Color.rgba(rgb[0], rgb[1], rgb[2], alpha.clamp(0, 255))
      draw_circle(x, y, radius, color)
    end
  end
end

FlameWindow.new.show