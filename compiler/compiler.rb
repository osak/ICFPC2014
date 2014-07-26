module GCC
  class Compiler
    def initialize
      @subroutines = []
    end

    def register(obj)
      holder = []
      @subroutines << holder
      holder.push(*compile(obj))
      holder << "RTN"
    end

    def to_gcc
      tbl = []
      index = 0
      ops = []
      @subroutines.compact.each do |sr|
        ops.push(*sr)
        tbl << index
        index += sr.size
      end
      ops.each do |op|
        op.gsub!(/#{PLACEHOLDER_PREFIX}(\d+)/){
          tbl[$1.to_i]
        }
      end
      ops
    end

    private

    ADDRESSING_FUNCTIONS =[
      :if, :let, :lambda
    ].freeze
    PLACEHOLDER_PREFIX = "__"

    def compile(obj)
      case obj
      when Expression
        compile_expression(obj)
      when Numeric
        compile_numeric(obj)
      end
    end

    def compile_expression(expr)
      code = []
      if expr.args[0].is_a?(Symbol)
        if ADDRESSING_FUNCTIONS.index(expr.args[0])
          code.push(*compile_addressing_function(expr))
        else
          expr.args[1..-1].each do |arg|
            code.push(*compile(arg))
          end

          case expr.args[0]
          when :+
            code << "ADD"
          when :-
            code << "SUB"
          when :*
            code << "MUL"
          when :/
            code << "DIV"
          when :cons
            code << "CONS"
          when :car
            code << "CAR"
          when :cdr
            code << "CDR"
          when :==
            code << "CEQ"
          when :<
            code << "CGT"
          when :<=
            code << "CGTE"
          when :atom?
            code << "ATOM"
          end
        end
        code
      else
        raise "unsupported"
      end
    end

    def compile_addressing_function(expr)
      code = []
      case expr.args[0]
      when :if
        code.push(*compile(expr.args[1]))
        t = compile_subroutine(expr.args[2], "JOIN")
        f = compile_subroutine(expr.args[3], "JOIN")
        code << "SEL #{t} #{f}"
      when :let
        # specialized form
        # first tuple is bind list
        binds, body = expr.args
      end
      code
    end

    def compile_subroutine(expr, *post_op)
      @subroutines << compile(expr)
      @subroutines.last.push(*post_op)
      "#{PLACEHOLDER_PREFIX}#{@subroutines.size-1}"
    end

    def compile_numeric(num)
      ["LDC #{num}"]
    end
  end
end
