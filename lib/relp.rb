require_relative 'relp/server'

module Relp
	server = Relp::RelpServer.new('0.0.0.0', 2000, 'syslog', nil )
	server.run
end
