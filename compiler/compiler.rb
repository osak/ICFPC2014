module GCC
  class Compiler
    def initialize
    end

    def compile(obj)
      case obj
      when Expression
        compile_expression(obj)
      when Numeric
        compile_numeric(obj)
      end
    end

    private

    def compile_expression(expr)
      code = []
      expr.each_arg do |arg|
        code.push(*compile(arg))
      end

      case expr.name
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
      end

      code
    end

    def compile_numeric(num)
      ["LDC #{num}"]
    end
  end
end
