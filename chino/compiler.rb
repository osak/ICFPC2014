require_relative 'environment'
require_relative 'compiler_exception'

module Chino
  class Compiler
    def initialize
      @subroutines = {}
      @toplevel_func = {}
      @roots = []
      @env = nil
    end

    def register(obj)
      insts = compile(obj)
      if insts.size > 0
        insts << "RTN"
        @roots << add_subroutine(insts)
      end
    end

    def to_gcc
      tbl = {}
      index = 0
      ops = []
      (@roots + @subroutines.keys).uniq.each do |key|
        sr = @subroutines[key]
        ops.push(*sr)
        tbl[key] = index
        index += sr.size
      end
      ops.each do |op|
        op.gsub!(/(#{PLACEHOLDER_PREFIX}[0-9a-f]+)/){
          tbl[$1]
        }
      end
      ops
    end

    private

    ADDRESSING_FUNCTIONS =[
      :if, :let, :lambda, :main, :define
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
        elsif expr.args[0] == :set!
          code.push(*compile_set(expr))
        elsif expr.args[0] == :begin
          code.push(*compile_begin(expr))
        else
          expr.args[1..-1].each do |arg|
            code.push(*compile(arg))
          end

          if current_env && spec = current_env.get(expr.args[0])
            # User defined lambda
            # TODO: check is it really function
            code << "LD #{spec[:frame]} #{spec[:index]}"
            code << "AP #{expr.args.size - 1}"
          elsif tag = @toplevel_func.fetch(expr.args[0], nil)
            # User defined top-level function
            code << "LDF #{tag}"
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
            when :"="
              code << "CEQ"
            when :>
              code << "CGT"
            when :>=
              code << "CGTE"
            when :atom?
              code << "ATOM"
            when :break
              code << "BRK\t;@line #{expr.line_no} #{expr}"
            when :void
              code << "DBUG"
            else
              error("Unsupported function #{expr.args[0]}", expr)
            end
          end
        end
        code
      else
        error("Using non-symbol as a function is not supported", expr)
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
          code << "DUM #{binds.args.size}"
          binds.args.each_with_index do |bind, i|
            error("Symbol is expected for let binding", expr) unless bind.args[0].is_a?(Symbol)
            current_env.put(bind.args[0], i)
            code.push(*compile(bind.args[1]))
          end
          b = compile_subroutine(body, "RTN")
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
          @subroutines[b][0] += "\t;lambda @#{expr.line_no}"
          code << "LDF #{b}\t;load lambda @#{expr.line_no}"
        end
      when :main
        args = expr.args[1]
        new_env do
          current_env.put(args.args[0], 0)
          current_env.put(args.args[1], 1)
          code.push(*compile(expr.args[2]))
        end
      when :define
        if !expr.args[1].is_a?(Expression)
          error("Second argument of define must be a tuple", expr)
        end
        args, body = expr.args[1..-1]
        f = args.args[0]
        @toplevel_func[f] = subroutine_placeholder
        new_env do
          args.args[1..-1].each_with_index do |name, i|
            current_env.put(name, i)
          end
          insts = compile(body)
          insts << "RTN"
          insts[0] += "\t; function #{args.args[0]}"
          update_subroutine(@toplevel_func[f], insts)
        end
      end
      code
    end

    def compile_subroutine(expr, *post_op)
      insts = compile(expr)
      insts.push(*post_op)
      add_subroutine(insts)
    end

    def compile_numeric(num)
      ["LDC #{num}"]
    end

    def compile_variable(name)
      if current_env && spec = current_env.get(name)
        ["LD #{spec[:frame]} #{spec[:index]}"]
      elsif addr = @toplevel_func[name]
        ["LDF #{addr}"]
      else
        error("Unbound name '#{name}'", nil)
      end
    end

    def compile_set(expr)
      name = expr.args[1]
      code = compile(expr.args[2])
      if current_env && spec = current_env.get(name)
        code << "ST #{spec[:frame]} #{spec[:index]}"
      else
        error("Unbound name '#{name}'", expr)
      end
      code
    end

    def compile_begin(expr)
      code = []
      expr.args[1..-1].each do |sub|
        code.push(*compile(sub))
      end
      code
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

    def add_subroutine(insts)
      tag = PLACEHOLDER_PREFIX + @subroutines.size.to_s
      @subroutines[tag] = insts
      tag
    end

    def subroutine_placeholder
      add_subroutine([])
    end

    def update_subroutine(tag, insts)
      @subroutines[tag] = insts
    end

    def error(message, context)
      raise CompilerException.new(message, context)
    end
  end
end
