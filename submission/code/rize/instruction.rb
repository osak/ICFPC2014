module Rize
  class Instruction
    attr_reader :mnemonic, :args
    def initialize(mnemonic, *args)
      @mnemonic = mnemonic
      @args = args.dup
    end

    def to_s
      "#{mnemonic.to_s.upcase} #{args.join(' ')}"
    end
  end
end

