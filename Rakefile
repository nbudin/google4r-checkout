# google4r-checkout Rakefile

require 'bundler'
Bundler.setup

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run all tests tests.'
task :default => :'test:all'

desc 'Runs all tests (alias of test:all)'
task :test => :'test:all'

#
# Documentation
#

desc 'Generate documentation for the google4r library.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'docs'
  rdoc.title    = 'google4r/checkout'
  rdoc.main     = 'README.md'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files = FileList['lib/**/*.rb'] + FileList['README.md','LICENSE', 'CHANGES'] 
end

#
# Test, test, test! I love saying the word "test"!
#

desc 'Run all tests on the Google4R::Checkout::* classes.'
task :test => ["test:all"]

namespace :test do
  desc 'Run all tests on the Google4R::Checkout::* classes.'
  task :all do
    errors = %w(unit integration system).collect do |task|
      begin
        Rake::Task["test:#{task}"].invoke
        nil
      rescue => e
        task
      end
    end.compact
    abort "Errors running #{errors.join(", ")}!" if errors.any? 
  end  
  
  desc 'Run unit tests on the Google4R::Checkout::* classes.'
  Rake::TestTask.new(:unit) do |t|
    t.libs << 'lib'
    t.test_files = FileList['test/unit/*_test.rb']
    t.verbose = true
  end

  desc 'Run integration tests on the Google4R::Checkout::* classes.'
  Rake::TestTask.new(:integration) do |t|
    t.libs << 'lib'
    t.test_files = FileList['test/integration/*_test.rb']
    t.verbose = true
  end

  desc 'Run system tests on the Google4R::Checkout::* classes.'
  Rake::TestTask.new(:system) do |t|
    t.libs << 'lib'
    t.test_files = FileList['test/system/*_test.rb']
    t.verbose = true
  end
end
