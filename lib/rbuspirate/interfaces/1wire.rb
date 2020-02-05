# Encoding: binary
# frozen_string_literal: true

module Rbuspirate
  module Interfaces
    class LE1WIRE < Abstract
      def initialize(serial, bup)
        raise 'Bus pirate must be in 1wire mode' unless bup.mode == :'1wire'
        @le_port = serial
      end

      def reset
        simplex_command(
          Commands::LE1WIRE::RESET,
          Timeouts::LE1WIRE::RESET,
          'Unable to reset external device (comm timeout/no device)'
        )
      end

      def write(data, write_slice_timeout: Timeouts::LE1WIRE::WRITE)
        !(data.is_a?(String) && !data.empty?) &&
          raise(ArgumentError, 'data must be non empty String instance')

        data = StringIO.new(data)
        while (slice = data.read(16))
          command = Commands::LE1WIRE::IO::WRITE | slice.bytesize - 1
          simplex_command(
            command, write_slice_timeout, 'Prepare slice write timeout'
          )
          @le_port.expect(Responses::SUCCESS, Timeouts::SUCCESS)
          @le_port.write(slice)
          res = @le_port.expect(Responses::SUCCESS, write_slice_timeout)
          raise 'Write timeout' unless res
        end
        true
      end

      def read(bytes = 1, readbyte_timeout: Timeouts::LE1WIRE::READ)
        result = ''.dup.b
        bytes.times do
          @le_port.write(Commands::LE1WIRE::IO::READ.chr)
          Timeout.timeout(readbyte_timeout) do
            result << @le_port.read(1)
          end
        end

        result
      end
    end
  end
end
