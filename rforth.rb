#!/usr/bin/env ruby
require_relative 'lib/rforth'

def welcome
  puts "Welcome to rForth"
end

def prompt(i)
  if i.compiling?
    print "(compiling) > "
  else
    print "[#{i.stack.to_a.join(' ')}] > "
  end

end

def main
  i = Rforth::Interpreter.new

  welcome
  prompt(i)

  while line = gets
    i.eval(line)
    puts i.message if i.message
    prompt(i)
  end
end

main
