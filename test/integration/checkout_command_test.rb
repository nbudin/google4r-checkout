#--
# Project:   google_checkout4r 
# File:      test/checkout/integration/checkout_command.rb
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

# Integration tests for the CheckoutCommand class.
#
# Tests the CheckoutCommand class against the Google Checkout Web Service.
class Google4R::Checkout::CheckoutCommandIntegrationTest < Test::Unit::TestCase
  include Google4R::Checkout

  def setup
    @frontend = Frontend.new(FRONTEND_CONFIGURATION)
    @frontend.tax_table_factory = TestTaxTableFactory.new
    @command = @frontend.create_checkout_command
  end
  
  def test_sending_to_google_works_with_valid_request
    setup_command(@command)
    result = @command.send_to_google_checkout
    assert_kind_of CheckoutRedirectResponse, result
  end
  
  def test_sending_to_google_works_with_merchant_calculated_shipping
    setup_command(@command, MerchantCalculatedShipping)
    result = @command.send_to_google_checkout
    assert_kind_of CheckoutRedirectResponse, result
  end
  
  def test_sending_to_google_works_with_carrier_calculated_shipping
    setup_command(@command, CarrierCalculatedShipping)
    result = @command.send_to_google_checkout
    # Uncomment the two lines below to see the shopping cart xml and
    # the redirect URL
    #puts @command.to_xml
    #puts result
    assert_kind_of CheckoutRedirectResponse, result
  end
  
  def test_using_invalid_credentials_raise_google_checkout_error
    invalid_patches = [ [ :merchant_id, 'invalid' ], [ :merchant_key, 'invalid' ] ]
    
    invalid_patches.each do |patch|
      config = FRONTEND_CONFIGURATION.dup
      config[patch[0]] = patch[1]
      @frontend = Frontend.new(config)
      @frontend.tax_table_factory = TestTaxTableFactory.new
      @command = @frontend.create_checkout_command

      setup_command(@command)
      assert_raises(GoogleCheckoutError) { @command.send_to_google_checkout }
    end
  end
  
  def test_invalid_xml_raises_google_checkout_error
    class << @command
      def to_xml
        ''
      end
    end
    
    setup_command(@command)
    assert_raises(GoogleCheckoutError) { @command.send_to_google_checkout }
  end
  
  protected
  
  # Sets up the given CheckoutCommand so it contains some
  # shipping methods and its cart contains some items.
  def setup_command(command, shipping_type=FlatRateShipping)
    
    if shipping_type == FlatRateShipping
      # Add shipping methods.
      command.create_shipping_method(FlatRateShipping) do |shipping|
        shipping.name = 'UPS Ground Shipping'
        shipping.price = Money.new(2000) # USD 20, GPB 20, etc.
        shipping.create_allowed_area(UsCountryArea) do |area|
          area.area = UsCountryArea::ALL
        end
      end
    end
    
    if shipping_type == MerchantCalculatedShipping
      command.merchant_calculations_url = 'http://www.example.com'
      
      command.create_shipping_method(MerchantCalculatedShipping) do |shipping|
        shipping.name = 'International Shipping'
        shipping.price = Money.new(2000)
        shipping.create_address_filters_allowed_area(PostalArea) do |area|
          area.country_code = 'US'
          area.postal_code_pattern = '12*'
        end
      end
    end
    
    if shipping_type == CarrierCalculatedShipping
      command.create_shipping_method(CarrierCalculatedShipping) do |shipping|
        shipping.create_carrier_calculated_shipping_option do | option |
          option.shipping_company = 
              CarrierCalculatedShipping::CarrierCalculatedShippingOption::FEDEX
          option.price = Money.new(3000)
          option.shipping_type = 'Priority Overnight'
          option.carrier_pickup = 'REGULAR_PICKUP'
          option.additional_fixed_charge = Money.new(500)
          option.additional_variable_charge_percent = 15.5
        end
        shipping.create_shipping_package do | package |
          ship_from = AnonymousAddress.new
          ship_from.address_id = 'ABC'
          ship_from.city = 'Ann Arbor'
          ship_from.region = 'MI'
          ship_from.country_code = 'US'
          ship_from.postal_code = '48104'
          package.ship_from = ship_from
          package.delivery_address_category = 
              CarrierCalculatedShipping::ShippingPackage::COMMERCIAL
          package.height = Dimension.new(1)
          package.length = Dimension.new(2)
          package.width = Dimension.new(3)
        end
      end
    end
    
    # Add items to the cart.
    1.upto(5) do |i|
      command.shopping_cart.create_item do |item|
        item.name = "Test Item #{i}"
        item.description = "This is a test item (#{i})"
        item.unit_price = Money.new(350)
        item.quantity = i * 3
        item.id = "test-#{i}-123456789"
        item.weight = Weight.new(2.2)
        if (i == 5)
          item.create_digital_content do |dc|
            dc.display_disposition = 
                Google4R::Checkout::Item::DigitalContent::OPTIMISTIC
            dc.description = "Information on how to get your content"
            dc.url = "http://my.domain.com/downloads"
            dc.key = "abcde12345"
            dc.email_delivery = false
          end
        end
      end
    end
  end
end