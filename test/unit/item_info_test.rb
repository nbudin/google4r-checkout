require 'google4r/checkout'

require 'test/frontend_configuration'
#--
# Project:   google_checkout4r 
# File:      test/unit/item_info_test.rb
# Author:    Tony Chan <api.htchan at gmail dot com>
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
#++

require File.expand_path(File.dirname(__FILE__)) + '/../test_helper'

require 'google4r/checkout'

require 'test/frontend_configuration'

# Test for the class ItemInfo.
class Google4R::Checkout::ItemInfoTest < Test::Unit::TestCase
  include Google4R::Checkout

  def setup
    @item_info = ItemInfo.new('A1')
    @item_info.create_tracking_data('UPS', '55555555')
    @item_info.create_tracking_data('FedEx', '12345678')
  end
  
  def test_initialization_works
    assert_kind_of ItemInfo, @item_info
  end
  
  def test_responds_correctly 
    [ :merchant_item_id, :tracking_data_arr].each do |sym|
      assert_respond_to @item_info, sym
    end
  end
  
  def test_merchant_item_id
    assert_equal('A1', @item_info.merchant_item_id) 
  end
  
  def test_tracking_data_arr
    tracking_data = @item_info.tracking_data_arr[0]
    assert_equal('UPS', tracking_data.carrier)
    assert_equal('55555555', tracking_data.tracking_number)
    tracking_data = @item_info.tracking_data_arr[1]
    assert_equal('FedEx', tracking_data.carrier)
    assert_equal('12345678', tracking_data.tracking_number)
  end
end