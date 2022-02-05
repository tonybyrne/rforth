module Rforth
  class Interpreter
    attr_reader :stack, :dictionary

    def initialize
      @stack = Stack.new
      @dictionary = Dictionary.new
    end

    def eval(string)
      words = string.split
      process_words(words) if words.any?
    end

    def process_words(words)
      words.each do |word|
        process_word(word)
      end
    end

    def process_word(word)
      if word.numeric?
        stack.push(word.to_number)
      else
        definition = dictionary.find(word)
        definition.call(self)
      end
    end
  end
end
