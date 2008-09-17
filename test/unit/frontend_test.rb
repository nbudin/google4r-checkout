#--
# Project:   google_checkout4r 
# File:      test/unit/frontend_test.rb
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

# Test for the class Area and all of its subclasses.
class Google4R::Checkout::FrontendTest < Test::Unit::TestCase
  include Google4R::Checkout
  
  def setup
    @frontend = Frontend.new(FRONTEND_CONFIGURATION)
    @frontend.tax_table_factory = TestTaxTableFactory.new
  end
  
  def test_initialized_correctly
    assert_equal FRONTEND_CONFIGURATION.dup, @frontend.configuration
    assert @frontend.configuration.frozen?
  end
  
  def test_frontend_behaves_correctly
    [ :configuration, :tax_table_factory, :tax_table_factory=,
      :create_notification_handler, :create_callback_handler,
      :create_deliver_order_command, :create_charge_order_command,
      :create_checkout_command, :create_cancel_order_command,
      :create_refund_order_command, :create_send_buyer_message_command,
      :create_authorize_order_command, :create_add_merchant_order_number_command,
      :create_add_tracking_data_command, :create_archive_order_command,
      :create_unarchive_order_command, :create_ship_items_command,
      :create_backorder_items_command, :create_return_items_command,
      :create_cancel_items_command, :create_reset_items_shipping_information_command,
      :create_order_report_command
    ].each do |symbol|
      assert_respond_to @frontend, symbol
    end
  end
  
  def test_create_notification_handler_works_correctly
    assert_kind_of NotificationHandler, @frontend.create_notification_handler
  end
  
  def test_create_callback_handler_works_correctly
    assert_kind_of CallbackHandler, @frontend.create_callback_handler
  end

  def test_create_deliver_order_command_works_correctly
    assert_kind_of DeliverOrderCommand, @frontend.create_deliver_order_command
  end
  
  def test_create_charge_order_command_works_correctly
    assert_kind_of ChargeOrderCommand, @frontend.create_charge_order_command
  end
  
  def test_create_checkout_command_works_correctly
    assert_kind_of CheckoutCommand, @frontend.create_checkout_command
  end

  def test_create_cancel_order_command_works_correctly
    assert_kind_of CancelOrderCommand, @frontend.create_cancel_order_command
  end
  
  def test_create_refund_order_command_works_correctly
    assert_kind_of RefundOrderCommand, @frontend.create_refund_order_command
  end
  
  def test_create_send_buyer_message_command_works_correctly
    assert_kind_of SendBuyerMessageCommand, @frontend.create_send_buyer_message_command
  end
  
  def test_create_authorize_order_command_works_correctly
    assert_kind_of AuthorizeOrderCommand, @frontend.create_authorize_order_command
  end
  
  def test_create_add_merchant_order_number_command_works_correctly
    assert_kind_of AddMerchantOrderNumberCommand, @frontend.create_add_merchant_order_number_command
  end
  
  def test_create_add_tracking_data_command_works_correctly
    assert_kind_of AddTrackingDataCommand, @frontend.create_add_tracking_data_command
  end
  
  def test_create_archive_order_command_works_correctly
    assert_kind_of ArchiveOrderCommand, @frontend.create_archive_order_command
  end
  
  def test_create_unarchive_order_command_works_correctly
    assert_kind_of UnarchiveOrderCommand, @frontend.create_unarchive_order_command
  end
  
  def test_create_ship_items_command_works_correctly
    assert_kind_of ShipItemsCommand, @frontend.create_ship_items_command
  end
  
  def test_create_backorder_items_command_works_correctly
    assert_kind_of BackorderItemsCommand, @frontend.create_backorder_items_command
  end
  
  def test_create_return_items_command_works_correctly
    assert_kind_of ReturnItemsCommand, @frontend.create_return_items_command
  end
  
  def test_create_cancel_items_command_works_correctly
    assert_kind_of CancelItemsCommand, @frontend.create_cancel_items_command
  end
  
  def test_create_reset_items_shipping_information_command_works_correctly
    assert_kind_of ResetItemsShippingInformationCommand, 
        @frontend.create_reset_items_shipping_information_command
  end

  def test_create_order_report_command_works_correctly
    assert_kind_of OrderReportCommand,
        @frontend.create_order_report_command(
            Time.utc(2007, 9, 1, 0, 0, 0),
            Time.utc(2007, 9, 30, 23, 59, 59))
  end
end
