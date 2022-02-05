module Rforth
  class Word
    attr_reader :actions, :name

    def initialize(name, actions, immediate = false)
      @name = name
      @actions = actions
      @immediate = immediate
    end

    def immediate?
      @immediate
    end

    def execute(interpreter)
      actions.each { |action| action.call(interpreter) }
    end
  end
end
