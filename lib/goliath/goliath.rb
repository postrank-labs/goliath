require 'eventmachine'
require 'http/parser'
require 'async_rack'
require 'goliath/constants'
require 'goliath/version'

# The Goliath Framework
module Goliath
  module_function

  ENVIRONMENTS = [:development, :production, :test, :staging]

  # for example:
  #
  #   def development?
  #     env? :development
  #   end
  class << self
    ENVIRONMENTS.each do |e|
      define_method "#{e}?" do
        warn "[DEPRECATION] `Goliath.#{e}?` is deprecated.  Please use `Goliath.env?(#{e})` instead."
        env? e
      end
    end

    alias :prod? :production?
    alias :dev? :development?

    # Controls whether or not the application will be run using an at_exit block.
    attr_accessor :run_app_on_exit
    alias_method :run_app_on_exit?, :run_app_on_exit
  end
  # By default, we do run the application using the at_exit block.
  self.run_app_on_exit = true

  # Retrieves the current goliath environment
  #
  # @return [String] the current environment
  def env
    @env
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
