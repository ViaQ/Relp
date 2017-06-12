require 'relp/server'
# require 'relp/relp_protocol.rb'
# require '../lib/relp/exceptions.rb'
require 'logger'



module Relp

	server = Relp::RelpServer.new('0.0.0.0', 2000, 'syslog')
	server.run

end



# pozriet sa na nadvezovanie a ukoncovanie komunikacie v relp protokole
