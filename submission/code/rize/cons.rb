module Rize
  class Cons
    attr_reader :car, :cdr
    def initialize(car, cdr)
      @car = car
      @cdr = cdr
    end

    def to_s
      "(#{car}, #{cdr})"
    end
  end
end

