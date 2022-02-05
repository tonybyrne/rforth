module Rforth
  class Dictionary
    def initialize
      @words = []
    end

    def define_word(word, action)
      @words << { word => action }
    end

    def last_word_idx
      @words.length - 1
    end

    def find(word, index = last_word_idx)
      while (index >= 0)
        if @words[index].keys.first == word
          return @words[index].values.first
        end
        index -= 1
      end
    end
  end
end
