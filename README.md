# google4r/checkout [![Build Status](https://secure.travis-ci.org/nbudin/google4r-checkout.png)](http://travis-ci.org/nbudin/google4r-checkout)

google4r/checkout is a library to access the Google Checkout API.

It currently supports version 2.3 of the API and subscription beta API.

### License

google4r itself is distributed under an MIT style license.

However, the library includes the [cacert.pem](http://curl.haxx.se/ca/cacert.pem) file from the Mozilla project. This file is distributed under the [MPL](http://www.mozilla.org/MPL/).

### Installing

Gems are hosted on rubygems.org (aka Gemcutter), so on reasonably recent versions of Rubygems, you should be able to install just like this:

    gem install google4r-checkout

Or, go to [our page on rubygems.org](http://rubygems.org/gems/google4r-checkout).

### Issue Tracking and Wiki

Our issue tracker and wiki can be found [on Google Code](http://code.google.com/p/google-checkout-ruby-sample-code/).  The best way to let us know about bugs or feature requests is to report an issue there.

### Documentation

We've got RDoc documentation for the google4r-checkout library [generated on rdoc.info](http://rdoc.info/projects/nbudin/google4r-checkout).

You can find more information on the Google Checkout API [here](http://code.google.com/apis/checkout/developer/index.html). Note that the API documentation assumes an understanding of the Google Checkout XML API.

## Google Checkout Tests

You have to place a file called 'frontend_configuration.rb' in the directory'test' with the configuration for the Google4R::Checkout::Frontend class to use for running the tests.

The file should contain content similar to:

    # Uncomment the following line if you are using Google Checkout in Great Britain
    # and adjust it if you want to test google4r-checkout against any other (future)
    # Google Checkout service.
    
    # Money.default_currency = 'GBP'
    
    # The test configuration for the Google4R::Checkout::Frontend class.
    FRONTEND_CONFIGURATION = 
      { 
        :merchant_id => '<your merchant id>', 
        :merchant_key => '<your merchant key>',
        :use_sandbox => true
      }

## Sending Commands to Google Checkout

To send commands to Google Checkout, use a Google4R::Checkout::Frontend object.  The Frontend class contains a variety of methods for easily generating several types of commands, including checkout, cancel_order, charge_and_ship_order, etc.

Here's an example:

      # Create the Frontend from our configuration
      frontend = Google4R::Checkout::Frontend.new(
        :merchant_id => conf['merchant_id'],
        :merchant_key => conf['merchant_key'],
        :use_sandbox => conf['use_sandbox']
      )
      
      # Create a new checkout command (to place an order)
      cmd = frontend.create_checkout_command
      
      # Add an item to the command's shopping cart
      cmd.shopping_cart.create_item do |item|
        item.name = "2-liter bottle of Diet Pepsi"
        item.quantity = 100
        item.unit_price = Money.new(1.99, "USD")
      end
      
      # Send the command to Google and capture the HTTP response
      response = cmd.send_to_google_checkout
      
      # Redirect the user to Google Checkout to complete the transaction
      redirect_to response.redirect_url

For more information, see the Frontend class's RDocs and the Google Checkout API documentation.

## Writing Responders

To receive notifications from Google Checkout, you'll need to write an action in your web application to respond to Google Checkout XML requests.  The basic strategy for this is to use a NotificationHandler object (which can be obtained through a Frontend object) to parse the HTTP request, then handle the resulting Notification object according to its class.  You should then generate a NotificationAcknowledgment and return it as the response.

It's a good idea to verify the HTTP authentication headers for incoming requests.  This will be a combination of your Merchant ID and Merchant Key.

Here is an example of how one might do this in Rails:

    class PaymentNotificationController < ApplicationController
      before_filter :verify_merchant_credentials, :only => [:google]
  
      def google
        frontend = Google4R::Checkout::Frontend.new(
          :merchant_id => conf['merchant_id'],
          :merchant_key => conf['merchant_key'],
          :use_sandbox => conf['use_sandbox']
        )
        handler = frontend.create_notification_handler
        
        begin
           notification = handler.handle(request.raw_post) # raw_post contains the XML
        rescue Google4R::Checkout::UnknownNotificationType
           # This can happen if Google adds new commands and Google4R has not been
           # upgraded yet. It is not fatal.
           logger.warn "Unknown notification type"
           return render :text => 'ignoring unknown notification type', :status => 200
        end
        
        case notification
        when Google4R::Checkout::NewOrderNotification then
          
          # handle a NewOrderNotification
          
        when Google4R::Checkout::OrderStateChangeNotification then
          
          # handle an OrderStateChangeNotification
          
        else
          return head :text => "I don't know how to handle a #{notification.class}", :status => 500
        end
    
        notification_acknowledgement = Google4R::Checkout::NotificationAcknowledgement.new(notification)
        render :xml => notification_acknowledgement, :status => 200
      end
  
      private
      # make sure the request authentication headers use the right merchant_id and merchant_key
      def verify_merchant_credentials
        authenticate_or_request_with_http_basic("Google Checkout notification endpoint") do |merchant_id, merchant_key|
          (conf['merchant_id'].to_s == merchant_id.to_s) and (conf['merchant_key'].to_s == merchant_key.to_s)
        end
      end
    end

## Dependencies

google4r-checkout makes extensive use of the money gem library, which is a required dependency.  The unit tests also use Mocha and Nokogiri, which should be automatically pulled down by Bundler.

google4r-checkout doesn't depend on any particular Ruby web framework, so it should work with any version of Rails, Sinatra, Camping, or even no web framework at all.
