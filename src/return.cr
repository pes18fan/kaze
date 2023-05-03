module Kaze
  class Return < Exception
    property value

    def initialize(@value : VG)
    end
  end
end