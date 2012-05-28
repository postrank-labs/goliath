#!/usr/bin/env ruby

# This example shows an ActiveRecord model being exposed as an API using Grape and then being served up using Goliath.

# 1. Install these gems
# gem install em-synchrony
# gem install mysql2
# gem install grape

# 2. Create a database
# create database goliath_test
# create user 'goliath'@'localhost' identified by 'goliath'
# grant all on goliath_test.* to 'goliath'@'localhost'
# create table users (id int not null auto_increment primary key, name varchar(255), email varchar(255));
# insert into users (name, email) values ('dan', 'dj2@everyburning.com'), ('Ilya', 'ilya@igvita.com');

# 3. Start server
# ruby ./server.rb

# 4. Try Examples
# curl http://localhost:9000/v1/users/2.json
# => {"email":"ilya@igvita.com","id":2,"name":"Ilya"}

# All users
# curl http://localhost:9000/v1/users

# Create a new user
# curl -X POST -d '{"user":{"name":"David Jones","email":"david@example.com"}}' http://localhost:9000/v1/users/create

$: << "../../lib" << "./lib"

require 'goliath'
require 'em-synchrony/activerecord'
require 'yajl' if RUBY_PLATFORM != 'java'
require 'grape'

class User < ActiveRecord::Base
end

class MyAPI < Grape::API

  version 'v1', :using => :path
  format :json

  resource 'users' do
    get "/" do
      User.all
    end

    get "/:id" do
      User.find(params['id'])
    end

    post "/create" do
      User.create(params['user'])
    end
  end

end

class APIServer < Goliath::API

  def response(env)
    MyAPI.call(env)
  end

end