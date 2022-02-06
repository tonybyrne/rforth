module Rforth
  class Word
    attr_accessor :actions, :name, :immediate

    def initialize(name = nil, actions = [], immediate = false)
      @name = name
      @actions = actions
      @immediate = immediate
    end

    def immediate!
      @immediate = true
    end

    def immediate?
      @immediate
    end

    def execute(interpreter)
      if actions.respond_to?(:call)
        actions.call(interpreter) unless interpreter.skipping?
      else
        actions.each { |action| action.call(interpreter) unless interpreter.skipping? }
      end
    end
  end
end
