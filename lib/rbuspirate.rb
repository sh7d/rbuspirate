require 'expect'
require 'serialport'

require 'rbuspirate/commands'
require 'rbuspirate/responses'
require 'rbuspirate/timeouts'
require 'rbuspirate/interfaces/abstract'
require 'rbuspirate/interfaces/i2c'
require 'rbuspirate/interfaces/uart'
require 'rbuspirate/interfaces/1wire'

module Rbuspirate
  class Client
    def self.register_mode(
      name_symbol,    switch_command,
      wait_timeout,   enter_response,
      interface_class
    )
      define_method("enter_#{name_symbol}".to_sym) do
        switch_mode(
          name_symbol,    switch_command,
          wait_timeout,   enter_response,
          interface_class
        )
      end
    end

    attr_reader :mode, :interface, :needs_reset
    alias iface interface

    def initialize(dvc, sync: true)
      raise ArgumentError, 'Shitty arg' unless [SerialPort, String].include?(dvc.class)

      if dvc.instance_of?(String)
        raise 'Connect buspirate first' unless File.exist?(dvc)
        raise 'Device argument must be device' if File.stat(dvc).rdev.zero?

        dvc = SerialPort.new(dvc, 115_200, 8, 1, SerialPort::NONE)
        dvc.flow_control = SerialPort::NONE
      end
      @le_port = dvc
      @le_port.sync = true if sync
      @needs_reset = false
      reset_binary_mode
    end

    def reset_binary_mode
      raise 'Device needs reset to change mode' if @needs_reset

      20.times do
        @le_port.putc(Commands::RESET_BITBANG)
        resp = @le_port.expect(
          Responses::BITBANG_MODE, Timeouts::BINARY_RESET
        )

        if resp
          @interface = nil
          @mode = :bitbang
          return true
        end
      end

      raise 'Enter to bitbang failied'
    end

    def pin_on_off(power: false, pullup: false, aux: false, mosi: false, clk: false, miso: false, cs: false)
      argarray = [power, pullup, aux, mosi, clk, miso, cs].freeze
      argarray.each do |arg|
        raise ArgumentError, 'Shitty arg' unless [true, false].include?(arg)
      end

      final_comm = argarray
                   .each.with_index
                   .inject(Commands::Config::PINONOFF) do |comm, (arg, idx)|
                     arg ? (comm | 1 << idx) : (comm)
                   end
      @le_port.putc(final_comm)
      # I don't fucking understand:
      # "The Bus pirate responds to each update
      #  with a byte in the same format
      # that shows the current state of the pins"
      # So, why response is always a null byte ?
      resp = @le_port.expect(
        Responses::PINS_SET, Timeouts::PINONOFF
      )
      raise 'Setting pins state failied' unless resp
    end

    [
      [
        :i2c, Commands::I2C::ENTER,
        Timeouts::I2C::ENTER, Responses::I2C::ENTER,
        Interfaces::I2C
      ],
      [
        :uart, Commands::UART::ENTER,
        Timeouts::UART::ENTER, Responses::UART::ENTER,
        Interfaces::UART
      ],
      [
        :'1wire', Commands::LE1WIRE::ENTER,
        Timeouts::LE1WIRE::ENTER, Responses::LE1WIRE::ENTER,
        Interfaces::LE1WIRE
      ]
    ].each do |mode|
      register_mode(*mode)
    end

    private

    def switch_mode(
      name_symbol,    switch_command,
      wait_timeout,   enter_response,
      interface_class
    )
      raise 'Device needs reset to change mode' if @needs_reset
      reset_binary_mode
      @le_port.write(switch_command.chr)
      resp = @le_port.expect(
        enter_response, wait_timeout
      )
      if resp
        @mode = name_symbol
        @interface = interface_class.new(@le_port, self)
        return true
      end

      raise "Switch to #{name_symbol.to_s.upcase} failied"
    end
  end
end
