module Goliath
  module Rack
    module Formatters
      autoload :HTML, 'goliath/rack/formatters/html'
      autoload :JSON, 'goliath/rack/formatters/json'
      autoload :Plist, 'goliath/rack/formatters/plist'
      autoload :XML, 'goliath/rack/formatters/xml'
      autoload :YAML, 'goliath/rack/formatters/yaml'
    end
  end
end
