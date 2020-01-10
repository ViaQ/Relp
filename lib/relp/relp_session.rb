require 'relp/relp_protocol'
require 'logger'
require 'thread'

module Relp
  class RelpSession < RelpProtocol
    def initialize(socket, callback, logger = nil)
      @logger = logger
      @logger = Logger.new(STDOUT) if logger.nil?
      @socket = socket
      @remote_ip = socket.peeraddr[3]
      @callback = callback

      begin
        connection_setup()
        process()
        close()
      rescue Relp::ConnectionClosed
        @logger.warn "Relp unexpected Connection closed"
      rescue Relp::FrameParseException => err
        # We can't respond to a bad frame because we do not know its :txnr
        @logger.warn 'Relp frame parse error', :exception => err
      rescue Relp::RelpProtocolError => err
        @logger.warn 'Relp protocol error', :exception => err
      rescue OpenSSL::SSL::SSLError => ssl_error
        @logger.warn "Relp SSL Error", :exception => ssl_error
      end
    end

    private
    def read_socket()
      begin
        # Assume that the client is well behaved and only sends one message before
        # waiting for a reply.  A streaming client would require parsing of the stream
        # in order as the end of frame marker \n can also be part of the frame.
        data = @socket.readpartial(4096)
        data.chomp!
        @logger.debug "Relp #{@remote_ip} read: #{data.dump}"
        return data
      rescue Errno::EPIPE,Errno::ECONNRESET,EOFError
        @logger.debug "Relp #{@remote_ip} read: connection reset"
        raise Relp::ConnectionClosed
      rescue StandardException => err
        @logger.debug "Relp #{@remote_ip} read: ", :exception => err
        retry
      end
    end

    def write_socket(data)
      begin
        @logger.debug "Relp #{@remote_ip} write: #{data.dump}"
        @socket.puts(data)
      rescue Errno::EPIPE,Errno::ECONNRESET,EOFError
        @logger.debug "Relp #{@remote_ip} write: connection reset"
        raise Relp::ConnectionClosed
      rescue StandardException => err
        @logger.debug "Relp #{@remote_ip} write: ", :exception => err
        retry
      end
    end

    def connection_setup()
      begin
        socket_content = read_socket()
        frame = frame_parse(socket_content)
        if frame[:command] != 'open'
          raise Relp::RelpProtocolError.new("Relp #{@remote_ip} expected open, got #{frame[:command].dump}")
        end
        validate_offer(frame[:message])
        write_socket(ack_offer_frame(frame))
        @logger.info "Relp #{@remote_ip} connection negotiated"
      rescue Relp::InvalidOffer => err
        @logger.error "Relp #{@remote_ip} invalid connection offer", :exception => err
        write_socket(nack_frame(frame, err.message))
        retry
      end
    end

    def process()
      while Thread.current.alive? do
        socket_content = read_socket()
        frame = frame_parse(socket_content)
        case frame[:command]
        when 'syslog'
          @logger.info "Relp #{@remote_ip} message: '#{frame[:message].dump}'"
          @callback.call(frame[:message], @remote_ip)
          write_socket(ack_frame(frame))
        when 'close'
          write_socket(ack_frame(frame))
          return
        else
          @logger.warn "Relp #{@remote_ip} unknown command #{frame[:command].dump}"
          write_socket(nack_frame(frame, 'Unknown command'))
        end
      end
    end

    def close()
      # socket might already be closed
      begin
        write_socket('0 close 0')
      rescue StandardException
      end
    end

  end
end
