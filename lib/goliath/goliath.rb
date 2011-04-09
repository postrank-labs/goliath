require 'eventmachine'
require 'http/parser'
require 'async_rack'

# The Goliath Framework
module Goliath
  module_function

  @env = :development

  # Retrieves the current goliath environment
  #
  # @return [String] the current environment
  def env
    @env
  end

  # Sets the current goliath environment
  #
  # @param [String] env the environment string of [dev|prod|test]
  def env=(env)
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
    @env == :production
  end

  # Determines if we are in the development environment
  #
  # @return [Boolean] true if current environemnt is development, false otherwise
  def dev?
    @env == :development
  end

  # Determines if we are in the test environment
  #
  # @return [Boolean] true if current environemnt is test, false otherwise
  def test?
    @env == :test
  end
end