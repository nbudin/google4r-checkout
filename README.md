# google4r/checkout

google4r/checkout is a library to access the Google Checkout API.

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

## Dependencies

The unit tests use Mocha so you have to install the gem "mocha" to run the tests. You will also need the money gem library.

## How To: Freeze a google4r version in a Rails project

<code>rake rails:freeze:gems</code> only works for the Rails gems. So, how do you freeze your own gems like google4r? It turns out to be pretty straightforward:

    cd RAILS_ROOT
    cd vendor
    gem unpack google4r-checkout
    ls 
    # ... google4r-checkout-0.1.1 ...

Then, open RAILS_ROOT/config/environment.rb in your favourite text editor and add the following lines at the top of the file just below <code>require File.join(File.dirname(__FILE__), 'boot')</code>:

    # Freeze non-Rails gem.
    Dir.glob(File.join(RAILS_ROOT, 'vendor', '*', 'lib')) do |path|
      $LOAD_PATH << path
    end

Now you can use the following in your own code:

    require 'google4r/checkout'
