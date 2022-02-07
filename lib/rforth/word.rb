module Rforth
  class Word
    attr_accessor :actions, :name, :immediate, :control

    def initialize(name = nil, actions = [], immediate: false, control: false, comment: false)
      @name = name
      @actions = actions
      @immediate = immediate
      @control = control
      @comment = comment
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

    def comment?
      @comment
    end

    def compile_only?
      comment? || control?
    end

    def unnamed?
      @name == nil
    end

    def call(interpreter)
      return unless should_execute?(interpreter)

      if actions.respond_to?(:call)
        actions.call(interpreter)
      else
        interpreter.action_idx = 0
        while actions[interpreter.action_idx]
          actions[interpreter.action_idx].call(interpreter)
          interpreter.action_idx += 1
        end
      end
    end

    private

    def should_execute?(interpreter)
      interpreter.in_executable_scope? || control? || comment?
    end
  end
end
