#!/usr/bin/env ruby

require 'optparse'
require 'pp'
require_relative '../compiler/parser.rb'
require_relative '../compiler/compiler.rb'

def parse(src)
  parser = GCC::Parser.new(src)
  compiler = GCC::Compiler.new
  ast = parser.parse
  ast.each{|a| compiler.register(a)}

  puts compiler.to_gcc.join("\n")
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

