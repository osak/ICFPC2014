module Rize
  class Control
    attr_reader :type, :pc
    def initialize(type, pc)
      @type = type
      @pc = pc
    end

    def to_s
      "<#{type}, #{pc}>"
    end
  end
end

