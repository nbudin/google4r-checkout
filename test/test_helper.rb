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
require 'bundler'
Bundler.setup(:default, :test)

require 'mocha'
require 'nokogiri'

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
  
  def command_selector(command)
    "#{Google4R::Checkout::CommandXmlGenerator::COMMAND_TO_TAG[command.class]}" +
    "[google-order-number='#{command.google_order_number}']"
  end
  
  def find_elements(selector, xml)
    Nokogiri.parse(xml).css(selector)
  end
  
  def assert_element_exists(selector, xml, msg=nil)
    found = find_elements(selector, xml)
    assert_not_equal 0, found.size, (msg || "Expected to find #{selector} in #{xml}")
  end
  
  def assert_no_element_exists(selector, xml, msg=nil)
    found = find_elements(selector, xml)
    assert_equal 0, found.size, (msg || "Expected to find #{selector} in #{xml}")
  end
  
  def assert_element_text_equals(text, selector, xml, msg=nil)
    found = find_elements(selector, xml)
    assert_equal 1, found.size, "Expected to find one #{selector} in #{xml} but found #{found.size}"
    assert_equal text, found.text, msg
  end
  
  def find_command_elements(selector, command)
    find_elements("#{command_selector(command)} #{selector}", command.to_xml)
  end
  
  def assert_command_element_text_equals(text, selector, command, msg=nil)
    assert_element_text_equals(text, "#{command_selector(command)} #{selector}", command.to_xml, msg)
  end
  
  def assert_command_element_exists(selector, command, msg=nil)
    assert_element_exists("#{command_selector(command)} #{selector}", command.to_xml, msg)
  end
  
  def assert_no_command_element_exists(selector, command, msg=nil)
    assert_no_element_exists("#{command_selector(command)} #{selector}", command.to_xml, msg)
  end
end
