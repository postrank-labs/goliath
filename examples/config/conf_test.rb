config['global'] = 'my global'
config['test'] = options[:test]

import('shared')

environment :production do
  config['prod'] = 'my prod'
end

environment :development do
  config['dev'] = 'my dev'
end
