require 'gosu'

class ECGWindow < Gosu::Window
  def initialize
    super(400, 200)
    self.caption = "Resident Evil ECG - Final Pixel Art"
    
    # Configuration des états
    # J'ai légèrement augmenté les vitesses pour que les diagonales soient plus visibles
    @states = {
      fine:    { color: Gosu::Color::GREEN,  speed: 3, pulse_interval: 120 },
      caution: { color: Gosu::Color::YELLOW, speed: 4, pulse_interval: 80 },
      danger:  { color: Gosu::Color::RED,    speed: 6, pulse_interval: 40 }
    }
    
    @current_state = :fine
    @x = 0
    @base_y = 100
    @trail = []
    @tick = 0
    # Taille des blocs. Essayez 3, 4 ou 5 pour différents rendus "rétro".
    @pixel_size = 4 
  end

  def update
    state = @states[@current_state]
    
    # --- Calcul du tracé ECG ---
    y_offset = 0
    cycle_pos = @tick % state[:pulse_interval]
    
    # Définition des pics du complexe QRS
    if cycle_pos > 10 && cycle_pos < 32
      case cycle_pos
      # Petit creux initial
      when 11..13 then y_offset = 15  
      # Montée rapide vers le grand pic (R)
      when 14..17 then y_offset = -70 + (17-cycle_pos)*10 
      # Descente rapide vers le grand creux (S)
      when 18..21 then y_offset = 40 - (21-cycle_pos)*10
      # Retour à la ligne de base avec un petit ressaut (T)
      when 22..26 then y_offset = -20
      when 27..31 then y_offset = -10 + (cycle_pos-27)*2
      end
    end

    # Enregistrement du point (en s'assurant que ce sont des entiers)
    current_y = (@base_y + y_offset).to_i
    @trail << { x: @x.to_i, y: current_y }
    
    # Avancement
    @x += state[:speed]
    @tick += 1
    
    # Boucle de l'écran
    if @x > width
      @x = 0
      @trail.clear
    end
  end

  def button_down(id)
    # Touches 1, 2, 3 pour changer l'état
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

    # --- NOUVELLE LOGIQUE DE DESSIN ---
    @trail.each_with_index do |point, index|
      next if index == 0
      prev_point = @trail[index - 1]

      # Empêche de relier le bord droit au bord gauche lors du retour à zéro
      next if point[:x] < prev_point[:x] 

      # Calcul de la couleur avec effet de traînée (phosphorescence)
      distance = @x - point[:x]
      alpha = 255 - (distance * 2.0).to_i # Estompement un peu plus rapide
      alpha = 0 if alpha < 0
      c = Gosu::Color.rgba(base_color.red, base_color.green, base_color.blue, alpha)
      
      # === INTERPOLATION LINÉAIRE POUR DES PICS POINTUS ===
      start_x = prev_point[:x]
      end_x = point[:x]
      dx_total = (end_x - start_x).to_f
      
      # Sécurité pour éviter la division par zéro si la vitesse est nulle (ne devrait pas arriver ici)
      next if dx_total == 0

      # On boucle sur chaque pixel horizontal entre le point précédent et le nouveau.
      # Pour chaque pas en X, on calcule le Y correspondant sur la diagonale.
      (start_x...end_x).each do |cur_x|
        # Pourcentage d'avancement sur le segment (entre 0.0 et 1.0)
        progress = (cur_x - start_x) / dx_total
        
        # Calcul du Y interpolé
        cur_y = prev_point[:y] + (point[:y] - prev_point[:y]) * progress
        
        # On dessine notre "gros pixel" à la position calculée.
        # .to_i permet de "snapper" sur la grille de pixels.
        Gosu.draw_rect(cur_x, cur_y.to_i, @pixel_size, @pixel_size, c)
      end
    end
  end

  def draw_grid
    grid_color = Gosu::Color.rgba(0, 70, 0, 60)
    cell_size = 25
    (0..width).step(cell_size) { |x| Gosu.draw_rect(x, 0, 1, height, grid_color) }
    (0..height).step(cell_size) { |y| Gosu.draw_rect(0, y, width, 1, grid_color) }
  end
end

ECGWindow.new.show