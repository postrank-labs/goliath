require 'eventmachine'
require 'http/parser'
require 'async_rack'
require 'goliath/constants'
require 'goliath/version'
require 'goliath/deprecated/environment_helpers'

# The Goliath Framework
module Goliath
  module_function
  extend EnvironmentHelpers

  # Retrieves the current goliath environment
  #
  # @return [String] the current environment
  def env
    @env or fail "environment has not been set"
  end

  # Sets the current goliath environment
  #
  # @param [String|Symbol] env the environment symbol
  def env=(e)
    @env = case(e.to_sym)
    when :dev  then :development
    when :prod then :production
    else e.to_sym
    end
  end

  # Determines if we are in a particular environment
  #
  # @return [Boolean] true if current environment matches, false otherwise
  def env?(e)
    env == e.to_sym
  end
end
