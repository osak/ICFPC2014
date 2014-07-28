module Chino
  class CompilerException < Exception
    attr_reader :context
    def initialize(message, context)
      super(message)
      @context = context
    end
  end
end
