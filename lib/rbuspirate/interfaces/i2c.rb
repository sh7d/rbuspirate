# Encoding: binary
# frozen_string_literal: true

require 'timeout'

module Rbuspirate
  module Interfaces
    class I2C < Abstract
      attr_reader :speed, :power, :pullup, :aux, :cs

      def initialize(serial, bup)
        raise 'Bus pirate must be in i2c mode' unless bup.mode == :i2c

        @le_port = serial
        set_speed(:'400khz')
      end

      def speed=(le_speed)
        set_speed(le_speed)
      end

      def send_start
        simplex_command(
          Commands::I2C::Flow::START,
          Timeouts::I2C::STARTSTOP,
          'Unable to sent start bit'
        )
      end

      def send_stop
        simplex_command(
          Commands::I2C::Flow::STOP,
          Timeouts::I2C::STARTSTOP,
          'Unable to sent stop bit'
        )
      end

      def send_ack
        simplex_command(
          Commands::I2C::Flow::ACK,
          Timeouts::I2C::ACKNACK,
          'Unable to sent ack'
        )
      end

      def send_nack
        simplex_command(
          Commands::I2C::Flow::NACK,
          Timeouts::I2C::ACKNACK,
          'Unable to sent nack'
        )
      end

      def read(bytes = 1, auto_ack: true, auto_nack: true, readbyte_timeout: Timeouts::I2C::READ)
        result = ''.dup.b
        bytes.times do |t|
          @le_port.write(Commands::I2C::READBYTE.chr)
          Timeout.timeout(readbyte_timeout) do
            result << @le_port.read(1)
          end
          send_ack if auto_ack && t + 1 != bytes
          send_nack if auto_nack && t + 1 == bytes
        end
        result
      end

      def bulk_write(data, ack_timeout: Timeouts::I2C::SLAVE_ACKNACK)
        raise ArgumentError, 'data must be String instance' unless data.instance_of?(String)

        if !data.instance_of?(String) || data.instance_of?(String) && data.empty?
          raise ArgumentError, 'Bad data argument'
        end
        raise ArgumentError, 'Data is too long' if data.bytesize > 16

        bit_bulk_write = Commands::I2C::PREPARE_WRITE | data.bytesize - 1
        simplex_command(
          bit_bulk_write.chr,
          Timeouts::I2C::PREPARE_WRITE,
          'Unable to prepare write mode'
        )
        ack_array = []
        data.each_byte do |data_byte|
          @le_port.write(data_byte.chr)
          Timeout.timeout(ack_timeout) do
            ack_array << case @le_port.read(1).ord
                         when 0
                           :ack
                         when 1
                           :nack
                         else
                           raise 'Unknown bytewrite response'
                         end
            yield(ack_array.last) if block_given?
          end
        end
        ack_array.freeze
      end

      def write_then_read(
        data, expected_bytes = 0,
        succes_timeout: Timeouts::I2C::WRITE_THEN_READ_S,
        allow_zerobyte: false
      )
        raise ArgumentError, 'Bad data type' unless data.instance_of?(String)
        raise ArgumentError, 'Data is too long' if data.bytesize > 4096
        raise ArgumentError, 'Bad expected_bytes type' unless expected_bytes.instance_of?(Integer)
        raise ArgumentError, 'Bad expected_bytes value' if expected_bytes.negative? || expected_bytes > 4096

        binary_command = Commands::I2C::WRITE_THEN_READ.chr +
                         [data.bytesize, expected_bytes].pack('S>S>') +
                         data
        @le_port.write(binary_command)
        result = nil
        # So fucking ugly
        begin
          Timeout.timeout(succes_timeout) do
            result = @le_port.read(1)
          end
        rescue Timeout::Error
          return false
        end
        return false if allow_zerobyte && result.ord.zero?
        raise 'Write failed' if result.ord.zero?
        if expected_bytes != 0
          Timeout.timeout(Timeouts::I2C::WRITE_THEN_READ_D) do
            result = @le_port.read(expected_bytes)
          end
          result
        else
          true
        end
      end
      private
      def set_speed(le_speed)
        bit_speed = case le_speed.to_sym
                    when :'5khz'
                      Commands::I2C::Config::Speed::S5KHZ
                    when :'50khz'
                      Commands::I2C::Config::Speed::S50KHZ
                    when :'100khz'
                      Commands::I2C::Config::Speed::S100KHZ
                    when :'400khz'
                      Commands::I2C::Config::Speed::S400KHZ
                    else
                      raise ArgumentError, 'Bad speed argument'
                    end

        simplex_command(bit_speed, Timeouts::SUCCESS, 'Unable to set speed')
        @speed = le_speed
      end
    end
  end
end
