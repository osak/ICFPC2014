module Rize
  class SECDMachine
    def initialize
      @value_stack = []
      @call_stack = []
      @pc = 0
    end

    def load(insts)
      @insts = insts
      @pc = 0
    end

    def execute!
      loop do
        inst = insts[@pc]
        case inst.mnemonic
        when :ldc
          push_value(inst.args[0])
        when :ld
          level, index = inst.args
          frame = current_frame
          level.times do
            frame = frame.parent
          end
          check_frame_type(frame, lambda{|type| type != :dum})
          error "Index out of bound" if index >= frame.size
          push_value(frame[index])
        when :add
          b = pop_value(Integer)
          a = pop_value(Integer)
          push_value(a+b)
        when :sub
          b = pop_value(Integer)
          a = pop_value(Integer)
          push_value(a-b)
        when :mul
          b = pop_value(Integer)
          a = pop_value(Integer)
          push_value(a*b)
        when :div
          b = pop_value(Integer)
          a = pop_value(Integer)
          push_value(a/b)
        when :ceq
          b = pop_value(Integer)
          a = pop_value(Integer)
          push_value(a == b ? 1 : 0)
        when :cgt
          b = pop_value(Integer)
          a = pop_value(Integer)
          push_value(a > b ? 1 : 0)
        when :cgte
          b = pop_value(Integer)
          a = pop_value(Integer)
          push_value(a >= b ? 1 : 0)
        when :atom
          a = pop_value
          push_value(a.is_a?(Integer) ? 1 : 0)
        when :cons
          b = pop_value
          a = pop_value
          push_value(Cons.new(a, b))
        when :car
          a = pop_value(Cons)
          push_value(a.car)
        when :cdr
          a = pop_value(Cons)
          push_value(a.cdr)
        when :sel
          cond = pop_value(Integer)
          next_pc = cond ? inst.args[0] : inst.args[1]
          push_call(Control.new(:join, @pc))
          @pc = next_pc - 1
        when :join
          control = pop_call(:join)
          @pc = control.pc
        when :ldf
          push_value(Closure.new(inst.args[0], current_frame))
        when :ap
          a = pop_value(Closure)
          fp = Frame.new(inst.args[0], a.frame)
          (0...inst.args[0]).reverse_each do |i|
            fp[i] = pop_value
          end
          push_call(CallFrame.new(:rtn, current_frame, @pc))
          current_frame = fp
          @pc = a.pc - 1
        when :rtn
          a = pop_call(lambda{|t| t == :rtn || t == :stop})
          if a.type == :stop
            break
          else
            current_frame = a.frame
            @pc = a.pc
          end
        when :dum
          fp = Frame.new(inst.args[0], current_frame, :dum)
          current_frame = fp
        when :rap
          a = pop_value(Closure)
          check_frame_type(a.frame, :dum)
          error "Frame size mismatch" if inst.args[0] != a.frame.size
          error "Invalid frame for RAP" if current_frame != a.frame
          (0...inst.args[0]).reverse_each do |i|
            current_frame[i] = pop_value
          end
          ep = current_frame.parent
          push_call(CallFrame.new(:rtn, ep, @pc))
          current_frame.type = :normal
          @pc = a.pc - 1
        when :stop
          return :stop
        when :tsel
          error "TSEL is unsupported"
        when :tap
          error "TAP is unsupported"
        when :trap
          error "TRAP is unsupported"
        when :st
          level, index = inst.args
          frame = current_frame
          level.times do
            frame = frame.parent
          end
          check_frame_type(frame, lambda{|t| t != :dum})
          error "Index out of bound" if index >= frame.size
          frame[index] = pop_value
        when :dbug
          a = pop_value
          trace(a)
        when :brk
          return :break
        end
        @pc += 1
      end
      :stop
    end

    private

    def current_frame
      @current_frame
    end

    def current_frame=(val)
      @current_frame = val
    end

    def push_value(val)
      @value_stack << val
    end

    def pop_value(type = nil)
      error "Value stack is empty" if @value_stack.empty?
      val = @value_stack.pop
      error "Type mismatch" if type && !(type === val)
      val
    end

    def push_call(val)
      @call_stack << val
    end

    def pop_call(cond = nil)
      error "Call stack is empty" if @call_stack.empty?
      val = @call_stack.pop
      error "Type mismatch" if cond && !(cond === val.type)
      val
    end

    def check_frame_type(frame, cond)
      error "Frame mismatch" if cond && !(cond === frame.type)
    end

    def error(message)
      STDERR.puts("#{@pc}(#{@insts[@pc]}): #{message}")
    end
  end
end
