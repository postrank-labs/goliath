module Goliath
  module Rack
    module Validation
      autoload :Coerce, 'goliath/rack/validation/coerce'
      autoload :Required, 'goliath/rack/validation/required'
      autoload :Param,  'goliath/rack/validation/param'
      autoload :BooleanValue,  'goliath/rack/validation/boolean_value'
      autoload :DefaultParams, 'goliath/rack/validation/default_params'
      autoload :NumericRange,  'goliath/rack/validation/numeric_range'
      autoload :RequestMethod, 'goliath/rack/validation/request_method'
      autoload :RequiredParam, 'goliath/rack/validation/required_param'
      autoload :RequiredValue, 'goliath/rack/validation/required_value'
    end
  end
end
