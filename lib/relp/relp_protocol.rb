require 'relp/exceptions'
require 'relp/version'

module Relp
  class RelpProtocol
    @@relp_version = '0'.freeze
    @@relp_software = "ruby-relp,#{VERSION},https://github.com/ViaQ/Relp".freeze
    @@required_commands = 'syslog'.freeze

    def frame_parse(content)
      frame = Hash.new
      if match = content.match(/\A([0-9]+) ([\S]*) (\d+)(?: ?)([\s\S]*)\z/)
        frame[:txnr], frame[:command], frame[:data_length], frame[:message] = match.captures
      else
        raise Relp::FrameParseException.new("Invalid RELP frame: #{content}")
      end
      if frame[:message].length != frame[:data_length].to_i
        raise Relp::FrameParseException.new("Got #{frame[:message].length} bytes of data, expected #{frame[:data_length]}")
      end
      frame
    end

    def ack_frame(frame)
      # librelp violates the spec and requires a space after 200
      return frame[:txnr] + ' rsp 6 200 OK'
    end

    def ack_offer_frame(frame)
      data = {
        'relp_version' => @@relp_version,
        'relp_software'=> @@relp_software,
        'commands' => @@required_commands
      }
      # librelp violates the spec and requires a space after 200
      message = "200 OK"
      data.each do |key, value|
        message += "\n#{key}=#{value}"
      end
      frame_encode(frame[:txnr], 'rsp', message)
    end

    def nack_frame(frame, error_message)
      frame_encode(frame[:txnr], 'rsp', '500 ' + error_message)
    end

    def validate_offer(message)
      # Parse information from an offer message and crate new hash (symbol => value) e.g. (:version => 0)
      offer_data = Hash[message.scan(/^(.*)=(.*)$/).map { |(key, value)| [key.to_sym, value] }]
      if offer_data[:relp_version].empty?
        raise Relp::InvalidOffer.new('Missing RELP version')
      elsif offer_data[:relp_version] != '0'
        raise Relp::InvalidOffer.new('Incompatible RELP version')
      elsif offer_data[:commands] != @@required_commands
        raise Relp::InvalidOffer.new("Missing required commands #{@@required_commands}")
      end
    end

    private
    def frame_encode(txnr, command, message)
      data = [
        txnr,
        command,
        message.length
      ].join(' ')
      data += ' ' + message if message.length >= 0
    end

  end
end
