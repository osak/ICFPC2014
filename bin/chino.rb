#!/usr/bin/env ruby

require 'optparse'
require 'pp'
require_relative '../compiler/parser.rb'
require_relative '../compiler/compiler.rb'

OptionParser.new do |opt|
end

parser = GCC::Parser.new(File.open(ARGV[0]))
compiler = GCC::Compiler.new
ast = parser.parse
ast.each{|a| compiler.register(a)}

puts compiler.to_gcc.join("\n")
