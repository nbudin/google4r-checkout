#--
# Project:   google_checkout4r 
# File:      test/unit/paramterized_url_test.rb
# Author:    Johnathan Niziol <johnathan.niziol at canadadrugs dot com>
# Copyright: (c) 2011 by Johnathan Niziol
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
#++

require File.expand_path(File.dirname(__FILE__)) + '/../test_helper'

require 'google4r/checkout'

require 'test/frontend_configuration'

# Test for the Parameterized class.
class Google4R::Checkout::ParameterizedUrlTest < Test::Unit::TestCase
  include Google4R::Checkout

  def setup
    @parameterized_url = ParameterizedUrl.new("http://testurl.com")   
  end
  
  def test_parameterized_url_behaves_correctly
    assert_respond_to @parameterized_url, :url
    assert_respond_to @parameterized_url, :create_url_parameter
    assert_respond_to @parameterized_url, :url_parameters 
  end
  
  def test_initialized_correctly
    assert_equal "http://testurl.com", @parameterized_url.url
    assert_equal [], @parameterized_url.url_parameters
  end
    
  def test_accessors_work_correctly
    @parameterized_url.url = "url"
    assert_equal "url", @parameterized_url.url    
  end
end