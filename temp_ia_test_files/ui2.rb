require 'gosu'

class DocumentReader
  def initialize(window)
    @window = window
    @font = Gosu::Font.new(24, name: "Courier New") # Style machine à écrire
    @title_font = Gosu::Font.new(28, name: "Courier New", bold: true)
    
    @active = false
    @pages = []
    @current_page = 0
    @title = ""
  end

  # Ouvre un document et le découpe en pages
  def open(title, full_text)
    @title = title
    @current_page = 0
    @active = true
    
    # Découpage rudimentaire : 6 lignes max par page pour le style PS1
    words = full_text.split(' ')
    @pages = [[]]
    line = ""
    
    words.each do |word|
      if @font.text_width(line + word) < 400
        line += "#{word} "
      else
        @pages.last << line
        line = "#{word} "
        if @pages.last.size >= 6
          @pages << []
        end
      end
    end
    @pages.last << line unless line.empty?
  end

  def next_page
    if @current_page < @pages.size - 1
      @current_page += 1
    else
      @active = false # Ferme le document à la fin
    end
  end

  def draw
    return unless @active

    # 1. Overlay sombre sur tout l'écran
    @window.draw_rect(0, 0, @window.width, @window.height, Gosu::Color.argb(200, 0, 0, 0), 50)

    # 2. Le cadre du document (Style Resident Evil 1/2)
    w, h = 450, 300
    x = (@window.width - w) / 2
    y = (@window.height - h) / 2
    
    # Bordure blanche et fond noir
    @window.draw_rect(x-2, y-2, w+4, h+4, Gosu::Color::WHITE, 51)
    @window.draw_rect(x, y, w, h, Gosu::Color::BLACK, 52)

    # 3. Titre du document
    @title_font.draw_text(@title, x + 30, y + 20, 53, 1, 1, Gosu::Color::RED)

    # 4. Texte de la page actuelle
    @pages[@current_page].each_with_index do |line, i|
      @font.draw_text(line, x + 30, y + 70 + (i * 30), 53, 1, 1, Gosu::Color::WHITE)
    end

    # 5. Indicateur de pagination
    page_info = "Page #{@current_page + 1}/#{@pages.size}"
    @font.draw_text(page_info, x + w - 120, y + h - 40, 53, 0.8, 0.8, Gosu::Color::GRAY)
  end

  def active?; @active; end
end

class Game < Gosu::Window
  def initialize
    super 640, 480
    self.caption = "Resident Evil Document System"
    @reader = DocumentReader.new(self)
    
    # Contenu d'exemple (Journal du Gardien)
    @diary_title = "Journal du Gardien"
    @diary_text = "9 mai 1998. Joué au poker avec Scott et Alias. Alias a gagné. Je parie qu'il a triché. " +
                  "10 mai 1998. Un des prisonniers s'est échappé. Il avait l'air... différent. " +
                  "11 mai 1998. Ça gratte. Ça gratte énormément. Scott est mort. Il était bon. " +
                  "Itchy. Tasty."
  end

  def draw
    # Image de fond imaginaire
    Gosu.draw_rect(0, 0, 640, 480, Gosu::Color.argb(255, 40, 40, 50))
    @reader.draw
  end

  def button_down(id)
    if id == Gosu::KB_RETURN || id == Gosu::KB_SPACE
      if @reader.active?
        @reader.next_page
      else
        @reader.open(@diary_title, @diary_text)
      end
    end
  end
end

Game.new.show