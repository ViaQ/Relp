require 'socket'

class Client
  attr_reader :socket

  def initialize(port, logger)
    @logger = logger
    @socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
    @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
    @socket.connect Socket.pack_sockaddr_in(port, '127.0.0.1')
  end

  def send_data(data)
    @logger.debug("Client sending #{data.dump}")
    @socket.puts data
  end

  def recv_data
    @logger.debug("Client waiting for message")
    data = @socket.readpartial(4096)
    @logger.debug("Client received #{data.dump}")
    data.chomp
  end

end
