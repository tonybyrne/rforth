require 'forwardable'

module Rforth
  class Interpreter
    extend Forwardable

    attr_reader :stack, :dictionary, :message

    def_delegators :dictionary, :define_word
    def_delegators :stack, :pop, :push, :dup

    def initialize
      @compiling = false
      @stack = Stack.new
      @dictionary = Dictionary.new
      define_primitives
    end

    def define_primitives
      define_word('bye', [->(i) { exit }])
      define_word('.', [->(i) { print i.pop }])
      define_word('drop', [->(i) { i.pop }])
      define_word('dup', [->(i) { i.dup }])
      define_word(':', [->(i) { i.start_compiling }])
      define_word(';', [->(i) { i.end_compiling }], true)
      define_word('+', [->(i) { i.push(i.pop + i.pop) }])
      define_word('-', [->(i) { a = i.pop; b = i.pop; i.push(b - a) }])
      define_word('*', [->(i) { i.push(i.pop * i.pop) }])
      define_word('/', [->(i) { a = i.pop; b = i.pop; i.push(b / a) }])
    end

    def start_compiling
      @compiling = true
      @current_definition = { word: nil, actions: [] }
    end

    def end_compiling
      define_word(@current_definition[:word], @current_definition[:actions].flatten)
      @compiling = false
    end

    def eval(string)
      @message = nil
      words = string.split
      eval_words(words) if words.any?
      @message = 'ok.'
      true
    rescue StandardError => e
      @message = e.message
      false
    end

    def eval_words(words)
      words.each do |word|
        if immediate?
          execute_word(word)
        else
          compile_word(word)
        end
      end
    end

    def execute_word(word)
      if word.numeric?
        push(word.to_number)
      else
        found_word = dictionary.find(word)
        if found_word
          execute_definition(found_word)
        else
          raise WordNotFound, "#{word}?"
        end
      end
    end

    def compile_word(word)
      if current_definition_unnamed?
        set_current_definition_name_to(word)
      elsif word.numeric?
        add_to_current_definition(->(i) { i.push(word) })
      else
        found_word = dictionary.find(word)
        if found_word
          if found_word[:immediate]
            execute_definition(found_word)
          else
            add_to_current_definition(found_word[:actions])
          end
        else
          raise WordNotFound, "#{word}?"
        end
      end
    end

    def compiling?
      @compiling
    end

    def immediate?
      !compiling?
    end

    private

    def current_definition_unnamed?
      @current_definition[:word].nil?
    end

    def set_current_definition_name_to(word)
      @current_definition[:word] = word
    end

    def add_to_current_definition(actions)
      @current_definition[:actions].push(actions)
    end

    def execute_definition(definition)
      definition[:actions].each { |action| action.call(self) }
    end
  end
end
