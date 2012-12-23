require 'matrix'
require 'csv'
require 'enc/trans/transdb'
require './parameters'
require './roid'
require './food'

class Vector
  def /(x)
    if (x != 0)
      Vector[self[0]/x.to_f,self[1]/x.to_f]
    else
      self
    end
  end  
end

def random_location
  Vector[rand(WORLD[:xmax]),rand(WORLD[:ymax])]
end

def populate
  POPULATION_SIZE.times do
    random_velocity = Vector[rand(11)-5,rand(11)-5]
    $roids << Roid.new(self, random_location, random_velocity)
  end  
end

def scatter_food
  FOOD_COUNT.times do
    $food << Food.new(self, random_location)     
  end  
end

def randomly_scatter_food(probability)
  if (0..probability).include?(rand(100))
    $food << Food.new(self, random_location)
  end  
end

def write(data)
  CSV.open('data.csv', 'w') do |csv|
    data.each do |row|
      csv << row
    end
  end  
end

Shoes.app(:title => 'Utopia', :width => WORLD[:xmax], :height => WORLD[:ymax]) do
  background ghostwhite
  stroke slategray

  $roids = []
  $food = []
  data = []
  populate
  scatter_food
  
  time = END_OF_THE_WORLD
  
  animate(FPS) do 
    randomly_scatter_food 70
    clear do
      males = 0
      females = 0
      fill yellowgreen      
      $food.each do |food| food.tick; end
      fill gainsboro      
      $roids.each do |roid| 
        males += 1 if roid.male?
        females += 1 if roid.female?
        roid.tick 
      end
      data << [$roids.size, males, females]
      para "countdown: #{time}"
      para "population: #{$roids.size}"      
      para "male: #{males}"
      para "female: #{females}"
    end
    
    time -= 1
    close & write(data) if time < 0 or $roids.size <= 0        
  end
end
