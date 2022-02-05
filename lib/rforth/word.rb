module Rforth
  class Word
    attr_accessor :actions, :name, :immediate

    def initialize(name = nil, actions = [], immediate = false)
      @name = name
      @actions = actions
      @immediate = immediate
    end

    def immediate?
      @immediate
    end

    def unnamed?
      name.nil?
    end

    def execute(interpreter)
      if actions.respond_to?(:call)
        actions.call(interpreter)
      else
        actions.each { |action| action.call(interpreter) }
      end
    end
  end
end
