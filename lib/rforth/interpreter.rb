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
      @comment_stack = Stack.new
      @dictionary = Dictionary.new
      bootstrap_dictionary
    end

    def bootstrap_dictionary
      define_word('//', ->(i) { i.comment_to_eol })
      define_word('(', ->(i) { i.start_comment }, control: true)
      define_word(')', ->(i) { i.end_comment }, control: true)
      define_word('cold', ->(i) { i.cold_start })
      define_word('bye', ->(_i) { exit })
      define_word('immediate', ->(i) { i.immediate }, immediate: true)
      define_word('.', ->(i) { print i.pop; print ' ' })
      define_word('drop', ->(i) { i.pop })
      define_word('dup', ->(i) { v = i.pop; i.push(v); i.push(v) })
      define_word('swap', ->(i) { a = i.pop; b = i.pop; i.push(a); i.push(b) })
      define_word('over', ->(i) { a = i.pop; b = i.pop; i.push(b); i.push(a); i.push(b) })
      define_word('rot', ->(i) { a = i.pop; b = i.pop; c = i.pop; i.push(b); i.push(a); i.push(c) })
      define_word(':', ->(i) { i.start_compiling }, immediate: true)
      define_word(';', ->(i) { i.end_compiling }, immediate: true)
      define_word('+', ->(i) { i.push(i.pop + i.pop) })
      define_word('-', ->(i) { b = i.pop; a = i.pop; i.push(a - b) })
      define_word('*', ->(i) { i.push(i.pop * i.pop) })
      define_word('/', ->(i) { b = i.pop; a = i.pop; i.push(a / b) })
      define_word('=', ->(i) { push(i.pop == i.pop ? -1 : 0) })
      define_word('!=', ->(i) { push(i.pop != i.pop ? -1 : 0) })

      define_word('if', ->(i) { i.control_if }, control: true)
      define_word('endif', ->(i) { i.control_endif }, control: true)
      define_word('else', ->(i) { i.control_else }, control: true)

      self.eval(': ++ 1 + ;')
      self.eval(': -- 1 - ;')
      self.eval(': double 2 * ;')
      self.eval(': square dup * ;')
    end

    def in_executable_scope?
      return false if in_comment?

      @control_flow_stack.empty? || @control_flow_stack.all? { |condition| condition }
    end

    def comment_to_eol
      @comment_to_eol = true
    end

    def comment_to_eol?
      @comment_to_eol
    end

    def in_comment?
      !@comment_stack.empty?
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

    def start_comment
      @comment_stack.push(true)
    end

    def end_comment
      if @comment_stack.empty?
        raise Error, "')' without preceding '('!"
      end
      @comment_stack.pop
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
        @control_flow_stack.push(true)
      else
        @control_flow_stack.push(false)
      end
    end

    def control_endif
      if @control_flow_stack.empty?
        raise "'endif' without preceding 'if'!"
      end
      @control_flow_stack.pop
    end

    def control_else
      if @control_flow_stack.empty?
        raise "'else' without preceding 'if'!"
      end
      v = @control_flow_stack.pop
      @control_flow_stack.push(!v)
    end

    def eval(string)
      @message = nil
      @words = string.split
      @word_idx = 0
      eval_words if @words.any?
      @message = 'ok.'
      @comment_to_eol = false
      true
    rescue StandardError => e
      @message = e.message
      false
    end

    def eval_words
      while word = get_word do
        if immediate?
          execute_word(word)
        else
          compile_word(word)
        end
      end
    end

    def get_word
      return if comment_to_eol?
      word = @words[@word_idx]
      @word_idx += 1
      word
    end

    def execute_word(word)
      if found_word = dictionary.find(word)
        found_word.call(self)
      elsif word.numeric?
        push(word.to_number) if in_executable_scope?
      elsif in_comment?
        # Do nothing
      else
        raise WordNotFound, "#{word}?"
      end
    end

    def compile_word(word)
      if found_word = dictionary.find(word)
        if found_word.immediate? or found_word.control?
          found_word.call(self)
        else
          add_to_current_definition(found_word)
        end
      elsif (word.numeric?)
        add_to_current_definition(->(i) { i.push(word.to_number) if i.in_executable_scope? })
      elsif in_comment?
        # Do nothing
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
