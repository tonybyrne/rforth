#!/usr/bin/env ruby
require_relative 'lib/rforth'

def welcome
  puts "Welcome to rForth"
  prompt
end

def prompt
  print "\n> "
end

def main
  i = Rforth::Interpreter.new

  welcome
  while line = gets
    i.eval(line)
    puts " #{i.message}"
    prompt
  end
end

main
