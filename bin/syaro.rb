#!/usr/bin/env ruby

require 'optparse'
require_relative '../rize/instruction.rb'
require_relative '../rize/secd.rb'
require_relative '../rize/closure.rb'
require_relative '../rize/cons.rb'
require_relative '../rize/frame.rb'

TABLE = {
  "#" => 0,
  " " => 1,
  "." => 2,
  "o" => 3,
  "%" => 4,
  "\\" => 5,
  "=" => 6
}.freeze
REV_TABLE = {}
TABLE.each_pair do |key,val|
  REV_TABLE[val] = key
end
REV_TABLE[5] = " "
REV_TABLE.freeze

class Game
  LambdaMan = Struct.new(:vital, :pos, :dir, :lives, :score)
  Ghost = Struct.new(:vital, :pos, :dir)
  def initialize(field)
    @field = field.dup
    @lm = LambdaMan.new(0, nil, 0, 3, 0)
    @ghosts = []
    @field.each_with_index do |row, y|
      row.each_with_index do |tile, x|
        if tile == 5
          @lm.pos = Rize::Cons.new(x, y)
        elsif tile == 6
          @ghosts << Ghost.new(0, Rize::Cons.new(x, y), 0)
        end
      end
    end
  end

  def encode
    build_tuple(build_map, build_lambda_man_states, build_ghost_states, fruit_state)
  end

  def fruit_state
    0
  end

  def build_ghost_states
    @ghosts.reverse.reduce(0) do |acc, ghost|
      Rize::Cons.new(build_ghost(ghost), acc)
    end
  end

  def build_ghost(g)
    build_tuple(g.vital, g.pos, g.dir)
  end

  def build_lambda_man_states
    build_tuple(@lm.vital, @lm.pos, @lm.dir, @lm.lives, @lm.score)
  end

  def build_map
    build_list(*@field.map{|row|
      build_list(*row)
    })
  end

  def build_tuple(*args)
    args[0..-2].reverse.reduce(args[-1]){|acc, val| Rize::Cons.new(val, acc)}
  end

  def build_list(*args)
    args.reverse.reduce(0){|acc, val| Rize::Cons.new(val, acc)}
  end

  def to_s
    str = ""
    @field.each_with_index do |row, y|
      row_str = row.map{|i| REV_TABLE[i]}.join
      if y == @lm.pos.cdr
        row_str[@lm.pos.car] = "\\"
      end
      str << row_str
      str << "\n"
    end
    str
  end

  def move(dir)
    x, y = @lm.pos.car, @lm.pos.cdr
    case dir
    when 0
      y -= 1
    when 1
      x += 1
    when 2
      y += 1
    when 3
      x -= 1
    end
    if @field[y][x] != 0
      tile = @field[y][x]
      if tile == 2
        @lm.score = @lm.score + 10
        @field[y][x] = 1
      elsif tile == 3
        @lm.score = @lm.score + 50
        @field[y][x] = 1
      end
      @lm.pos = Rize::Cons.new(x, y)
    end
  end
end

def load_field(path)
    File.open(path).each_line.map do |line|
    line.each_char.map do |ch|
      TABLE[ch]
    end
  end
end

def trap_machine
  ret = yield
  if ret == :stop
    #puts "Successfully stopped."
  elsif ret == :error
    #puts "Error."
  else
    raise "Break."
  end
  ret
end

OptionParser.new do |opt|
end

if ARGV.size < 2
  STDERR.puts("Usage: #{$0} [gcc-file] [map-file]")
  exit 2
end
print "\033[2J"

insts = []
src = File.open(ARGV[0])
field = load_field(ARGV[1])
game = Game.new(field)

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

# Acquire step function
ret = trap_machine do
  main = Rize::Closure.new(0, Rize::Frame.new(2, nil))
  main.frame[0] = game.encode
  main.frame[1] = nil
  machine.call(main)
end
step = machine.value_stack.last
unless step.is_a?(Rize::Cons) && step.cdr.is_a?(Rize::Closure)
  STDERR.puts("Initialize function must return cons pair, with cdr being a closure.")
  exit 1
end

# Execution loop
state = step.car
loop do
  ret = trap_machine do
    machine.call(step.cdr, state, Rize::Cons.new(nil, nil))
  end
  if ret == :stop
    res = machine.value_stack.last
    unless res.is_a?(Rize::Cons) && res.cdr.is_a?(Integer)
      STDERR.puts("Step function must return cons pair, with cdr being an integer")
    end
    unless (0..3).include?(res.cdr)
      STDERR.puts("Cdr of step function return must be within 0..3")
    end
    puts res
    state = res.car
    game.move(res.cdr)
    print "\033[0;0H"
    puts game.to_s
  end
end

puts "Contents of machine stack:"
machine.value_stack.reverse_each do |val|
  puts val
end
