#--
# Project:   google4r
# File:      lib/google4r/checkout/commands.rb 
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
# This file contains the classes and modules that are used by the command
# generating code.

require 'openssl'
require 'money'
require 'net/http'
require 'net/https'
require 'uri'

module Google4R #:nodoc:
  module Checkout #:nodoc:
    # Abstract super class for all commands that are to be sent to Google. Provides the base
    # functionality for signing and encoding the cart.
    class Command
      # The URL to use for requests to the sandboxed API. The merchant id is to be
      # put in via String#%.
      SANDBOX_URL_PREFIX = 'https://sandbox.google.com/checkout/'
      
      # The URL to use for real requests to the Google Checkout API. The merchant id
      # is to be put in via String#%.
      PRODUCTION_URL_PREFIX = 'https://checkout.google.com/'
      
      # Orders
      CHECKOUT_API_URL = 'api/checkout/v2/merchantCheckout/Merchant/%s'
      ORDER_PROCESSING_API_URL = 'api/checkout/v2/request/Merchant/%s'
      ORDER_REPORT_API_URL = 'api/checkout/v2/reports/Merchant/%s'
      POLLING_API_URL = 'api/checkout/v2/reports/Merchant/%s'

      # Donations
      DONATE_CHECKOUT_API_URL = 'api/checkout/v2/merchantCheckout/Donations/%s'
      DONATE_ORDER_PROCESSING_API_URL = 'api/checkout/v2/request/Donations/%s'
      DONATE_ORDER_REPORT_API_URL = 'api/checkout/v2/reports/Donations/%s'

      
      # The Frontent class that was used to create this CheckoutCommand and whose
      # configuration will be used.
      attr_reader :frontend
      
      # The tag name of the command
      attr_reader :command_tag_name
      
      # The google order number, required, String
      attr_accessor :google_order_number

      # Initialize the frontend attribute with the value of the frontend parameter.
      def initialize(frontend)
        if self.instance_of?(Command) || self.instance_of?(ItemsCommand)
          raise 'Cannot instantiate abstract class ' + self.class.to_s
        end
        @frontend = frontend
      end

      # Sends the cart's XML to GoogleCheckout via HTTPs with Basic Auth.
      #
      # Raises an OpenSSL::SSL::SSLError when the SSL certificate verification failed.
      #
      # Raises a GoogleCheckoutError when Google returns an error.
      #
      # Raises a RuntimeException on unknown responses.
      #--
      # TODO: The send-and-expect-response part should be adaptable to other commands and responses.
      #++
      def send_to_google_checkout
        xml_response = (self.class == OrderReportCommand) ? false : true        
        # Create HTTP(S) POST command and set up Basic Authentication.
        url_str = 
          if frontend.configuration[:use_sandbox] then
            SANDBOX_URL_PREFIX
          else
            PRODUCTION_URL_PREFIX
          end
        url_str += 
          if frontend.configuration[:purchase_type] == :donation
            if self.class == CheckoutCommand then
              DONATE_CHECKOUT_API_URL
            elsif self.class == OrderReportCommand || self.class == NotificationHistoryRequestCommand then
              DONATE_ORDER_REPORT_API_URL
            else
              DONATE_ORDER_PROCESSING_API_URL
            end
          else
            if self.class == CheckoutCommand then
              CHECKOUT_API_URL
            elsif self.class == OrderReportCommand || self.class == NotificationHistoryRequestCommand then
              ORDER_REPORT_API_URL
            elsif self.class == NotificationDataRequestCommand || self.class == NotificationDataTokenRequestCommand then
              POLLING_API_URL
            else
              ORDER_PROCESSING_API_URL
            end
          end
        url_str = url_str % frontend.configuration[:merchant_id]

        url = URI.parse(url_str)
        
        request = Net::HTTP::Post.new(url.path)
        request.basic_auth(frontend.configuration[:merchant_id], frontend.configuration[:merchant_key])

        # Set up the HTTP connection object and the SSL layer.
        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        https.cert_store = self.class.x509_store
        https.verify_mode = OpenSSL::SSL::VERIFY_PEER
        https.verify_depth = 5
        https.verify_callback = Proc.new do |ok, ctx|
          domain = ctx.chain.first.subject.to_a.select { |part| part.first == "CN" }.first[1]
          
          domain == if frontend.configuration[:use_sandbox]
            "sandbox.google.com"
          else
            "checkout.google.com"
          end
        end

        # Send the request to Google.
        result = https.request(request, self.to_xml)
        
        case result
        when Net::HTTPSuccess then
          if ( xml_response ) then
            xml_doc = REXML::Document.new(result.body)
             
            case xml_doc.root.name
            when 'checkout-redirect'
                serial_number = xml_doc.elements['/checkout-redirect'].attributes['serial-number']
                redirect_url = xml_doc.elements['/checkout-redirect/redirect-url/text()'].value
                return CheckoutRedirectResponse.new(serial_number, redirect_url)
            when 'request-received'
                serial_number = xml_doc.elements['/request-received'].attributes['serial-number']
                return serial_number
            # report history notifications
            when 'order-summary'
                raise 'Response type OrderSummaryResponse not implemented'
            when 'new-order-notification'
                return NewOrderNotification.create_from_element xml_doc.root, @frontend
            when 'risk-information-notification'
                return RiskInformationNotification.create_from_element xml_doc.root, @frontend
            when 'order-state-change-notification'
                return OrderStateChangeNotification.create_from_element xml_doc.root, @frontend
            when 'charge-amount-notification'
                return ChargeAmountNotification.create_from_element xml_doc.root, @frontend
            when 'authorization-amount-notification'
                return AuthorizationAmountNotification.create_from_element xml_doc.root, @frontend
            when 'refund-amount-notification'
                return RefundAmountNotification.create_from_element xml_doc.root, @frontend
            when 'chargeback-amount-notification'
                return ChargebackAmountNotification.create_from_element xml_doc.root, @frontend
            when 'notification-history-response'
                next_page_token = xml_doc.root.elements['next-page-token'].try(:value)
                notifications = xml_doc.root.elements['notifications'].elements.map do |element| 
                  case element.name
                    when 'new-order-notification'
                      NewOrderNotification.create_from_element element, @frontend
                    when 'risk-information-notification'
                      RiskInformationNotification.create_from_element element, @frontend
                    when 'order-state-change-notification'
                      OrderStateChangeNotification.create_from_element element, @frontend
                    when 'charge-amount-notification'
                      ChargeAmountNotification.create_from_element element, @frontend
                    when 'authorization-amount-notification'
                      AuthorizationAmountNotification.create_from_element element, @frontend
                    when 'refund-amount-notification'
                      RefundAmountNotification.create_from_element element, @frontend
                    when 'chargeback-amount-notification'
                      ChargebackAmountNotification.create_from_element element, @frontend
                  end
                end
                { :notifications => notifications, :next_page_token => next_page_token }
              when 'notification-data-token-response'
                serial_number = xml_doc.elements['/notification-data-token-response'].attributes['serial-number']
                continue_token = xml_doc.root.elements['continue-token/text()'].value
                { :continue_token => continue_token, :serial_number => serial_number}
              when 'notification-data-response'
                serial_number = xml_doc.elements['/notification-data-response'].attributes['serial-number']
                continue_token = xml_doc.root.elements['continue-token/text()'].value
                has_more_notifications = xml_doc.root.elements['has-more-notifications/text()'].value
                notifications = xml_doc.root.elements['notifications'].elements.map do |element|
                  case element.name
                    when 'new-order-notification'
                      NewOrderNotification.create_from_element element, @frontend
                    when 'risk-information-notification'
                      RiskInformationNotification.create_from_element element, @frontend
                    when 'order-state-change-notification'
                      OrderStateChangeNotification.create_from_element element, @frontend
                    when 'charge-amount-notification'
                      ChargeAmountNotification.create_from_element element, @frontend
                    when 'authorization-amount-notification'
                      AuthorizationAmountNotification.create_from_element element, @frontend
                    when 'refund-amount-notification'
                      RefundAmountNotification.create_from_element element, @frontend
                    when 'chargeback-amount-notification'
                      ChargebackAmountNotification.create_from_element element, @frontend
                  end
                end
                { :notifications => notifications, :continue_token => continue_token, :serial_number => serial_number, :has_more_notifications => has_more_notifications }
            else
                raise "Unknown response:\n--\n#{xml_doc.to_s}\n--"
            end
          else
            # handle the CSV output of the order-report-list command
            return result.body
          end
        when Net::HTTPClientError then
          xml_doc = REXML::Document.new(result.body)
          
          if xml_doc.elements['/error'].attributes['serial-number'].nil? or xml_doc.elements['/error/error-message/text()'].nil? then
            raise "Invalid response from Google:\n---\n#{result.body}\n---"
          end
          
          hash = 
            {
              :serial_number => xml_doc.elements['/error'].attributes['serial-number'],
              :message       => xml_doc.elements['/error/error-message/text()'].value
            }
          
          raise GoogleCheckoutError.new(hash)
        when Net::HTTPRedirection, Net::HTTPServerError, Net::HTTPInformation then
          raise "Unexpected reponse code (#{result.class}): #{result.code} - #{result.message}"
        else
          raise "Unknown reponse code: #{result.code} - #{result.message}"
        end
      end
      
      # Class method to return the command's XML representation.
      def to_xml
        generator_class = Google4R::Command.get_const("#{self.class}XmlGenerator")
        return generator_class.new(self).generate
      end
      
      protected
      
      # Class method to return the OpenSSL::X509::Store instance for the
      # CA certificates.
      #--
      # TODO: Is OpenSSL::X509::Store thread safe when reading only? This method most certainly is *not*. It must become so.
      #++
      def self.x509_store
        return @@x509_store if defined?(@@x509_store)
        
        cacert_path = File.expand_path(File.dirname(__FILE__) + '/../../../var/cacert.pem')
        
        @@x509_store = OpenSSL::X509::Store.new
        @@x509_store.add_file(cacert_path)
        
        return @@x509_store
      end
    end

    # The CheckoutCommand represents a <checkout-shopping-cart> command sent
    # to the server.
    #
    # A CheckoutCommand instance can have an arbitrary number of TaxTable
    # and ShippingMethod instances. You must create these instances using the
    # create_* methods which CheckoutCommand supplies.
    # 
    # CheckoutCommand#send_to_google_checkout returns CheckoutRedirectResponse 
    # instances.
    #
    # Use the Frontend class to create new CheckoutCommand instances and do not
    # instanciate the class directly.
    #
    # Note that you have to create/set the tax tables for CheckoutCommands before you
    # can add any items to the cart that define a tax table.
    #
    # === Example
    #
    #   frontend = Google4R::Checkout::Frontend.new(configuration)
    #   frontend.tax_table_factory = TaxTableFactory.new
    #   command = frontend.create_checkout_command
    class CheckoutCommand < Command
      # The ShoppingCart of this CheckoutCommand.
      attr_reader :shopping_cart
      
      # An array of the TaxTable objects of this CheckoutCommand. They have been
      # created with the tax table factory of the frontend which created this
      # command.
      attr_reader :tax_tables
      
      # An array of ShippingMethod objects of this CheckoutCommand. Use 
      # #create_shipping_method to create new shipping methods.
      attr_reader :shipping_methods
      
      attr_reader :parameterized_urls

      # The URL at where the cart can be edited (String, optional).
      attr_accessor :edit_cart_url
      
      # The URL to continue shopping after completing the checkout (String, optional).
      attr_accessor :continue_shopping_url
      
      # A boolean flag; true iff the customer HAS to provide his phone number (optional).
      attr_accessor :request_buyer_phone_number
      
      # The URL of the merchant calculation callback (optional).
      attr_accessor :merchant_calculations_url
      
      # A boolean flag to indicate whether merchant coupon is supported or not (optional).
      attr_accessor :accept_merchant_coupons

      # A boolean flag to indicate whether gift certificate is supported or not (optional).
      attr_accessor :accept_gift_certificates
      
      # A Google Checkout merchant ID that identifies the eCommerce provider.
      attr_accessor :platform_id

      # Setting this allows Google Analytics to track purchases that use Checkout
      # The value should be as set by the analytics javascript in the hidden form
      # element names "analyticsdata" on the page with the checkout button.
      # If left unset then the element will not be generated.
      # see: http://code.google.com/apis/checkout/developer/checkout_analytics_integration.html
      attr_accessor :analytics_data
      
      # Generates the XML for this CheckoutCommand.
      def to_xml
        CheckoutCommandXmlGenerator.new(self).generate
      end
      
      # Initialize a new CheckoutCommand with a fresh CheckoutCart and an empty
      # Array of tax tables and an empty array of ShippingMethod instances.
      # Do not use this method directly but use Frontent#create_checkout_command
      # to create CheckoutCommand objects.
      def initialize(frontend)
        super(frontend)
        @shopping_cart = ShoppingCart.new(self)
        @shipping_methods = Array.new
        @parameterized_urls = Array.new
        if frontend.tax_table_factory
          @tax_tables = frontend.tax_table_factory.effective_tax_tables_at(Time.new)
        end
      end
      
      # Use this method to create a new shipping method. You have to pass in one of
      # { PickupShipping, FlatRateShipping } for clazz. The method will create a 
      # new instance of the class you passedin object and add it to the internal list 
      # of shipping methods.
      #
      # If you pass a block to this method (preferred) then the newly created
      # ShippingMethod object will be passed into this block for setting its attributes.
      # The newly created shipping method will be returned in all cases.
      #
      # The first created shipping method will be used as the default.
      #
      # Raises a ArgumentError if the parameter clazz is invalid.
      def create_shipping_method(clazz, &block)
        if not [ PickupShipping, FlatRateShipping, 
                 MerchantCalculatedShipping, CarrierCalculatedShipping
               ].include?(clazz) then
          raise ArgumentError, "Unknown shipping method: #{clazz.inspect}."
        end
        
        shipping_method = clazz.new
        @shipping_methods << shipping_method

        yield(shipping_method) if block_given?
        
        return shipping_method
      end
      
      # Use this method to create a new parameterized_url object. It requires the URL
      # to be passed in the 'opts' hash. It will create a new instance of the 
      # paramterized URL object. 
      # 
      # Raises an argument error if the URL passed in the opts hash is not a String
      #
      # To find more information on 3rd party conversion tracking visit the API documentation
      # http://code.google.com/apis/checkout/developer/checkout_pixel_tracking.html 
      def create_parameterized_url(opts, &block)
        raise(ArgumentError, "Url option required") unless opts[:url].kind_of?(String)

        parameterized_url = ParameterizedUrl.new(opts[:url])
        @parameterized_urls << parameterized_url

        yield(parameterized_url) if block_given?

        return parameterized_url
      end
      
    end

    # CheckoutRedirectResponse instances are returned when a CheckoutCommand is successfully
    # processed by Google Checkout.
    class CheckoutRedirectResponse
      # The serial number of the <checkout-redirect> response.
      attr_reader :serial_number
      
      # The URL to redirect to.
      attr_reader :redirect_url
      
      # Create a new CheckoutRedirectResponse with the given serial number and redirection URL.
      # Do not create CheckoutRedirectResponse instances in your own code. Google4R creates them
      # for you.
      def initialize(serial_number, redirect_url)
        @serial_number = serial_number
        @redirect_url = redirect_url
      end
      
      def to_s
        return @redirect_url
      end
    end
    
    # SubscriptionRequestReceivedResponse instances are returned when a 
    # CreateOrderRecurrenceRequestCommand is successfully processed by Google Checkout.
    class SubscriptionRequestReceivedResponse
      # The serial number of the <subscription-request-received> response.
      attr_reader :serial_number
      
      # The new order number that was generated for this request.
      attr_reader :new_google_order_number
      
      # Create a new SubscriptionRequestReceivedResponse with the given serial number and Google
      # order number.  Do not create SubscriptionRequestReceivedResponse instances in your own
      # code.  Google4R creates them for you.
      def initialize(serial_number, new_google_order_number)
        @serial_number = serial_number
        @new_google_order_number = new_google_order_number
      end
      
      def to_s
        return @new_google_order_number
      end
    end

    #
    # The ChargeOrderCommand instructs Google Checkout to charge the buyer for a
    # particular order.
    #
    class ChargeOrderCommand < Command
      # The amount to charge, optional, Money
      attr_accessor :amount

      # Generates the XML for this ChargeOrderCommand
      def to_xml
        ChargeOrderCommandXmlGenerator.new(self).generate
      end
    end

    class ChargeAndShipOrderCommand < Command
      # The amount to charge, optional, Money
      attr_accessor :amount

      # if google checkout should email buyer to ssay order is dispatched
      attr_accessor :send_email
      
      # The name of the company responsible for shipping the item. Valid values
      # for this tag are DHL, FedEx, UPS, USPS and Other.
      attr_accessor :carrier
      
      # The shipper's tracking number that is associated with an order
      attr_accessor :tracking_number

      # Generates the XML for this ChargeOrderCommand
      def to_xml
        ChargeAndShipOrderCommandXmlGenerator.new(self).generate
      end      
    end

    # The RefundOrderCommand instructs Google Checkout to refund an order
    class RefundOrderCommand < Command
      # The amount to refund, optional, Money
      attr_accessor :amount
      
      # The reason that the order is to be refunded, String of maximum 140 characters, required
      attr_accessor :reason
      
      # A comment related to the refunded order, String of maximum 140 characters, optional
      attr_accessor :comment

      def to_xml
        RefundOrderCommandXmlGenerator.new(self).generate
      end
    end
    
    # The CancelOrderCommand instructs Google Checkout to cancel an order
    class CancelOrderCommand < Command
      # The reason that the order is to be cancelled, String of maximum 140 characters, required
      attr_accessor :reason
      
      # A comment related to the cancelled order, String of maximum 140 characters, optional
      attr_accessor :comment

      def to_xml
        CancelOrderCommandXmlGenerator.new(self).generate
      end
    end

    # The AuthorizeOrderCommand instructs Google Checkout to explicitly reauthorize
    # a customer's credit card for the uncharged balance of an order to verify that
    # funds for the order are available
    class AuthorizeOrderCommand < Command
      def to_xml
        AuthorizeOrderCommandXmlGenerator.new(self).generate
      end
    end
    
    # The ProcessOrderCommand instructs Google Checkout to to update
    # an order's fulfillment state from NEW to PROCESSING
    class ProcessOrderCommand < Command
      def to_xml
        ProcessOrderCommandXmlGenerator.new(self).generate
      end
    end

    # The AddMerchantOrderCommand instructs Google Checkout to associate a 
    # merchant-assigned order number with an order
    class AddMerchantOrderNumberCommand < Command
      # The merchant-assigned order number associated with an order
      attr_accessor :merchant_order_number

      def to_xml
        AddMerchantOrderNumberCommandXmlGenerator.new(self).generate
      end
    end
    
    # The DeliverOrderCommand indicates that Google should update an order's fulfillment order state to DELIVERED
    class DeliverOrderCommand < Command
      # if google checkout should email buyer to ssay order is dispatched
      attr_accessor :send_email
      
      # The name of the company responsible for shipping the item. Valid values
      # for this tag are DHL, FedEx, UPS, USPS and Other.
      attr_accessor :carrier
      
      # The shipper's tracking number that is associated with an order
      attr_accessor :tracking_number

      def to_xml
        DeliverOrderCommandXmlGenerator.new(self).generate
      end        
    end
    
    # The AddTrackingDataCommand instructs Google Checkout to associate a shipper's tracking number with an order.
    class AddTrackingDataCommand < Command
      # The name of the company responsible for shipping the item. Valid values
      # for this tag are DHL, FedEx, UPS, USPS and Other.
      attr_accessor :carrier
      
      # The shipper's tracking number that is associated with an order
      attr_accessor :tracking_number

      def to_xml
        AddTrackingDataCommandXmlGenerator.new(self).generate
      end        
    end
    
    # The SendBuyerMessageCommand instructs Google Checkout to place a message in the customer's Google Checkout account.
    class SendBuyerMessageCommand < Command
      # The message to the customer
      attr_accessor :message
      
      # if google checkout should email buyer to say order is dispatched
      attr_accessor :send_email

      def to_xml
        SendBuyerMessageCommandXmlGenerator.new(self).generate
      end        
    end
    
    # The ArchiveOrderCommand instructs Google Checkout to remove an order from your Merchant Center Inbox.
    class ArchiveOrderCommand < Command
      def to_xml
        ArchiveOrderCommandXmlGenerator.new(self).generate
      end
    end
      
    # The UnarchiveOrderCommand instructs Google Checkout to return a previously archived order to your Merchant Center Inbox.
    class UnarchiveOrderCommand < Command
      def to_xml
        UnarchiveOrderCommandXmlGenerator.new(self).generate
      end
    end
    
    # The <create-order-recurrence-request> tag contains a request to charge a customer for one or more items in a subscription.
    class CreateOrderRecurrenceRequestCommand < Command
      # The ID that uniquely identifies this order
      attr_accessor :google_order_number
      
      attr_reader :shopping_cart
      
      # Initialize a new CreateOrderRecurrenceRequestCommand with a fresh ShoppingCart.
      def initialize(frontend)
        super(frontend)
        @shopping_cart = ShoppingCart.new(self)
      end
      
      def to_xml
        CreateOrderRecurrenceRequestCommandXmlGenerator.new(self).generate
      end
    end
    
    #
    # XML API Commands for Line-item Shipping
    #

    # Abstract class for Line-item shipping commands
    class ItemsCommand < Command
      # An array of ItemInfo objects that you are marking as backordered,
      # cancelled, returned or resetting shipping information
      attr_accessor :item_info_arr
      
      # if google checkout should email buyer to say order is dispatched
      attr_accessor :send_email
      
      def initialize(frontend)
        super
        @item_info_arr = []
        @send_email = false
      end
    end

    # The <ship-items> command specifies shipping information for one or 
    # more items in an order.
    class ShipItemsCommand < ItemsCommand
      def to_xml
        ShipItemsCommandXmlGenerator.new(self).generate
      end
    end
    
    # The <backorder-items> command lets you specify that one or more
    # specific items in an order are out of stock.
    class BackorderItemsCommand < ItemsCommand
      def to_xml
        BackorderItemsCommandXmlGenerator.new(self).generate
      end
    end
    
    # The <cancel-items> command lets you specify that one or more
    # specific items in an order have been cancelled, meaning they 
    # will not be delivered to the customer.
    class CancelItemsCommand < ItemsCommand  
      # The reason that you are canceling one or more line items
      attr_accessor :reason
      
      # An optional comment related to one or more canceled line items
      attr_accessor :comment
      
      def to_xml
        CancelItemsCommandXmlGenerator.new(self).generate
      end
    end
    
    # The <return-items> command lets you specify that your customer
    # returned one or more specific items in an order.
    class ReturnItemsCommand < ItemsCommand
      def to_xml
        ReturnItemsCommandXmlGenerator.new(self).generate
      end
    end
    
    # The <reset-items-shipping-information> command allows you to reset
    # the shipping status for specific items in an order to "Not yet shipped".
    class ResetItemsShippingInformationCommand < ItemsCommand
      def to_xml
        ResetItemsShippingInformationCommandXmlGenerator.new(self).generate
      end
    end

    # The <order-list-request> command lets you to download a list of 
    # Google Checkout orders into a comma-separated file. 
    # The API will return a list of orders for a period of up to 31 days, 
    # and you can limit results to orders that have specific financial or 
    # fulfillment order states.
    # http://code.google.com/apis/checkout/developer/Google_Checkout_XML_API_Order_Report_API.html
    class OrderReportCommand < Command
      # The earliest time that an order could have been submitted to be
      # included in the API response (Time)
      attr_reader :start_date
      
      # The time before which an order must have been sent to be included
      # in the API response (Time)
      attr_reader :end_date
      
      # The financial status of an order
      attr_accessor :financial_state
      
      # The fulfillment status of an order
      attr_accessor :fulfillment_state
      
      # The time zone that will be associated with the start date and
      # end date for the report
      attr_accessor :date_time_zone
      
      def initialize(frontend, start_date, end_date)
        super frontend
        raise 'start_date has to be of type Time' unless start_date.class == Time
        raise 'end_date has to be of type Time' unless start_date.class == Time
        raise 'end_date has to be before start_date' unless
            end_date >= start_date
        @start_date = start_date
        @end_date = end_date
      end

      def start_date
        return @start_date.strftime('%Y-%m-%dT%H:%M:%S')
      end
      
      def end_date
        return @end_date.strftime('%Y-%m-%dT%H:%M:%S')
      end
      
      def financial_state=(financial_state)
        financial_state_name = financial_state.to_s
        
        raise 'Invalid financial state %s' % financial_state unless
            FinancialState.constants.any? { |state_name| state_name.to_s == financial_state_name }
        @financial_state = financial_state_name
      end
      
      def fulfillment_state=(fulfillment_state)
        fulfillment_state_name = fulfillment_state.to_s
        
        raise 'Invalid fulfillment state %s' % fulfillment_state unless
            FulfillmentState.constants.any? { |state_name| state_name.to_s == fulfillment_state_name }
        @fulfillment_state = fulfillment_state_name
      end
      
      def to_xml
        ReturnOrderReportCommandXmlGenerator.new(self).generate
      end
    end
    
    # The <notification-history-request> command allows you to receive
    # a notification type node refered to by the serial number posted by
    # google to the notification callback URL
    class NotificationHistoryRequestCommand < Command
      
      attr_reader :serial_number, :start_time, :end_time, :notification_types, :order_numbers, :next_page_token
      
      def initialize(frontend, args)
        super frontend

        if args.is_a? Hash
          @serial_number = args[:serial_number]
          @start_time = args[:start_time]
          @end_time = args[:end_time]
          @notification_types = args[:notification_types]
          @order_numbers = args[:order_numbers]
          @next_page_token = args[:next_page_token]
        else
          @serial_number = args
        end
      end
      
      def to_xml
        NotificationHistoryReportCommandXmlGenerator.new(self).generate
      end
    end


    class NotificationDataRequestCommand < Command

      attr_reader :continue_token

      def initialize(frontend, continue_token)
        super frontend

        @continue_token = continue_token
      end

      def to_xml
        NotificationDataRequestCommandXmlGenerator.new(self).generate
      end
    end


    class NotificationDataTokenRequestCommand < Command
      # The earliest time that an order could have been submitted to be
      # included in the API response (Time)
      attr_reader :start_time

      def initialize(frontend, options = {})
        super frontend
        @start_time = options[:start_time] if options.has_key?(:start_time)
      end

      def to_xml
        NotificationDataTokenRequestCommandXmlGenerator.new(self).generate
      end
    end
  end
end
