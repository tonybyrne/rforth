module Rforth
  class Dictionary
    def initialize
      @words = []
    end

    def add_word(word)
      @words << word
    end

    def define_word(name, actions, immediate = false)
      add_word(Word.new(name, actions, immediate))
    end

    def last_word_idx
      @words.length - 1
    end

    def find(word, index = last_word_idx)
      while (index >= 0)
        if @words[index].name == word
          return @words[index]
        end
        index -= 1
      end
    end
  end
end
