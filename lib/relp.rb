 require 'lib/relp/server'
# require 'relp/relp_protocol.rb'
# require '../lib/relp/exceptions.rb'
require 'logger'



module Relp

  port = 5000
  @relp_server = RelpServer.new( port)

end



# pozriet sa na nadvezovanie a ukoncovanie komunikacie v relp protokole
