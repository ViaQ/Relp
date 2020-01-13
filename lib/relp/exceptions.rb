module Relp
  class RelpProtocolError < StandardError
  end

  class ConnectionClosed < RelpProtocolError
  end

  class FrameParseException < RelpProtocolError
  end

  class InvalidOffer < RelpProtocolError
  end
end
