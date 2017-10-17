module Relp
  class RelpProtocolError < StandardError
  end

  class ConnectionClosed < RelpProtocolError
  end

  class ConnectionRefused < RelpProtocolError
  end

  class FrameReadException < RelpProtocolError
  end

  class InvalidCommand < RelpProtocolError
  end

  class MissingData < RelpProtocolError
  end
end
