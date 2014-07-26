module GCC
  class Expression
    attr_reader :name
    def initialize(name, args)
      @name = name.to_sym
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

    def each_arg(&blk)
      @args.each(&blk)
    end
  end
end
