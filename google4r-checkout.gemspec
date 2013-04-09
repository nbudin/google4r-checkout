Gem::Specification.new do |gem|
  gem.platform = Gem::Platform::RUBY

  gem.name = "google4r-checkout"
  gem.summary = "Full-featured Google Checkout library for Ruby"
  gem.description = <<-EOF
  google4r-checkout is a lightweight, framework-agnostic Ruby library to access the Google Checkout service and implement 
  notification handlers. It exposes object-oriented wrappers for all of Google Checkout's API commands and notifications.
  EOF
  gem.version = "1.2.0"
  gem.authors = ["Tony Chan", "Dan Dukeson", "Nat Budin", "George Palmer", "Daniel Higham", "Johnathan Niziol", "Chris Parrish", "Larry Salibra", "Paul Schreiber", "Ben Hutton", "James Martin", "Jacob Comer", "Chance Downs"]
  gem.email = "natbudin@gmail.com"
  gem.homepage = "http://github.com/nbudin/google4r-checkout"

  gem.test_files = Dir['test/**/*_test.rb', 'test/test_helper.rb', 'test/frontend_configuration_example.rb'] 
  gem.files      = Dir['lib/**/*.rb', 'var/cacert.pem'] 
  gem.extra_rdoc_files = Dir['README.md','LICENSE', 'CHANGES'] 
  gem.files.reject! { |str| str =~ /^\./ } 
  
  gem.require_path = 'lib'
  gem.required_ruby_version = '>= 1.8.4'
  
  gem.add_dependency('money', '>= 2.3.0')
  gem.add_development_dependency('mocha')
  gem.add_development_dependency('nokogiri')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('pry')
end
