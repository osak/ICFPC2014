module GCC
  class Expression
    attr_reader :args

    def initialize(args)
      @args = args.dup
    end

    def to_s
      base = "("
      res = nil
      @args.each_with_index do |arg, i|
        if i == 0
          base << arg.to_s
          res = base.dup
        else
          res << " " + arg.to_s
        end
      end
      res + ")"
    end

    def each_arg(&blk)
      @args.each(&blk)
    end
  end
end
