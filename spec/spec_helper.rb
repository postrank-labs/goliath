require 'bundler'

Bundler.setup
Bundler.require

require 'goliath/test_helper'

Goliath.env = :test

RSpec.configure do |c|
  c.include Goliath::TestHelper, :file_path => /spec\/integration/
end
