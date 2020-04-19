# Encoding: binary
# frozen_string_literal: true

module Rbuspirate
  module Timeouts
    BINARY_RESET = 0.05
    SUCCESS = 0.1
    PINONOFF = 0.1

    module LE1WIRE
      ENTER = 0.2
      RESET = 0.5
      WRITE = 1
      READ = 1
    end

    module I2C
      ENTER = 0.2
      STARTSTOP = 0.5
      PREPARE_WRITE = 0.1
      ACKNACK = 0.3
      READ = 1
      SLAVE_ACKNACK = 0.5
      WRITE_THEN_READ_S = 5
      WRITE_THEN_READ_D = 5
    end

    module UART
      ENTER = 0.2
      BULK_WRITE = 5
    end
  end
end
