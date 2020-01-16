require 'rbuspirate'

bp = Rbuspirate::Client.new('/dev/buspirate')
bp.enter_uart
# set speed
bp.interface.speed = 115_200
# parity_data possible vaules are: :n8, :e8, :o8, :n9
bp.interface.config_uart(
  pin_out_33: true, stop_bits: 1, parity_data: :n8, rx_idle: true
)
# you can see defined settings via accesors
puts "Pin out voltage #{bp.interface.pin_out_33 ? '3.3V' : '5V'}"
# Enable power
bp.interface.configure_peripherals(
  power: false, pullup: false, aux: false, cs: false
)
# you can call to configure_peripherals like configure_peripherals(power: true)
# rest of arguments will be in default state (false)
# you can also see peripherals config state via accesors
puts "Power #{bp.interface.power ? 'enabled' : 'disabled'}"
# Bridge mode
bp.interface.enter_bridge

# raw port is exposed via port accesor
port = bp.interface.port

while (line = port.readline)
  puts line
end
