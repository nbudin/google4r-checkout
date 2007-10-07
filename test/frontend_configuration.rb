  # Uncomment the following line if you are using Google Checkout in Great Britain
  # and adjust it if you want to test google4r-checkout against any other (future)
  # Google Checkout service.
  
  # Money.default_currency = 'GBP'
  
  # The test configuration for the Google4R::Checkout::Frontend class.
  FRONTEND_CONFIGURATION = 
    { 
      :merchant_id => '', 
      :merchant_key => '',
      :use_sandbox => true
    }