#--
# Project:   google_checkout4r 
# File:      test/unit/risk_info_notification_test.rb
# Author:    Dan Dukeson <dandukeson AT gmail.com>
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

# Test for the class Area.
class Google4R::Checkout::RiskInformationNotificationTest < Test::Unit::TestCase

  include Google4R::Checkout

  def setup

    @example_xml = %q{
    <?xml version="1.0" encoding="UTF-8"?>
<risk-information-notification xmlns="http://checkout.google.com/schema/2" serial-number="4f5adc5b-aac5-4618-9e3b-75e60eaf29cd">
  <timestamp>2007-04-30T08:03:57.000Z</timestamp>
  <google-order-number>1564645586934214</google-order-number>
  <risk-information>
    <billing-address>
      <contact-name>Mr Contact Smith</contact-name>
      <company-name>ACME Products</company-name>
      <email>contact_smith@example.com</email>
      <phone>012345 234567</phone>
      <fax>012345 345678</fax>
      <address1>123 Testing Road</address1>
      <address2>Test Village</address2>
      <country-code>GB</country-code>
      <city>Testcity</city>
      <region>South Testshire</region>
      <postal-code>S6 1TT</postal-code>
    </billing-address>
    <ip-address>123.456.123.456</ip-address>
    <avs-response>Y</avs-response>
    <cvn-response>M</cvn-response>
    <eligible-for-protection>true</eligible-for-protection>
    <partial-cc-number>6789</partial-cc-number>
    <buyer-account-age>61</buyer-account-age>
  </risk-information>
</risk-information-notification>
}

    frontend = Frontend.new(FRONTEND_CONFIGURATION)
    root_element = REXML::Document.new(@example_xml).root

    @risk = RiskInformationNotification.create_from_element(root_element, frontend)

  end

  def test_xml_parsing_works   
    root = REXML::Document.new(@example_xml).root
    assert_equal '4f5adc5b-aac5-4618-9e3b-75e60eaf29cd', root.attributes['serial-number']
  end

  def test_serial_accessor

    @risk.serial_number = 'e4r'
    assert_equal 'e4r', @risk.serial_number
  end

  def test_risk_not_nil
    assert_not_nil @risk
  end

  def test_serial_number
    assert_equal '4f5adc5b-aac5-4618-9e3b-75e60eaf29cd', @risk.serial_number
  end

  def test_google_order_number
    assert_equal '1564645586934214', @risk.google_order_number
  end

  def test_eligible_protection
    assert_equal true, @risk.eligible_for_protection
  end

  def test_buyer_billing_address
    # address has its own unit tests, just check we have an address
    assert @risk.buyer_billing_address        
  end

  def test_avs_response
    assert_equal 'Y', @risk.avs_response
  end

  def test_cvn_response
    assert_equal 'M', @risk.cvn_response
  end

  def test_partial_card_number
    assert_equal 6789, @risk.partial_card_number
  end

  def test_ip_address
    assert_equal '123.456.123.456', @risk.ip_address
  end

  def test_buyer_account_age
    assert_equal 61, @risk.buyer_account_age
  end

  def test_timestamp
    assert_equal Time.parse('2007-04-30T08:03:57.000Z'), @risk.timestamp
  end

end
