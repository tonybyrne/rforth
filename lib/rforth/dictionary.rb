module Rforth
  class Dictionary
    def initialize
      @words = []
    end

    def define_word(word, actions, immediate = false)
      @words << { word: word, actions: actions, immediate: immediate }
    end

    def last_word_idx
      @words.length - 1
    end

    def find(word, index = last_word_idx)
      while (index >= 0)
        if @words[index][:word] == word
          return @words[index]
        end
        index -= 1
      end
    end
  end
end
