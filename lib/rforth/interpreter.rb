require 'forwardable'

module Rforth
  class Interpreter
    extend Forwardable

    attr_reader :stack, :dictionary, :message
    attr_accessor :action_idx

    def_delegators :dictionary, :define_word, :add_word
    def_delegators :stack, :pop, :push, :dup

    def initialize
      cold_start
    end

    def cold_start
      @compiling = false
      @stack = Stack.new
      @control_flow_stack = Stack.new
      @loop_stack = Stack.new
      @comment_stack = Stack.new
      @dictionary = Dictionary.new
      bootstrap_dictionary
    end

    def bootstrap_dictionary
      define_word('//', ->(i) { i.comment_to_eol }, comment: true)
      define_word('(', ->(i) { i.start_comment }, comment: true)
      define_word(')', ->(i) { i.end_comment }, comment: true)
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

      define_word('do', ->(i) { i.control_do }, control: true)
      define_word('loop', ->(i) { i.control_loop }, control: true)
      define_word('i', ->(i) { i.push_i })

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
      !@comment_stack.empty? || comment_to_eol?
    end

    def start_compiling
      if @compiling
        @compiling = false
        raise Error, "':' (start compile) while already compiling!"
      else
        @compiling = true
        @current_definition = Word.new
      end
    end

    def end_compiling
      if !@compiling
        raise Error, "';' (end compile) when not compiling!"
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

    def control_do
      @loop_stack.push(idx: stack.pop, limit: stack.pop, location: @action_idx)
    end

    def control_loop
      lp = @loop_stack.pop
      idx = lp[:idx] + 1
      limit = lp[:limit]
      location = lp[:location]

      if idx < limit
        @loop_stack.push(idx: idx, limit: limit, location: location)
        @action_idx = location
      end
    end

    def push_i
      if @loop_stack.top
        stack.push @loop_stack.top[:idx]
      else
        raise Error, "'i' referenced outside a do .. loop!"
      end
    end

    def eval(string)
      @message = nil
      @words = string.split
      @word_idx = 0
      eval_words if @words.any?
      @message = 'ok.' unless compiling?
      @comment_to_eol = false
      true
    rescue StandardError, SystemStackError => e
      @message = "Error: #{e.message}"
      false
    end

    def eval_words
      while word = get_word do
        if compiling?
          compile_word(word)
        else
          execute_word(word)
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
        if found_word.compile_only?
          raise Error, "'#{word}' can only be used within a word definition!"
        else
          found_word.call(self)
        end
      elsif word.numeric?
        push(word.to_number)
      else
        raise WordNotFound, "#{word}?"
      end
    end

    def compile_word(word)
      if @current_definition.unnamed?
        @current_definition.name = word
      elsif word == @current_definition.name
        add_to_current_definition(->(i) { i.execute_word(word) if i.in_executable_scope? }) unless in_comment?
      elsif found_word = dictionary.find(word)
        if found_word.immediate? or found_word.comment?
          found_word.call(self)
        else
          add_to_current_definition(found_word) unless in_comment?
        end
      elsif (word.numeric?)
        add_to_current_definition(->(i) { i.push(word.to_number) if i.in_executable_scope? }) unless in_comment?
      elsif in_comment?
        # Do nothing
      else
        raise WordNotFound, "#{word}?"
      end
    end

    def compiling?
      @compiling
    end

    def add_to_current_definition(action)
      @current_definition.actions << action
    end
  end
end
