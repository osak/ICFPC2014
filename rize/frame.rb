module Rize
  class Frame
    attr_reader :type, :parent

    def initialize(size, parent, type = :normal)
      @buf = Array.new(size)
      @parent = parent
      @type = type
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

