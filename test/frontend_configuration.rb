  # We've created a google4r-checkout test account on Google Checkout's sandbox.
  # This is used for running automated tests.
  #
  # If you'd rather use your own Google account instead, you can change the
  # details below.

  # Uncomment the following line if you are using Google Checkout in Great Britain
  # and adjust it if you want to test google4r-checkout against any other (future)
  # Google Checkout service.
  
  # Money.default_currency = 'GBP'
  
  # The test configuration for the Google4R::Checkout::Frontend class.
  FRONTEND_CONFIGURATION = 
    { 
      :merchant_id => '853049939003362', 
      :merchant_key => 'Kfn6q1_7zM-KC4jKWa5KDg',
      :use_sandbox => true
    }
