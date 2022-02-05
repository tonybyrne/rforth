module Rforth
  class Error < StandardError
  end

  class StackUnderflowError < Error
  end

  class WordNotFound < Error
  end
end