require 'stringio'
require_relative 'expr'

module GCC
  class Parser
    def initialize(src)
      case src
      when String
        @src = StringIO.new(src)
      when lambda{|o| o.respond_to?(:getc)}
        @src = src
      else
        raise "src should be String or IO-like"
      end
      @cur = @src.getc
    end

    def parse
      res = []
      until eof?
        res << expr
      end
      res.reject{|r| r == :""}
    end

    private

    def expr
      skip_space
      if peek == "("
        should_read "("
        skip_space
        args = []
        until peek == ")"
          args << expr
          skip_space
        end
        should_read ")"
        skip_space
        Expression.new(args)
      else
        val = token
        case val
        when /\A-?\d+\z/
          val.to_i
        else
          val.to_sym
        end
      end
    end

    def skip_space
      while !eof? && peek.match(/\s/)
        read_next
      end
    end

    def read_next
      @cur = if @src.eof?
               nil
             else
               @src.getc
             end
    end

    def peek
      @cur
    end

    def token
      res = ""
      while !eof? && !peek.match(/\s|\)/)
        res << peek
        read_next
      end
      res
    end

    def should_read(ch)
      raise "Found #{peek} where #{ch} is expected" if peek != ch
      read_next
    end

    def eof?
      @src.eof? && @cur.nil?
    end
  end
end
