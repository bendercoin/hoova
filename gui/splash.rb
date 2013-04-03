module HoovaSplash
  def show_splash
    border(
        "#999",
        :strokewidth => 3
    )

    stack :width => "100%" do
      click { start }
      display_hoova_girl
      @logo = image "./hoova-medium.gif", :margin => [190, 20]
      @subtitle = image "./hoova-subtext-medium.gif", :margin => [95, 10]

      #splash_animate_slide('right', @logo, -245, 190)
      #splash_animate_slide('left', @subtitle, 640, 95)
      para "Sweeping Your Bitcoin Balances Faster than a Cypress Bureaucrat.\n",
           "Hiro White 2013. Visit: ",
           link("http://agoristradio.github.com/hoova/", :click => "http://agoristradio.github.com/hoova/"),
           :align => 'center', :margin => [0,30]
    end
    timer(10) do
      start
    end

  end

  def start
    visit '/start'
  end

  def display_hoova_girl
    hoova_girl_frame
    image "./hoova-girl.png", :margin => [220, 25],
          :stroke => black, :strokewidth => 0.25
  end

  def hoova_girl_frame
    rect 218, 23, 199, 243
  end

  def splash_animate_slide(direction, item, position, end_position)
    animation = animate 1000 do
      case direction
        when 'right'
          position += 1
        when 'left'
          position -= 1
      end
      item.displace(position, 0)
      animation.stop if position == end_position
    end
  end
end


