#!/usr/bin/env ruby

# gem install em-synchrony
# gem install mysql2

# create database goliath_test
# create user 'goliath'@'localhost' identified by 'goliath'
# grant all on goliath_test.* to 'goliath'@'localhost'
# create table users (id int not null auto_increment primary key, name varchar(255), email varchar(255));
# insert into users (name, email) values ('dan', 'dj2@everyburning.com'), ('Ilya', 'ilya@igvita.com');

$: << "../../lib" << "./lib"

require 'goliath'
require 'em-synchrony/activerecord'
require 'yajl'

class User < ActiveRecord::Base
end

class Srv < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::DefaultMimeType
  use Goliath::Rack::Render, 'json'

  use Goliath::Rack::Validation::RequiredParam, {:key => 'id', :type => 'ID'}
  use Goliath::Rack::Validation::NumericRange, {:key => 'id', :min => 1}

  def response(env)
    [200, {}, User.find(params['id']).to_json]
  end
end
