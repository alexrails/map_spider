# frozen_string_literal: true

source "https://rubygems.org"

# HTTP
gem "httparty"
gem "retryable"

# ENV
gem "dotenv"

# CSV
gem "csv"

# CLI
gem "thor"

# UI
gem "colorize"
gem "ruby-progressbar"
gem "terminal-table"

# DEBUG
gem "pry-byebug"

group :test do
  gem "rspec"
  gem "rspec-mocks"
  gem "webmock"
end

group :development, :test do
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rspec", require: false
end
