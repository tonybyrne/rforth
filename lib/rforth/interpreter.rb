require 'forwardable'

module Rforth
  class Interpreter
    extend Forwardable

    attr_reader :stack, :dictionary, :message

    def_delegators :dictionary, :define_word, :add_word
    def_delegators :stack, :pop, :push, :dup

    def initialize
      cold_start
    end

    def cold_start
      @compiling = false
      @stack = Stack.new
      @dictionary = Dictionary.new
      bootstrap_dictionary
    end

    def bootstrap_dictionary
      define_word('cold', ->(i) { i.cold_start })
      define_word('bye', ->(i) { exit })
      define_word('.', ->(i) { print i.pop ; print ' ' })
      define_word('drop', ->(i) { i.pop })
      define_word('dup', ->(i) { v = i.pop ; i.push(v) ; i.push(v) })
      define_word('swap', ->(i) { a = i.pop ; b = i.pop; i.push(a) ; i.push(b) })
      define_word('over', ->(i) { a = i.pop ; b = i.pop; i.push(b) ; i.push(a) ; i.push(b)})
      define_word('rot', ->(i) { a = i.pop ; b = i.pop; c = i.pop ; i.push(b) ; i.push(a) ; i.push(c) })
      define_word(':', ->(i) { i.start_compiling })
      define_word(';', ->(i) { i.end_compiling }, true)
      define_word('+', ->(i) { i.push(i.pop + i.pop) })
      define_word('-', ->(i) { b = i.pop; a = i.pop; i.push(a - b) })
      define_word('*', ->(i) { i.push(i.pop * i.pop) })
      define_word('/', ->(i) { b = i.pop; a = i.pop; i.push(a / b) })

      self.eval(': ++ 1 + ;')
      self.eval(': -- 1 - ;')
      self.eval(': double 2 * ;')
      self.eval(': square dup * ;')
    end

    def start_compiling
      @compiling = true
      @current_definition = Word.new()
    end

    def end_compiling
      add_word(@current_definition)
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
          found_word.execute(self)
        else
          raise WordNotFound, "#{word}?"
        end
      end
    end

    def compile_word(word)
      if current_definition_unnamed?
        set_current_definition_name_to(word)
      elsif word.numeric?
        add_to_current_definition(->(i) { i.push(word.to_number) })
      else
        found_word = dictionary.find(word)
        if found_word
          if found_word.immediate?
            found_word.execute(self)
          else
            add_to_current_definition(->(i) { found_word.execute(i) })
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
      @current_definition.unnamed?
    end

    def set_current_definition_name_to(word)
      @current_definition.name = word
    end

    def add_to_current_definition(action)
      @current_definition.actions << action
    end
  end
end
