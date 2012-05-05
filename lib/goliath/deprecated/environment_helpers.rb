module Goliath
  #
  #
  # Deprecated helper methods for all pre-defined environments,
  #
  module EnvironmentHelpers

    ENVIRONMENTS = [:development, :production, :test, :staging]

    # for example:
    #
    #   def development?
    #     env? :development
    #   end
    ENVIRONMENTS.each do |e|
      define_method "#{e}?" do
        warn "[DEPRECATION] `Goliath.#{e}?` is deprecated.  Please use `Goliath.env?(#{e})` instead."
        env? e
      end
    end

    alias :prod? :production?
    alias :dev? :development?
  end
end
