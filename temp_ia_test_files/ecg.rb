require 'gosu'

class ECGWindow < Gosu::Window
  def initialize
    super(400, 200)
    self.caption = "Resident Evil ECG - Pic Central Fixe"
    
    # On n'a plus besoin du pulse_interval (timer), la vitesse suffit !
    @states = {
      fine:    { color: Gosu::Color::GREEN,  speed: 2.5, amplitude: 1.0 },
      caution: { color: Gosu::Color::YELLOW, speed: 4.0, amplitude: 0.6 },
      danger:  { color: Gosu::Color::RED,    speed: 6.0, amplitude: 0.25 }
    }
    
    @current_state = :fine
    @x = 0
    @base_y = 100
    @trail = []
    @pixel_size = 3
    
    # La forme du battement reste la même
    @pulse_shape = [
      0, 5, 15, -10, -50, -85, -20, 20, 40, 15, 0
    ]
  end

  # === NOUVELLE MÉTHODE : Calcule la hauteur selon la position sur l'écran ===
  def get_y_for_x(current_x, amplitude)
    center_x = width / 2.0
    wave_width = 80.0 # C'est la largeur de l'onde au centre de l'écran
    
    start_x = center_x - wave_width / 2.0
    end_x = center_x + wave_width / 2.0

    # Si on n'est pas au milieu de l'écran, la ligne reste plate
    return @base_y if current_x <= start_x || current_x >= end_x

    # Si on est au milieu, on calcule à quel % de l'onde on se trouve
    progress = (current_x - start_x) / wave_width
    
    # On fait correspondre ce pourcentage à notre tableau @pulse_shape
    exact_index = progress * (@pulse_shape.length - 1)
    
    # Interpolation pour que le tracé soit parfaitement lisse
    idx_floor = exact_index.floor
    idx_ceil = exact_index.ceil
    rem = exact_index - idx_floor

    y1 = @pulse_shape[idx_floor]
    y2 = @pulse_shape[idx_ceil]
    
    interpolated_y = y1 + (y2 - y1) * rem
    
    # On applique l'amplitude
    return @base_y + (interpolated_y * amplitude)
  end

  def update
    state = @states[@current_state]
    
    # On calcule la position Y en fonction de la position X actuelle
    current_y = get_y_for_x(@x, state[:amplitude])
    
    # On sauvegarde le point
    @trail << { x: @x, y: current_y }
    
    # On avance le rayon
    @x += state[:speed]
    
    # Retour à gauche une fois au bout
    if @x > width
      @x = 0
      @trail.clear
    end
  end

  def button_down(id)
    case id
    when Gosu::KB_1 then @current_state = :fine
    when Gosu::KB_2 then @current_state = :caution
    when Gosu::KB_3 then @current_state = :danger
    when Gosu::KB_ESCAPE then close
    end
  end

  def draw
    state = @states[@current_state]
    base_color = state[:color]
    draw_grid

    @trail.each_with_index do |point, index|
      next if index == 0
      prev_point = @trail[index - 1]

      next if point[:x] < prev_point[:x] 

      # Traînée lumineuse
      distance = @x - point[:x]
      alpha = 255 - (distance * 1.8).to_i
      alpha = 0 if alpha < 0
      c = Gosu::Color.rgba(base_color.red, base_color.green, base_color.blue, alpha)
      
      # Algorithme DDA pour un tracé continu sans aucun trou
      x1, y1 = prev_point[:x], prev_point[:y]
      x2, y2 = point[:x], point[:y]
      
      dx = x2 - x1
      dy = y2 - y1
      
      steps = [dx.abs, dy.abs].max
      
      if steps > 0
        x_increment = dx / steps.to_f
        y_increment = dy / steps.to_f
        
        cur_x, cur_y = x1, y1
        
        (steps.to_i + 1).times do
          Gosu.draw_rect(cur_x.round, cur_y.round, @pixel_size, @pixel_size, c)
          cur_x += x_increment
          cur_y += y_increment
        end
      else
        Gosu.draw_rect(x1.round, y1.round, @pixel_size, @pixel_size, c)
      end
    end
  end

  def draw_grid
    grid_color = Gosu::Color.rgba(0, 50, 0, 70)
    (0..width).step(20) { |x| Gosu.draw_rect(x, 0, 1, height, grid_color) }
    (0..height).step(20) { |y| Gosu.draw_rect(0, y, width, 1, grid_color) }
  end
end

ECGWindow.new.show