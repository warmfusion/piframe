require 'ws2801'
require 'weather-api'

WS2801.generate                # generate empty strip (Would happen from alone if you just start setting colors)

WS2801.length 12               # default
WS2801.device "/dev/spidev0.0" # default
WS2801.strip []
WS2801.autowrite true          # default


WS2801.off

class BaseFace
  @frame_size

  def initialize(size)
    size(size)
  end

  def size(size = nil)
    return @frame_size if size.nil?
    @frame_size = size
  end

  # Return 
  def getFrame(frame = nil)
    frame = []
    (0..size).each{ frame << { :r => frame % 127, :b => (frame % 127), :g => frame % 127 } }
    return frame
  end

end

class WeatherFace < BaseFace

  @location
  @forecast

  def initialize(size, location)
    size(size)
    @location = location
    updateForecast(location)
  end
  
  def updateForecast(location)
    forecast( Weather.lookup(location, Weather::Units::CELSIUS) )
  end

  def forecast(f = nil)
    return @forecast if f.nil?
    @forecast = f
  end

  def temp
    return forecast().condition.temp
  end

  def getFrame(frame = nil)
   # puts forecast().astronomy.sunrise
   # puts forecast().astronomy.sunset
   # puts forecast().condition.temp

    temp = forecast.condition.temp
    max=30
    min=0
    
    ratio = temp / (max-min).to_f if (temp < max and temp > min)
    ratio = 0 if temp < min
    ratio = 1 if temp > max

    puts ratio

    frame = []
    (0..size).each{ frame << { :r => 255 * (ratio), :b => 255 * (1-ratio), :g => 0 } }
    return frame
  end
end

class TimeColorCalculator < BaseFace
  @size
  @hms
  @offset
  @power
  LED_SPREAD = 2

  def initialize(size, offset=0, power=127)
    @size = size
    @offset = offset
    @power = power
    thr = Thread.new { while true; refresh; sleep 0.25; end }
    refresh
  end

  def getLuminance(target, position)
    ledDist = (target - position).abs # How far is the target from the position
    ledDist = ledDist 
    if ledDist > @size/2 
      ledDist = (ledDist - @size).abs # Wrap around edge
    end
    distRatio = ledDist / @size              # as a ratio of the whole
    # If the LED is outside our spread then, just return
    #puts "distRatio (%s) > spread (%s)" % [ distRatio, (LED_SPREAD / @size.to_f)]
    if distRatio > (LED_SPREAD / @size.to_f)
       return 0
    end

    # Now calculate what power to return;
    #  print "t: %f, p: %f, s: %f ; dist: %f" % (target, position, LED_SPREAD, distRatio)  
    offset = (LED_SPREAD - distRatio) / @size
    #puts "offset %s" % offset
    #puts "power %s" % @power
    #puts "luminance = %s" % (@power * offset)
    return (@power * offset).to_i

  end

  def getColor(position, frame)
    position = (position + @offset) % @size
    n = { 
         :r => getLuminance(@hms[:s], position), 
         :g => getLuminance(@hms[:m], position), 
         :b => getLuminance(@hms[:h], position) 
       }
    # puts 'At position %s, color should be: %s' % [position, n]
    return n 
  end

  # Calculates the position which is closest to the 
  # hour hand in question
  def refresh
    time = Time.new#(2015,01,01,0,0,0)
    h = ((time.hour + (time.min / 60.0)) / 12.0) * @size;
    m = ((time.min +  (time.sec / 60.0))/ 60.0) * @size;
    s = ((time.sec + (time.nsec/1000000000.0) )  / 60.0) * @size;
    @hms={ :h => h, :m => m, :s => s }
  end
end

#calc = ColorCalculator.new
calc = WeatherFace.new( 12, 12056 )

pixels = []
while true do
  WS2801.off
  frame = calc.getFrame
  frame.each_index do |i|
    pixels[(i*3)]   = frame[i][:r] || 0
    pixels[(i*3)+1] = frame[i][:g] || 0
    pixels[(i*3)+2] = frame[i][:b] || 0
  end

  WS2801.strip pixels
  WS2801.write
  sleep 10
end

