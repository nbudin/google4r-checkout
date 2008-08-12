#--
# Project:   google_checkout4r 
# File:      test/unit/digital_content_test.rb
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

# Tests for the ShipItemsCommand class.
class Google4R::Checkout::DigitalContentTest < Test::Unit::TestCase
  include Google4R::Checkout

  def setup
    @frontend = Frontend.new(FRONTEND_CONFIGURATION)
    @frontend.tax_table_factory = TestTaxTableFactory.new
    
    @email_delivery_str = %q{<?xml version="1.0" encoding="UTF-8" ?>
<digital-content>
  <display-disposition>OPTIMISTIC</display-disposition>
  <email-delivery>true</email-delivery>
</digital-content>}

    @key_url_delivery_str = %q{<?xml version="1.0" encoding="UTF-8" ?>
<digital-content>
  <display-disposition>PESSIMISTIC</display-disposition>
  <description>
    Please go to &amp;lt;a href=&quot;http://supersoft.example.com&quot;&amp;gt;our website&amp;lt;/a&amp;gt;,
    and enter your access key so that you can download our software.
  </description>
  <key>1456-1514-3657-2198</key>
  <url>http://supersoft.example.com</url>
</digital-content>}

    @description_delivery_str = %q{<?xml version="1.0" encoding="UTF-8" ?>
<digital-content>
  <display-disposition>OPTIMISTIC</display-disposition>
  <description>
    It may take up to 24 hours to process your new storage. You will
    be able to see your increased storage on your 
    &amp;lt;a href=&quot;http://login.example.com&quot;&amp;gt;account page&amp;lt;/a&amp;gt;.
  </description>
</digital-content>}

    
    @optional_tags = [ 'merchant-item-id', 'merchant-private-item-data', 'tax-table-selector' ]

    @command = @frontend.create_checkout_command
    @shopping_cart = @command.shopping_cart
    @item = @shopping_cart.create_item
    @item.create_digital_content
  end

  def test_behaves_correctly
    [ :description, :description=, :display_disposition,
      :display_disposition=, :email_delivery,
      :email_delivery=, :key, :key=, :url, :url= ].each do |symbol|
      assert_respond_to @item.digital_content, symbol
    end
  end
  
  def test_create_from_element_works
    digital_content = Item::DigitalContent.create_from_element(REXML::Document.new(@email_delivery_str).root)
    assert_equal 'OPTIMISTIC', digital_content.display_disposition
    assert_equal "true", digital_content.email_delivery
    
    digital_content = Item::DigitalContent.create_from_element(REXML::Document.new(@key_url_delivery_str).root)
    assert_equal 'PESSIMISTIC', digital_content.display_disposition
    assert_nil digital_content.email_delivery
    assert_equal '1456-1514-3657-2198', digital_content.key
    assert_equal 'http://supersoft.example.com', digital_content.url
    
    digital_content = Item::DigitalContent.create_from_element(REXML::Document.new(@description_delivery_str).root)
    assert_equal 'OPTIMISTIC', digital_content.display_disposition
    assert_nospace_equal %q{It may take up to 24 hours to process your new
    storage. You will be able to see your increased storage on your &amp;lt;a
    href=&quot;http://login.example.com&quot;&amp;gt;account page&amp;lt;/a&amp;gt;.},
    REXML::Text.new(digital_content.description).to_s
  end

end
