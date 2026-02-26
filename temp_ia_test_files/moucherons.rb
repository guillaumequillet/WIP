require 'gosu'

# --- Constantes Globales ---
LARGEUR = 800
HAUTEUR = 600

# Centre de l'essaim adapté au plafonnier
LAMPE_X = LARGEUR / 2
LAMPE_Y = 85

# --- NOUVEAUX REGLAGES ---
NB_MOUCHERONS = 7   # Encore un peu moins
VITESSE_MAX = 0.18  # Vitesse maximale doublée (était à 0.09)

# Paramètres de profondeur
TAILLE_MIN = 1.0
TAILLE_MAX = 3.5
ALPHA_MIN = 100 
ALPHA_MAX = 255

class Moucheron
  attr_accessor :x, :y, :z, :angle

  def initialize
    @angle = rand(0..2 * Math::PI)
    
    # Vitesse de base augmentée (0.06 minimum au lieu de 0.02)
    @speed = rand(0.06..VITESSE_MAX)
    
    # Rayon d'action resserré près de l'ampoule
    @radius = rand(15..50)

    # Hauteur de vol
    @base_y = rand(LAMPE_Y - 15..LAMPE_Y + 25)
    @y_jitter = rand(-10..10)
  end

  def update
    @angle += @speed

    # Calcul de la position 3D
    @base_x = LAMPE_X + Math.cos(@angle) * @radius
    @z = Math.sin(@angle)

    # Vol erratique
    @y = @base_y + rand(@y_jitter-2..@y_jitter+2)
  end

  def color_at_depth
    perspective_factor = (@z + 1.0) / 2.0
    alpha = (ALPHA_MIN + (ALPHA_MAX - ALPHA_MIN) * perspective_factor).to_i
    
    # Couleur noire constante, on joue sur l'alpha
    Gosu::Color.new(alpha, 10, 10, 10)
  end

  def scale_at_depth
    perspective_factor = (@z + 1.0) / 2.0
    TAILLE_MIN + (TAILLE_MAX - TAILLE_MIN) * perspective_factor
  end

  def draw
    scale = scale_at_depth
    color = color_at_depth

    draw_x = @base_x - scale/2
    draw_y = @y - scale/2

    # Couche 1 pour être au-dessus du fond
    Gosu.draw_rect(draw_x, draw_y, scale, scale, color, 1)
  end
end

class MaFenetre < Gosu::Window
  def initialize
    super(LARGEUR, HAUTEUR, false)
    self.caption = "Moucherons rapides autour du plafonnier"

    @fond = Gosu::Image.new("./scenes/vestiaire/CAM_01.png")

    @moucherons = []
    NB_MOUCHERONS.times { @moucherons << Moucheron.new }
  end

  def update
    @moucherons.each(&:update)
    close if Gosu.button_down?(Gosu::KB_ESCAPE)
  end

  def draw
    # Dessiner l'image de fond sur la couche 0
    scale_x = LARGEUR.to_f / @fond.width
    scale_y = HAUTEUR.to_f / @fond.height
    @fond.draw(0, 0, 0, scale_x, scale_y)

    # Dessiner les moucherons triés par profondeur
    moucherons_tries = @moucherons.sort_by { |m| m.z }
    moucherons_tries.each(&:draw)
  end
end

MaFenetre.new.show