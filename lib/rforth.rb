module Rforth
  require_relative 'rforth/errors'
  require_relative 'rforth/word'
  require_relative 'rforth/dictionary'
  require_relative 'rforth/stack'
  require_relative 'rforth/interpreter'
end

class String
  def numeric?
    Float(self) != nil rescue false
  end

  def to_number
    (to_f % 1) > 0 ? to_f : to_i
  end
end
