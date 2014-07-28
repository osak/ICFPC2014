#!/usr/bin/env ruby

require 'optparse'
require_relative '../rize/instruction.rb'
require_relative '../rize/secd.rb'

OptionParser.new do |opt|
end

insts = []
src = ARGV.size > 0 ? File.open(ARGV[0]) : STDIN
src.each_line do |line|
  line.gsub!(/;.*$/, '')
  line.strip!
  next if line == ""

  mnemonic, *args = line.split
  mnemonic = mnemonic.downcase.to_sym
  args.map!(&:to_i) if args
  insts << Rize::Instruction.new(mnemonic, *args)
end

puts "Load #{insts.size} instructions."

machine = Rize::SECDMachine.new
machine.load(insts)
loop do
  ret = machine.execute!
  if ret == :stop
    puts "Successfully stopped."
    break
  elsif ret == :error
    break
  else
    raise "Break."
  end
end

puts "Contents of machine stack:"
machine.value_stack.reverse_each do |val|
  puts val
end
