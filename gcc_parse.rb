#!/usr/bin/env ruby

cur = nil
last_section = nil
instructions = []

$<.each_line do |line|
  line.chomp!
  case line
  when /\A\s/
    if last_section == :effect
      cur[last_section] += "\n#{line.chomp}"
    else
      cur[last_section] += "\n#{line.strip}"
    end
  when /\A(\w+) - (.*)\z/
    instructions << cur if cur

    cur = {}
    cur[:mnemonic] = $1
    cur[:desc] = $2.strip
  when /\A(\w+):(.*)\z/
    section = $1.downcase.to_sym
    cur[section] = $2.strip
    last_section = section
  end
end

#instructions.each do |inst|
  #tag = "#{inst[:mnemonic].downcase}---#{inst[:desc].downcase.gsub(' ', '-')}"
  #puts "- [#{inst[:mnemonic]} - #{inst[:desc]}](##{tag})"
#end

puts ""
instructions.each do |inst|
  puts "## #{inst[:mnemonic]} - #{inst[:desc]}"
  puts "- Synopsis: #{inst[:synopsis]}"
  puts "- Syntax: `#{inst[:syntax]}`"
  puts "- Example: `#{inst[:example]}`" if inst[:example]
  puts "- Effect:\n~~~#{inst[:effect]}\n~~~"
end
