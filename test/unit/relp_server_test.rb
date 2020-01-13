require 'test_helper'
require 'logger'

CONNECT_STRING = "relp_version=0\nrelp_software=librelp,1.4.0,http://librelp.adiscon.com\ncommands=syslog"
CONNECT_RESPONSE = "200 OK\nrelp_version=0\nrelp_software=ruby-relp,1.0.0,https://github.com/ViaQ/Relp\ncommands=syslog"

class TestRelpSession < MiniTest::Test
  def setup
    @logger = Logger.new STDERR
    @logger.level = Logger::DEBUG
    @callback = Minitest::Mock.new
    @server = Relp::RelpServer.new(1234, @callback, logger: @logger)
    @server_thread = Thread.new { @server.run }
    @client = Client.new 1234, @logger
  end

  def teardown
    @callback.verify
    @client.send_data('0 close 0')
    @client.socket.close
    @server.server_shutdown
    @server_thread.join
  end

  def connect
    @msg_number = 1
    @client.send_data("#{@msg_number} open #{CONNECT_STRING.length} #{CONNECT_STRING}")
    data = @client.recv_data
    assert_equal("#{@msg_number} rsp #{CONNECT_RESPONSE.length} #{CONNECT_RESPONSE}", data)
  end

  def syslog(msg)
    @msg_number += 1
    @client.send_data("#{@msg_number} syslog #{msg.length} #{msg}")
    resp = @client.recv_data
    assert_equal("#{@msg_number} rsp 6 200 OK", resp)
  end

  def test_connect
    connect
  end

  def test_send
    connect
    @callback.expect(:call, nil, [ "test", "127.0.0.1" ])
    syslog("test")
  end

  def test_multi_send
    connect
    @callback.expect(:call, nil, [ "test", "127.0.0.1" ])
    @callback.expect(:call, nil, [ "foo", "127.0.0.1" ])
    @callback.expect(:call, nil, [ "bar", "127.0.0.1" ])
    syslog("test")
    syslog("foo")
    syslog("bar")
  end

end
