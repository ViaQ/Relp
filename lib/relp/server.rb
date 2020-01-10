require 'relp/relp_session'
require 'logger'
require 'thread'
require 'openssl'

module Relp
  class RelpServer
    def initialize(port, callback, host = '0.0.0.0' , tls_context = nil, logger = nil)
      @logger = logger
      @logger = Logger.new(STDOUT) if logger.nil?
      @socket_list = Array.new
      @callback = callback

      begin
        @server = TCPServer.new host, port
        if tls_context
          @logger.info "Starting #{self.class} with SSL enabled on %s:%i" % @server.local_address.ip_unpack
          @server = OpenSSL::SSL::SSLServer.new(@server, tls_context)
          @server.start_immediately = true
        else
          @logger.info "Starting #{self.class} on %s:%i" % @server.local_address.ip_unpack
        end
      rescue Errno::EADDRINUSE
        @logger.error  "ERROR Could not start relp server: Port #{port} in use"
        raise Errno::EADDRINUSE
      end
    end

    def run
      begin
        loop do
          client_socket = @server.accept
          Thread.start(client_socket) do |client_socket|
            begin
              @socket_list.push client_socket
              remote_ip = client_socket.peeraddr[3]
              @logger.info "New client connection coming from ip #{remote_ip}"
              RelpSession.new(client_socket, @callback, @logger)
            ensure
              @socket_list.delete client_socket
              @logger.info "Connection from ip #{remote_ip} closed"
            end
          end
        end
      rescue OpenSSL::SSL::SSLError => ssl_error
        # Certificate issues are thrown on accept
        @logger.error "SSL Connection Error", :exception => ssl_error
        retry
      rescue Errno::EINVAL
        # When @server.shutdown is called
      rescue StandardError => err
        @logger.error 'unexpected error', :exception => err
        @logger.error_backtrace
      end
    end

    def server_shutdown
      @socket_list.each do |client_socket|
        client_socket.close() if client_socket != nil
      end
      @logger.info 'Relp server shutdown'
      @server.shutdown
      @server = nil
    end

    private

  end
end
