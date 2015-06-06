require 'ws2801'

WS2801.generate                # generate empty strip (Would happen from alone if you just start setting colors)

WS2801.length 12               # default
WS2801.device "/dev/spidev0.0" # default
WS2801.strip []
WS2801.autowrite true          # default


#4.times do |i|
#  WS2801.set :pixel => i*3, :r => 127
#  WS2801.set :pixel => (i*3)+1, :g => 127
#  WS2801.set :pixel => (i*3)+2, :b => 127
#end


#sleep(1)

def guage(n) 
 r = (255 * n) / 100
 g = (255 * (100 - n)) / 100 
 b = 0
 return { :r => r, :g => g, :b => b }
end

WS2801.off

# Flash from outer to in

x=0
while true do
        x = x+1
	c = guage(x % 100)
	((WS2801.length/2).to_i+1).times do |i|
		WS2801.set :pixel => ((WS2801.length-i)..WS2801.length).to_a + (0..i).to_a, :r => c[:r], :g => c[:g], :b => c[:b]
		sleep(0.01)
	end
	c = nil
end

exit

WS2801.off
len = WS2801.length
blk = { :r=>0, :g=>0, :b=>0};

while true do
  len.times do |i|
#    c = { :r => rand(255), :g => rand(255), :b => rand(255) }
	c = { :r => 0, :g => 0, :b => 255 }
    WS2801.set blk.merge ({:pixel => ((i+len)-1) % len}) 
    WS2801.set c.merge ({:pixel => i} )
   sleep (0.2)
  end
end

WS2801.off

