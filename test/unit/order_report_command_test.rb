#--
# Project:   google_checkout4r 
# File:      test/unit/order_report_command_test.rb
# Author:    Tony Chan <api.htchan at gmail dot com>
# Copyright: (c) 2007 by Dan Dukeson
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

# Tests for the CancelItemsCommand class.
class Google4R::Checkout::OrderReportCommandTest < Test::Unit::TestCase
  include Google4R::Checkout

  def setup
    @frontend = Frontend.new(FRONTEND_CONFIGURATION)
    @command = @frontend.create_order_report_command(
        Time.utc(2007, 9, 1, 0, 0, 0),
        Time.utc(2007, 9, 30, 23, 59, 59))
    @command.financial_state = 'CHARGED'
    @command.fulfillment_state = 'NEW'
    @command.date_time_zone = 'America/New_York'
    
    @sample_xml=%Q{<?xml version='1.0' encoding='UTF-8'?>
<order-list-request end-date='2007-09-30T23:59:59' start-date='2007-09-01T00:00:00' xmlns='http://checkout.google.com/schema/2'>
  <financial-state>CHARGED</financial-state>
  <fulfillment-state>NEW</fulfillment-state>
  <date-time-zone>America/New_York</date-time-zone>
</order-list-request>}
  end

  def test_behaves_correctly
    [ :start_date, :end_date,
      :financial_state, :financial_state=,
      :fulfillment_state, :fulfillment_state=,
      :date_time_zone, :date_time_zone= ].each do |symbol|
      assert_respond_to @command, symbol
    end
  end

  def test_to_xml
    assert_strings_equal(@sample_xml, @command.to_xml)
  end

  def test_accessors
    assert_equal('2007-09-01T00:00:00', @command.start_date)
    assert_equal('2007-09-30T23:59:59', @command.end_date)
    assert_equal('CHARGED', @command.financial_state)
    assert_equal('NEW', @command.fulfillment_state)
    assert_equal('America/New_York', @command.date_time_zone)
  end
  
  def test_good_dates
    assert_nothing_raised RuntimeError do
      @frontend.create_order_report_command(
          Time.utc(2007, 9, 1, 0, 0, 0),
          Time.utc(2007, 9, 30, 23, 59, 59))
    end
  end
  
  def test_dates_should_not_be_string
    assert_raise RuntimeError do
      @frontend.create_order_report_command(
          '2007-09-01T00:00:00',
          '2007-09-30T23:59:59')
    end
  end
  
  def test_end_date_before_start_date
    assert_raise RuntimeError do
      @frontend.create_order_report_command(
          Time.utc(2007, 9, 1, 0, 0, 0),
          Time.utc(2006, 9, 30, 23, 59, 59))
    end
  end
  
  def test_financial_state
    assert_raise RuntimeError do
      @command.financial_state = 'DUMMY'
    end
  end
  
  def test_fulfillment_state
    assert_raise RuntimeError do
      @command.fulfillment_state = 'DUMMY'
    end
  end
end
