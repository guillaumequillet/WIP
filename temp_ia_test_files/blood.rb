require 'gosu'

# Classe pour une particule individuelle de sang purement générée par code
class BloodParticle
  attr_reader :dead

  def initialize(window, x, y, vx, vy, size)
    @window = window
    @x = x
    @y = y
    @vx = vx
    @vy = vy
    @size = size # Taille de la particule en "pixels" (ex: 2 à 5 pour NxN)
    
    # Durée de vie aléatoire en trames (plus long = projection plus large)
    @life = rand(25..55)
    @total_life = @life
    @dead = false
    
    # Couleur : un rouge sang net, style RM2003
    base_red = rand(180..220)
    base_green = rand(0..15)
    base_blue = rand(0..15)
    @color = Gosu::Color.argb(255, base_red, base_green, base_blue)
  end

  def update
    return if @dead

    # Appliquer la vélocité
    @x += @vx
    @y += @vy

    # Appliquer la gravité (légère friction verticale)
    @vy += 0.32
    
    # Appliquer la friction de l'air horizontale (ralentit la projection)
    @vx *= 0.98

    # Réduire la vie
    @life -= 1
    @dead = true if @life <= 0
  end

  def draw
    return if @dead

    # Calculer l'alpha pour le fadeout (disparition progressive)
    # Pour un style plus net (less alpha), on pourrait juste faire disparaître.
    # L'alpha aide ici à simuler la perte de densité de la projection.
    alpha = (255.0 * @life / @total_life).to_i
    
    # Couleur finale avec alpha pour le fadeout
    final_color = Gosu::Color.argb(alpha, @color.red, @color.green, @color.blue)
    
    # Dessiner la particule comme un carré plein (style pixel net)
    @window.draw_rect(@x, @y, @size, @size, final_color, 2)
  end
end

# Classe principale de la fenêtre de jeu
class GameWindow < Gosu::Window
  WIDTH = 640
  HEIGHT = 480

  def initialize
    super WIDTH, HEIGHT, false
    self.caption = "Particle Blood Spray (Size 2-5, Directional)"

    # Tableau pour stocker les particules de sang actives
    @particles = []
  end

  def update
    # Déclencher l'effet sur clic gauche de la souris (MS_LEFT)
    if Gosu.button_down?(Gosu::MS_LEFT)
      # Décider de l'orientation en fonction des touches pressées
      direction = :explode # Par défaut, une explosion
      
      if Gosu.button_down?(Gosu::KB_W) || Gosu.button_down?(Gosu::KB_UP)
        direction = :up
      elsif Gosu.button_down?(Gosu::KB_S) || Gosu.button_down?(Gosu::KB_DOWN)
        direction = :down
      elsif Gosu.button_down?(Gosu::KB_A) || Gosu.button_down?(Gosu::KB_LEFT)
        direction = :left
      elsif Gosu.button_down?(Gosu::KB_D) || Gosu.button_down?(Gosu::KB_RIGHT)
        direction = :right
      end
      
      trigger_blood_effect(mouse_x, mouse_y, direction)
    end

    # Mettre à jour toutes les particules
    @particles.each(&:update)
    # Supprimer les particules mortes
    @particles.reject!(&:dead)
  end

  def draw
    # Fond magenta de l'image d'origine pour le contraste
    Gosu.draw_rect(0, 0, WIDTH, HEIGHT, Gosu::Color.argb(255, 128, 0, 128), 0)

    # Instructions
    draw_text("Instructions:", 10, HEIGHT - 110, 1, 1, 1, Gosu::Color::WHITE)
    draw_text("1. Cliquez gauche (MS_LEFT) pour l'origine.", 10, HEIGHT - 90, 1, 0.8, 0.8, Gosu::Color::YELLOW)
    draw_text("2. Maintenez une touche (Z/Q/S/D ou flèches) en cliquant:", 10, HEIGHT - 70, 1, 0.8, 0.8, Gosu::Color::YELLOW)
    draw_text("- Z/Haut: :up, Q/Gauche: :left, S/Bas: :down, D/Droite: :right", 10, HEIGHT - 50, 1, 0.8, 0.8, Gosu::Color::GRAY)
    draw_text("- Rien: :explode (explosion)", 10, HEIGHT - 30, 1, 0.8, 0.8, Gosu::Color::GRAY)

    # Dessiner les particules de sang
    @particles.each(&:draw)
  end

  # Méthode utilitaire pour dessiner du texte simple
  def draw_text(text, x, y, z_index, scale_x=1, scale_y=1, color=Gosu::Color::WHITE)
    @font ||= Gosu::Font.new(20)
    @font.draw_text(text, x, y, z_index, scale_x, scale_y, color)
  end

  private

  # Crée de multiples particules de sang avec des vélocités adaptées à l'orientation
  def trigger_blood_effect(x, y, direction)
    # Nombre de particules par projection
    35.times do
      vx = 0
      vy = 0
      
      # Logique de vélocité basée sur l'orientation décidée
      case direction
      when :left
        # Projection forte vers la gauche, légère remontée
        vx = rand(-15.0..-6.0) 
        vy = rand(-10.0..-3.0)
      when :right
        # Projection forte vers la droite, légère remontée
        vx = rand(6.0..15.0) 
        vy = rand(-10.0..-3.0)
      when :up
        # Projection forte vers le haut, faible étalement horizontal
        vx = rand(-4.0..4.0) 
        vy = rand(-15.0..-8.0)
      when :down
        # Projection vers le bas (fanning rapide), faible étalement horizontal
        vx = rand(-4.0..4.0) 
        vy = rand(6.0..13.0)
      when :explode
        # Explosion radiale (éparpillement large)
        vx = rand(-12.0..12.0) 
        vy = rand(-12.0..12.0)
      end
      
      # Taille de particule aléatoire entre 2 et 5 pixels de côté
      # (C'est la contrainte principale : rand(2..5))
      size = rand(2..5)
      
      @particles << BloodParticle.new(self, x, y, vx, vy, size)
    end
  end
end

GameWindow.new.show