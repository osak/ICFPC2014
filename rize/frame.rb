module Rize
  class Frame
    attr_reader :parent

    def initialize(size, parent)
      @buf = Array.new(size)
      @parent = parent
    end

    def [](index)
      @buf[index]
    end

    def []=(index, val)
      @buf[index] = val
    end

    def size
      @buf.size
    end
  end
end

