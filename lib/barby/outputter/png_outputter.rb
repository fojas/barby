require 'barby/outputter'
require 'chunky_png'

module Barby

  #Renders the barcode to a PNG image using chunky_png (gem install chunky_png)
  #
  #Registers the to_png, to_datastream and to_canvas methods
  class PngOutputter < Outputter

    register :to_png, :to_image, :to_datastream

    attr_accessor :xdim, :ydim, :width, :height, :margin, :color, :bgcolor


    #Creates a PNG::Canvas object and renders the barcode on it
    def to_image(opts={})
      with_options opts do
        canvas = ChunkyPNG::Image.new(full_width, full_height, bgcolor)

        if barcode.two_dimensional?
          x, y = margin, margin
          booleans.each do |line|
            line.each do |bar|
              if bar
                x.upto(x+(xdim-1)) do |xx|
                  y.upto y+(ydim-1) do |yy|
                    canvas[xx,yy] = color
                  end
                end
              end
              x += xdim
            end
            y += ydim
            x = margin
          end
        else
          x, y = margin, margin
          booleans.each do |bar|
            if bar
              x.upto(x+(xdim-1)) do |xx|
                y.upto y+(height-1) do |yy|
                  canvas[xx,yy] = ChunkyPNG::Color::BLACK
                end
              end
            end
            x += xdim
          end
        end

        canvas
      end
    end


    #Create a ChunkyPNG::Datastream containing the barcode image
    #
    # :constraints - Value is passed on to ChunkyPNG::Image#to_datastream
    #                E.g. to_datastream(:constraints => {:color_mode => ChunkyPNG::COLOR_GRAYSCALE})
    def to_datastream(*a)
      constraints = a.first && a.first[:constraints] ? [a.first[:constraints]] : []
      to_image(*a).to_datastream(*constraints)
    end


    #Renders the barcode to a PNG image
    def to_png(*a)
      to_datastream(*a).to_s
    end


    def width
      length * xdim
    end

    def height
      barcode.two_dimensional? ? (ydim * encoding.length) : (@height || 100)
    end

    def full_width
      width + (margin * 2)
    end

    def full_height
      height + (margin * 2)
    end

    def xdim
      @xdim || 1
    end

    def ydim
      @ydim || xdim
    end

    def margin
      @margin || 10
    end

    def color
      ( parse_color @color ) || ChunkyPNG::Color::BLACK
    end

    def bgcolor
      ( parse_color @bgcolor ) || ChunkyPNG::Color::WHITE
    end

    def length
      barcode.two_dimensional? ? encoding.first.length : encoding.length
    end

    def parse_color color_string
      return if color_string.nil?
      hex = if matches = color_string.match(/#([0-9a-f]{3,6})/i)
          ChunkyPNG::Color.parse matches[1]
      # rgb/rgba
      elsif matches = color_string.match(/rgba?\((\d{1,3}[,\s]+\d{1,3}[,\s]+\d{1,3})/)
        r, g, b = matches[1].split(",").map {|color| color.strip }
        ChunkyPNG::Color.parse "##{"%02x"%r}#{"%02x"%g}#{"%02x"%b}"
      end
    end


  end

end
