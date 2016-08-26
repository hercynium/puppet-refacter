# rubocop: disable Style/HashSyntax
source 'https://rubygems.org'

gem 'rake'
gem 'rspec', '~> 3.1.0', :require => false
gem 'puppetlabs_spec_helper', :require => false

if (puppetversion = ENV['PUPPET_GEM_VERSION'])
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end
