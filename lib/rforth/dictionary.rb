module Rforth
  class Dictionary
    attr_reader :words

    def initialize
      @words = []
    end

    def add_word(word)
      @words << word
    end

    def define_word(name, actions, immediate:  false, control: false)
      add_word(Word.new(name, actions, immediate: immediate, control: control))
    end

    def lastest_word_idx
      @words.length - 1
    end

    def latest
      return @words[lastest_word_idx]
    end

    def find(word, index = lastest_word_idx)
      while (index >= 0)
        if @words[index].name == word
          return @words[index]
        end
        index -= 1
      end
    end
  end
end
