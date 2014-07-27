#!/usr/bin/env ruby

require 'optparse'
require 'pp'
require_relative '../compiler/parser.rb'
require_relative '../compiler/compiler.rb'
require_relative '../compiler/compiler_exception.rb'

def parse(src)
  begin
    parser = GCC::Parser.new(src)
    compiler = GCC::Compiler.new
    ast = parser.parse
    ast.each{|a| compiler.register(a)}

    puts compiler.to_gcc.join("\n")
  rescue GCC::CompilerException => e
    STDERR.puts "#{e}"
    if e.context
      STDERR.puts "  context: #{e.context} at line #{e.context.line_no}"
    end
  end
end

OptionParser.new do |opt|
end

if ARGV.size == 0
  loop do
    print "> "
    STDOUT.flush
    parse(gets.chomp)
  end
else
  parse(File.open(ARGV[0]))
end

