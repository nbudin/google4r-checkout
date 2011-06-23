#--
# Project:   google_checkout4r 
# File:      test/unit/chargeback_amount_notification_test.rb
# Author:    Tony Chan <api.htchan AT gmail.com>
# Copyright: (c) 2007 by Tony Chan
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
require 'rexml/document'
require 'test/frontend_configuration'

# Test for the class ChargebackAmountNotification
class Google4R::Checkout::ChargebackAmountNotificationTest < Test::Unit::TestCase
  include Google4R::Checkout

  def setup
    @frontend = Frontend.new(FRONTEND_CONFIGURATION)
    @frontend.tax_table_factory = TestTaxTableFactory.new

    @example_xml = %q{
<?xml version="1.0" encoding="UTF-8"?>
<chargeback-amount-notification xmlns="http://checkout.google.com/schema/2"
  serial-number="bea6bc1b-e1e2-44fe-80ff-0180e33a2614">
  <google-order-number>841171949013218</google-order-number>
  <latest-chargeback-amount currency="GBP">226.06</latest-chargeback-amount>
  <total-chargeback-amount currency="GBP">226.06</total-chargeback-amount>
  <latest-fee-refund-amount currency="GBP">2.21</latest-fee-refund-amount>
  <latest-chargeback-fee-amount currency="GBP">10.00</latest-chargeback-fee-amount>
  <timestamp>2006-03-18T20:25:31</timestamp>
</chargeback-amount-notification>
}

    @example2_xml = %q{
<?xml version="1.0" encoding="UTF-8"?>
<chargeback-amount-notification xmlns="http://checkout.google.com/schema/2"
  serial-number="bea6bc1b-e1e2-44fe-80ff-0180e33a2614">
  <google-order-number>841171949013218</google-order-number>
  <latest-chargeback-amount currency="GBP">226.06</latest-chargeback-amount>
  <total-chargeback-amount currency="GBP">226.06</total-chargeback-amount>
  <timestamp>2006-03-18T20:25:31</timestamp>
</chargeback-amount-notification>
}

  end
  
  def test_create_from_element_works_correctly
    root = REXML::Document.new(@example_xml).root
    
    notification = ChargebackAmountNotification.create_from_element(root, @frontend)

    assert_equal 'bea6bc1b-e1e2-44fe-80ff-0180e33a2614', notification.serial_number
    assert_equal '841171949013218', notification.google_order_number
    assert_equal Time.parse('2006-03-18T20:25:31'), notification.timestamp
    assert_equal(Money.new(22606, 'GBP'), notification.total_chargeback_amount)
    assert_equal(Money.new(22606, 'GBP'), notification.latest_chargeback_amount)
    assert_equal(Money.new(221, 'GBP'), notification.latest_fee_refund_amount)
    assert_equal(Money.new(1000, 'GBP'), notification.latest_chargeback_fee_amount)
  end

  def test_create_from_minimal_element_works_correctly
    root = REXML::Document.new(@example2_xml).root
    
    notification = ChargebackAmountNotification.create_from_element(root, @frontend)

    assert_equal 'bea6bc1b-e1e2-44fe-80ff-0180e33a2614', notification.serial_number
    assert_equal '841171949013218', notification.google_order_number
    assert_equal Time.parse('2006-03-18T20:25:31'), notification.timestamp
    assert_equal(Money.new(22606, 'GBP'), notification.total_chargeback_amount)
    assert_equal(Money.new(22606, 'GBP'), notification.latest_chargeback_amount)
  end

end
