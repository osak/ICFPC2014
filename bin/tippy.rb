#!/usr/bin/env ruby

require 'optparse'

OptionParser.new do |opt|
end

lines = []
jmp_table = {}
$<.each_line do |line|
  line.chomp!
  line.gsub!(/;.*\z/, "")
  line.strip!
  next if line.match(/\A\s*\z/)
  if m = line.match(/\A(.*):\s*\z/)
    jmp_table[m[1]] = lines.size
  else
    lines << line
  end
end

lines.each do |line|
  line.gsub!(/@([a-zA-Z0-9_]+)/){
    jmp_table.fetch($1)
  }
end

puts lines.join("\n")
