# Encoding: binary
# frozen_string_literal: true

module Rbuspirate
  module Responses
    BITBANG_MODE = 'BBIO1'
    SUCCESS = 0x01.chr
    PINS_SET = 0x00.chr

    module LE1WIRE
      ENTER = '1W01'
    end

    module I2C
      ENTER = 'I2C1'
    end

    module UART
      ENTER = 'ART1'
    end
  end
end
