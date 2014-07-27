#!/usr/bin/env ruby

require 'optparse'

OptionParser.new do |opt|
end

constants = {}
lines = []
jmp_table = {}
$<.each_line do |line|
  line.chomp!
  line.gsub!(/;.*\z/, "")
  line.strip!
  next if line.match(/\A\s*\z/)
  case line
  when /\A(.*):\s*\z/
    jmp_table[$1] = lines.size
  when /\A\.const\s+([a-zA-Z0-9_]+)\s+([0-9]+)/
    constants[$1] = $2.to_i
  else
    lines << line
  end
end

lines.each do |line|
  line.gsub!(/@([a-zA-Z0-9_]+)/){
    jmp_table.fetch($1)
  }
  line.gsub!(/\$([a-zA-Z0-9_]+)/){
    constants.fetch($1)
  }
end

puts lines.join("\n")
