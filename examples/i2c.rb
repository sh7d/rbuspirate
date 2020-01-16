require 'rbuspirate'

bp = Rbuspirate::Client.new('/dev/buspirate')
bp.enter_i2c
# valid settings are :'5khz', :'50khz', :'100khz', :'400khz'
bp.interface.speed = :'400khz'
# default vaules are false
bp.interface.configure_peripherals(
  power: true, pullup: true, aux: false, cs: false
)
# you can see definet peripherals config via accesors
puts "Power #{bp.interface.power ? 'enabled' : 'disabled'}"
puts "Pull-up resitors #{bp.interface.pullup ? 'enabled' : 'disabled'}"
# Frist argument is command
# second expected data to read
# succes_timeout specifies timeout to read data from device
# allow_zerobyte: allows one single byte instead of expected data to read
data = bp.interface.write_then_read(0xA1.chr, 4, succes_timeout: 5, allow_zerobyte: false)
puts "First 4 bytes are #{data.unpack('H*').join}"

# You can also acces raw mode
# Block is optional
bp.interface.send_start
ack_array = bp.interface.bulk_write("\xA0\x00\x00\xDE\xAD".b, ack_timeout: 1, &method(:puts))
bp.interface.send_stop
puts ack_array

# And read
bp.interface.send_start
bp.interface.bulk_write("\xA0\x00\x00".b)
bp.interface.send_stop
bp.interface.send_start
bp.interface.bulk_write("\xA1".b)
# default vaules are true for acks, and 1 for readbyte_timeout
data = bp.interface.read(4, auto_ack: true, auto_nack: true, readbyte_timeout: 1)
bp.interface.send_stop
puts "First 4 bytes are: #{data.unpack('H*').join}"
