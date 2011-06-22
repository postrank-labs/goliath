require 'eventmachine'
require 'http/parser'
require 'async_rack'
require 'goliath/constants'
require 'goliath/version'

# The Goliath Framework
module Goliath
  module_function

  ENVIRONMENTS = [:development, :production, :test]

  # Retrieves the current goliath environment
  #
  # @return [String] the current environment
  def env
    @env or fail "environment has not been set"
  end

  # Sets the current goliath environment
  #
  # @param [String|Symbol] env the environment symbol of [dev | development | prod | production | test]
  def env=(e)
    es = case(e.to_sym)
    when :dev  then :development
    when :prod then :production
    else e.to_sym
    end

    if ENVIRONMENTS.include?(es)
      @env = es
    else
      fail "did not recognize environment: #{e}, expected one of: #{ENVIRONMENTS.join(', ')}"
    end
  end

  # Determines if we are in the production environment
  #
  # @return [Boolean] true if current environment is production, false otherwise
  def prod?
    env == :production
  end

  # Determines if we are in the development environment
  #
  # @return [Boolean] true if current environment is development, false otherwise
  def dev?
    env == :development
  end

  # Determines if we are in the test environment
  #
  # @return [Boolean] true if current environment is test, false otherwise
  def test?
    env == :test
  end
end
