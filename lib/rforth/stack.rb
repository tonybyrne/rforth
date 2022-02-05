module Rforth
  class Stack
    def initialize
      @items = []
    end

    def to_a
      return @items
    end

    def push(item)
      @items << item
    end

    def pop
      raise StackUnderflowError, 'Stack underflow!' if empty?
      @items.pop
    end

    def depth
      @items.length
    end

    def empty?
      @items.empty?
    end
  end
end
