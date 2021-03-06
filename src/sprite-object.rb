#==============================================================================
# ■ Sprite_Object
#==============================================================================

class Sprite_Object < Sprite_Base
  
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize(viewport = nil)
    super(viewport)
    #---
    @dest_angle = 0
    @dest_x = 0
    @dest_y = 0
    #---
    @angle_rate = 0
    @move_x_rate = 0
    @move_y_rate = 0
    @fade_rate = 0
    #---
    @arc = 0
    @parabola = {}
    @f = 0
    @arc_y = 0
    #---
    @battler = nil
    @offset_x = 0
    @offset_y = 0
    @offset_z = 0
    @attach_x = 0
    @attach_y = 0
    @attachment = :middle
  end
  
  #--------------------------------------------------------------------------
  # set_battler
  #--------------------------------------------------------------------------
  def set_battler(battler = nil)
    @battler = battler
    update
  end
  
  #--------------------------------------------------------------------------
  # set_position
  #--------------------------------------------------------------------------
  def set_position(x, y)
    @dest_x = self.x = x
    @dest_y = self.y = y
  end
  
  #--------------------------------------------------------------------------
  # set_angle
  #--------------------------------------------------------------------------
  def set_angle(angle)
    @dest_angle = self.angle = angle
    @dest_angle = self.angle = -angle if mirror_battler?
  end
  
  #--------------------------------------------------------------------------
  # set_icon
  #--------------------------------------------------------------------------
  def set_icon(index)
    return if index <= 0
    bitmap = Cache.system("Iconset")
    self.bitmap ||= bitmap
    self.src_rect.set(index % 16 * 24, index / 16 * 24, 24, 24)
    self.ox = self.oy = 12
  end
  
  #--------------------------------------------------------------------------
  # set_origin
  #--------------------------------------------------------------------------
  def set_origin(type)
    @offset_z = 2
    @attachment = type
    case type
    when :item
      self.ox = 12
      self.oy = 12
      @offset_y = -@battler.sprite.height
      @offset_x = -@battler.sprite.width / 2
    when :hand1
      self.ox = 24
      self.oy = 24
      @attach_y = -@battler.sprite.height/3
      @attach_x = -@battler.sprite.width/5
    when :hand2
      self.ox = 24
      self.oy = 24
      @attach_y = -@battler.sprite.height/3
      @attach_x = @battler.sprite.width/5
    when :middle
      self.ox = 12
      self.oy = 12
      @offset_y = -@battler.sprite.height/2
    when :top
      self.ox = 12
      self.oy = 24
      @offset_y = -@battler.sprite.height
    when :base
      self.ox = 12
      self.oy = 24
    end
    self.y = @battler.screen_y + @attach_y + @offset_y + @arc_y
  end
  
  #--------------------------------------------------------------------------
  # set_fade
  #--------------------------------------------------------------------------
  def set_fade(rate)
    @fade_rate = rate
  end
  
  #--------------------------------------------------------------------------
  # create_angle
  #--------------------------------------------------------------------------
  def create_angle(angle, frames = 8)
    return if angle == self.angle
    @dest_angle = angle
    @dest_angle = - @dest_angle if mirror_battler?
    frames = [frames, 1].max
    @angle_rate = [(self.angle - @dest_angle).abs / frames, 2].max
  end
  
  #--------------------------------------------------------------------------
  # create_arc
  #--------------------------------------------------------------------------
  def create_arc(arc)
    @arc = arc
    @parabola[:x] = 0
    @parabola[:y0] = 0
    @parabola[:y1] = @dest_y - self.y
    @parabola[:h]  = - (@parabola[:y0] + @arc * 5)
    @parabola[:d]  = (self.x - @dest_x).abs
  end
  
  #--------------------------------------------------------------------------
  # create_movement
  #--------------------------------------------------------------------------
  def create_movement(destination_x, destination_y, frames = 12)
    return if self.x == destination_x && self.y == destination_y
    @arc = 0
    @dest_x = destination_x
    @dest_y = destination_y
    frames = [frames, 1].max
    @f = frames.to_f / 2
    @move_x_rate = [(self.x - @dest_x).abs / frames, 2].max
    @move_y_rate = [(self.y - @dest_y).abs / frames, 2].max
  end
  
  #--------------------------------------------------------------------------
  # create_move_direction
  #--------------------------------------------------------------------------
  def create_move_direction(direction, distance, frames = 12)
    case direction
    when 1; move_x = distance / -2; move_y = distance /  2
    when 2; move_x = distance *  0; move_y = distance *  1
    when 3; move_x = distance / -2; move_y = distance /  2
    when 4; move_x = distance * -1; move_y = distance *  0
    when 6; move_x = distance *  1; move_y = distance *  0
    when 7; move_x = distance / -2; move_y = distance / -2
    when 8; move_x = distance *  0; move_y = distance * -1
    when 9; move_x = distance /  2; move_y = distance / -2
    else; return
    end
    #---
    move_x += self.x
    move_y += self.y
    #---
    create_movement(move_x, move_y, frames)
  end
  
  #--------------------------------------------------------------------------
  # update
  #--------------------------------------------------------------------------
  def update
    super
    update_angle
    @arc == 0 ? update_movement : update_arc
    update_position
    update_opacity
  end
  
  #--------------------------------------------------------------------------
  # update_angle
  #--------------------------------------------------------------------------
  def update_angle
    return if @angle_rate == 0
    @angle_rate = 0 if self.angle == @dest_angle
    value = [(self.angle - @dest_angle).abs, @angle_rate].min
    self.angle += (@dest_angle > self.angle) ? value : -value
  end
  
  #--------------------------------------------------------------------------
  # update_arc
  #--------------------------------------------------------------------------
  def update_arc
    return unless [@move_x_rate, @move_y_rate].any? { |x| x != 0 }
    #---
    value = [(self.x - @dest_x).abs, @move_x_rate].min
    @offset_x += (@dest_x > self.x) ? value : -value
    @parabola[:x] += value
    #---
    if @dest_x == self.x
      self.y = @dest_y
    else
      a = (2*(@parabola[:y0]+@parabola[:y1])-4*@parabola[:h])/(@parabola[:d]**2)
      b = (@parabola[:y1]-@parabola[:y0]-a*(@parabola[:d]**2))/@parabola[:d]
      @arc_y = a * @parabola[:x] * @parabola[:x] + b * @parabola[:x] + @parabola[:y0]
    end
    #---
    @move_x_rate = 0 if self.x == @dest_x
    @move_y_rate = 0 if self.y == @dest_y
  end
  
  #--------------------------------------------------------------------------
  # update_movement
  #--------------------------------------------------------------------------
  def update_movement
    return unless [@move_x_rate, @move_y_rate].any? { |x| x != 0 }
    @move_x_rate = 0 if self.x == @dest_x
    @move_y_rate = 0 if self.y == @dest_y
    value = [(self.x - @dest_x).abs, @move_x_rate].min
    @offset_x += (@dest_x > self.x) ? value : -value
    value = [(self.y - @dest_y).abs, @move_y_rate].min
    @offset_y += (@dest_y > self.y) ? value : -value
  end
  
  #--------------------------------------------------------------------------
  # update_position
  #--------------------------------------------------------------------------
  def update_position
    if @battler != nil
      self.mirror = mirror_battler?
      update_attachment(self.mirror)
      attach_x = self.mirror ? -@attach_x : @attach_x
      self.x = @battler.screen_x + attach_x + @offset_x
      self.y = @battler.screen_y + @attach_y + @offset_y + @arc_y
      self.z = @battler.screen_z + @offset_z
    else
      self.x = @offset_x
      self.y = @offset_y
      self.z = @offset_z
    end
  end
  
  #--------------------------------------------------------------------------
  # update_attachment
  #--------------------------------------------------------------------------
  def update_attachment(mirror = false)
    case @attachment
    when :hand1
      self.ox = mirror ? 0 : 24
      self.oy = 24
      @attach_y = -@battler.sprite.height/3
      @attach_x = -@battler.sprite.width/5
    when :hand2
      self.ox = mirror ? 0 : 24
      self.oy = 24
      @attach_y = -@battler.sprite.height/3
      @attach_x = @battler.sprite.width/5
    else
      @attach_x = 0
      @attach_y = 0
    end
  end
  
  #--------------------------------------------------------------------------
  # update_attachment
  #--------------------------------------------------------------------------
  def update_opacity
    self.opacity += @fade_rate
  end
  
  #--------------------------------------------------------------------------
  # mirror_battler?
  #--------------------------------------------------------------------------
  def mirror_battler?
    return false if @battler.sprite == nil
    direction = Direction.direction(@battler.pose)
    return true if [9, 6, 3].include?(direction)
    return true if @battler.sprite.mirror
    return false
  end
  
  #--------------------------------------------------------------------------
  # effecting?
  #--------------------------------------------------------------------------
  def effecting?
    [@angle_rate,@move_y_rate,@move_x_rate,@fade_rate].any? { |x| x > 0 }
  end
  
end # Sprite_Object