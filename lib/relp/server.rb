require 'relp/relp_protocol'
require 'logger'
require 'thread'
require "openssl"

module Relp
  class RelpServer < RelpProtocol
    def initialize(port, callback, host = '0.0.0.0' , tls_context = nil, logger = nil)
      @logger = logger
      @logger = Logger.new(STDOUT) if logger.nil?
      @socket_list = Array.new
      @callback = callback
      @required_command = 'syslog'

      begin
        @server = TCPServer.new host, port
        if tls_context
          @logger.info "Starting #{self.class} with SSL enabled on %s:%i" % @server.local_address.ip_unpack
          @server = OpenSSL::SSL::SSLServer.new(@server, tls_context)
        else
          @logger.info "Starting #{self.class} on %s:%i" % @server.local_address.ip_unpack
        end
      rescue Errno::EADDRINUSE
        @logger.error  "ERROR Could not start relp server: Port #{port} in use"
        raise Errno::EADDRINUSE
      end
    end

    def run
      loop do
        client_socket = @server.accept
        Thread.start(client_socket) do |client_socket|
          begin
            @socket_list.push client_socket
            remote_ip = client_socket.peeraddr[3]
            @logger.info "New client connection coming from ip #{remote_ip}"
            @logger.debug "New client started with object id=#{client_socket.object_id}"
            connection_setup(client_socket)
            while Thread.current.alive? do
              ready = IO.select([client_socket], nil, nil, 10)
              if ready
                frame = communication_processing(client_socket)
                return_message(frame[:message], (@callback))
                ack_frame(client_socket,frame[:txnr])
              end
            end
          rescue Relp::ConnectionClosed
            @logger.info "Connection closed"
          rescue Relp::RelpProtocolError => err
            @logger.warn 'Relp error: ' + err.class.to_s + ' ' + err.message
          rescue OpenSSL::SSL::SSLError => ssl_error
            @logger.error "SSL Error", :exception => ssl_error
          rescue Exception => e
            @logger.debug e
          ensure
            server_close_message(client_socket) rescue nil
            @logger.debug "Closing client socket=#{client_socket.object_id}"
            @logger.info "Client from ip #{remote_ip} closed"
          end
        end
      end
    rescue Errno::EINVAL
      # Swallowing exception here because it results even from properly closed socket
      @logger.info "Socket close."
    end

    def return_message(message, callback)
      list_of_messages = message.split(/\n+/)
      list_of_messages.each do |msg|
        remove = msg.split(": ").first + ": "
        msg.slice! remove
        callback.call(msg)
      end
    end

    def ack_frame(socket, txnr)
      frame = {:txnr => txnr,
               :command => 'rsp',
               :message => "6 200 OK\n"
      }
      frame_write(socket, frame)
    end

    def server_close_message(socket)
      Hash.new frame = {:txnr => 0,
               :command => 'close',
               :message => '0'
      }
      begin
        frame_write(socket,frame)
        @logger.debug 'Server close message send'
        socket.close
        @socket_list.delete socket
      rescue Relp::ConnectionClosed
      end
    end

    def server_shutdown
      @socket_list.each do |client_socket|
        if client_socket != nil
	        server_close_message(client_socket)
	      end
      end
      @logger.info 'Server shutdown'
      @server.shutdown
      @server = nil
    end

    private
    def communication_processing(socket)
      @logger.debug 'Communication processing'
      frame = frame_read(socket)
      if frame[:command] == 'syslog'
        return frame
      elsif frame[:command] == 'close'
        response_frame = create_frame(frame[:txnr], "rsp", "0")
        frame_write(socket,response_frame)
        @logger.info 'Client send close message'
        server_close_message(socket)
        raise Relp::ConnectionClosed
      else
        server_close_message(socket)
        raise Relp::RelpProtocolError, 'Wrong relp command'
      end
    end

    def connection_setup(socket)
      @logger.debug 'Connection setup'
      begin
        read_ready = IO.select([socket], nil, nil, 10)
        if read_ready
          frame = frame_read(socket)
          @logger.debug 'Frame read complete, processing..'
          if frame[:command] == 'open'
            @logger.debug 'Client command open'
            message_informations = extract_message_information(frame[:message])
            if message_informations[:relp_version].empty?
              @logger.warn 'Missing RELP version specification'
              server_close_message(socket)
              raise Relp::RelpProtocolError
            elsif @required_command != message_informations[:commands]
              @logger.warn 'Missing required commands - syslog'
              Hash.new response_frame = create_frame(frame[:txnr], 'rsp', '20 500 Missing required command ' + @required_command)
              frame_write(socket, response_frame)
              server_close_message(socket)
              raise Relp::InvalidCommand, 'Missing required command'
            else
              Hash.new response_frame = create_frame(frame[:txnr], 'rsp', '93 200 OK' + "\n" + 'relp_version=' +@@relp_version + "\n" + 'relp_software=' + @@relp_software + "\n" + 'commands=' + @required_command + "\n")
              @logger.debug 'Sending response to client'
              frame_write(socket, response_frame)
            end
          else
            server_close_message(socket)
            raise Relp::InvalidCommand, frame[:command] + ' expecting open command'
          end
        end
      rescue Relp::RelpProtocolError
        @logger.debug 'Timed out (no frame to read)'
        server_close_message(socket)
      end
    end
  end
end
