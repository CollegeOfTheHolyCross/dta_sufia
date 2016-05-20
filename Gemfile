source 'https://rubygems.org'

#gem 'active-fedora', '9.9.1'

#gem 'hydra-access-controls', '9.5.0'

#Fix the 4kb session limit
gem 'activerecord-session_store'



#gem "rdf-vocab"
gem 'rdf', '1.99.0'

#gem 'mysql2', '0.3.18'
#gem 'blacklight', '5.16.2'
gem 'blacklight', '5.16.4'
#gem 'sufia', '6.4.0'
#gem 'google-api-client', '0.8.6'
gem 'sufia', '6.6.1'
#gem 'sufia', :git=>'https://github.com/projecthydra/sufia.git'
gem 'kaminari', github: 'jcoyne/kaminari', branch: 'sufia'  # required to handle pagination properly in dashboard. See https://github.com/amatsuda/kaminari/pull/322
gem "hydra-role-management"

gem "rest-client-components"
gem "rack-cache"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.6'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
#gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'qa'

#gem 'rdf-edtf', :git=>'https://github.com/dpla/rdf-edtf.git'
gem 'edtf'

gem "blacklight_range_limit"
gem "blacklight-maps"

gem 'rmagick', :require => 'RMagick'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

gem 'sprockets-rails', '2.3.3'

gem 'ckeditor', '4.1.6'


gem 'rsolr', '~> 1.0.6'
gem 'devise'
gem 'devise-guests', '~> 0.3'

gem 'friendly_id', '5.1.0'
gem 'gon'

gem 'rdf-blazegraph'

gem 'typhoeus'

gem 'rubyzip', '>= 1.0.0' # will load new rubyzip version

#gem 'sidekiq', :require=>['sidekiq', 'sidekiq/web']

group :development, :test do
  gem 'rspec-rails'
  gem 'jettywrapper'
end
