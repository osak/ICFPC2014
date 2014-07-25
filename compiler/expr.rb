module GCC
  class Expression
    def initialize(name, args)
      @name = name.dup
      @args = args.dup
    end

    def to_s
      base = "(#{@name}"
      res = base.dup
      @args.each_with_index do |arg, i|
        res << " " + arg.to_s
      end
      res + ")"
    end
  end
end
