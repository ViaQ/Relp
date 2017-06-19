require 'relp/exceptions'
require 'socket'
module Relp

  class RelpProtocol
    @@relp_version = '0'
    @@relp_software = 'librelp,1.2.13,http://librelp.adiscon.com'

    def frame_write(socket, frame)
      raw_data=[
          frame[:txnr],
          frame[:command],
          frame[:message]
      ].join(' ')
      @logger.debug "Writing Frame #{frame.inspect}"
      begin
        socket.write(raw_data)
      rescue Errno::EPIPE,IOError,Errno::ECONNRESET
        raise Relp::ConnectionClosed
      end
    end

    def frame_read(socket)
      begin
        socket_content = socket.read_nonblock(4096)
        frame = Hash.new
        if match = socket_content.match(/(^[0-9]+) ([\S]*) (\d+)([\s\S]*)/)
          frame[:txnr], frame[:command], frame[:data_length], frame[:message] = match.captures
          frame[:message].lstrip! #message could be empty
        else
          raise raise Relp::FrameReadException.new('Problem with reading RELP frame')
        end
        @logger.debug "Reading Frame #{frame.inspect}"
      rescue IOError
        @logger.error 'Problem with reading RELP frame'
        raise Relp::FrameReadException.new 'Problem with reading RELP frame'
      rescue Errno::ECONNRESET
        @logger.error 'Connection reset'
        raise Relp::ConnectionClosed.new 'Connection closed'
      end
      is_valid_command(frame[:command])

      return frame
    end

    def is_valid_command(command)
      valid_commands = ["open", "close", "rsp", "syslog"]
      if !valid_commands.include?(command)
        @logger.error 'Invalid RELP command'
        raise Relp::InvalidCommand.new('Invalid command')
      end
    end

    def extract_message_information(message)
      informations = Hash[message.scan(/^(.*)=(.*)$/).map { |(key, value)| [key.to_sym, value] }]
    end
  end
end
