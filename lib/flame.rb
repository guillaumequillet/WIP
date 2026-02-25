class Flame
  def initialize(window, x, y, scale = 1.0, type = :candle)
    @window = window
    @x, @y = x, y
    @scale = scale
    @type = type
    @particles = []
    
    # Configuration selon le type
    @max_p = (@type == :candle ? 30 : 80)
    
    # Initialisation avec âge aléatoire pour une boucle parfaite immédiate
    @max_p.times { @particles << create_particle(true) }
  end

  def create_particle(random_age = false)
    # On ajuste les vitesses et tailles par le scale
    if @type == :candle
      vx, vy = rand(-0.1..0.1) * @scale, rand(-0.6..-0.3) * @scale
      size = rand(1.5..2.5) * @scale
      decay = 7
    else
      vx, vy = rand(-1.5..1.5) * @scale, rand(-3.0..-1.0) * @scale
      size = rand(8.0..15.0) * @scale
      decay = 5
    end

    {
      x: @x, y: @y,
      vx: vx, vy: vy,
      size: size,
      alpha: random_age ? rand(0..255) : 255,
      decay: decay
    }
  end

  def update
    @particles.each do |p|
      p[:x] += p[:vx] if @type == :fire
      p[:y] += p[:vy]
      p[:alpha] -= p[:decay]
      p[:size] *= (@type == :candle ? 0.98 : 0.95)
    end

    # Remplacement immédiat pour maintenir la boucle
    @particles.map! { |p| p[:alpha] <= 0 ? create_particle : p }
  end

  def draw
    draw_glow
    @particles.each do |p|
      r, g, b = @type == :candle ? [255, 140, 20] : [255, rand(50..150), 0]
      color = Gosu::Color.rgba(r, g, b, p[:alpha])
      Gosu.draw_rect(p[:x] - p[:size]/2, p[:y], p[:size], p[:size], color, 2, :add)
    end
  end

  private

  def draw_glow
    max_radius = (@type == :candle ? 80 : 180) * @scale
    rgb = @type == :candle ? [255, 120, 0] : [255, 50, 0]
    vibration = Math.sin(Gosu.milliseconds / 150.0) * 2

    [0.3, 0.6, 1.0].each_with_index do |mult, i|
      radius = max_radius * mult
      alpha = ((15 / (i + 1)) + vibration).clamp(0, 255)
      color = Gosu::Color.rgba(rgb[0], rgb[1], rgb[2], alpha)
      
      # Dessin du cercle (halo)
      steps = 15
      angle_step = 360.0 / steps
      steps.times do |j|
        a1, a2 = j * angle_step * Math::PI / 180, (j + 1) * angle_step * Math::PI / 180
        Gosu.draw_triangle(@x, @y, color, 
                              @x + Math.cos(a1) * radius, @y + Math.sin(a1) * radius, color,
                              @x + Math.cos(a2) * radius, @y + Math.sin(a2) * radius, color, 0, :add)
      end
    end
  end
end