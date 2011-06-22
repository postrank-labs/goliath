module Goliath
  module Rack
    module Validation
      autoload :BooleanValue,  'goliath/rack/validation/boolean_value'
      autoload :DefaultParams, 'goliath/rack/validation/default_params'
      autoload :NumericRange,  'goliath/rack/validation/numeric_range'
      autoload :RequestMethod, 'goliath/rack/validation/request_method'
      autoload :RequiredParam, 'goliath/rack/validation/required_param'
      autoload :RequiredValue, 'goliath/rack/validation/required_value'
    end
  end
end
