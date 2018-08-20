source ENV['GEM_SOURCE'] || 'https://rubygems.org'

group :test do
  gem 'metadata-json-lint',                  :require => false
  gem 'puppet-blacksmith',                   :require => false
  gem 'rubocop-rspec', '~> 1.6',             :require => false if RUBY_VERSION >= '2.3.0'
  gem 'rspec-puppet', '~> 2.5',              :require => false
  gem 'puppetlabs_spec_helper', '~> 1.2.2',  :require => false
end

group :development do
  gem 'travis',       :require => false
  gem 'travis-lint',  :require => false
end

ENV['PUPPET_VERSION'].nil? ? puppetversion = '~> 4.0' : puppetversion = ENV['PUPPET_VERSION'].to_s
gem 'puppet', puppetversion, :require => false, :groups => [:test]
