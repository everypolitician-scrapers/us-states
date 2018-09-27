# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

ruby '2.4.1'

gem 'rest-client'
gem 'scraperwiki', github: 'openaustralia/scraperwiki-ruby', branch: 'morph_defaults'

group :development do
  gem 'pry'
end

group :test do
  gem 'rake'
  gem 'rubocop'
end
