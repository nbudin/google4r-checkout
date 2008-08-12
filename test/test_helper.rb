# Project:   google4r
# File:      /test/test_helper.rb
# Author:    Manuel Holtgrewe <purestorm at ggnore dot net>
# Copyright: (c) 2007 by Manuel Holtgrewe
# License:   MIT License as follows:
#
# Permission is hereby granted, free of charge, to any person obtaining 
# a copy of this software and associated documentation files (the 
# "Software"), to deal in the Software without restriction, including 
# without limitation the rights to use, copy, modify, merge, publish, 
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the 
# following conditions:
#
# The above copyright notice and this permission notice shall be included 
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 

# setup load path
$LOAD_PATH << File.join(File.dirname(__FILE__), '..')
$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

# require dependencies

require 'test/unit'

require 'rubygems'
require 'mocha'
require 'stubba'

class Array
  # Returns the "power set" for this Array. This means that an array with all
  # subsets of the array's elements will be returned.
  def power
    # the power set line is stolen from http://johncarrino.net/blog/2006/08/11/powerset-in-ruby/
    inject([[]]){|c,y|r=[];c.each{|i|r<<i;r<<i+[y]};r}
  end
end

# A helper class for the tests that require TaxTable objects.
class TestTaxTableFactory
  def effective_tax_tables_at(time)
    table = Google4R::Checkout::TaxTable.new(false)
    table.name = "Some Table"
    
    [ table ]
  end
end

class Test::Unit::TestCase
  def assert_nospace_equal(expected, actual)
    return assert_equal(expected.gsub(/\s/, ''), actual.gsub(/\s/, ''))
  end
  
  # Perform assertion on strings. The advantage of this method over the normal assert_equal
  # method is that it displays the exact mismatch location and is aware of multi line strings.
  # 
  # This comes at a performance cost since we have to compare character wise.
  #
  # === Example
  #
  #   assert_string_equals("1\n2", "1\3", "Test Message!")
  #   
  #   Test Message!
  #   <1
  #   2> expected but was
  #   <1
  #   3>.Actual value is a real prefix of the expected value!
  def assert_strings_equal(expected, actual, msg=nil)
    return true if expected == actual
    
    message = msg.nil? ? '' : "#{msg}\n"
    message += %Q{<#{expected}> expected but was
<#{actual}>.}
    
    expected_lines, actual_lines = expected.split(/\r\n|\n|\r/), actual.split(/\r\n|\n|\r/)
    
    1.upto([ expected_lines.length, actual_lines.length ].min) do |i|
      next if expected_lines[i] == actual_lines[i]
      
      # expected line != actual line
      if expected_lines[i].length != actual_lines[i].length then
        _wrap_assertion do
          message += "\nLine <#{i+1}> expected to be <#{expected_lines[i].length}> bytes long but was <#{actual_lines[i].length}> bytes long."
          raise Test::Unit::AssertionFailedError, message
        end
      end
      
      1.upto(expected_lines[i].length) do |j|
        if expected_lines[i][j] != actual_lines[i][j] then
          _wrap_assertion do
            message += "\nCharacter <#{j}> of line <#{i+1}> expected to be <#{expected_lines[i][j]}> but was <#{actual_lines[i][j]}.>"
            raise Test::Unit::AssertionFailedError, message
          end
        end
      end
    end
    
    # if we reach here then one of expected and actual is a prefix of the other
    if expected.length < actual.length then
      message += "\nExpected value is a real prefix of the actual value!"
    else
      message += "\nActual value is a real prefix of the expected value!"
    end
    _wrap_assertion do
      raise Test::Unit::AssertionFailedError, message
    end
  end
end