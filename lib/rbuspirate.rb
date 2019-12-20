require 'expect'
require 'optparse'
require 'serialport'

require 'rbuspirate/commands'
require 'rbuspirate/helpers'
require 'rbuspirate/responses'
require 'rbuspirate/timeouts'
require 'rbuspirate/interfaces/i2c'

Dir.glob(File.expand_path(__FILE__) + '**/*.rb') { |f| require_relative f }
module Rbuspirate
  class Client
    attr_reader :mode, :interface

    def initialize(serial)
      raise ArgumentError, 'Shitty arg' unless serial.class == SerialPort

      @le_port = serial
      reset_binary_mode
    end

    def reset_binary_mode
      20.times do
        @le_port.putc(Commands::RESET_BITBANG)
        resp = @le_port.expect(
          Responses::BITBANG_MODE, Timeouts::BINARY_RESET
        )
        return true if resp
      end
      raise 'Enter to bitbang failied'
      @mode = :bitbang
    end

    def enter_i2c
      return true if @mode == :i2c

      @le_port.write(Commands::I2C::ENTER.chr)
      resp = @le_port.expect(
        Responses::I2C::ENTER, Timeouts::I2C::ENTER
      )
      if resp
        @mode = :i2c
        @interface = Interfaces::I2C.new(@le_port, self)
        return true
      end

      raise 'Switch to I2C failied'
    end
  end
end
