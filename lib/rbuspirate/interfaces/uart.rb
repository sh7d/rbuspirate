# Encoding: binary
# frozen_string_literal: true

require 'timeout'

module Rbuspirate
  module Interfaces
    class UART < Abstract
      attr_reader :bridge, :speed, :power, :pullup, :aux, :cs,
                  :pin_out_33, :parity_data, :stop_bits, :rx_idle,
                  :port, :speed, :echo_rx

      def initialize(serial, bup)
        raise 'Bus pirate must be in uart mode' unless bup.mode == :uart

        @bridge = false
        @bup = bup
        @le_port = serial
        @echo_rx = false
      end

      def configure_peripherals(...)
        raise 'Device needs reset in order to reconfigure it' if @bridge

        super
      end

      def speed=(le_speed)
        raise 'Device needs reset in order to reconfigure it' if @bridge

        bit_speed = case le_speed
                    when 300
                      Commands::UART::Config::Speed::S300
                    when 1200
                      Commands::UART::Config::Speed::S1200
                    when 2400
                      Commands::UART::Config::Speed::S2400
                    when 4800
                      Commands::UART::Config::Speed::S4800
                    when 9600
                      Commands::UART::Config::Speed::S9600
                    when 19_200
                      Commands::UART::Config::Speed::S19200
                    when 31_250
                      Commands::UART::Config::Speed::S31250
                    when 38_400
                      Commands::UART::Config::Speed::S38400
                    when 57_600
                      Commands::UART::Config::Speed::S57600
                    when 115_200
                      Commands::UART::Config::Speed::S115200
                    else
                      raise ArgumentError, 'Unsupported speed'
                    end

        simplex_command(bit_speed, Timeouts::SUCCESS, 'Unable to set speed')
        @speed = bit_speed
      end

      # Not working ?
      def echo_rx=(echo_state)
        raise ArgumentError, 'Echo state arg should be false or true' unless [true, false].include?(echo_state)
        return if echo_state == @echo_rx

        echo_comm = (Commands::UART::ECHO_RX | (echo_state ? 0 : 1))
        simplex_command(echo_comm, Timeouts::SUCCESS, "Unable to set echo rx state to #{echo_state}")
        @echo_rx = echo_state
      end

      def config_uart(
        pin_out_33: false, parity_data: :n8, stop_bits: 1, rx_idle: true
      )
        raise 'Device needs reset in order to reconfigure it' if @bridge

        raise ArgumentError, 'Pin out should be false or true' unless [true, false].include?(pin_out_33)
        raise ArgumentError, 'Unknown praity and databits mode' unless [:n8, :e8, :o8, :n9].include?(parity_data)
        raise ArgumentError, 'Unknown stop bits mode' unless [1, 2].include?(stop_bits)
        raise ArgumentError, 'Rx idle should be false or true' unless [true, false].include?(rx_idle)

        bit_conf_uart = Commands::UART::Config::CONF_UART

        bit_conf_uart |= Commands::UART::Config::UartConf::PIN_OUT_33 if pin_out_33
        bit_conf_uart |= case parity_data
                         when :e8
                           Commands::UART::Config::UartConf::DAT_PARITY_8E
                         when :o8
                           Commands::UART::Config::UartConf::DAT_PARITY_8O
                         when :n9
                           Commands::UART::Config::UartConf::DAT_PARITY_9N
                         else
                           0
                         end
        bit_conf_uart |= Commands::UART::Config::UartConf::STOP_BIT_2 if stop_bits == 2
        bit_conf_uart |= Commands::UART::Config::UartConf::DISABLE_RX_IDLE unless rx_idle

        simplex_command(bit_conf_uart, Timeouts::SUCCESS, 'Unable to config uart')

        @pin_out_33, @parity_data, @stop_bits, @rx_idle = pin_out_33, parity_data, stop_bits, rx_idle
      end

      def enter_bridge
        return @bridge if @bridge

        simplex_command(Commands::UART::START_BRIDGE, Timeouts::SUCCESS, 'Unable to enter bridge')
        @bridge = true
        @bup.instance_variable_set(:@needs_reset, true)
        @port = @le_port
      end

      def read(bytes = 0)
        raise 'Enable echo_rx or enter to bridge mode' unless @bridge || @echo_rx
        # Not working in echo rx mode - firmware bug or expect discards data buffer
        bytes.positive? ? @le_port.read(bytes) : @le_port.read
      end

      def write(data)
        data = data.to_s.b
        @bridge ? @le_port.write(data) : bulk_write(data)
      end

      protected

      def bulk_write(data)
        raise ArgumentError, 'Shitty arg' unless data.instance_of?(String)
        dbt = data.bytesize
        unpackstr = 'a16' * (dbt / 16)
        !(dbt % 16).zero? && unpackstr += "a#{dbt % 16}"
        data = data.unpack(unpackstr)
        data.each do |slice|
          comm = Commands::UART::BULK_WRITE | (slice.bytesize - 1)
          simplex_command(comm, Timeouts::SUCCESS, 'Unable to write data slice prepare')
          simplex_command(slice, Timeouts::SUCCESS, 'Unable to write data slice')
        end
        dbt
      end
    end
  end
end
