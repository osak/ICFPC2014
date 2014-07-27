#!/usr/bin/env ruby

require 'optparse'

def error(msg, line_no)
  STDERR.puts("Line #{line_no+1}: #{msg}")
  exit 1
end

OptionParser.new do |opt|
end

constants = {}
lines = []
jmp_table = {}
$<.each_line.with_index do |line, i|
  line.chomp!
  line.gsub!(/;.*\z/, "")
  line.strip!
  next if line.match(/\A\s*\z/)
  case line
  when /\A(.*):\s*\z/
    if jmp_table.has_key?($1)
      error("Duplicated label '#{$1}'", i)
    end
    jmp_table[$1] = lines.size
  when /\A\.const\s+([a-zA-Z0-9_\[\]]+)\s+([0-9]+)/
    if constants.has_key?($1)
      error("Duplicated constant name '#{$1}'", i)
    end
    constants[$1] = $2.to_i
  else
    lines << line
  end
end

lines.each do |line|
  line.gsub!(/@([a-zA-Z0-9_]+)/){
    jmp_table.fetch($1)
  }
  line.gsub!(/\$([a-zA-Z0-9_\[\]]+)/){
    constants.fetch($1)
  }
end

puts lines.join("\n")
