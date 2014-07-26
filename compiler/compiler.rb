require_relative 'environment'

module GCC
  class Compiler
    def initialize
      @subroutines = []
      @lambda_env = {}
      @env = nil
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
      when Symbol
        compile_variable(obj)
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

          if spec = current_env.get(expr.args[0])
            # User defined function
            # TODO: check is it really function
            code << "LD #{spec[:frame]} #{spec[:index]}"
            code << "AP #{expr.args.size - 1}"
          else
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
        binds, body = expr.args[1..-1]
        new_env do
          binds.args.each_with_index do |bind, i|
            raise "Symbol is expected for let binding" unless bind.args[0].is_a?(Symbol)
            code.push(*compile(bind.args[1]))
            current_env.put(bind.args[0], i)
          end
          b = compile_subroutine(body, "RTN")
          code << "DUM #{binds.args.size}"
          code << "LDF #{b}"
          code << "RAP #{binds.args.size}"
        end
      when :lambda
        # specialized form
        # first tuple is (args...)
        args, body = expr.args[1..-1]
        new_env do
          args.args.each_with_index do |name, i|
            current_env.put(name, i)
          end
          b = compile_subroutine(body, "RTN")
          @lambda_env[b] = current_env
          code << "LDF #{b}"
        end
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

    def compile_variable(name)
      spec = current_env.get(name)
      ["LD #{spec[:frame]} #{spec[:index]}"]
    end

    def current_env
      @env
    end

    def new_env
      prev_env = @env
      @env = Environment.new(@env)
      yield
      @env = prev_env
    end
  end
end
