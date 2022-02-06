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
      @control_flow_stack = Stack.new
      @dictionary = Dictionary.new
      bootstrap_dictionary
    end

    def bootstrap_dictionary
      define_word('\\', ->(i) { i.skip })
      define_word('cold', ->(i) { i.cold_start })
      define_word('bye', ->(_i) { exit })
      define_word('immediate', ->(i) { i.immediate }, immediate: true)
      define_word('words', ->(i) { i.words })
      define_word('.', ->(i) { print i.pop; print ' ' })
      define_word('drop', ->(i) { i.pop })
      define_word('dup', ->(i) { v = i.pop; i.push(v); i.push(v) })
      define_word('swap', ->(i) { a = i.pop; b = i.pop; i.push(a); i.push(b) })
      define_word('over', ->(i) { a = i.pop; b = i.pop; i.push(b); i.push(a); i.push(b) })
      define_word('rot', ->(i) { a = i.pop; b = i.pop; c = i.pop; i.push(b); i.push(a); i.push(c) })
      define_word(':', ->(i) { i.start_compiling}, immediate: true )
      define_word(';', ->(i) { i.end_compiling }, immediate: true)
      define_word('+', ->(i) { i.push(i.pop + i.pop) })
      define_word('-', ->(i) { b = i.pop; a = i.pop; i.push(a - b) })
      define_word('*', ->(i) { i.push(i.pop * i.pop) })
      define_word('/', ->(i) { b = i.pop; a = i.pop; i.push(a / b) })
      define_word('=', ->(i) { push(i.pop == i.pop ? -1 : 0) })
      define_word('!=', ->(i) { push(i.pop != i.pop ? -1 : 0) })

      define_word('if', ->(i) { i.control_if })
      define_word('then', ->(i) { i.control_then })

      self.eval(': ++ 1 + ;')
      self.eval(': -- 1 - ;')
      self.eval(': double 2 * ;')
      self.eval(': square dup * ;')
    end

    def skip
      @skip = true
    end

    def unskip
      @skip = false
    end

    def skipping?
      @skip
    end

    def start_compiling
      if @compiling
        @compiling = false
        raise Error, 'Nested compile!'
      else
        @compiling = true
        @current_definition = Word.new(get_word)
      end
    end

    def end_compiling
      if !@compiling
        raise Error, 'End compile when not compiling.'
      else
        add_word(@current_definition)
        @compiling = false
      end
    end

    def immediate
      if compiling?
        @current_definition.immediate!
      else
        dictionary.latest.immediate!
      end
    end

    def control_if
      value = stack.pop
      if value == -1
      else
        skip
      end
    end

    def control_then
      unskip
    end

    def words
      dictionary.words.each do |w|
        if w.immediate
          puts "#{w.name} (immediate)"
        else
          puts w.name
        end
      end
    end

    def eval(string)
      @message = nil
      @words = string.split
      @word_idx = 0
      eval_words if @words.any?
      @message = 'ok.'
      @skip = false
      true
    rescue StandardError => e
      @message = e.message
      false
    end

    def eval_words
      while (word = get_word) do
        if immediate?
          execute_word(word)
        else
          compile_word(word)
        end
      end
    end

    def get_word
      word = @words[@word_idx]
      @word_idx += 1
      word
    end

    def execute_word(word)
      return if @skip

      if found_word = dictionary.find(word)
        found_word.execute(self)
      elsif word.numeric?
        push(word.to_number)
      else
        raise WordNotFound, "#{word}?"
      end
    end

    def compile_word(word)
      if found_word = dictionary.find(word)
        if found_word.immediate?
          found_word.execute(self)
        else
          add_to_current_definition(->(i) { found_word.execute(i) })
        end
      elsif (word.numeric?)
        add_to_current_definition(->(i) { i.push(word.to_number) })
      else
        raise WordNotFound, "#{word}?"
      end
    end

    def compiling?
      @compiling
    end

    def immediate?
      !compiling?
    end

    def add_to_current_definition(action)
      @current_definition.actions << action
    end
  end
end
