#--
# Project:   google4r
# File:      lib/google4r/checkout/xml_generation.rb
# Authors:   Manuel Holtgrewe <purestorm at ggnore dot net>
#            Tony Chan <api.htchan at gmail dot com>
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
# This file contains the classes that allow to persist the object hierarchies
# that are created with the Google Checkout API to XML.

require 'stringio'
require 'rexml/document'
require 'time'

module Google4R #:nodoc:
  module Checkout #:nodoc:
    
    class XmlGenerator
      def initialize()
        raise 'Cannot instantiate an abstract class.'
      end
      
      # Base method to generate the XML for a particular command
      def generate
        @document = REXML::Document.new
        
        declaration = REXML::XMLDecl.new
        declaration.encoding = 'utf-8'
        @document << declaration
      end
    end
    
    # Abstract super class for all CommandXmlGenerators
    # It should never be instantiated directly
    class CommandXmlGenerator < XmlGenerator
      
      # The list of command tag names
      COMMAND_TO_TAG =
      {
        ChargeAndShipOrderCommand => "charge-and-ship-order",
        ChargeOrderCommand => 'charge-order',
        RefundOrderCommand => 'refund-order',
        CancelOrderCommand => 'cancel-order',
        AuthorizeOrderCommand => 'authorize-order',
        ProcessOrderCommand => 'process-order',
        AddMerchantOrderNumberCommand => 'add-merchant-order-number',
        DeliverOrderCommand  => 'deliver-order',
        AddTrackingDataCommand => 'add-tracking-data',
        SendBuyerMessageCommand => 'send-buyer-message',
        ArchiveOrderCommand => 'archive-order',
        UnarchiveOrderCommand => 'unarchive-order',
        CreateOrderRecurrenceRequestCommand => 'create-order-recurrence-request',
        ShipItemsCommand => 'ship-items',
        BackorderItemsCommand => 'backorder-items',
        CancelItemsCommand => 'cancel-items',
        ReturnItemsCommand => 'return-items',
        ResetItemsShippingInformationCommand => 'reset-items-shipping-information',
        OrderReportCommand => 'order-list-request',
        NotificationHistoryRequestCommand => 'notification-history-request',
      }
      
      def initialize(command)
        if COMMAND_TO_TAG.has_key?(command.class)
          @command = command
        else
          raise 'Cannot instantiate an abstract class.'
        end
      end
      
      # Base method to generate the XML for a particular command
      def generate
        super
        self.process_command(@command)
        io = StringIO.new
        @document.write(io, -1)
        return io.string
      end

      def tag_name_for_command(klass)
        COMMAND_TO_TAG[klass]
      end
      
      protected
            
      # Base method to generate root tag of a command
      def process_command(command)
        tag_name = self.tag_name_for_command(command.class)
        root = @document.add_element(tag_name)
        root.add_attribute('google-order-number', command.google_order_number)
        root.add_attribute('xmlns', 'http://checkout.google.com/schema/2')
        return root
      end
    end
    
    # Use the CheckoutXmlGenerator to create an XML document from a CheckoutCommand
    # object.
    #
    # Usage:
    #
    #   checkout = CheckoutCommand.new
    #   # set up the CheckoutCommand
    #   
    #   generator = CheckoutCommandXmlGenerator.new(checkout)
    #   puts generator.generate # => "<xml? version=..."
    #   File.new('some.xml', 'w') { |f| f.write generator.generate }
    #--
    # TODO: Refactor the big, monolitic generator into smaller, easier testable ones. One for each major part of the resulting XML document. This will also reduce the overhead in generating other types of XML documents.
    #++
    class CheckoutCommandXmlGenerator < CommandXmlGenerator
      
      def initialize(command)
        @command = command
      end
      
      protected
      
      def process_command(command)
        root = @document.add_element("checkout-shopping-cart" , { 'xmlns' => 'http://checkout.google.com/schema/2' })
        
        self.process_shopping_shopping_cart(root, command.shopping_cart)
        
        # <merchant-checkout-flow-support>
        flow_element = root.add_element('checkout-flow-support').add_element('merchant-checkout-flow-support')

        # <tax-tables>
        if command.tax_tables then
          self.process_tax_tables(command.tax_tables, flow_element)
        end

        # <continue-shopping-url>
        if not command.continue_shopping_url.nil? then
          flow_element.add_element('continue-shopping-url').text = command.continue_shopping_url
        end
        
        # <edit-cart-url>
        if not command.edit_cart_url.nil? then
          flow_element.add_element('edit-cart-url').text = command.edit_cart_url
        end
        
        # <request-buyer-phone-number>
        if not command.request_buyer_phone_number.nil? then
          flow_element.add_element('request-buyer-phone-number').text =
            if command.request_buyer_phone_number then
              "true"
            else
              "false"
            end
        end
       
        # <merchant-calculations>
        if not command.merchant_calculations_url.nil? then
          merchant_calculations = flow_element.add_element('merchant-calculations')
          merchant_calculations.add_element('merchant-calculations-url').text =
            command.merchant_calculations_url
          if not command.accept_merchant_coupons.nil? then
            merchant_calculations.add_element('accept-merchant-coupons').text =
              command.accept_merchant_coupons.to_s
          end
          if not command.accept_gift_certificates.nil? then
            merchant_calculations.add_element('accept-gift-certificates').text =
              command.accept_gift_certificates.to_s
          end
        end
        
        # <platform-id>
        if not command.platform_id.nil? then
          flow_element.add_element('platform-id').text = command.platform_id
        end
        
        # <shipping-methods>
        shippings_element = flow_element.add_element('shipping-methods')
        command.shipping_methods.each do |shipping_method|
          self.process_shipping_method(shippings_element, shipping_method)
        end

        # <analytics-data>
        unless command.analytics_data.nil? then
          analytics_element = flow_element.add_element('analytics-data')
          analytics_element.text = command.analytics_data
        end
        
        # <parameterized-urls>
        if command.parameterized_urls then
          parameterized_url_element = flow_element.add_element('parameterized-urls')
          command.parameterized_urls.each do |parameterized_url|
            self.process_parameterized_urls(parameterized_url, parameterized_url_element)
          end
        end 
      end
      
      # adds the tax-tables to the parent xml element
      # assumes that the first member of the tax_tables array is the default tax rule table
      # and that all others are alternate tax rules
      def process_tax_tables(tax_tables, parent)
        tax_tables_element = parent.add_element('tax-tables')
        
        # assumes that the first tax table is the default
        default_table = tax_tables.first
        
        if default_table.merchant_calculated
          tax_tables_element.add_attribute('merchant-calculated', 'true')
        else
          tax_tables_element.add_attribute('merchant-calculated', 'false') 
        end

        default_table_element = tax_tables_element.add_element('default-tax-table')
        rules_element = default_table_element.add_element('tax-rules')

        default_table.rules.each do |rule|
          default_rule_element = rules_element.add_element('default-tax-rule')
          default_rule_element.add_element('shipping-taxed').text=rule.shipping_taxed.to_s
          default_rule_element.add_element('rate').text=rule.rate.to_s
          self.process_area(default_rule_element.add_element('tax-area'), rule.area)
        end

        # populate alternate tax tables
        alt_tables = tax_tables.last(tax_tables.length-1)
        alt_tables_element = tax_tables_element.add_element('alternate-tax-tables')

        alt_tables.each do |table|
          table_element = alt_tables_element.add_element('alternate-tax-table')
          table_element.add_attribute('name', table.name)
          table_element.add_attribute('standalone', table.standalone.to_s)

          rules_element = table_element.add_element('alternate-tax-rules')
          table.rules.each do |rule|
            alt_rule_element = rules_element.add_element('alternate-tax-rule')
            alt_rule_element.add_element('rate').text=rule.rate.to_s

            self.process_area(alt_rule_element.add_element('tax-area'), rule.area)
          end
        end         
      end


      def process_shopping_shopping_cart(parent, shopping_cart)
        cart_element = parent.add_element('shopping-cart')
        
        # add <cart-expiration> tag to the cart if a time has been added to the cart
        if not shopping_cart.expires_at.nil? then
          cart_element.add_element('cart-expiration').add_element('good-until-date').text =
            shopping_cart.expires_at.iso8601
        end
        
        # add <merchant-private-data> to the cart if any has been set
        if not shopping_cart.private_data.nil? then
          self.process_hash(cart_element.add_element('merchant-private-data'), shopping_cart.private_data)
        end
        
        # process the items in the cart
        items_element = cart_element.add_element('items')
        shopping_cart.items.each do |item|
          self.process_item(items_element, item)
        end
      end
      
      # Adds an <item> tag to the tag parent with the appropriate values.
      def process_item(parent, item)
        item_element = parent.add_element('item')
        
        item_element.add_element('item-name').text = item.name
        item_element.add_element('item-description').text = item.description
        
        item_element.add_element('unit-price', { 'currency' => item.unit_price.currency.to_s }).text = item.unit_price.to_s
        item_element.add_element('quantity').text = item.quantity.to_i
        
        if not item.id.nil? then
          item_element.add_element('merchant-item-id').text = item.id 
        end
        
        if not item.weight.nil? then
          item_element.add_element('item-weight', 
              { 'unit' => item.weight.unit,
                'value' => item.weight.value })
        end
        
        if not item.private_data.nil? then
          self.process_hash(item_element.add_element('merchant-private-item-data'), item.private_data)
        end
        
        # The above was easy; now we need to get the appropriate tax table for this
        # item. The Item class makes sure that the table exists.
        if not item.tax_table.nil? then
          item_element.add_element('tax-table-selector').text = item.tax_table.name
        end
        
        if not item.digital_content.nil? then
          self.process_digital_content(item_element, item.digital_content)
        end
        
        if not (item.kind_of? Item::Subscription::RecurrentItem || item.subscription.nil?) then
          self.process_subscription(item_element, item.subscription)
        end
      end
      
      # Adds a <subscription> element to a parent (<item>) element
      def process_subscription(parent, subscription)
        subscription_element = parent.add_element('subscription')
        
        if not subscription.no_charge_after.nil? then
          subscription_element.attributes['no-charge-after'] = subscription.no_charge_after.xmlschema
        end
        
        if not subscription.period.nil? then
          subscription_element.attributes['period'] = subscription.period.to_s
        end
        
        if not subscription.start_date.nil? then
          subscription_element.attributes['start-date'] = subscription.start_date.xmlschema
        end
        
        if not subscription.type.nil? then
          subscription_element.attributes['type'] = subscription.type.to_s
        end
        
        if subscription.payments.length > 0
          payments_element = subscription_element.add_element('payments')
          
          subscription.payments.each do |payment|
            self.process_subscription_payment(payments_element, payment)
          end
        end
        
        if subscription.recurrent_items.length > 0
          # this is a little bit of a hack; we use the normal way of generating items
          # for a shopping cart, and then rename the elements to 'recurrent-item'
          # after the fact
          
          subscription.recurrent_items.each do |item|
            self.process_item(subscription_element, item)
          end
          
          subscription_element.elements.each('item') do |item_element|
            item_element.name = 'recurrent-item'
          end
        end
      end
      
      # Adds a <subcription-payment> element to a parent (<payments>) element
      def process_subscription_payment(parent, payment)
        payment_element = parent.add_element('subscription-payment')
        
        if not payment.times.nil? then
          payment_element.attributes['times'] = payment.times.to_s
        end
        
        if not payment.maximum_charge.nil? then
          payment_element.add_element('maximum-charge', { 'currency' => payment.maximum_charge.currency.to_s }).text = payment.maximum_charge.to_s
        end
      end
      
      # Adds a <digital-content> element to a parent (<item>) element
      def process_digital_content(parent, digital_content)
        digital_content_element = parent.add_element('digital-content')

        if not digital_content.description.nil? then
          digital_content_element.add_element('description').text = digital_content.description.to_s
        end

        if not digital_content.email_delivery.nil? then
          digital_content_element.add_element('email-delivery').text = digital_content.email_delivery.to_s
        end

        if not digital_content.key.nil? then
          digital_content_element.add_element('key').text = digital_content.key.to_s
        end

        if not digital_content.url.nil? then
          digital_content_element.add_element('url').text = digital_content.url.to_s
        end

        digital_content_element.add_element('display-disposition').text = digital_content.display_disposition.to_s
      end
      
      # Adds an item for the given shipping method.
      def process_shipping_method(parent, shipping_method)
        if shipping_method.kind_of? PickupShipping then
          process_pickup(parent, shipping_method)
        elsif shipping_method.kind_of? FlatRateShipping then
          process_shipping('flat-rate-shipping', parent, shipping_method)
        elsif shipping_method.kind_of? MerchantCalculatedShipping then
          process_shipping('merchant-calculated-shipping', parent, shipping_method)
        elsif shipping_method.kind_of? CarrierCalculatedShipping then
          process_carrier_calculated_shipping('carrier-calculated-shipping', parent, shipping_method)
        else
          raise "Unknown ShippingMethod type of #{shipping_method.inspect}!"
        end
      end
      
      def process_shipping(shipping_type, parent, shipping)
        element = parent.add_element(shipping_type)
        element.add_attribute('name', shipping.name)
        element.add_element('price', { 'currency' => shipping.price.currency.to_s }).text = shipping.price.to_s
        
        if shipping.shipping_restrictions_excluded_areas.length + 
           shipping.shipping_restrictions_allowed_areas.length > 0 then
          shipping_restrictions_tag = element.add_element('shipping-restrictions')
          
          allow_us_po_box = shipping_restrictions_tag.add_element('allow-us-po-box')
          if shipping.shipping_restrictions_allow_us_po_box
            allow_us_po_box.text = 'true'
          else
            allow_us_po_box.text = 'false'
          end          
          
          if shipping.shipping_restrictions_allowed_areas.length > 0 then
            allowed_tag = shipping_restrictions_tag.add_element('allowed-areas')
            
            shipping.shipping_restrictions_allowed_areas.each do |area|
              self.process_area(allowed_tag, area)
            end
          end
        
          if shipping.shipping_restrictions_excluded_areas.length > 0 then
            excluded_tag = shipping_restrictions_tag.add_element('excluded-areas')

            shipping.shipping_restrictions_excluded_areas.each do |area|
              self.process_area(excluded_tag, area)
            end
          end
        end

        if shipping.kind_of? MerchantCalculatedShipping then
          if shipping.address_filters_excluded_areas.length + 
             shipping.address_filters_allowed_areas.length > 0 then
            address_filters_tag = element.add_element('address-filters')
            
            allow_us_po_box = address_filters_tag.add_element('allow-us-po-box')
            if shipping.address_filters_allow_us_po_box
              allow_us_po_box.text = 'true'
            else
              allow_us_po_box.text = 'false'
            end
            
            if shipping.address_filters_allowed_areas.length > 0 then
              allowed_tag = address_filters_tag.add_element('allowed-areas')
              
              shipping.address_filters_allowed_areas.each do |area|
                self.process_area(allowed_tag, area)
              end
            end
          
            if shipping.address_filters_excluded_areas.length > 0 then
              excluded_tag = address_filters_tag.add_element('excluded-areas')
  
              shipping.address_filters_excluded_areas.each do |area|
                self.process_area(excluded_tag, area)
              end
            end
          end
        end
      end
      
      def process_pickup(parent, shipping)
        element = parent.add_element('pickup')
        element.add_attribute('name', shipping.name)
        element.add_element('price', { 'currency' => shipping.price.currency.to_s }).text = shipping.price.to_s
      end
      
      def process_carrier_calculated_shipping(shipping_type, parent, shipping)
        element = parent.add_element(shipping_type)
        options_element = element.add_element('carrier-calculated-shipping-options')
        packages_element = element.add_element('shipping-packages')
        shipping.carrier_calculated_shipping_options.each do | option |
          process_carrier_calculated_shipping_option(options_element, option)
        end
        shipping.shipping_packages.each do | package |
          process_shipping_package(packages_element, package)
        end
      end
      
      def process_carrier_calculated_shipping_option(parent, option)
        element = parent.add_element('carrier-calculated-shipping-option')
        element.add_element('price', { 'currency' => option.price.currency.to_s }).text = option.price.to_s
        element.add_element('shipping-company').text = option.shipping_company
        element.add_element('shipping-type').text = option.shipping_type
        if not option.carrier_pickup.nil?
          element.add_element('carrier-pickup').text = option.carrier_pickup
        end
        if not option.additional_fixed_charge.nil?
          element.add_element('additional-fixed-charge', 
              { 'currency' => option.additional_fixed_charge.currency.to_s }).text = 
              option.additional_fixed_charge.to_s
        end
        if not option.additional_variable_charge_percent.nil?
          element.add_element('additional-variable-charge-percent').text = 
              option.additional_variable_charge_percent.to_s
        end
      end
      
      def process_shipping_package(parent, package)
        element = parent.add_element('shipping-package')
        ship_from = package.ship_from
        ship_from_element = element.add_element('ship-from')
        ship_from_element.add_attribute('id', ship_from.address_id)
        ship_from_element.add_element('city').text = ship_from.city
        ship_from_element.add_element('region').text = ship_from.region
        ship_from_element.add_element('country-code').text = ship_from.country_code
        ship_from_element.add_element('postal-code').text = ship_from.postal_code
        if not package.delivery_address_category.nil?
          element.add_element('delivery-address-category').text = 
              package.delivery_address_category
        end
        if not package.height.nil?
          height_element = element.add_element('height')
          height_element.add_attribute('unit', package.height.unit)
          height_element.add_attribute('value', package.height.value.to_s)
        end
        if not package.length.nil?
          length_element = element.add_element('length')
          length_element.add_attribute('unit', package.length.unit)
          length_element.add_attribute('value', package.length.value.to_s)
        end
        if not package.width.nil?
          width_element = element.add_element('width')
          width_element.add_attribute('unit', package.width.unit)
          width_element.add_attribute('value', package.width.value.to_s)
        end
      end
      
      # Adds an appropriate tag for the given Area subclass instance to the parent Element.
      def process_area(parent, area)
        if area.kind_of? UsZipArea then
          parent.add_element('us-zip-area').add_element('zip-pattern').text = area.pattern
        elsif area.kind_of? UsCountryArea then
          parent.add_element('us-country-area', { 'country-area' => area.area })
        elsif area.kind_of? UsStateArea then
          parent.add_element('us-state-area').add_element('state').text = area.state
        elsif area.kind_of? WorldArea then
          parent.add_element('world-area')
        elsif area.kind_of? PostalArea then
          postal_area_element = parent.add_element('postal-area')
          postal_area_element.add_element('country-code').text = area.country_code
          if area.postal_code_pattern then
            postal_area_element.add_element('postal-code-pattern').text = area.postal_code_pattern
          end
        else
          raise "Area of unknown type: #{area.inspect}."
        end
      end
      
      # Adda the paramterized URL nodes for 3rd party conversion tracking
      # Adds a <paramertized-url> element to a parent (<parameterized-urls>) element      
      def process_parameterized_urls(parameterized_url, parent)
        parameterized_url_node = parent.add_element('parameterized-url')
        parameterized_url_node.add_attribute('url', parameterized_url.url)
        parent_parameters_node = parameterized_url_node.add_element('parameters') if parameterized_url.url_parameters
        parameterized_url.url_parameters.each do |parameter|
          parameter_node = parent_parameters_node.add_element('url-parameter')
          parameter_node.add_attribute('name', parameter.name)
          parameter_node.add_attribute('type',parameter.parameter_type)
        end        
      end
      
      # Converts a Hash into an XML structure. The keys are converted to tag names. If
      # the values are Hashs themselves then process_hash is called upon them. If the
      # values are Arrays then a new element with the key's name will be created.
      #
      # If a value is an Array then this array will be flattened before it is processed.
      # Thus, nested arrays are not allowed.
      #
      # === Example
      #
      #   process_hash(parent, { 'foo' => { 'bar' => 'baz' } })
      #   
      #   # will produce a structure that is equivalent to.
      #
      #   <foo>
      #     <bar>baz</bar>
      #   </foo>
      #
      #
      #   process_hash(parent, { 'foo' => [ { 'bar' => 'baz' }, "d'oh", 2 ] })
      #   
      #   # will produce a structure that is equivalent to.
      #
      #   <foo>
      #     <bar>baz</bar>
      #   </foo>
      #   <foo>d&amp;</foo>
      #   <foo>2</foo>
      def process_hash(parent, hash)
        hash.each do |key, value|
          if value.kind_of? Array then
            value.flatten.each do |arr_entry|
              if arr_entry.kind_of? Hash then
                self.process_hash(parent.add_element(self.str2tag_name(key.to_s)), arr_entry)
              else
                parent.add_element(self.str2tag_name(key.to_s)).text = arr_entry.to_s
              end
            end
          elsif value.kind_of? Hash then
            process_hash(parent.add_element(self.str2tag_name(key.to_s)), value)
          else
            parent.add_element(self.str2tag_name(key.to_s)).text = value.to_s
          end
        end
      end
      
      # Converts a string to a valid XML tag name. Whitespace will be converted into a dash/minus
      # sign, non alphanumeric characters that are neither "-" nor "_" nor ":" will be stripped.
      def str2tag_name(str)
        str.gsub(%r{\s}, '-').gsub(%r{[^a-zA-Z0-9\-\_:]}, '')
      end
    end

    class ChargeOrderCommandXmlGenerator < CommandXmlGenerator
      
      protected

      def process_command(command)
        root = super
        process_money(root, command.amount) if command.amount
      end

      # add the amount element to the charge command
      def process_money(parent, money)
        amount_element = parent.add_element('amount')
        amount_element.text = money.to_s
        amount_element.add_attribute('currency', money.currency.to_s)
      end
    end
    
    class ChargeAndShipOrderCommandXmlGenerator < CommandXmlGenerator
      
      protected
      
      def process_command(command)
        root = super
        process_money(root, command.amount) if command.amount
        process_tracking_data(root, command.carrier, command.tracking_number)
        root.add_element('send-email').text = command.send_email.to_s if command.send_email
      end
      
      def process_money(parent, money)
        amount_element = parent.add_element('amount')
        amount_element.text = money.to_s
        amount_element.add_attribute('currency', money.currency.to_s)
      end

      def process_tracking_data(parent, carrier, tracking_number)
        if carrier && tracking_number then
          e1 = parent.add_element('tracking-data-list')
          e2 = e1.add_element('tracking-data')
          e2.add_element('carrier').text = carrier
          e2.add_element('tracking-number').text = tracking_number
        end
      end
    end

    class RefundOrderCommandXmlGenerator < CommandXmlGenerator

      protected

      def process_command(command)
        root = super
        process_money(root, command.amount) if command.amount
        process_comment(root, command.comment) if command.comment
        process_reason(root, command.reason)
      end

      # add the amount element to the refund command
      def process_money(parent, money)
        amount_element = parent.add_element('amount')
        amount_element.text = money.to_s
        amount_element.add_attribute('currency', money.currency.to_s)
      end
      
      # add the comment element to the refund command
      def process_comment(parent, comment)
        comment_element = parent.add_element('comment')
        comment_element.text = comment
      end
      
      # add the reason element to the refund command
      def process_reason(parent, reason)
        reason_element = parent.add_element('reason')
        reason_element.text = reason
      end
    end
    
    class CancelOrderCommandXmlGenerator < CommandXmlGenerator

      protected

      def process_command(command)
        root = super
        root.add_element('reason').text = command.reason
        
        if command.comment then
          root.add_element('comment').text = command.comment
        end
      end

    end

    class AuthorizeOrderCommandXmlGenerator < CommandXmlGenerator

      protected

      def process_command(command)        
        super
      end
    end
 
    class ProcessOrderCommandXmlGenerator < CommandXmlGenerator

      protected

      def process_command(command)        
        super
      end
    end

    class AddMerchantOrderNumberCommandXmlGenerator < CommandXmlGenerator

      protected

      def process_command(command)        
        root = super
        process_merchant_order_number(root, command.merchant_order_number)
      end
      
      def process_merchant_order_number(parent, merchant_order_number)
        merchant_order_number_element = parent.add_element('merchant-order-number')
        merchant_order_number_element.text = merchant_order_number
      end
    end
    
    class DeliverOrderCommandXmlGenerator < CommandXmlGenerator

      protected

      def process_command(command)        
        root = super
        # Add tracking info
        process_tracking_data(root, command.carrier, command.tracking_number)
        root.add_element('send-email').text = command.send_email.to_s
      end

      def process_tracking_data(parent, carrier, tracking_number)
        if carrier && tracking_number then
          element = parent.add_element('tracking-data')
          element.add_element('carrier').text = carrier
          element.add_element('tracking-number').text = tracking_number
        end
      end
    end
    
    class AddTrackingDataCommandXmlGenerator < CommandXmlGenerator
      
      protected
      
      def process_command(command)
        root = super
        # Add tracking info
        process_tracking_data(root, command.carrier, command.tracking_number)
      end
      
      def process_tracking_data(parent, carrier, tracking_number)
        if carrier && tracking_number then
          element = parent.add_element('tracking-data')
          element.add_element('carrier').text = carrier
          element.add_element('tracking-number').text = tracking_number
        end
      end
    end
    
    class SendBuyerMessageCommandXmlGenerator < CommandXmlGenerator
      
      protected

      def process_command(command)        
        root = super
        root.add_element('message').text = command.message
        if not command.send_email.nil? then
          root.add_element('send-email').text = command.send_email.to_s
        end
      end
    end
    
    class ArchiveOrderCommandXmlGenerator < CommandXmlGenerator

      protected

      def process_command(command)        
        super
      end
    end
    
    class UnarchiveOrderCommandXmlGenerator < CommandXmlGenerator

      protected

      def process_command(command)        
        super
      end
    end
    
    class CreateOrderRecurrenceRequestCommandXmlGenerator < CheckoutCommandXmlGenerator
      
      protected
      
      def process_command(command)
        root = @document.add_element("create-order-recurrence-request" , { 'xmlns' => 'http://checkout.google.com/schema/2' })
        
        root.attributes['google-order-number'] = command.google_order_number
        
        self.process_shopping_shopping_cart(root, command.shopping_cart)
      end
    end
    
    class MerchantCalculationResultsXmlGenerator < XmlGenerator
      
      def initialize(merchant_calculation_results)
        @merchant_calculation_results = merchant_calculation_results
      end
      
      def generate()
        super
        process_results(@merchant_calculation_results.merchant_calculation_results)
        io = StringIO.new
        @document.write(io, -1)
        return io.string
      end
      
      protected
      
      def process_results(merchant_calculation_results)
        root = @document.add_element("merchant-calculation-results" , { 'xmlns' => 'http://checkout.google.com/schema/2' })
        results = root.add_element("results")
        for merchant_calculation_result in merchant_calculation_results do
          process_result(results, merchant_calculation_result)
        end
      end
      
      def process_result(parent, merchant_calculation_result)
        element = parent.add_element("result")
        element.add_attribute("shipping-name", merchant_calculation_result.shipping_name)
        element.add_attribute("address-id", merchant_calculation_result.address_id)
        shipping_rate = element.add_element("shipping-rate")
        shipping_rate.text = merchant_calculation_result.shipping_rate.to_s
        shipping_rate.add_attribute("currency", merchant_calculation_result.shipping_rate.currency.to_s)
        element.add_element("shippable").text = merchant_calculation_result.shippable.to_s
        if (!merchant_calculation_result.total_tax.nil?)
          total_tax = element.add_element("total-tax")
          total_tax.text = merchant_calculation_result.total_tax.to_s
          total_tax.add_attribute("currency", merchant_calculation_result.total_tax.currency.to_s)
        end
        process_code_results(element, merchant_calculation_result.merchant_code_results)
      end
      
      def process_code_results(parent, merchant_code_results)
        element = parent.add_element("merchant-code-results")
        for merchant_code_result in merchant_code_results do
          process_merchant_code_result(element, merchant_code_result)
        end
      end
      
      def process_merchant_code_result(parent, merchant_code_result)
        if merchant_code_result.kind_of?(CouponResult)
          element = parent.add_element("coupon-result")
        elsif merchant_code_result.kind_of?(GiftCertificateResult)
          element = parent.add_element("gift-certificate-result")
        else
          raise "Code of unknown type: #{merchant_code_result.inspect}."
        end
        element.add_element("valid").text = merchant_code_result.valid.to_s
        element.add_element("code").text = merchant_code_result.code.to_s
        calculated_amount = element.add_element("calculated-amount")
        calculated_amount.text = merchant_code_result.calculated_amount.to_s
        calculated_amount.add_attribute("currency", merchant_code_result.calculated_amount.currency.to_s)
        element.add_element("message").text = merchant_code_result.message
      end
    end

    class NotificationAcknowledgementXmlGenerator < XmlGenerator
      
      def initialize(notification_acknowledgement)
        @notification_acknowledgement = notification_acknowledgement
      end

      def generate
        super
        self.process_notification_acknowledgement(@notification_acknowledgement) 
        io = StringIO.new
        @document.write(io, -1)
        return io.string
      end

      def process_notification_acknowledgement(notification_acknowledgement)
        root = @document.add_element('notification-acknowledgment')
        root.add_attribute('xmlns', 'http://checkout.google.com/schema/2')
        if not notification_acknowledgement.serial_number.nil?
          root.add_attribute('serial-number', notification_acknowledgement.serial_number)
        end
      end
    end

    # Line-item shipping commands
    class ItemsCommandXmlGenerator < CommandXmlGenerator
      protected
      
      def process_command(command)
        root = super
        process_item_info_arr(root, command.item_info_arr)
        process_send_email(root, command.send_email)
        return root
      end
      
      def process_item_info_arr(parent, item_info_arr)
        element = parent.add_element('item-ids')
        item_info_arr.each do |item_info|
          item_id = element.add_element('item-id')
          item_id.add_element('merchant-item-id').text = 
              item_info.merchant_item_id
        end
      end
      
      def process_send_email(parent, send_email)
        parent.add_element('send-email').text = send_email.to_s
      end
    end
    
    class ShipItemsCommandXmlGenerator < ItemsCommandXmlGenerator
      protected

      def process_item_info_arr(parent, item_info_arr)
        e1 = parent.add_element('item-shipping-information-list')
        item_info_arr.each do |item_info|
          e2 = e1.add_element('item-shipping-information')
          item_id = e2.add_element('item-id')
          item_id.add_element('merchant-item-id').text = 
              item_info.merchant_item_id
          if !item_info.tracking_data_arr.nil?
            e3 = e2.add_element('tracking-data-list')
            item_info.tracking_data_arr.each do |tracking_data|
              e4 = e3.add_element('tracking-data')
              e4.add_element('carrier').text = tracking_data.carrier
              e4.add_element('tracking-number').text = 
                  tracking_data.tracking_number
            end
          end
        end
      end
    end
    
    class BackorderItemsCommandXmlGenerator < ItemsCommandXmlGenerator
    end
    
    class CancelItemsCommandXmlGenerator < ItemsCommandXmlGenerator
      protected
      
      def process_command(command)
        root = super
        root.add_element('reason').text = command.reason
        
        if command.comment then
          root.add_element('comment').text = command.comment
        end
      end
    end
    
    class ReturnItemsCommandXmlGenerator < ItemsCommandXmlGenerator
    end
    
    class ResetItemsShippingInformationCommandXmlGenerator < ItemsCommandXmlGenerator
    end

    class ReturnOrderReportCommandXmlGenerator < CommandXmlGenerator
      def initialize(command)
        @command = command
      end
      
      protected
      
      def process_command(command)
        root = super
        # TODO - sanity check format ?
        root.add_attribute('start-date', command.start_date.to_s)
        root.add_attribute('end-date', command.end_date.to_s)
        flow_element = root

        # <financial-state>
        if command.financial_state then
          financial_state_element = flow_element.add_element('financial-state')
          financial_state_element.text = command.financial_state.to_s
        end
        
        # <fulfillment-state>
        if command.fulfillment_state then
          fulfillment_state_element = flow_element.add_element('fulfillment-state')
          fulfillment_state_element.text = command.fulfillment_state.to_s
        end
        
        # <date-time-zone>
        if command.date_time_zone then
          dtz_element = flow_element.add_element('date-time-zone')
          dtz_element.text = command.date_time_zone.to_s
        end
      end
    end

    class NotificationHistoryReportCommandXmlGenerator < CommandXmlGenerator

      def initialize(command)
        @command = command
      end

      protected

      def process_command(command)
        root = super

        if command.serial_number
          element = root.add_element('serial-number')
          element.text = command.serial_number
        end

        if command.start_time
          element = root.add_element('start-time')
          element.text = command.start_time.xmlschema
        end

        if command.end_time
          element = root.add_element('end-time')
          element.text = command.end_time.xmlschema
        end

        if command.notification_types.present?
          nt_element = root.add_element('notification-types')
          command.notification_types.each do |notification_type|
            element = nt_element.add_element('notification-type')
            element.text = notification_type
          end
        end

        if command.order_numbers.present?
          on_element = root.add_element('order-numbers')
          command.order_numbers.each do |order_number|
            element = on_element.add_element('google-order-number')
            element.text = order_number
          end
        end

        if command.next_page_token
          element = root.add_element('next-page-token')
          element.text = command.next_page_token
        end

      end
    end
  end
end
