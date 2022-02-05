#!/usr/bin/env ruby
require_relative 'lib/rforth'

def welcome
  puts "Welcome to rForth"
end

def prompt(i)
  print "[#{i.stack.to_a.join(' ')}] > "
end

def main
  i = Rforth::Interpreter.new

  welcome
  prompt(i)

  while line = gets
    i.eval(line)
    puts i.message
    prompt(i)
  end
end

main
