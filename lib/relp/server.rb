require_relative 'relp_protocol'
require 'logger'
require 'thread'
require 'pry-byebug'

module Relp
  class RelpServer < RelpProtocol

    def initialize(host, port, required_commands=[])
      @logger = Logger.new(STDOUT)

      @required_command = required_commands

      begin
        @server = TCPServer.new(host, port)
        @logger.info "Starting #{self.class} on %s:%i" % @server.local_address.ip_unpack
      rescue Errno::EADDRINUSE
        @logger.error  "ERROR Could not start relp server: Port #{port} in use" #add port number
        raise
      end
    end

    def run
      loop do
        Thread.start(@server.accept) do |client_socket| #pridat zachytavanie vynimiek
          begin
            remote_ip = client_socket.peeraddr[3]
            @logger.info "New client connection coming from ip #{remote_ip}"
            @logger.debug "New client started with object id=#{client_socket.object_id}"
            connection_setup(client_socket)
	    loop do
                frame = communication_processing(client_socket)
		if frame != nil
                  return_message(frame[:message]) #there is message- callback to return method
                  ack_frame(client_socket,frame[:txnr])
		end
	    end
          rescue Relp::ConnectionClosed
            @logger.debug("Connection to #{remote_ip} Closed")
          ensure
            client.close rescue nil
	    @logger.debug "Client closed"
          end
        end

      end
    end

    def return_message(message) #TODO add callback 
      puts(message)
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
               :command => 'serverclose'
      }
      begin
        @logger.info "Closing client socket=#{socket.object_id}"
        frame_write(socket,frame)
        socket.close
      rescue Relp::ConnectionClosed
      end
    end

    def communication_processing(socket)
      @logger.debug 'Communication processing'
      frame = frame_read(socket)
	if frame == nil
	  return nil
	end
      if frame[:command] == 'syslog'
        return frame
      elsif frame[:command] == 'close'
        response_frame = create_frame(frame[:txnr], "rsp", "")
        frame_write(socket,response_frame)
        server_close_message(socket)
        raise Relp::ConnectionClosed
      else
        server_close_message(socket)
        raise Relp::RelpProtocolError, 'Wrong relp command'
      end
    end
  #

    def connection_setup(socket)
      @logger.debug 'Connection setup'
      begin
        frame = frame_read(socket)
        @logger.debug 'Frame read complete, processing..'
        if frame[:command] == 'open'
          @logger.debug 'Client command open'
          message_informations = extract_mesage_information(frame[:message])
          if message_informations[:relp_version].empty?
            @logger.warn'Missing RELP version specification'
            self.server_close_message(socket)
            raise Relp::RelpProtocolError
          elsif @required_command != message_informations[:commands]
            @logger.warn'Missing required commands - syslog'
            server_close_message(socket)
            Hash.new response_frame = create_frame(frame[:txnr], 'rsp', '500 Missing required command ' + @required_command)
            frame_write(socket, response_frame)
            raise Relp::InvalidCommand, 'Missing required command'
          else
            Hash.new response_frame = create_frame(
	    frame[:txnr], 'rsp', '93 200 OK' + "\n" + 'relp_version=' +@@relp_version + "\n" + 'relp_software=' + @@relp_software + "\n" + 'commands=' + @required_command + "\n")
            @logger.info "Sending response to client"
            #binding.pry
            frame_write(socket, response_frame)

          end
        else
          server_close_message(socket)
          raise Relp::InvalidCommand, frame[:command] + ' expecting open command'
        end
      rescue Relp::RelpProtocolError
        @logger.debug 'timed out (no frame)'
        server_close_message(socket)
      end
    end

    def close_server
      @server.close
    end

    def server_shut_down
      if @server
        @server.shutdown
        @server = nil
      end
    end
  end
end

server = Relp::RelpServer.new('0.0.0.0', 5140, 'syslog')
server.run
