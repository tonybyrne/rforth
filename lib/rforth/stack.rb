require 'forwardable'

module Rforth
  class Stack
    extend Forwardable

    attr_reader :items

    def_delegators :items, :empty?, :all?

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

    def top
      @items.last
    end
  end
end
