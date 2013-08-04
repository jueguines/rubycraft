class Player
  SPEED = 0.1
  TURN_SPEED = 0.3
  REACH = 4
  WIDTH = 0.4

  attr_reader :x, :y, :z, :y_angle, :x_angle

  def initialize
    @x = 50
    @y = 20
    @z = -50
    @y_angle = 0
    @x_angle = 0
    @velocity = 0.0
  end

  def x1; @x-WIDTH; end
  def x2; @x+WIDTH; end
  def y1; @y-1.5; end
  def y2; @y+0.5; end
  def z1; @z-WIDTH; end
  def z2; @z+WIDTH; end

  def _move!(dx, dz)
    @x += dx
    @z += dz

    resolve_horizontal_collision
    resolve_horizontal_collision
  end

  def resolve_horizontal_collision
    unless colliding_blocks.empty?
      x_resolutions = colliding_blocks.map do |block|
        pos = block.x2 - x1
        neg = block.x1 - x2

        pos < neg.abs ? pos : neg
      end

      z_resolutions = colliding_blocks.map do |block|
        pos = block.z2 - z1
        neg = block.z1 - z2

        pos < neg.abs ? pos : neg
      end

      pos_x, neg_x = x_resolutions.partition{|x| x > 0 }
      pos_z, neg_z = z_resolutions.partition{|z| z > 0 }

      dx = if pos_x.size > neg_x.size
        pos_x.min
      elsif pos_x.size < neg_x.size
        neg_x.max
      elsif pos_z.size == neg_z.size
        x_resolutions.min_by(&:abs)
      else
        1.0/0
      end

      dz = if pos_z.size > neg_z.size
        pos_z.min
      elsif pos_z.size < neg_z.size
        neg_z.max
      elsif pos_x.size == neg_x.size
        z_resolutions.min_by(&:abs)
      else
        1.0/0
      end

      if dx.abs < dz.abs
        @x += dx
      else
        @z += dz
      end
    end
  end

  def fall!
    @y += @velocity

    unless colliding_blocks.empty?
      target_y = if @velocity > 0
                   colliding_blocks.map(&:y1).min - 0.5
                 else
                   colliding_blocks.map(&:y2).max + 1.5
                 end

      @y = target_y
      @velocity = 0
    end
  end

  def jump!
    if @velocity == 0
      @velocity = 0.19
    end
  end

  def gravity!
    @velocity -= 0.006
  end

  def forward!
    _move!(Gosu.offset_x(@y_angle, SPEED), Gosu.offset_y(@y_angle, SPEED))
  end

  def backward!
    _move!(-Gosu.offset_x(@y_angle, SPEED), -Gosu.offset_y(@y_angle, SPEED))
  end

  def sright!
    _move!(-Gosu.offset_y(@y_angle, SPEED), Gosu.offset_x(@y_angle, SPEED))
  end

  def sleft!
    _move!(Gosu.offset_y(@y_angle, SPEED), -Gosu.offset_x(@y_angle, SPEED))
  end

  def right!
    @y_angle += TURN_SPEED
  end

  def left!
    @y_angle -= TURN_SPEED
  end

  def turn!(d)
    @y_angle += d * TURN_SPEED
  end

  def look_up!(d)
    @x_angle -= d * TURN_SPEED
    @x_angle = [[90, @x_angle].min, -90].max
  end

  def targeted_block
    (0..REACH).step(0.05).map do |distance|
      horizontal = Math.cos(x_angle * Math::PI / 180) * distance
      vertical = Math.sin(x_angle * Math::PI / 180) * distance

      x = @x + Math.sin(y_angle * Math::PI / 180) * horizontal
      z = @z - Math.cos(y_angle * Math::PI / 180) * horizontal
      y = @y + vertical
      [x,y,z]
    end.map do |x, y, z|
      Blocks[Point.new(x.round,y.round,z.round)]
    end.compact.first
  end

  def colliding_blocks
    x_min = x1.floor.to_i
    x_max = x2.ceil.to_i
    y_min = y1.floor.to_i
    y_max = y2.ceil.to_i
    z_min = z1.floor.to_i
    z_max = z2.ceil.to_i

    nearby_blocks = (x_min..x_max).flat_map do |x|
      (y_min..y_max).flat_map do |y|
        (z_min..z_max).flat_map do |z|
          Array(Blocks[Point.new(x, y, z)])
        end
      end
    end

    nearby_blocks.select{|b| colliding?(b) }
  end

  def colliding?(block)
    x2 > block.x1 &&
      x1 < block.x2 &&
      y2 > block.y1 &&
      y1 < block.y2 &&
      z2 > block.z1 &&
      z1 < block.z2
  end
end
