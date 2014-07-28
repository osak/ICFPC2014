module Rize
  class CallFrame
    attr_reader :frame, :pc
    attr_accessor :type
    def initialize(type, frame, pc)
      @type = type
      @frame = frame
      @pc = pc
    end

    def to_s
      "<#{type}, #{frame}, #{pc}>"
    end
  end
end
