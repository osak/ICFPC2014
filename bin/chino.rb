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
prog = ast.map{|a| compiler.compile(a)}.compact

pp prog
