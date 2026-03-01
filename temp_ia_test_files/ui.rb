require 'gosu'

class DialogueWindow
  def initialize(window)
    @window = window
    @font = Gosu::Font.new(22, name: "Verdana") # Plus proche du style RE
    @bg_color = Gosu::Color.argb(180, 0, 0, 0)   # Noir translucide
    @active = false
    @display_text = ""
    @full_text = []
    @index = 0
    @line_height = 28
  end

  # Cette méthode découpe le texte pour qu'il tienne dans la largeur
  def say(text, width_limit)
    words = text.split(' ')
    lines = [""]
    
    words.each do |word|
      if @font.text_width(lines.last + word) < width_limit
        lines[lines.size - 1] += "#{word} "
      else
        lines << "#{word} "
      end
    end
    
    @full_text = lines
    @display_text = ""
    @char_index = 0
    @line_index = 0
    @active = true
  end

  def update
    return unless @active
    # Vitesse d'apparition des caractères
    if @line_index < @full_text.size
      current_line_full = @full_text[@line_index]
      if @char_index < current_line_full.length
        @char_index += 1
      elsif @line_index < @full_text.size - 1
        @line_index += 1
        @char_index = 0
      end
    end
  end

  def draw
    return unless @active
    
    # Style Resident Evil : Bandeau sobre
    h = 120
    y = @window.height - h - 20
    x = 10
    w = @window.width - 20

    # Fond noir simple
    @window.draw_rect(x, y, w, h, @bg_color, 10)

    # Affichage des lignes
    @full_text.each_with_index do |line, i|
      next if i > @line_index
      
      # Si c'est la ligne en cours d'écriture, on la tronque
      content = (i == @line_index) ? line[0...@char_index] : line
      
      # Texte avec ombre portée légère
      @font.draw_text(content, x + 21, y + 21 + (i * @line_height), 11, 1, 1, Gosu::Color::BLACK)
      @font.draw_text(content, x + 20, y + 20 + (i * @line_height), 12, 1, 1, Gosu::Color::WHITE)
    end
  end
end

class GameWindow < Gosu::Window
  def initialize
    super 640, 480
    @ui = DialogueWindow.new(self)
    # On définit une limite de largeur (largeur fenêtre - marges)
    @ui.say("Barry: 'Regarde cette architecture... On dirait l'ère PlayStation 1 ! C'est vraiment impressionnant, n'est-ce pas ?'", 580)
  end

  def update; @ui.update; end
  def draw
    # Simule un décor sombre
    Gosu.draw_rect(0, 0, width, height, Gosu::Color.argb(255, 20, 15, 15))
    @ui.draw
  end
end

GameWindow.new.show