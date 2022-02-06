module Rforth
  class Word
    attr_accessor :actions, :name, :immediate, :control

    def initialize(name = nil, actions = [], immediate: false, control: false)
      @name = name
      @actions = actions
      @immediate = immediate
      @control = control
    end

    def immediate!
      @immediate = true
    end

    def immediate?
      @immediate
    end

    def control?
      @control
    end

    def call(interpreter)
      return if interpreter.skipping? && !control?
      puts " about to exec #{name} #{@control}"

      if actions.respond_to?(:call)
        actions.call(interpreter)
      else
        actions.each { |action| action.call(interpreter) }
      end
    end
  end
end
