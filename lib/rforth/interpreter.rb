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
      # puts "OK"
      # rescue RuntimeError => e
      # puts "Error: #{e.message}"
    end

    def process_word(word)
      # if word.numeric?
        stack.push(word.to_number)
      # else
      #   definition = find_word(word)
      #   if definition == nil
      #     raise RuntimeError, "'#{word}' not found in dictionary."
      #   elsif definition[:builtin]
      #     send definition[:builtin]
      #   else
      #     process_words(definition[:words])
      #   end
      # end
    end
  end
end
