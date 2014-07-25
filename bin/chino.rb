#!/usr/bin/env ruby

require 'optparse'
require_relative '../compiler/parser.rb'

OptionParser.new do |opt|
end

parser = GCC::Parser.new(File.open(ARGV[0]))
expr = parser.parse
puts expr
