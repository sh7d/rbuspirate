# Encoding: binary
# frozen_string_literal: true

module Rbuspirate
  module Interfaces
    class Abstract
      def configure_peripherals(
        power: false, pullup: false, aux: false, cs: false
      )
        [power, pullup, aux, cs].map(&:class).each do |cls|
          raise ArgumentError, 'All args must be true or false' unless [FalseClass, TrueClass].include?(cls)
        end

        bit_config = Commands::CONF_PER
        bit_config |= Commands::Config::Peripherals::POWER if power
        bit_config |= Commands::Config::Peripherals::PULLUP if pullup
        bit_config |= Commands::Config::Peripherals::AUX if aux
        bit_config |= Commands::Config::Peripherals::CS if cs

        simplex_command(
          bit_config,
          Timeouts::SUCCESS,
          'Unable to confgure peripherals'
        )
       @power, @pullup, @aux, @cs = power, pullup, aux, cs
      end

      protected

      def simplex_command(command, tout, ex_message)
        command = command.chr if command.instance_of?(Integer)
        @le_port.write(command.chr)
        resp = @le_port.expect(Responses::SUCCESS, tout)
        return true if resp

        raise ex_message
      end
    end
  end
end
