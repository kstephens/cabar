#!/usr/bin/env ruby

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'ruby'))

require 'cabar'
require 'cabar/main'

begin
  main =
    Cabar::Main.
    new(:args => ARGV)
  
  $x = main.configuration
rescue Object => err
  $stderr.puts "#{err.inspect}\n  #{err.backtrace.join("\n  ")}"
  raise err
end

