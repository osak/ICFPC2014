module Rize
  class Closure
    attr_reader :pc, :frame
    def initialize(pc, frame)
      @pc = pc
      @frame = @frame
    end

    def to_s
      "Closure(#{pc}, #{frame})"
    end
  end
end

