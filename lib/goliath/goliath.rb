require 'eventmachine'
require 'http/parser'
require 'async_rack'

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
  # @param [Symbol] env the environment symbol of [development|production|test]
  def env= e
    es = e.to_sym
    if ENVIRONMENTS.include? es
      @env = es
    else
      fail "did not recognize environment: #{e}, expected one of: #{ENVIRONMENTS.join(', ')}"
    end
  end

  # Sets the current goliath environment
  #
  # @param [String] env the environment string of [dev|prod|test]
  def short_env=(env)
    case(env.to_s)
    when 'dev'  then @env = :development
    when 'prod' then @env = :production
    when 'test' then @env = :test
    end
  end

  # Determines if we are in the production environment
  #
  # @return [Boolean] true if current environemnt is production, false otherwise
  def prod?
    env == :production
  end

  # Determines if we are in the development environment
  #
  # @return [Boolean] true if current environemnt is development, false otherwise
  def dev?
    env == :development
  end

  # Determines if we are in the test environment
  #
  # @return [Boolean] true if current environemnt is test, false otherwise
  def test?
    env == :test
  end
end
