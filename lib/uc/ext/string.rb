class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end 

  def bold
    "\e[1m#{self}\e[0m"
  end 
  
  def white
    colorize(37)
  end 

  def green
    colorize(32)
  end 

  def yellow
    colorize(33)
  end 

  def red 
    colorize(31)
  end 

  def blue
    colorize(34)
  end 
end
