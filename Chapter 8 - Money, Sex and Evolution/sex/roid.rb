class Roid
  attr_reader :velocity, :position, :energy, :sex, :lifespan, :age
  attr_writer :energy

  def initialize(slot, p, v)
    @velocity = v # assume v is a Vector with X velocity and Y velocity as elements
    @position = p # assume p is a Vector with X and Y as elements
    @slot = slot
    @energy = rand(MAX_ENERGY)
    @sex = rand(2) == 1 ? :male : :female
    @lifespan = rand(MAX_LIFESPAN)
    @age = 0
  end

  def male?
    @sex == :male
  end

  def female?
    @sex == :female
  end

  def distance_from(roid)
    distance_from_point(roid.position)
  end

  def distance_from_point(vector)
    x = self.position[0] - vector[0]
    y = self.position[1] - vector[1]
    Math.sqrt(x*x + y*y)    
  end

  def nearby?(threshold, roid)
    return false if roid === self
    (distance_from(roid) < threshold) and within_fov?(roid)
  end

  def within_fov?(roid)
    v1 = self.velocity - self.position
    v2 = roid.position - self.position
    cos_angle = v1.inner_product(v2)/(v1.r*v2.r)
    Math.acos(cos_angle) < 0.75 * Math::PI
  end

  def draw
    size = ROID_SIZE * @energy.to_f/50.0
    size = 10 if size > 10
    o = @slot.oval :left => @position[0], :top => @position[1], :radius => size, :center => true
    o.fill = @slot.lightblue if male?
    @slot.line @position[0], @position[1], @position[0] - @velocity[0], @position[1] - @velocity[1]    
  end

  def move
    @delta = Vector[0,0]    
    %w(separate align cohere muffle hungry).each do |action|
      self.send action
    end    
    @velocity += @delta
    @position += @velocity
    fallthrough and draw    
  end

  def separate
    distance = Vector[0,0]
    r = $roids.sort {|a,b| self.distance_from(a) <=> self.distance_from(b)}
    roids = r.first(MAGIC_NUMBER)
      roids.each do |roid|
        if nearby?(SEPARATION_RADIUS, roid)
          distance += self.position - roid.position
        end    
      end
    @delta += distance
  end

  # roids should look out for roids near it and then fly towards the center of where the rest are flying
  def align
    alignment = Vector[0,0]
    r = $roids.sort {|a,b| self.distance_from(a) <=> self.distance_from(b)}
    roids = r.first(MAGIC_NUMBER)
    roids.each do |roid|
      alignment += roid.velocity
    end
    alignment /= MAGIC_NUMBER
    @delta += alignment/ALIGNMENT_ADJUSTMENT
  end

  # roids should stick to each other
  def cohere
    average_position = Vector[0,0]
    r = $roids.sort {|a,b| self.distance_from(a) <=> self.distance_from(b)}
    roids = r.first(MAGIC_NUMBER)
    roids.each do |roid|
      average_position += roid.position
    end
    average_position /= MAGIC_NUMBER
    @delta +=  (average_position - @position)/COHESION_ADJUSTMENT
  end

  # get the roids to move around the center of the displayed world
  def center
    @delta -= (@position - Vector[WORLD[:xmax]/2, WORLD[:ymax]/2]) / CENTER_RADIUS
  end

  # muffle the speed of the roid to dampen the swing
  # swing causes the roid to move too quickly out of range to be affected by the rules
  def muffle
    if @velocity.r > MAX_ROID_SPEED
      @velocity /= @velocity.r 
      @velocity *= MAX_ROID_SPEED  
    end
  end

  def center
    @delta -= (@position - Vector[WORLD[:xmax]/2, WORLD[:ymax]/2]) / CENTER_RADIUS
  end

  def fallthrough
    x = case 
    when @position[0] < 0            then WORLD[:xmax] + @position[0]
    when @position[0] > WORLD[:xmax] then WORLD[:xmax] - @position[0]
    else @position[0]
    end
    y = case 
    when @position[1] < 0            then WORLD[:ymax] + @position[1]
    when @position[1] > WORLD[:ymax] then WORLD[:ymax] - @position[1]
    else @position[1]
    end 
    
    @position = Vector[x,y]    
  end

  # get attracted to food
  def hungry
    $food.each do |food|
      if distance_from_point(food.position) < (food.quantity + ROID_SIZE*5)
        @delta -= self.position - food.position
      end  
      if distance_from_point(food.position) <= food.quantity + 5
        eat food
      end  
    end    
  end

  def reduce_energy_from_childbirth
    @energy -= CHILDBEARING_ENERGY_SAP
  end

  # consume the food and replenish energy with it
  def eat(food)  
    amt_consumed = (male? ? MALE_METABOLISM : FEMALE_METABOLISM)
    food.eat amt_consumed    
    @energy += amt_consumed
  end

  # lose energy at every tick
  def lose_energy
    @energy -= 1
  end
  
  def grow_older
    @age += 1
  end

  def procreate
    if attractive and female?
      # check for potential nearby mates
      r = $roids.sort {|a,b| self.distance_from(a) <=> self.distance_from(b)}
      roids = r.first(MAGIC_NUMBER)
      roid = roids.delete_if {|r| r.female? or not (r.attractive)}.first

      if roid
        baby = Roid.new(@slot, @position, @velocity)

        $roids << baby
        reduce_energy_from_childbirth
        roid.reduce_energy_from_childbirth
      end

    end
  end

  def attractive
    CHILDBEARING_AGE.include? @age  and @energy > CHILDBEARING_ENERGY_LEVEL
  end

  # called at every tick of time
  def tick
    move
    lose_energy
    grow_older
    procreate
    if @energy <= 0 or @age > @lifespan
      $roids.delete self
    end    
  end

end