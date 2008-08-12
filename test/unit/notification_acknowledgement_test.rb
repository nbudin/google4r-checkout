#--
# Project:   google_checkout4r 
# File:      test/unit/notification_acknowledgement_test.rb
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
#++

require File.expand_path(File.dirname(__FILE__)) + '/../test_helper'

require 'google4r/checkout'

require 'test/frontend_configuration'

# Test for the class NotificationAcknowledgement.
class Google4R::Checkout::NotificationAcknowledgementTest < Test::Unit::TestCase
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
  <timestamp>2006-03-18T20:25:31</timestamp>
</chargeback-amount-notification>
}
  end
    
  def test_to_xml_works_as_expected
    ack = NotificationAcknowledgement.new
    str = %q{<?xml version='1.0' encoding='UTF-8'?><notification-acknowledgment xmlns='http://checkout.google.com/schema/2'/>}
    assert_equal str, ack.to_xml
  end
  
  def test_to_xml_with_serial_number
    root = REXML::Document.new(@example_xml).root
    notification = ChargebackAmountNotification.create_from_element(root, @frontend)
    ack = NotificationAcknowledgement.new(notification)
    str = %q{<?xml version='1.0' encoding='UTF-8'?><notification-acknowledgment serial-number='bea6bc1b-e1e2-44fe-80ff-0180e33a2614' xmlns='http://checkout.google.com/schema/2'/>}
    assert_equal str, ack.to_xml
  end
end