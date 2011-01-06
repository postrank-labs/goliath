
config['global'] = 'my global'

import('shared')

environment :production do
  config['prod'] = 'my prod'
end

environment :development do
  config['dev'] = 'my dev'
end
