module GCC
  class Expression
    attr_reader :args, :line_no

    def initialize(args, line_no)
      @args = args.dup
      @line_no = line_no
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
