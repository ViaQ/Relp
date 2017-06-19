require 'relp/relp_protocol'
require 'logger'
require 'thread'

module Relp
  class RelpServer < RelpProtocol

    def initialize(host, port, logger = nil, callback)
      @logger = logger
      @logger = Logger.new(STDOUT) if logger.nil?
      @socket_list = Array.new
      #@logger.level = Logger::INFO #TODO find how to set log level
      @callback = callback
      @required_command = 'syslog'

      begin
        @server = TCPServer.new(host, port)
        @logger.info "Starting #{self.class} on %s:%i" % @server.local_address.ip_unpack
      rescue Errno::EADDRINUSE
        @logger.error  "ERROR Could not start relp server: Port #{port} in use" #add port number
        raise Errno::EADDRINUSE
      end
    end

    def run
      loop do
        Thread.start(@server.accept) do |client_socket|
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
            @logger.error "Connection closed"
          rescue Relp::RelpProtocolError => err
            @logger.warn 'Relp error: ' + err.class.to_s + ' ' + err.message
          ensure
            server_close_message(client_socket) rescue nil
            @logger.debug "Closing client socket=#{client_socket.object_id}"
            @logger.info "Client from ip #{remote_ip} closed"
          end
        end

      end
    end

    def return_message(message, callback)
      list_of_messages = message.split(/\n+/)
      list_of_messages.each do |msg|
        remove = msg.split(": ").first + ": "
        msg.slice! remove
        callback.call(msg)
      end
    end

    def create_frame( txnr, command, message)
      frame = {:txnr => txnr,
               :command => command,
               :message => message
      }
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
               :command => 'serverclose',
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

    def server_shut_down
      @socket_list.each do |client|
        server_close_message(client)
      end
      @logger.info 'Server shutdown'
      @server.shutdown
      @server = nil
    end

    private

    def communication_processing(socket)
      @logger.debug 'Communication processing'
      frame = frame_read(socket)
	if frame == nil
	  return nil
	end
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
