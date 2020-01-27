# Encoding: binary
# frozen_string_literal: true

module Rbuspirate
  module Commands
    RESET_BITBANG = 0b00000000
    CONF_PER = 0b01000000

    module Config
      module Peripherals
        POWER = 0b00001000
        PULLUP = 0b00000100
        AUX = 0b00000010
        CS = 0b00000001
      end
    end

    module I2C
      ENTER = 0b00000010
      PREPARE_WRITE = 0b00010000
      READBYTE = 0b00000100
      WRITE_THEN_READ = 0x8

      module Config
        module Speed
          S5KHZ = 0b01100000
          S50KHZ = 0b01100001
          S100KHZ = 0b01100010
          S400KHZ = 0b01100011
        end
      end

      module Flow
        START = 0b00000010
        STOP = 0b00000011
        ACK = 0b00000110
        NACK = 0b00000111
      end
    end

    module UART
      ENTER = 0b00000011
      START_BRIDGE = 0b00001111

      module Config
        CONF_UART = 0b10000000

        module Speed
          S300 = 0b01100000
          S1200 = 0b01100001
          S2400 = 0b01100010
          S4800 = 0b01100011
          S9600 = 0b01100100
          S19200 = 0b01100101
          S31250 = 0b01100110
          S38400 = 0b01100111
          S57600 = 0b01101000
          S115200 = 0b01101010
        end

        module UartConf
          PIN_OUT_33 = 0b00010000
          DAT_PARITY_8E = 0b00000100
          DAT_PARITY_80 = 0b00001000
          DAT_PARITY_9N = 0b00001100
          STOP_BIT_2 = 0b00000010
          DISABLE_RX_IDLE = 0b00000001
        end
      end
    end
  end
end
