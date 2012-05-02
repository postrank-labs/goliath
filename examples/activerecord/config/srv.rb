require 'mysql2'

ActiveRecord::Base.establish_connection(:adapter  => 'em_mysql2',
                                        :database => 'goliath_test',
                                        :username => 'goliath',
                                        :password => 'goliath',
                                        :host     => 'localhost',
                                        :pool     => 5)
