module GCC
  class Environment
    def initialize(parent)
      @table = {}
      @parent = parent
    end

    def put(name, index)
      @table[name] = index
    end

    def get(name)
      if idx = @table.fetch(name, nil)
        {frame: 0, index: idx}
      else
        res = @parent && @parent.get(name)
        if res
          res[:frame] += 1
        end
        res
      end
    end
  end
end
